import '../models/models.dart';
import '../algorithms/debt_simplification.dart';

class GroupState {
  final String? groupId;
  final GroupModel? group;
  final List<UserModel> members;
  final List<ExpenseModel> expenses;
  final List<ExpenseSplitModel> splits;
  final List<SettlementModel> settlements;
  final bool isLoading;
  final String? errorMessage;

  GroupState({
    this.groupId,
    this.group,
    this.members = const [],
    this.expenses = const [],
    this.splits = const [],
    this.settlements = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  GroupState copyWith({
    String? groupId,
    GroupModel? group,
    List<UserModel>? members,
    List<ExpenseModel>? expenses,
    List<ExpenseSplitModel>? splits,
    List<SettlementModel>? settlements,
    bool? isLoading,
    String? errorMessage,
  }) {
    return GroupState(
      groupId: groupId ?? this.groupId,
      group: group ?? this.group,
      members: members ?? this.members,
      expenses: expenses ?? this.expenses,
      splits: splits ?? this.splits,
      settlements: settlements ?? this.settlements,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Derived state: Computes the net balance for each group member.
  /// Formula: (Total Paid as Payer) - (Total Owed in Splits) + (Settlements Sent as Debtor) - (Settlements Received as Creditor)
  Map<String, double> get netBalances {
    final Map<String, double> balances = {};

    // Initialize every member's balance to 0.0
    for (var member in members) {
      balances[member.id] = 0.0;
    }

    // 1. Accumulate raw expenses and splits
    for (var expense in expenses) {
      // Payer gets credited the full expense amount
      if (balances.containsKey(expense.payerId)) {
        balances[expense.payerId] = balances[expense.payerId]! + expense.amount;
      } else {
        // Fallback in case member list is out of sync
        balances[expense.payerId] = expense.amount;
      }

      // Each participant gets debited their share
      final expenseSplits = splits.where((s) => s.expenseId == expense.id);
      for (var split in expenseSplits) {
        if (balances.containsKey(split.userId)) {
          balances[split.userId] = balances[split.userId]! - split.amountOwed;
        } else {
          balances[split.userId] = -split.amountOwed;
        }
      }
    }

    // 2. Adjust for settlements (ONLY confirmed ones)
    for (var settlement in settlements) {
      if (settlement.status == SettlementStatus.confirmed) {
        // Debtor paid, so their debt decreases (moves balance positive)
        if (balances.containsKey(settlement.debtorId)) {
          balances[settlement.debtorId] = balances[settlement.debtorId]! + settlement.amount;
        } else {
          balances[settlement.debtorId] = settlement.amount;
        }

        // Creditor received money, so what they are owed decreases (moves balance negative)
        if (balances.containsKey(settlement.creditorId)) {
          balances[settlement.creditorId] = balances[settlement.creditorId]! - settlement.amount;
        } else {
          balances[settlement.creditorId] = -settlement.amount;
        }
      }
    }

    return balances;
  }

  /// Derived state: Calculates the simplified cash flows needed to settle all debts in the group.
  List<DebtTransfer> get simplifiedDebts {
    return DebtSimplificationEngine.simplifyDebts(netBalances);
  }

  @override
  String toString() {
    return 'GroupState(groupId: $groupId, group: ${group?.name}, membersCount: ${members.length}, expensesCount: ${expenses.length}, splitsCount: ${splits.length}, settlementsCount: ${settlements.length})';
  }
}
