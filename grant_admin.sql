-- Replace the UUID with the user's ID from Supabase Authentication > Users.
insert into public.admin_users(user_id)
values ('PASTE-AUTH-USER-UUID-HERE')
on conflict (user_id) do nothing;
