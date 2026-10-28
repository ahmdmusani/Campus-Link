import 'package:cloud_firestore/cloud_firestore.dart';

class WalletModel {
  final String walletId;
  final String userId;
  final double balance;
  final double totalEarned;
  final double totalSpent;
  final DateTime updatedAt;

  const WalletModel({
    required this.walletId,
    required this.userId,
    required this.balance,
    required this.totalEarned,
    required this.totalSpent,
    required this.updatedAt,
  });

  factory WalletModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WalletModel(
      walletId: doc.id,
      userId: data['userId'] ?? doc.id,
      balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
      totalEarned: (data['totalEarned'] as num?)?.toDouble() ?? 0.0,
      totalSpent: (data['totalSpent'] as num?)?.toDouble() ?? 0.0,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'walletId': walletId,
      'userId': userId,
      'balance': balance,
      'totalEarned': totalEarned,
      'totalSpent': totalSpent,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  WalletModel copyWith({
    String? walletId,
    String? userId,
    double? balance,
    double? totalEarned,
    double? totalSpent,
    DateTime? updatedAt,
  }) {
    return WalletModel(
      walletId: walletId ?? this.walletId,
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      totalEarned: totalEarned ?? this.totalEarned,
      totalSpent: totalSpent ?? this.totalSpent,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletModel &&
          runtimeType == other.runtimeType &&
          walletId == other.walletId &&
          userId == other.userId &&
          balance == other.balance &&
          totalEarned == other.totalEarned &&
          totalSpent == other.totalSpent &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      walletId.hashCode ^
      userId.hashCode ^
      balance.hashCode ^
      totalEarned.hashCode ^
      totalSpent.hashCode ^
      updatedAt.hashCode;
}
