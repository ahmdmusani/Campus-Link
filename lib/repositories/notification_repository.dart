import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Saves a new notification document in Firestore using document ID as canonical notificationId.
  Future<NotificationModel> sendNotification(NotificationModel notification) async {
    final docRef = _firestore.collection('notifications').doc();
    final canonicalNotification = notification.copyWith(notificationId: docRef.id);

    await docRef.set({
      'notificationId': canonicalNotification.notificationId,
      'receiverId': canonicalNotification.receiverId,
      'senderId': canonicalNotification.senderId,
      'type': canonicalNotification.type,
      'title': canonicalNotification.title,
      'body': canonicalNotification.body,
      'rideId': canonicalNotification.rideId,
      'isRead': canonicalNotification.isRead,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return canonicalNotification;
  }

  /// Streams real-time notifications for a specific receiverId.
  Stream<List<NotificationModel>> streamUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('receiverId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
      // Sort by createdAt descending
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Marks a specific notification document as read.
  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  /// Saves or appends an FCM token to the user's Firestore profile.
  Future<void> saveFCMToken({
    required String userId,
    required String token,
  }) async {
    await _firestore.collection('users').doc(userId).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }
}
