-- Magic Clicker online scoreboard setup
create table if not exists public.scores (
  id bigint generated always as identity primary key,
  player_id text,
  name text not null,
  score bigint not null,
  prestige int not null default 0,
  prestige_pts int not null default 0,
  exams int not null default 0,
  clicks bigint not null default 0,
  total_mana bigint not null default 0,
  total_crystals bigint not null default 0,
  total_souls bigint not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists scores_score_created_at_idx
  on public.scores (score desc, created_at asc);

delete from public.scores a
using public.scores b
where a.name = b.name
  and (
    a.score < b.score
    or (a.score = b.score and a.created_at > b.created_at)
  );

alter table public.scores add column if not exists player_id text;
update public.scores
set player_id = coalesce(player_id, 'legacy_' || id::text)
where player_id is null;
alter table public.scores alter column player_id set not null;
create unique index if not exists scores_player_id_uidx
  on public.scores (player_id);

create unique index if not exists scores_name_uidx
  on public.scores (name);

alter table public.scores enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'scores' and policyname = 'scores_select_all'
  ) then
    create policy scores_select_all
      on public.scores for select
      to anon
      using (true);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'scores' and policyname = 'scores_insert_all'
  ) then
    create policy scores_insert_all
      on public.scores for insert
      to anon
      with check (true);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'scores' and policyname = 'scores_update_all'
  ) then
    create policy scores_update_all
      on public.scores for update
      to anon
      using (true)
      with check (true);
  end if;
end $$;

alter publication supabase_realtime add table public.scores;
