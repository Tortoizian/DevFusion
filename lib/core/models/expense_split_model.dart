class ExpenseSplitModel {
  final String id;
  final String expenseId;
  final String userId;
  final double amountOwed;

  ExpenseSplitModel({
    required this.id,
    required this.expenseId,
    required this.userId,
    required this.amountOwed,
  });

  factory ExpenseSplitModel.fromJson(Map<String, dynamic> json) {
    return ExpenseSplitModel(
      id: json['id'] as String,
      expenseId: json['expense_id'] as String,
      userId: json['user_id'] as String,
      amountOwed: (json['amount_owed'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expense_id': expenseId,
      'user_id': userId,
      'amount_owed': amountOwed,
    };
  }

  ExpenseSplitModel copyWith({
    String? id,
    String? expenseId,
    String? userId,
    double? amountOwed,
  }) {
    return ExpenseSplitModel(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      userId: userId ?? this.userId,
      amountOwed: amountOwed ?? this.amountOwed,
    );
  }

  @override
  String toString() => 'ExpenseSplitModel(expenseId: $expenseId, userId: $userId, amountOwed: $amountOwed)';
}
