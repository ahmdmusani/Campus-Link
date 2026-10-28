import 'package:cloud_firestore/cloud_firestore.dart';

class RatingModel {
  final String ratingId;
  final String rideId;
  final String fromUserId;
  final String toUserId;
  final String fromUserRole;
  final double ratingValue;
  final String reviewText;
  final DateTime createdAt;

  const RatingModel({
    required this.ratingId,
    required this.rideId,
    required this.fromUserId,
    required this.toUserId,
    required this.fromUserRole,
    required this.ratingValue,
    required this.reviewText,
    required this.createdAt,
  });

  factory RatingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RatingModel(
      ratingId: doc.id,
      rideId: data['rideId'] ?? '',
      fromUserId: data['fromUserId'] ?? '',
      toUserId: data['toUserId'] ?? '',
      fromUserRole: data['fromUserRole'] ?? 'passenger',
      ratingValue: (data['ratingValue'] as num?)?.toDouble() ?? 5.0,
      reviewText: data['reviewText'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ratingId': ratingId,
      'rideId': rideId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'fromUserRole': fromUserRole,
      'ratingValue': ratingValue,
      'reviewText': reviewText,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  RatingModel copyWith({
    String? ratingId,
    String? rideId,
    String? fromUserId,
    String? toUserId,
    String? fromUserRole,
    double? ratingValue,
    String? reviewText,
    DateTime? createdAt,
  }) {
    return RatingModel(
      ratingId: ratingId ?? this.ratingId,
      rideId: rideId ?? this.rideId,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      fromUserRole: fromUserRole ?? this.fromUserRole,
      ratingValue: ratingValue ?? this.ratingValue,
      reviewText: reviewText ?? this.reviewText,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RatingModel &&
          runtimeType == other.runtimeType &&
          ratingId == other.ratingId &&
          rideId == other.rideId &&
          fromUserId == other.fromUserId &&
          toUserId == other.toUserId &&
          fromUserRole == other.fromUserRole &&
          ratingValue == other.ratingValue &&
          reviewText == other.reviewText &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      ratingId.hashCode ^
      rideId.hashCode ^
      fromUserId.hashCode ^
      toUserId.hashCode ^
      fromUserRole.hashCode ^
      ratingValue.hashCode ^
      reviewText.hashCode ^
      createdAt.hashCode;
}
