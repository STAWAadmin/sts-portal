-- STS Entry Portal: run this ONCE in Supabase -> SQL Editor -> New query -> Run.
-- It creates the tables, the security rules, the functions the website calls,
-- and the file storage bucket.

create extension if not exists pgcrypto;

-- ---------- Tables ----------
create table if not exists schools (
  code text primary key,
  name text not null,
  coord text not null,
  email text not null unique,
  phone text, ns text, ne text, nj text,
  created_at timestamptz default now()
);

create table if not exists entries (
  id text primary key,                       -- school code + 2 digits, e.g. 482101
  school text not null references schools(code),
  cat text not null,
  age text not null,
  type text not null,                        -- Individual or Group
  students jsonb not null,
  title text not null,
  summary text not null,
  link text default '',
  file text default '',
  report text default '',
  pub boolean default false,                 -- work publication permission
  safe boolean default true,                 -- safety declaration (required to submit)
  token text not null unique default encode(gen_random_bytes(9), 'hex'),  -- private judge link
  created_at timestamptz default now()
);

create table if not exists judges (
  code text primary key,                     -- 3-digit judge code
  name text not null,
  email text not null,
  phone text, org text, prev text,
  cats jsonb, ages jsonb, disc jsonb,
  coi text, "coiNote" text, teach text, "tAges" jsonb, "tCats" jsonb,
  created_at timestamptz default now()
);

create table if not exists admins (email text primary key);

-- ---------- Security: nobody can read or write tables directly except admins ----------
alter table schools enable row level security;
alter table entries enable row level security;
alter table judges  enable row level security;
alter table admins  enable row level security;

create or replace function is_admin() returns boolean
language sql security definer stable set search_path = public as $$
  select exists (select 1 from admins
                 where lower(email) = lower(coalesce(auth.jwt() ->> 'email', '')))
$$;

drop policy if exists admin_all_schools on schools;
drop policy if exists admin_all_entries on entries;
drop policy if exists admin_all_judges  on judges;
create policy admin_all_schools on schools for all to authenticated using (is_admin()) with check (is_admin());
create policy admin_all_entries on entries for all to authenticated using (is_admin()) with check (is_admin());
create policy admin_all_judges  on judges  for all to authenticated using (is_admin()) with check (is_admin());

-- ---------- Functions the public website calls ----------
create or replace function register_school(p jsonb) returns text
language plpgsql security definer set search_path = public as $$
declare c text; em text := lower(trim(coalesce(p->>'email','')));
begin
  if coalesce(trim(p->>'name'),'') = '' or coalesce(trim(p->>'coord'),'') = '' or position('@' in em) = 0 then
    raise exception 'Please complete the school name, coordinator and email.';
  end if;
  if exists (select 1 from schools where email = em) then
    raise exception 'That email is already registered. Log in with your school code instead.';
  end if;
  loop
    c := (1000 + floor(random() * 9000))::int::text;
    exit when not exists (select 1 from schools where code = c);
  end loop;
  insert into schools (code, name, coord, email, phone, ns, ne, nj)
  values (c, trim(p->>'name'), trim(p->>'coord'), em, p->>'phone', p->>'ns', p->>'ne', p->>'nj');
  return c;
end $$;

-- Returns the school and its own entries, or null if the code and email don't match.
create or replace function school_login(p_code text, p_email text) returns jsonb
language sql security definer set search_path = public as $$
  select jsonb_build_object(
           'school',  to_jsonb(s) - 'created_at',
           'entries', coalesce((select jsonb_agg(to_jsonb(e) - 'token' order by e.id)
                                from entries e where e.school = s.code), '[]'::jsonb))
  from schools s
  where s.code = p_code and s.email = lower(trim(p_email))
$$;

create or replace function submit_entry(p_code text, p_email text, p jsonb) returns text
language plpgsql security definer set search_path = public as $$
declare n int; nid text;
begin
  if not exists (select 1 from schools where code = p_code and email = lower(trim(p_email))) then
    raise exception 'Login not recognised.';
  end if;
  if coalesce(trim(p->>'title'),'') = '' or coalesce(trim(p->>'summary'),'') = '' then
    raise exception 'Please complete the entry title and summary.';
  end if;
  perform pg_advisory_xact_lock(hashtext(p_code));          -- stops two entries getting the same number
  select coalesce(max(substr(id, 5)::int), 0) + 1 into n from entries where school = p_code;
  if n > 99 then raise exception 'This school has reached 99 entries.'; end if;
  nid := p_code || lpad(n::text, 2, '0');
  insert into entries (id, school, cat, age, type, students, title, summary, link, file, report, pub)
  values (nid, p_code, p->>'cat', p->>'age', p->>'type', p->'students',
          trim(p->>'title'), trim(p->>'summary'),
          coalesce(p->>'link',''), coalesce(p->>'file',''), coalesce(p->>'report',''),
          coalesce((p->>'pub')::boolean, false));
  return nid;
end $$;

create or replace function register_judge(p jsonb) returns text
language plpgsql security definer set search_path = public as $$
declare c text;
begin
  if coalesce(trim(p->>'name'),'') = '' or position('@' in coalesce(p->>'email','')) = 0 then
    raise exception 'Please enter your name and a valid email.';
  end if;
  loop
    c := (100 + floor(random() * 900))::int::text;
    exit when not exists (select 1 from judges where code = c);
  end loop;
  insert into judges (code, name, email, phone, org, prev, cats, ages, disc, coi, "coiNote", teach, "tAges", "tCats")
  values (c, trim(p->>'name'), p->>'email', p->>'phone', p->>'org', p->>'prev',
          p->'cats', p->'ages', p->'disc', p->>'coi', p->>'coiNote', p->>'teach', p->'tAges', p->'tCats');
  return c;
end $$;

-- A judge link opens ONE entry, with no student or school names.
create or replace function judge_entry(p_token text) returns jsonb
language sql security definer set search_path = public as $$
  select jsonb_build_object('id', id, 'cat', cat, 'age', age, 'title', title,
                            'summary', summary, 'link', link, 'file', file, 'report', report)
  from entries where token = p_token
$$;

grant execute on function register_school(jsonb), school_login(text, text), submit_entry(text, text, jsonb),
                          register_judge(jsonb), judge_entry(text), is_admin() to anon, authenticated;

-- ---------- File storage ----------
-- Files get long random web addresses, so only people given a link can open them.
insert into storage.buckets (id, name, public, file_size_limit)
values ('entries', 'entries', true, 52428800)
on conflict (id) do nothing;

drop policy if exists "anyone can upload entry files" on storage.objects;
create policy "anyone can upload entry files" on storage.objects
  for insert to anon, authenticated with check (bucket_id = 'entries');

-- ---------- Your admin account ----------
-- Create the user first (README step 3), then this line makes them an admin.
insert into admins (email) values ('admin@stawa.net') on conflict do nothing;
