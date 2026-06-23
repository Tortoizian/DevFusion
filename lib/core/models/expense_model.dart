enum ExpenseCategory {
  food,
  travel,
  rent,
  utilities,
  entertainment,
  settlement,
  other;

  static ExpenseCategory fromString(String val) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => ExpenseCategory.other,
    );
  }
}

enum SplitType {
  equal,
  percentage,
  exact,
  shares;

  static SplitType fromString(String val) {
    return SplitType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => SplitType.equal,
    );
  }
}

class ExpenseModel {
  final String id;
  final String groupId;
  final String description;
  final double amount;
  final String payerId;
  final ExpenseCategory category;
  final SplitType splitType;
  final DateTime createdAt;

  ExpenseModel({
    required this.id,
    required this.groupId,
    required this.description,
    required this.amount,
    required this.payerId,
    required this.category,
    required this.splitType,
    required this.createdAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      payerId: json['payer_id'] as String,
      category: ExpenseCategory.fromString(json['category'] as String),
      splitType: SplitType.fromString(json['split_type'] as String),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'description': description,
      'amount': amount,
      'payer_id': payerId,
      'category': category.name,
      'split_type': splitType.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? groupId,
    String? description,
    double? amount,
    String? payerId,
    ExpenseCategory? category,
    SplitType? splitType,
    DateTime? createdAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      payerId: payerId ?? this.payerId,
      category: category ?? this.category,
      splitType: splitType ?? this.splitType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'ExpenseModel(id: $id, description: $description, amount: $amount, payerId: $payerId)';
}
