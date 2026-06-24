-- SplitSmart: Row Level Security for all tables
-- Run in Supabase SQL Editor after 004_settlements.sql

create or replace function public.is_group_member(gid uuid)
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1
    from public.group_members
    where group_id = gid
      and user_id = auth.uid()
  );
$$;

-- groups
alter table public.groups enable row level security;

create policy "Members and creators can view groups"
  on public.groups
  for select
  using (public.is_group_member(id) or auth.uid() = created_by);

create policy "Auth users can create groups"
  on public.groups
  for insert
  with check (auth.uid() = created_by);

create policy "Creator can update group"
  on public.groups
  for update
  using (auth.uid() = created_by);

-- group_members
alter table public.group_members enable row level security;

create policy "Members can view group membership"
  on public.group_members
  for select
  using (public.is_group_member(group_id));

create policy "Users can join groups"
  on public.group_members
  for insert
  with check (auth.uid() = user_id);

-- expenses
alter table public.expenses enable row level security;

create policy "Members can view expenses"
  on public.expenses
  for select
  using (public.is_group_member(group_id));

create policy "Members can add expenses"
  on public.expenses
  for insert
  with check (public.is_group_member(group_id));

-- expense_splits
alter table public.expense_splits enable row level security;

create policy "Members can view splits"
  on public.expense_splits
  for select
  using (
    exists (
      select 1
      from public.expenses e
      where e.id = expense_id
        and public.is_group_member(e.group_id)
    )
  );

create policy "Members can add splits"
  on public.expense_splits
  for insert
  with check (
    exists (
      select 1
      from public.expenses e
      where e.id = expense_id
        and public.is_group_member(e.group_id)
    )
  );

-- settlements
alter table public.settlements enable row level security;

create policy "Members can view settlements"
  on public.settlements
  for select
  using (public.is_group_member(group_id));

create policy "Debtor can create settlement"
  on public.settlements
  for insert
  with check (auth.uid() = debtor_id and public.is_group_member(group_id));

create policy "Creditor can confirm settlement"
  on public.settlements
  for update
  using (auth.uid() = creditor_id);

-- profiles: allow group co-members to read UPI VPAs for settlement
create policy "Group members can view co-member profiles"
  on public.profiles
  for select
  using (
    id in (
      select gm2.user_id
      from public.group_members gm1
      join public.group_members gm2 on gm1.group_id = gm2.group_id
      where gm1.user_id = auth.uid()
    )
  );
