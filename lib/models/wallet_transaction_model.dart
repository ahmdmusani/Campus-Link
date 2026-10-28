import 'package:cloud_firestore/cloud_firestore.dart';

class WalletTransactionModel {
  final String transactionId;
  final String userId;
  final String rideId;
  final double amount;
  final String transactionType; // 'credit' or 'debit'
  final String description;
  final double commissionDeducted;
  final DateTime createdAt;

  const WalletTransactionModel({
    required this.transactionId,
    required this.userId,
    required this.rideId,
    required this.amount,
    required this.transactionType,
    required this.description,
    this.commissionDeducted = 0.0,
    required this.createdAt,
  });

  factory WalletTransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WalletTransactionModel(
      transactionId: doc.id,
      userId: data['userId'] ?? '',
      rideId: data['rideId'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      transactionType: data['transactionType'] ?? 'debit',
      description: data['description'] ?? '',
      commissionDeducted: (data['commissionDeducted'] as num?)?.toDouble() ?? 0.0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'transactionId': transactionId,
      'userId': userId,
      'rideId': rideId,
      'amount': amount,
      'transactionType': transactionType,
      'description': description,
      'commissionDeducted': commissionDeducted,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  WalletTransactionModel copyWith({
    String? transactionId,
    String? userId,
    String? rideId,
    double? amount,
    String? transactionType,
    String? description,
    double? commissionDeducted,
    DateTime? createdAt,
  }) {
    return WalletTransactionModel(
      transactionId: transactionId ?? this.transactionId,
      userId: userId ?? this.userId,
      rideId: rideId ?? this.rideId,
      amount: amount ?? this.amount,
      transactionType: transactionType ?? this.transactionType,
      description: description ?? this.description,
      commissionDeducted: commissionDeducted ?? this.commissionDeducted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletTransactionModel &&
          runtimeType == other.runtimeType &&
          transactionId == other.transactionId &&
          userId == other.userId &&
          rideId == other.rideId &&
          amount == other.amount &&
          transactionType == other.transactionType &&
          description == other.description &&
          commissionDeducted == other.commissionDeducted &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      transactionId.hashCode ^
      userId.hashCode ^
      rideId.hashCode ^
      amount.hashCode ^
      transactionType.hashCode ^
      description.hashCode ^
      commissionDeducted.hashCode ^
      createdAt.hashCode;
}
