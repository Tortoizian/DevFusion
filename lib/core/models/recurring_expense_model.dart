enum RecurrenceInterval {
  daily,
  weekly,
  monthly,
  yearly;

  static RecurrenceInterval fromString(String val) {
    return RecurrenceInterval.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => RecurrenceInterval.monthly,
    );
  }
}

class RecurringExpenseModel {
  final String id;
  final String groupId;
  final String description;
  final double amount;
  final String payerId;
  final RecurrenceInterval interval;
  final DateTime nextRunAt;
  final DateTime createdAt;

  RecurringExpenseModel({
    required this.id,
    required this.groupId,
    required this.description,
    required this.amount,
    required this.payerId,
    required this.interval,
    required this.nextRunAt,
    required this.createdAt,
  });

  factory RecurringExpenseModel.fromJson(Map<String, dynamic> json) {
    return RecurringExpenseModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      payerId: json['payer_id'] as String,
      interval: RecurrenceInterval.fromString(json['interval'] as String),
      nextRunAt: DateTime.parse(json['next_run_at'] as String),
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
      'interval': interval.name,
      'next_run_at': nextRunAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
