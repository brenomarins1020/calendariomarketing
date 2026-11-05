-- Calendário de Marketing — lembretes no WhatsApp (Z-API)
-- Rode uma vez no SQL Editor do Supabase. Pode rodar de novo sem problema.
--
-- Todo dia às 13:00 (horário de Brasília), cada responsável com WhatsApp cadastrado
-- recebe a lista dos posts dele marcados para o dia seguinte que ainda não foram publicados.

-- 1) Extensões: agendador (pg_cron) e chamadas HTTP (pg_net)
create extension if not exists pg_cron;
create extension if not exists pg_net;

-- 2) WhatsApp do responsável (só números, com 55 + DDD)
alter table public.people add column if not exists phone text;

-- 3) Configurações privadas (credenciais da Z-API). RLS ligado e SEM políticas:
--    o site (chave publishable) não consegue ler nem escrever aqui.
create table if not exists public.app_settings (
  key   text primary key,
  value text not null
);
alter table public.app_settings enable row level security;
revoke all on public.app_settings from anon, authenticated;

-- 4) Registro dos lembretes enviados (evita mandar duas vezes o mesmo post)
create table if not exists public.reminders_log (
  post_id    text not null,
  person_id  text not null,
  for_date   date not null,
  phone      text,
  request_id bigint,
  sent_at    timestamptz not null default now(),
  primary key (post_id, for_date)
);
alter table public.reminders_log enable row level security;
revoke all on public.reminders_log from anon, authenticated;

-- 5) Envia uma mensagem de texto pela Z-API (assíncrono, via pg_net)
create or replace function public.mkt_whatsapp_send(p_phone text, p_message text)
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  v_instance text;
  v_token    text;
  v_client   text;
  v_phone    text := regexp_replace(coalesce(p_phone, ''), '\D', '', 'g');
begin
  select value into v_instance from public.app_settings where key = 'zapi_instance_id';
  select value into v_token    from public.app_settings where key = 'zapi_token';
  select value into v_client   from public.app_settings where key = 'zapi_client_token';
  if v_instance is null or v_token is null then
    raise exception 'Z-API não configurada: preencha zapi_instance_id e zapi_token em app_settings';
  end if;
  if length(v_phone) in (10, 11) then v_phone := '55' || v_phone; end if;

  return net.http_post(
    url     := format('https://api.z-api.io/instances/%s/token/%s/send-text', v_instance, v_token),
    body    := jsonb_build_object('phone', v_phone, 'message', p_message),
    headers := jsonb_build_object('Content-Type', 'application/json', 'Client-Token', coalesce(v_client, '')),
    timeout_milliseconds := 15000
  );
end;
$$;

-- 6) Monta e envia os lembretes de um dia (padrão: amanhã, no horário de Brasília)
create or replace function public.mkt_send_whatsapp_reminders(p_for date default null)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_for   date := coalesce(p_for, (now() at time zone 'America/Sao_Paulo')::date + 1);
  v_site  text;
  v_dia   text := (array['domingo','segunda','terça','quarta','quinta','sexta','sábado'])[extract(dow from v_for)::int + 1];
  v_msg   text;
  v_req   bigint;
  v_count integer := 0;
  r record;
begin
  select value into v_site from public.app_settings where key = 'site_url';

  for r in
    select pe.id   as person_id,
           pe.name as person_name,
           pe.phone,
           count(*) as n,
           array_agg(po.id) as post_ids,
           string_agg(format('• %s — %s', coalesce(ch.name, 'Sem canal'), po.title), E'\n'
                      order by coalesce(ch.ord, 999), po.ts) as lines
      from public.posts po
      join public.people pe on pe.id = po.person_id
      left join public.channels ch on ch.id = po.channel_id
     where po.date = v_for
       and not po.done
       and coalesce(pe.phone, '') <> ''
       and not exists (select 1 from public.reminders_log l where l.post_id = po.id and l.for_date = v_for)
     group by pe.id, pe.name, pe.phone
  loop
    v_msg := format(
      E'Olá, %s! 👋\n\nLembrete: amanhã (%s, %s) você tem %s para publicar:\n\n%s%s',
      r.person_name, v_dia, to_char(v_for, 'DD/MM'),
      case when r.n = 1 then '1 post' else r.n || ' posts' end,
      r.lines,
      case when v_site is not null then E'\n\nCalendário: ' || v_site else '' end
    );
    v_req := public.mkt_whatsapp_send(r.phone, v_msg);
    insert into public.reminders_log (post_id, person_id, for_date, phone, request_id)
    select unnest(r.post_ids), r.person_id, v_for, r.phone, v_req
    on conflict do nothing;
    v_count := v_count + 1;
  end loop;

  return v_count; -- quantas pessoas receberam mensagem
end;
$$;

-- Só o servidor pode executar (o site não)
revoke all on function public.mkt_whatsapp_send(text, text) from public, anon, authenticated;
revoke all on function public.mkt_send_whatsapp_reminders(date) from public, anon, authenticated;
grant execute on function public.mkt_whatsapp_send(text, text) to service_role;
grant execute on function public.mkt_send_whatsapp_reminders(date) to service_role;

-- 7) Agendamento: 16:00 UTC = 13:00 em Brasília (sem horário de verão)
do $$
begin
  perform cron.unschedule(jobid) from cron.job where jobname = 'lembrete-whatsapp-13h';
  perform cron.schedule('lembrete-whatsapp-13h', '0 16 * * *', 'select public.mkt_send_whatsapp_reminders()');
end $$;

-- 8) Endereço do site (aparece no fim da mensagem)
insert into public.app_settings (key, value)
values ('site_url', 'https://calendariomarketing.vercel.app')
on conflict (key) do nothing;

-- Depois, cadastre as credenciais da Z-API (troque os valores entre aspas):
-- insert into public.app_settings (key, value) values
--   ('zapi_instance_id',  'SEU_INSTANCE_ID'),
--   ('zapi_token',        'SEU_TOKEN'),
--   ('zapi_client_token', 'SEU_CLIENT_TOKEN')
-- on conflict (key) do update set value = excluded.value;
--
-- Testes úteis:
--   select public.mkt_whatsapp_send('11987654321', 'Teste do calendário ✅');
--   select public.mkt_send_whatsapp_reminders('2026-11-20');   -- envia os lembretes desse dia agora
--   select * from net._http_response order by created desc limit 5;  -- resposta da Z-API
