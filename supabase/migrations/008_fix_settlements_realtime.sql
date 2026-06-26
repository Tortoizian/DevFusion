-- SplitSmart: tighten settlement RLS and document realtime requirements

drop policy if exists "Debtor can create settlement" on public.settlements;
create policy "Debtor can create settlement"
  on public.settlements
  for insert
  with check (
    auth.uid() = debtor_id
    and public.is_group_member(group_id)
    and exists (
      select 1
      from public.group_members gm
      where gm.group_id = group_id
        and gm.user_id = creditor_id
    )
  );

drop policy if exists "Creditor can confirm settlement" on public.settlements;
create policy "Creditor can confirm settlement"
  on public.settlements
  for update
  using (auth.uid() = creditor_id and public.is_group_member(group_id))
  with check (auth.uid() = creditor_id);
