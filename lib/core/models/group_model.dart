enum GroupCategory {
  food,
  travel,
  rent,
  utilities,
  entertainment,
  other;

  String get label {
    return switch (this) {
      GroupCategory.food => 'Food',
      GroupCategory.travel => 'Travel',
      GroupCategory.rent => 'Rent',
      GroupCategory.utilities => 'Utilities',
      GroupCategory.entertainment => 'Entertainment',
      GroupCategory.other => 'Other',
    };
  }
}

class GroupModel {
  final String id;
  final String name;
  final String inviteCode;
  final String createdBy;
  final DateTime createdAt;
  final bool isTripMode;
  final double? tripBudget;

  GroupModel({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.createdBy,
    required this.createdAt,
    this.isTripMode = false,
    this.tripBudget,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] as String,
      name: json['name'] as String,
      inviteCode: json['invite_code'] as String,
      createdBy: json['created_by'] as String,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isTripMode: json['is_trip_mode'] as bool? ?? false,
      tripBudget: json['trip_budget'] != null ? (json['trip_budget'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'invite_code': inviteCode,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'is_trip_mode': isTripMode,
      if (tripBudget != null) 'trip_budget': tripBudget,
    };
  }

  GroupModel copyWith({
    String? id,
    String? name,
    String? inviteCode,
    String? createdBy,
    DateTime? createdAt,
    bool? isTripMode,
    double? tripBudget,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      inviteCode: inviteCode ?? this.inviteCode,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      isTripMode: isTripMode ?? this.isTripMode,
      tripBudget: tripBudget ?? this.tripBudget,
    );
  }

  @override
  String toString() => 'GroupModel(id: $id, name: $name, inviteCode: $inviteCode)';
}
