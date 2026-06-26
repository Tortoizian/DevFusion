import 'package:flutter/material.dart';

import '../../../core/models/expense_model.dart';
import '../../../core/state/group_state.dart';
import '../../../core/theme/app_colors.dart';

class ExpenseDetailSheet extends StatelessWidget {
  final ExpenseModel expense;
  final GroupState groupState;

  const ExpenseDetailSheet({
    super.key,
    required this.expense,
    required this.groupState,
  });

  String _memberName(String userId) {
    for (final member in groupState.members) {
      if (member.id == userId) return member.name;
    }
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final splits = groupState.splits.where((split) => split.expenseId == expense.id).toList();
    final payerName = _memberName(expense.payerId);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              expense.description,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '₹${expense.amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 20),
            _DetailRow(label: 'Paid by', value: payerName),
            _DetailRow(label: 'Category', value: expense.category.name.toUpperCase()),
            _DetailRow(label: 'Split type', value: expense.splitType.name.toUpperCase()),
            _DetailRow(
              label: 'Date',
              value: expense.createdAt.toLocal().toString().split('.').first,
            ),
            if (expense.receiptUrl != null)
              _DetailRow(label: 'Receipt', value: 'Attached'),
            const SizedBox(height: 16),
            Text(
              'Split breakdown',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (splits.isEmpty)
              Text(
                'No split details recorded.',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              ...splits.map(
                (split) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(child: Text(_memberName(split.userId))),
                      Text(
                        '₹${split.amountOwed.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
