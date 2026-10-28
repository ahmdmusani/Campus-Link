import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementModel {
  final String userId;
  final String name;
  final String email;
  final String role;
  final String userStatus; // 'active' or 'suspended'
  final DateTime createdAt;

  const UserManagementModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.userStatus = 'active',
    required this.createdAt,
  });

  factory UserManagementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserManagementModel(
      userId: doc.id,
      name: data['name'] ?? data['fullName'] ?? 'User',
      email: data['email'] ?? '',
      role: data['role'] ?? 'passenger',
      userStatus: data['userStatus'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'role': role,
      'userStatus': userStatus,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserManagementModel copyWith({
    String? userId,
    String? name,
    String? email,
    String? role,
    String? userStatus,
    DateTime? createdAt,
  }) {
    return UserManagementModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      userStatus: userStatus ?? this.userStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
