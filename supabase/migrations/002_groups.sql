-- SplitSmart: groups and membership junction table

create table public.groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  invite_code text not null unique,
  created_by uuid not null references public.profiles (id),
  category text not null default 'other',
  is_trip_mode boolean not null default false,
  trip_start date,
  trip_end date,
  budget numeric(12, 2),
  created_at timestamptz not null default now()
);

create table public.group_members (
  group_id uuid not null references public.groups (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

create index idx_group_members_user on public.group_members (user_id);
create index idx_groups_invite_code on public.groups (invite_code);
