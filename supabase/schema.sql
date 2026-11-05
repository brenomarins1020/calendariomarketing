-- Calendário de Marketing — estrutura do banco (rode uma vez no SQL Editor do Supabase)

create table if not exists public.channels (
  id         text primary key,
  name       text not null,
  ord        integer not null default 0,
  updated_at timestamptz not null default now()
);

create table if not exists public.people (
  id         text primary key,
  name       text not null,
  color      text not null default '#4f46e5',
  updated_at timestamptz not null default now()
);

create table if not exists public.posts (
  id         text primary key,
  title      text not null,
  person_id  text,
  channel_id text not null,
  date       date not null,
  done       boolean not null default false,
  ts         bigint not null default 0,
  updated_at timestamptz not null default now()
);
create index if not exists posts_date_idx on public.posts (date);

-- Acesso: o calendário é compartilhado por link, então leitura e escrita são liberadas
alter table public.channels enable row level security;
alter table public.people   enable row level security;
alter table public.posts    enable row level security;

do $$
declare t text;
begin
  foreach t in array array['channels','people','posts'] loop
    execute format('drop policy if exists "acesso publico" on public.%I', t);
    execute format('create policy "acesso publico" on public.%I for all to anon, authenticated using (true) with check (true)', t);
  end loop;
end $$;

-- Tempo real: avisa todos os navegadores abertos quando algo muda
do $$
declare t text;
begin
  foreach t in array array['channels','people','posts'] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;

-- Canais iniciais (só se ainda não houver nenhum)
insert into public.channels (id, name, ord)
select * from (values
  ('ch_instagram',   'Instagram',   0),
  ('ch_projecjr',    'Projec-jr',   1),
  ('ch_projeguinho', 'Projeguinho', 2),
  ('ch_tiktok',      'TikTok',      3),
  ('ch_blog',        'Blog',        4),
  ('ch_linkedin',    'LinkedIn',    5)
) as v(id, name, ord)
where not exists (select 1 from public.channels);
