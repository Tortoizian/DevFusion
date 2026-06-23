enum SettlementStatus {
  pending,
  confirmed;

  static SettlementStatus fromString(String val) {
    return SettlementStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => SettlementStatus.pending,
    );
  }
}

class SettlementModel {
  final String id;
  final String groupId;
  final String debtorId;
  final String creditorId;
  final double amount;
  final SettlementStatus status;
  final DateTime createdAt;

  SettlementModel({
    required this.id,
    required this.groupId,
    required this.debtorId,
    required this.creditorId,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  factory SettlementModel.fromJson(Map<String, dynamic> json) {
    return SettlementModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      debtorId: json['debtor_id'] as String,
      creditorId: json['creditor_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: SettlementStatus.fromString(json['status'] as String),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'debtor_id': debtorId,
      'creditor_id': creditorId,
      'amount': amount,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  SettlementModel copyWith({
    String? id,
    String? groupId,
    String? debtorId,
    String? creditorId,
    double? amount,
    SettlementStatus? status,
    DateTime? createdAt,
  }) {
    return SettlementModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      debtorId: debtorId ?? this.debtorId,
      creditorId: creditorId ?? this.creditorId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'SettlementModel(id: $id, debtorId: $debtorId, creditorId: $creditorId, amount: $amount, status: $status)';
}
