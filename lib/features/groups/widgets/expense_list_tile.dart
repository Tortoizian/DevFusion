import 'package:flutter/material.dart';

import '../../../core/models/expense_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/expense_category_style.dart';
import '../../../shared/widgets/app_card.dart';

class ExpenseListTile extends StatelessWidget {
  final ExpenseModel expense;
  final String payerName;
  final String? trailingLabel;
  final VoidCallback onTap;

  const ExpenseListTile({
    super.key,
    required this.expense,
    required this.payerName,
    required this.onTap,
    this.trailingLabel,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = ExpenseCategoryStyle.color(expense.category);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                ExpenseCategoryStyle.icon(expense.category),
                color: categoryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.description,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$payerName paid ₹${expense.amount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (trailingLabel != null)
                  Text(
                    trailingLabel!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                Text(
                  expense.splitType.name.toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
