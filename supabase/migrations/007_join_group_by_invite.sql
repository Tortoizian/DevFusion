-- SplitSmart: join group by invite code (bypasses groups SELECT RLS for non-members)

create or replace function public.join_group_by_invite_code(code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  normalized_code text := upper(trim(code));
  target_group_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  select id into target_group_id
  from public.groups
  where invite_code = normalized_code;

  if target_group_id is null then
    raise exception 'Invalid invite code';
  end if;

  insert into public.group_members (group_id, user_id)
  values (target_group_id, auth.uid())
  on conflict (group_id, user_id) do nothing;

  return target_group_id;
end;
$$;

grant execute on function public.join_group_by_invite_code(text) to authenticated;
