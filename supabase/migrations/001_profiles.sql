-- SplitSmart: user profiles linked to Supabase Auth
-- Run in Supabase SQL Editor (Dashboard → SQL → New query)

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null,
  upi_id text not null default '',
  avatar_url text,
  fcm_token text,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Users can view own profile"
  on public.profiles
  for select
  using (auth.uid() = id);

create policy "Users can insert own profile"
  on public.profiles
  for insert
  with check (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles
  for update
  using (auth.uid() = id);
