class UserModel {
  final String id;
  final String name;
  final String upiId;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.upiId,
    required this.createdAt,
  });

  /// Generates the avatar URL using the DiceBear API based on the user's name
  String get avatarUrl => 'https://api.dicebear.com/7.x/avataaars/svg?seed=${Uri.encodeComponent(name)}';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      upiId: json['upi_id'] as String,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'upi_id': upiId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? upiId,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      upiId: upiId ?? this.upiId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'UserModel(id: $id, name: $name, upiId: $upiId)';
}
