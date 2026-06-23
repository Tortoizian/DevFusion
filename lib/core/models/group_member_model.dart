class GroupMemberModel {
  final String groupId;
  final String userId;
  final DateTime joinedAt;

  GroupMemberModel({
    required this.groupId,
    required this.userId,
    required this.joinedAt,
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      joinedAt: json['joined_at'] != null 
          ? DateTime.parse(json['joined_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'group_id': groupId,
      'user_id': userId,
      'joined_at': joinedAt.toIso8601String(),
    };
  }

  GroupMemberModel copyWith({
    String? groupId,
    String? userId,
    DateTime? joinedAt,
  }) {
    return GroupMemberModel(
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  @override
  String toString() => 'GroupMemberModel(groupId: $groupId, userId: $userId)';
}
