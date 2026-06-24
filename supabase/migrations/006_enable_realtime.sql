-- SplitSmart: enable Realtime WebSocket broadcasts for live sync
-- Run in Supabase SQL Editor after 005_rls.sql
-- Verify: Dashboard → Database → Replication → tables listed

alter publication supabase_realtime add table public.expenses;
alter publication supabase_realtime add table public.expense_splits;
alter publication supabase_realtime add table public.settlements;
alter publication supabase_realtime add table public.group_members;
