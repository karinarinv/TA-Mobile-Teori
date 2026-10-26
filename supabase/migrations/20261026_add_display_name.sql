alter table public.users
add column if not exists display_name text;

update public.users
set display_name = username
where display_name is null or btrim(display_name) = '';
