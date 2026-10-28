import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

class NotificationService {
  final NotificationRepository _repository;
  final FirebaseAuth _firebaseAuth;

  NotificationService({
    NotificationRepository? repository,
    FirebaseAuth? firebaseAuth,
  })  : _repository = repository ?? NotificationRepository(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  /// Registers or updates the user's FCM device token in Firestore.
  Future<void> registerFCMToken(String token) async {
    final user = _firebaseAuth.currentUser;
    if (user != null && token.isNotEmpty) {
      await _repository.saveFCMToken(userId: user.uid, token: token);
    }
  }

  /// Streams real-time notifications for the authenticated user.
  Stream<List<NotificationModel>> streamUserNotifications() {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }
    return _repository.streamUserNotifications(user.uid);
  }

  /// Marks a notification as read.
  Future<void> markAsRead(String notificationId) async {
    await _repository.markAsRead(notificationId);
  }

  // 1. Event: Passenger Request Created -> Notify Driver
  Future<void> notifyRequestCreated({
    required String driverId,
    required String passengerId,
    required String passengerName,
    required String rideId,
  }) async {
    final notification = NotificationModel(
      notificationId: '',
      receiverId: driverId,
      senderId: passengerId,
      type: 'request_created',
      title: 'New Seat Request',
      body: '$passengerName has requested a seat in your published ride.',
      rideId: rideId,
      createdAt: DateTime.now(),
    );
    await _repository.sendNotification(notification);
  }

  // 2. Event: Request Accepted -> Notify Passenger
  Future<void> notifyRequestAccepted({
    required String passengerId,
    required String driverId,
    required String rideId,
  }) async {
    final notification = NotificationModel(
      notificationId: '',
      receiverId: passengerId,
      senderId: driverId,
      type: 'request_accepted',
      title: 'Seat Request Accepted! 🎉',
      body: 'Your seat request has been accepted by the driver.',
      rideId: rideId,
      createdAt: DateTime.now(),
    );
    await _repository.sendNotification(notification);
  }

  // 3. Event: Request Declined -> Notify Passenger
  Future<void> notifyRequestDeclined({
    required String passengerId,
    required String driverId,
    required String rideId,
  }) async {
    final notification = NotificationModel(
      notificationId: '',
      receiverId: passengerId,
      senderId: driverId,
      type: 'request_declined',
      title: 'Seat Request Update',
      body: 'Your seat request for the ride was declined.',
      rideId: rideId,
      createdAt: DateTime.now(),
    );
    await _repository.sendNotification(notification);
  }

  // 4. Event: Ride Started -> Notify Passengers
  Future<void> notifyRideStarted({
    required String passengerId,
    required String driverId,
    required String rideId,
  }) async {
    final notification = NotificationModel(
      notificationId: '',
      receiverId: passengerId,
      senderId: driverId,
      type: 'ride_started',
      title: 'Ride Started 🚗',
      body: 'The driver has started the ride! Live location tracking is active.',
      rideId: rideId,
      createdAt: DateTime.now(),
    );
    await _repository.sendNotification(notification);
  }

  // 5. Event: Ride Completed -> Notify Participants
  Future<void> notifyRideCompleted({
    required String participantId,
    required String driverId,
    required String rideId,
  }) async {
    final notification = NotificationModel(
      notificationId: '',
      receiverId: participantId,
      senderId: driverId,
      type: 'ride_completed',
      title: 'Ride Completed ✨',
      body: 'Your ride has safely reached the destination. Don\'t forget to rate your experience!',
      rideId: rideId,
      createdAt: DateTime.now(),
    );
    await _repository.sendNotification(notification);
  }

  // 6. Event: New Rating -> Notify Recipient
  Future<void> notifyNewRating({
    required String recipientId,
    required String senderId,
    required String rideId,
    required double ratingValue,
  }) async {
    final notification = NotificationModel(
      notificationId: '',
      receiverId: recipientId,
      senderId: senderId,
      type: 'new_rating',
      title: 'New Rating & Review ⭐',
      body: 'You received a ${ratingValue.toInt()}-star rating for your recent ride.',
      rideId: rideId,
      createdAt: DateTime.now(),
    );
    await _repository.sendNotification(notification);
  }
}
