import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/ride_lifecycle_repository.dart';
import 'notification_service.dart';

class RideLifecycleService {
  final RideLifecycleRepository _repository;
  final FirebaseAuth _firebaseAuth;

  RideLifecycleService({
    RideLifecycleRepository? repository,
    FirebaseAuth? firebaseAuth,
  })  : _repository = repository ?? RideLifecycleRepository(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  /// Starts a published ride owned by the authenticated driver.
  Future<void> startRide(String rideId) async {
    final driver = _firebaseAuth.currentUser;
    if (driver == null) {
      throw Exception('Driver must be authenticated to start a ride.');
    }

    await _repository.startRideTransaction(
      rideId: rideId,
      driverId: driver.uid,
    );

    try {
      final participantsQuery = await FirebaseFirestore.instance
          .collection('ride_participants')
          .where('rideId', isEqualTo: rideId)
          .where('participantStatus', isEqualTo: 'active')
          .get();

      for (final doc in participantsQuery.docs) {
        final passengerId = doc.data()['passengerId'] as String?;
        if (passengerId != null) {
          await NotificationService().notifyRideStarted(
            passengerId: passengerId,
            driverId: driver.uid,
            rideId: rideId,
          );
        }
      }
    } catch (_) {}
  }

  /// Completes an ongoing ride owned by the authenticated driver and logs history.
  Future<void> completeRide(String rideId) async {
    final driver = _firebaseAuth.currentUser;
    if (driver == null) {
      throw Exception('Driver must be authenticated to complete a ride.');
    }

    await _repository.completeRideTransaction(
      rideId: rideId,
      driverId: driver.uid,
    );

    try {
      final participantsQuery = await FirebaseFirestore.instance
          .collection('ride_participants')
          .where('rideId', isEqualTo: rideId)
          .where('participantStatus', isEqualTo: 'active')
          .get();

      for (final doc in participantsQuery.docs) {
        final passengerId = doc.data()['passengerId'] as String?;
        if (passengerId != null) {
          await NotificationService().notifyRideCompleted(
            participantId: passengerId,
            driverId: driver.uid,
            rideId: rideId,
          );
        }
      }
    } catch (_) {}
  }
}
