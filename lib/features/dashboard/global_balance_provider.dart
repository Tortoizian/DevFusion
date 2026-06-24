import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/models.dart';
import '../../core/state/group_state.dart';
import '../../core/state/group_state_notifier.dart';

/// Sums the signed-in user's net balance across every group they belong to.
final globalBalanceProvider = FutureProvider<double>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return 0.0;

  final repository = ref.watch(databaseRepositoryProvider);
  final groups = await repository.fetchUserGroups(userId);

  var total = 0.0;
  for (final group in groups) {
    final expenses = await repository.fetchExpensesForGroup(group.id);
    final splits = await repository.fetchSplitsForGroup(group.id);
    final settlements = await repository.fetchSettlementsForGroup(group.id);

    final groupState = GroupState(
      groupId: group.id,
      expenses: expenses,
      splits: splits,
      settlements: settlements,
    );
    total += groupState.netBalances[userId] ?? 0.0;
  }

  return total;
});

/// Groups for the signed-in user — used to toggle dashboard empty state.
final userGroupsProvider = FutureProvider<List<GroupModel>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  return ref.watch(databaseRepositoryProvider).fetchUserGroups(userId);
});
