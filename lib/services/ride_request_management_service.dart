import 'package:firebase_auth/firebase_auth.dart';
import '../models/driver_pending_request_item.dart';
import '../models/ride_request_model.dart';
import '../repositories/driver_request_repository.dart';
import 'notification_service.dart';

class RideRequestManagementService {
  final DriverRequestRepository _driverRequestRepository;
  final FirebaseAuth _firebaseAuth;

  RideRequestManagementService({
    DriverRequestRepository? driverRequestRepository,
    FirebaseAuth? firebaseAuth,
  })  : _driverRequestRepository = driverRequestRepository ?? DriverRequestRepository(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  /// Returns real-time stream of pending request items (request + ride) for the authenticated driver.
  Stream<List<DriverPendingRequestItem>> streamPendingRequestItems() {
    final driver = _firebaseAuth.currentUser;
    if (driver == null) {
      return Stream.value([]);
    }

    return _driverRequestRepository
        .streamPendingRequestsForDriver(driver.uid)
        .asyncMap((requests) async {
      final List<DriverPendingRequestItem> items = [];
      for (final req in requests) {
        final ride = await _driverRequestRepository.fetchRide(req.rideId);
        if (ride != null) {
          items.add(DriverPendingRequestItem(request: req, ride: ride));
        }
      }
      return items;
    });
  }

  /// Accepts a passenger seat request by executing an atomic Firestore transaction.
  Future<void> acceptRequest({
    required RideRequestModel request,
  }) async {
    final driver = _firebaseAuth.currentUser;
    if (driver == null) {
      throw Exception('Driver must be authenticated to accept requests.');
    }

    await _driverRequestRepository.acceptRequestTransaction(
      requestId: request.requestId,
      rideId: request.rideId,
      driverId: driver.uid,
      passengerId: request.passengerId,
      requestedSeats: request.requestedSeats,
    );

    try {
      await NotificationService().notifyRequestAccepted(
        passengerId: request.passengerId,
        driverId: driver.uid,
        rideId: request.rideId,
      );
    } catch (_) {}
  }

  /// Declines a passenger seat request by executing an atomic Firestore transaction.
  Future<void> declineRequest({
    required RideRequestModel request,
  }) async {
    final driver = _firebaseAuth.currentUser;
    if (driver == null) {
      throw Exception('Driver must be authenticated to decline requests.');
    }

    await _driverRequestRepository.declineRequestTransaction(
      requestId: request.requestId,
      driverId: driver.uid,
    );

    try {
      await NotificationService().notifyRequestDeclined(
        passengerId: request.passengerId,
        driverId: driver.uid,
        rideId: request.rideId,
      );
    } catch (_) {}
  }
}
