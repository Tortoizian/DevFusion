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

Stream<List<GroupBalanceSummary>> _watchGroupBalanceSummaries(
  DatabaseRepository repository,
  String userId,
) async* {
  yield await _loadGroupBalanceSummaries(repository, userId);
  await for (final _ in repository.watchUserGroupsActivity(userId)) {
    yield await _loadGroupBalanceSummaries(repository, userId);
  }
}

void refreshDashboardBalances(WidgetRef ref) {
  ref.invalidate(userGroupSummariesProvider);
}

/// Groups with live per-group balances for the dashboard list.
final userGroupSummariesProvider = StreamProvider<List<GroupBalanceSummary>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const []);

  final repository = ref.watch(databaseRepositoryProvider);
  return _watchGroupBalanceSummaries(repository, userId);
});

/// Sums the signed-in user's net balance across every group they belong to.
final globalBalanceProvider = Provider<AsyncValue<double>>((ref) {
  return ref.watch(userGroupSummariesProvider).when(
        data: (summaries) => AsyncData(
          summaries.fold<double>(0.0, (total, summary) => total + summary.netBalance),
        ),
        loading: () => const AsyncLoading(),
        error: (error, stackTrace) => AsyncError(error, stackTrace),
      );
});

/// Groups for the signed-in user — used to toggle dashboard empty state.
final userGroupsProvider = Provider<List<GroupModel>>((ref) {
  return ref.watch(userGroupSummariesProvider).maybeWhen(
        data: (summaries) => summaries.map((summary) => summary.group).toList(),
        orElse: () => const [],
      );
});
