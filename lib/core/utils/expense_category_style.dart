import 'package:flutter/material.dart';

import '../models/expense_model.dart';
import '../theme/app_colors.dart';

class ExpenseCategoryStyle {
  static IconData icon(ExpenseCategory category) {
    return switch (category) {
      ExpenseCategory.food => Icons.restaurant,
      ExpenseCategory.travel => Icons.flight,
      ExpenseCategory.rent => Icons.home,
      ExpenseCategory.utilities => Icons.bolt,
      ExpenseCategory.entertainment => Icons.movie,
      ExpenseCategory.settlement => Icons.handshake,
      ExpenseCategory.other => Icons.receipt_long,
    };
  }

  static Color color(ExpenseCategory category) {
    return switch (category) {
      ExpenseCategory.food => Colors.orange,
      ExpenseCategory.travel => Colors.blue,
      ExpenseCategory.rent => Colors.indigo,
      ExpenseCategory.utilities => Colors.amber,
      ExpenseCategory.entertainment => Colors.purple,
      ExpenseCategory.settlement => AppColors.success,
      ExpenseCategory.other => AppColors.textSecondary,
    };
  }
}
