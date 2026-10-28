import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String notificationId;
  final String receiverId;
  final String senderId;
  final String type;
  final String title;
  final String body;
  final String rideId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.notificationId,
    required this.receiverId,
    required this.senderId,
    required this.type,
    required this.title,
    required this.body,
    required this.rideId,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      notificationId: doc.id,
      receiverId: data['receiverId'] ?? '',
      senderId: data['senderId'] ?? '',
      type: data['type'] ?? 'general',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      rideId: data['rideId'] ?? '',
      isRead: data['isRead'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'notificationId': notificationId,
      'receiverId': receiverId,
      'senderId': senderId,
      'type': type,
      'title': title,
      'body': body,
      'rideId': rideId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  NotificationModel copyWith({
    String? notificationId,
    String? receiverId,
    String? senderId,
    String? type,
    String? title,
    String? body,
    String? rideId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      notificationId: notificationId ?? this.notificationId,
      receiverId: receiverId ?? this.receiverId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      rideId: rideId ?? this.rideId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationModel &&
          runtimeType == other.runtimeType &&
          notificationId == other.notificationId &&
          receiverId == other.receiverId &&
          senderId == other.senderId &&
          type == other.type &&
          title == other.title &&
          body == other.body &&
          rideId == other.rideId &&
          isRead == other.isRead &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      notificationId.hashCode ^
      receiverId.hashCode ^
      senderId.hashCode ^
      type.hashCode ^
      title.hashCode ^
      body.hashCode ^
      rideId.hashCode ^
      isRead.hashCode ^
      createdAt.hashCode;
}
