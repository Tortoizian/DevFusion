-- SplitSmart: UPI settlement records (pending → confirmed)

create table public.settlements (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete cascade,
  debtor_id uuid not null references public.profiles (id),
  creditor_id uuid not null references public.profiles (id),
  amount numeric(12, 2) not null check (amount > 0),
  status text not null default 'pending' check (status in ('pending', 'confirmed', 'cancelled')),
  created_at timestamptz not null default now()
);

create index idx_settlements_group on public.settlements (group_id);
create index idx_settlements_debtor on public.settlements (debtor_id);
create index idx_settlements_creditor on public.settlements (creditor_id);
