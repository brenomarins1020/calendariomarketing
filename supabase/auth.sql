-- Calendário de Marketing — contas (usuário + senha), cada conta com o seu próprio calendário
-- Rode uma vez no SQL Editor do Supabase. Pode rodar de novo sem problema.
--
-- Também é preciso desligar a confirmação de e-mail (o login é só usuário + senha):
-- Authentication → Sign In / Providers → Email → desligue "Confirm email" → Save.

-- 1) Desliga o lembrete de WhatsApp, se ele foi criado antes
do $$
begin
  if exists (select 1 from pg_namespace where nspname = 'cron') then
    perform cron.unschedule(jobid) from cron.job where jobname = 'lembrete-whatsapp-13h';
  end if;
end $$;

-- 2) Cada registro passa a ter um dono (a conta que criou)
alter table public.channels add column if not exists owner uuid default auth.uid() references auth.users (id) on delete cascade;
alter table public.people   add column if not exists owner uuid default auth.uid() references auth.users (id) on delete cascade;
alter table public.posts    add column if not exists owner uuid default auth.uid() references auth.users (id) on delete cascade;
create index if not exists channels_owner_idx on public.channels (owner);
create index if not exists people_owner_idx   on public.people (owner);
create index if not exists posts_owner_idx    on public.posts (owner);

-- 3) Permissões: só quem está logado, e cada conta só vê e altera o que é seu
do $$
declare t text;
begin
  foreach t in array array['channels', 'people', 'posts'] loop
    execute format('drop policy if exists "acesso publico" on public.%I', t);
    execute format('drop policy if exists "dono" on public.%I', t);
    execute format(
      'create policy "dono" on public.%I for all to authenticated
         using (owner = (select auth.uid())) with check (owner = (select auth.uid()))', t);
    execute format('revoke all on public.%I from anon', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
  end loop;
end $$;

-- Os dados antigos (criados antes das contas) ficam sem dono e não aparecem para ninguém.
-- Para passá-los para uma conta, troque o usuário abaixo e rode:
-- update public.channels set owner = (select id from auth.users where email = 'SEU_USUARIO@calendariomarketing.vercel.app') where owner is null;
-- update public.people   set owner = (select id from auth.users where email = 'SEU_USUARIO@calendariomarketing.vercel.app') where owner is null;
-- update public.posts    set owner = (select id from auth.users where email = 'SEU_USUARIO@calendariomarketing.vercel.app') where owner is null;
