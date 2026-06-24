-- SplitSmart: expenses and per-member split breakdown

create table public.expenses (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete cascade,
  description text not null,
  amount numeric(12, 2) not null check (amount > 0),
  payer_id uuid not null references public.profiles (id),
  category text not null,
  split_type text not null,
  receipt_url text,
  created_at timestamptz not null default now()
);

create table public.expense_splits (
  id uuid primary key default gen_random_uuid(),
  expense_id uuid not null references public.expenses (id) on delete cascade,
  user_id uuid not null references public.profiles (id),
  amount_owed numeric(12, 2) not null check (amount_owed >= 0)
);

create index idx_expenses_group on public.expenses (group_id);
create index idx_expenses_payer on public.expenses (payer_id);
create index idx_splits_expense on public.expense_splits (expense_id);
create index idx_splits_user on public.expense_splits (user_id);

-- category: food, travel, rent, utilities, entertainment, settlement, other
-- split_type: equal, percentage, exact, shares
