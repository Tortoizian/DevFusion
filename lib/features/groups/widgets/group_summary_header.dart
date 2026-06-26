import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/models/expense_model.dart';
import '../../../core/state/group_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/balance_chip.dart';

class GroupSummaryHeader extends ConsumerWidget {
  final GroupState groupState;

  const GroupSummaryHeader({
    super.key,
    required this.groupState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = groupState.group;
    final budget = group?.tripBudget;
    final currentUserId = ref.watch(currentUserIdProvider);
    final memberCount = groupState.members.length;
    final expenseCount = groupState.expenses
        .where((expense) => expense.category != ExpenseCategory.settlement)
        .length;
    final totalSpent = groupState.expenses
        .where((expense) => expense.category != ExpenseCategory.settlement)
        .fold(0.0, (sum, expense) => sum + expense.amount);
    final yourBalance = currentUserId == null ? 0.0 : groupState.netBalances[currentUserId] ?? 0.0;
    final unsettledTransfers = groupState.simplifiedDebts.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.18),
                        AppColors.primary.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    group?.isTripMode == true ? Icons.flight_takeoff : Icons.groups,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group?.name ?? 'Group',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$memberCount ${memberCount == 1 ? 'member' : 'members'} · $expenseCount ${expenseCount == 1 ? 'expense' : 'expenses'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (group?.isTripMode == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Trip mode',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
                BalanceChip(balance: yourBalance),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SummaryStat(
                    label: 'Total spent',
                    value: '₹${totalSpent.toStringAsFixed(2)}',
                  ),
                ),
                Expanded(
                  child: _SummaryStat(
                    label: 'Unsettled',
                    value: unsettledTransfers == 0 ? 'All clear' : '$unsettledTransfers transfers',
                  ),
                ),
              ],
            ),
            if (group?.isTripMode == true && budget != null && budget > 0) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Trip budget',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '₹${totalSpent.toStringAsFixed(0)} / ₹${budget.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (totalSpent / budget).clamp(0.0, 1.0),
                backgroundColor: AppColors.divider,
                color: totalSpent > budget ? AppColors.error : AppColors.success,
                borderRadius: BorderRadius.circular(999),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ],
    );
  }
}
