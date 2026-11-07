-- Família Prospera — banco de dados (versão de teste, sem login)
-- Cole tudo no SQL Editor do Supabase e clique em Run. Projeto separado do Vitrine.
-- Quem tem o link/código da família consegue ver e editar os planos dessa família.

create extension if not exists pgcrypto;

create table if not exists public.familias (
  id text primary key,
  nome text not null,
  criada timestamptz not null default now()
);

create table if not exists public.pessoas (
  id uuid primary key default gen_random_uuid(),
  familia_id text not null references public.familias(id) on delete cascade,
  nome text not null,
  mural jsonb not null default '{}'::jsonb,   -- metas que a pessoa escolheu mostrar, por trimestre
  criada timestamptz not null default now()
);

create table if not exists public.planos (
  pessoa_id uuid not null references public.pessoas(id) on delete cascade,
  trimestre text not null,                     -- ex.: 2026-T4
  dados jsonb not null default '{}'::jsonb,    -- metas, check-ins, reflexões e colheita
  atualizado timestamptz not null default now(),
  primary key (pessoa_id, trimestre)
);

-- As tabelas ficam fechadas: o site só acessa pelas funções abaixo, sempre com o código da família.
alter table public.familias enable row level security;
alter table public.pessoas  enable row level security;
alter table public.planos   enable row level security;

create or replace function public.criar_familia(p_nome text)
returns text language plpgsql security definer set search_path = public as $$
declare c text; a text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; i int;
begin
  if coalesce(trim(p_nome), '') = '' then raise exception 'nome obrigatorio'; end if;
  loop
    c := '';
    for i in 1..6 loop c := c || substr(a, 1 + floor(random() * length(a))::int, 1); end loop;
    exit when not exists (select 1 from familias where id = c);
  end loop;
  insert into familias (id, nome) values (c, left(trim(p_nome), 60));
  return c;
end $$;

create or replace function public.ver_familia(p_codigo text)
returns jsonb language sql security definer stable set search_path = public as $$
  select jsonb_build_object(
    'nome', f.nome,
    'pessoas', coalesce((
      select jsonb_agg(jsonb_build_object('id', p.id, 'nome', p.nome, 'mural', p.mural) order by p.criada)
      from pessoas p where p.familia_id = f.id), '[]'::jsonb))
  from familias f where f.id = upper(p_codigo);
$$;

create or replace function public.adicionar_pessoa(p_codigo text, p_nome text)
returns uuid language plpgsql security definer set search_path = public as $$
declare novo uuid;
begin
  if coalesce(trim(p_nome), '') = '' then raise exception 'nome obrigatorio'; end if;
  if not exists (select 1 from familias where id = upper(p_codigo)) then return null; end if;
  if (select count(*) from pessoas where familia_id = upper(p_codigo)) >= 30 then raise exception 'limite de pessoas'; end if;
  insert into pessoas (familia_id, nome) values (upper(p_codigo), left(trim(p_nome), 40)) returning id into novo;
  return novo;
end $$;

create or replace function public.ler_plano(p_codigo text, p_pessoa uuid, p_trimestre text)
returns jsonb language sql security definer stable set search_path = public as $$
  select pl.dados from planos pl
  join pessoas p on p.id = pl.pessoa_id
  where p.id = p_pessoa and p.familia_id = upper(p_codigo) and pl.trimestre = p_trimestre;
$$;

create or replace function public.salvar_plano(p_codigo text, p_pessoa uuid, p_trimestre text, p_dados jsonb, p_mural jsonb)
returns boolean language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from pessoas where id = p_pessoa and familia_id = upper(p_codigo)) then return false; end if;
  if octet_length(p_dados::text) > 200000 then raise exception 'plano muito grande'; end if;
  insert into planos (pessoa_id, trimestre, dados, atualizado) values (p_pessoa, p_trimestre, p_dados, now())
    on conflict (pessoa_id, trimestre) do update set dados = excluded.dados, atualizado = now();
  update pessoas set mural = jsonb_set(coalesce(mural, '{}'::jsonb), array[p_trimestre], coalesce(p_mural, '{}'::jsonb), true)
    where id = p_pessoa;
  return true;
end $$;

revoke all on function public.criar_familia(text) from public;
revoke all on function public.ver_familia(text) from public;
revoke all on function public.adicionar_pessoa(text, text) from public;
revoke all on function public.ler_plano(text, uuid, text) from public;
revoke all on function public.salvar_plano(text, uuid, text, jsonb, jsonb) from public;
grant execute on function public.criar_familia(text) to anon, authenticated;
grant execute on function public.ver_familia(text) to anon, authenticated;
grant execute on function public.adicionar_pessoa(text, text) to anon, authenticated;
grant execute on function public.ler_plano(text, uuid, text) to anon, authenticated;
grant execute on function public.salvar_plano(text, uuid, text, jsonb, jsonb) to anon, authenticated;
