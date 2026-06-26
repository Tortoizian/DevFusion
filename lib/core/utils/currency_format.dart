String formatCurrencyAmount(
  double amount, {
  bool compact = false,
  bool showSign = false,
}) {
  final settled = amount.abs() < 0.01;
  if (settled) {
    return compact ? '₹0' : '₹0.00';
  }

  final prefix = showSign ? (amount > 0 ? '+' : '-') : '';
  final value = amount.abs();

  if (compact) {
    if (value >= 100000) {
      return '$prefix₹${(value / 100000).toStringAsFixed(1)}L';
    }
    if (value >= 10000) {
      return '$prefix₹${(value / 1000).toStringAsFixed(1)}k';
    }
    if (value % 1 == 0) {
      return '$prefix₹${value.toStringAsFixed(0)}';
    }
    return '$prefix₹${value.toStringAsFixed(2)}';
  }

  return '$prefix₹${value.toStringAsFixed(2)}';
}
