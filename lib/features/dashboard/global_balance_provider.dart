import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/models.dart';
import '../../core/repository/database_repository.dart';
import '../../core/state/group_state.dart';
import '../../core/state/group_state_notifier.dart';

class GroupBalanceSummary {
  final GroupModel group;
  final double netBalance;

  const GroupBalanceSummary({
    required this.group,
    required this.netBalance,
  });
}

Future<List<GroupBalanceSummary>> _loadGroupBalanceSummaries(
  DatabaseRepository repository,
  String userId,
) async {
  final groups = await repository.fetchUserGroups(userId);
  final summaries = <GroupBalanceSummary>[];

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

    summaries.add(
      GroupBalanceSummary(
        group: group,
        netBalance: groupState.netBalances[userId] ?? 0.0,
      ),
    );
  }

  return summaries;
}

/// Sums the signed-in user's net balance across every group they belong to.
final globalBalanceProvider = FutureProvider<double>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return 0.0;

  final summaries = await ref.watch(userGroupSummariesProvider.future);
  return summaries.fold<double>(0.0, (total, summary) => total + summary.netBalance);
});

/// Groups with per-group balances for the dashboard list.
final userGroupSummariesProvider = FutureProvider<List<GroupBalanceSummary>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final repository = ref.watch(databaseRepositoryProvider);
  return _loadGroupBalanceSummaries(repository, userId);
});

/// Groups for the signed-in user — used to toggle dashboard empty state.
final userGroupsProvider = FutureProvider<List<GroupModel>>((ref) async {
  final summaries = await ref.watch(userGroupSummariesProvider.future);
  return summaries.map((summary) => summary.group).toList();
});
