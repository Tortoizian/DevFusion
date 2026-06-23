import 'package:collection/collection.dart';

class DebtTransfer {
  final String fromUserId;
  final String toUserId;
  final double amount;

  DebtTransfer({
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
  });

  @override
  String toString() => 'DebtTransfer(from: $fromUserId, to: $toUserId, amount: ${amount.toStringAsFixed(2)})';
}

class DebtSimplificationEngine {
  /// Simplifies the debts among a group of users given their net balances.
  /// Net balance is calculated as:
  /// (Total Owed/Paid by user) - (Total Owed by user in splits) + (Settlements Sent) - (Settlements Received)
  ///
  /// Positive net balance means the user is a creditor (is owed money).
  /// Negative net balance means the user is a debtor (owes money).
  static List<DebtTransfer> simplifyDebts(Map<String, double> netBalances) {
    final List<DebtTransfer> transfers = [];

    // Filter out zero balances and round to 2 decimal places to avoid floating-point errors
    final Map<String, double> filteredBalances = {};
    netBalances.forEach((userId, balance) {
      final rounded = _round(balance);
      if (rounded.abs() >= 0.01) {
        filteredBalances[userId] = rounded;
      }
    });

    // Create Max-Heaps for Creditors (positive balance) and Debtors (negative balance, absolute value)
    final creditors = PriorityQueue<_HeapNode>((a, b) => b.amount.compareTo(a.amount));
    final debtors = PriorityQueue<_HeapNode>((a, b) => b.amount.compareTo(a.amount));

    filteredBalances.forEach((userId, balance) {
      if (balance > 0) {
        creditors.add(_HeapNode(userId, balance));
      } else if (balance < 0) {
        debtors.add(_HeapNode(userId, balance.abs()));
      }
    });

    // Match maximum debtor with maximum creditor
    while (creditors.isNotEmpty && debtors.isNotEmpty) {
      final creditor = creditors.removeFirst();
      final debtor = debtors.removeFirst();

      // Find the transfer amount (minimum of debtor's debt and creditor's credit)
      final transferAmount = _round(_min(creditor.amount, debtor.amount));
      if (transferAmount < 0.01) continue;

      transfers.add(DebtTransfer(
        fromUserId: debtor.userId,
        toUserId: creditor.userId,
        amount: transferAmount,
      ));

      // Calculate remaining balances
      final remainingCreditorAmount = _round(creditor.amount - transferAmount);
      final remainingDebtorAmount = _round(debtor.amount - transferAmount);

      // Re-add to heaps if there's still a balance remaining above the threshold
      if (remainingCreditorAmount >= 0.01) {
        creditors.add(_HeapNode(creditor.userId, remainingCreditorAmount));
      }
      if (remainingDebtorAmount >= 0.01) {
        debtors.add(_HeapNode(debtor.userId, remainingDebtorAmount));
      }
    }

    return transfers;
  }

  static double _round(double val) {
    return (val * 100).round() / 100.0;
  }

  static double _min(double a, double b) => a < b ? a : b;
}

class _HeapNode {
  final String userId;
  final double amount;

  _HeapNode(this.userId, this.amount);
}
