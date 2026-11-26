-- STC CEAP Super Cup 2026 — run once in Supabase SQL Editor.
-- Public visitors can read tournament data. Only users listed in admin_users can edit it.
create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.tournament_state (
  id integer primary key check (id = 1),
  data jsonb not null default '{"teams":[],"players":[],"matches":[],"sponsors":[],"admins":[],"audit":[],"awards":{"playerOfTournament":"","bestGoalkeeper":"","fairPlay":""},"settings":{"date1":"2026-12-01","date2":"2026-12-02","half1":20,"half2":20,"thirdPlace":true,"fixtureMode":"manual","tieBreak":"penalties"}}'::jsonb,
  updated_at timestamptz not null default now()
);
insert into public.tournament_state(id) values (1) on conflict (id) do nothing;

alter table public.admin_users enable row level security;
alter table public.tournament_state enable row level security;
drop policy if exists "admins can read own role" on public.admin_users;
create policy "admins can read own role" on public.admin_users for select to authenticated using (user_id = auth.uid());
drop policy if exists "public can read tournament" on public.tournament_state;
create policy "public can read tournament" on public.tournament_state for select to anon, authenticated using (true);
drop policy if exists "admins can insert tournament state" on public.tournament_state;
create policy "admins can insert tournament state" on public.tournament_state for insert to authenticated with check (exists(select 1 from public.admin_users a where a.user_id=auth.uid()));
drop policy if exists "admins can update tournament state" on public.tournament_state;
create policy "admins can update tournament state" on public.tournament_state for update to authenticated using (exists(select 1 from public.admin_users a where a.user_id=auth.uid())) with check (exists(select 1 from public.admin_users a where a.user_id=auth.uid()));

-- Least-privilege API grants.
revoke all on public.admin_users from anon;
grant select on public.admin_users to authenticated;
grant select on public.tournament_state to anon, authenticated;
grant insert, update on public.tournament_state to authenticated;

-- Public media bucket for team/player/coach/sponsor photos. Upload/delete restricted to admins.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('tournament-media', 'tournament-media', true, 5242880, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = true, file_size_limit = 5242880, allowed_mime_types = excluded.allowed_mime_types;
drop policy if exists "public can view tournament media" on storage.objects;
create policy "public can view tournament media" on storage.objects for select to anon, authenticated using (bucket_id = 'tournament-media');
drop policy if exists "admins can upload tournament media" on storage.objects;
create policy "admins can upload tournament media" on storage.objects for insert to authenticated with check (bucket_id = 'tournament-media' and exists(select 1 from public.admin_users a where a.user_id=auth.uid()));
drop policy if exists "admins can update tournament media" on storage.objects;
create policy "admins can update tournament media" on storage.objects for update to authenticated using (bucket_id = 'tournament-media' and exists(select 1 from public.admin_users a where a.user_id=auth.uid())) with check (bucket_id = 'tournament-media' and exists(select 1 from public.admin_users a where a.user_id=auth.uid()));
drop policy if exists "admins can delete tournament media" on storage.objects;
create policy "admins can delete tournament media" on storage.objects for delete to authenticated using (bucket_id = 'tournament-media' and exists(select 1 from public.admin_users a where a.user_id=auth.uid()));

-- Enable Realtime updates for public live-score refreshes.
do $$ begin
  alter publication supabase_realtime add table public.tournament_state;
exception when duplicate_object then null;
when undefined_object then null;
end $$;

-- After creating each admin in Supabase Authentication, run the following
-- with that user's UUID (repeat for every authorised admin):
-- insert into public.admin_users(user_id) values ('PASTE-AUTH-USER-UUID-HERE');
