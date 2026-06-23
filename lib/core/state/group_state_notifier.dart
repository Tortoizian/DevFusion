import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repository/database_repository.dart';
import '../repository/mock_database_repository.dart';
import 'group_state.dart';

/// Provider for the DatabaseRepository. Defaults to [MockDatabaseRepository].
/// Can be overridden in the ProviderScope to use the real Supabase implementation.
final databaseRepositoryProvider = Provider<DatabaseRepository>((ref) {
  return MockDatabaseRepository();
});

/// StateNotifierProvider for managing the active group's state.
final groupStateNotifierProvider = StateNotifierProvider<GroupStateNotifier, GroupState>((ref) {
  final repository = ref.watch(databaseRepositoryProvider);
  return GroupStateNotifier(repository);
});

class GroupStateNotifier extends StateNotifier<GroupState> {
  final DatabaseRepository _repository;
  
  StreamSubscription? _expenseSub;
  StreamSubscription? _splitsSub;
  StreamSubscription? _settlementsSub;

  GroupStateNotifier(this._repository) : super(GroupState());

  /// Loads a group by its ID, fetches its members, and sets up real-time stream listeners.
  Future<void> loadGroup(String groupId) async {
    // Prevent reload if already loading the same group
    if (state.groupId == groupId && state.isLoading) return;

    // Clean up any existing listeners
    await _cancelSubscriptions();

    state = state.copyWith(
      groupId: groupId,
      isLoading: true,
      errorMessage: null,
      members: [],
      expenses: [],
      splits: [],
      settlements: [],
    );

    try {
      // 1. Fetch group members first (static query)
      final members = await _repository.fetchGroupMembers(groupId);
      state = state.copyWith(members: members);

      // 2. Set up real-time stream listeners
      _expenseSub = _repository.streamExpenses(groupId).listen(
        (expenses) {
          state = state.copyWith(expenses: expenses);
        },
        onError: (e) {
          state = state.copyWith(errorMessage: 'Real-time expenses sync error: $e');
        },
      );

      _splitsSub = _repository.streamSplits(groupId).listen(
        (splits) {
          state = state.copyWith(splits: splits);
        },
        onError: (e) {
          state = state.copyWith(errorMessage: 'Real-time splits sync error: $e');
        },
      );

      _settlementsSub = _repository.streamSettlements(groupId).listen(
        (settlements) {
          state = state.copyWith(settlements: settlements);
        },
        onError: (e) {
          state = state.copyWith(errorMessage: 'Real-time settlements sync error: $e');
        },
      );

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load group: $e',
      );
    }
  }

  /// Adds a new expense to the group.
  Future<void> addExpense({
    required String description,
    required double amount,
    required String payerId,
    required ExpenseCategory category,
    required SplitType splitType,
    required Map<String, double> userOwedAmounts,
  }) async {
    final groupId = state.groupId;
    if (groupId == null) {
      state = state.copyWith(errorMessage: 'No active group selected');
      return;
    }

    try {
      await _repository.addExpense(
        groupId: groupId,
        description: description,
        amount: amount,
        payerId: payerId,
        category: category,
        splitType: splitType,
        userOwedAmounts: userOwedAmounts,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to log expense: $e');
      rethrow;
    }
  }

  /// Initiates a settlement between a debtor and creditor.
  Future<void> settleDebt({
    required String debtorId,
    required String creditorId,
    required double amount,
  }) async {
    final groupId = state.groupId;
    if (groupId == null) {
      state = state.copyWith(errorMessage: 'No active group selected');
      return;
    }

    try {
      await _repository.createSettlement(
        groupId: groupId,
        debtorId: debtorId,
        creditorId: creditorId,
        amount: amount,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to initiate settlement: $e');
      rethrow;
    }
  }

  /// Confirms a settlement by the creditor (marking it settled).
  Future<void> confirmSettlement(String settlementId) async {
    try {
      await _repository.confirmSettlement(settlementId);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to confirm settlement: $e');
      rethrow;
    }
  }

  /// Helper to cancel all active stream subscriptions
  Future<void> _cancelSubscriptions() async {
    await _expenseSub?.cancel();
    await _splitsSub?.cancel();
    await _settlementsSub?.cancel();
    _expenseSub = null;
    _splitsSub = null;
    _settlementsSub = null;
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}
