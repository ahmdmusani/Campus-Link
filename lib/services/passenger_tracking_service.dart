import 'package:firebase_auth/firebase_auth.dart';
import '../models/driver_location_model.dart';
import '../models/ride_model.dart';
import '../repositories/passenger_tracking_repository.dart';

class SecurityValidationException implements Exception {
  final String message;
  SecurityValidationException(this.message);

  @override
  String toString() => message;
}

class PassengerTrackingService {
  final PassengerTrackingRepository _repository;
  final FirebaseAuth _firebaseAuth;

  PassengerTrackingService({
    PassengerTrackingRepository? repository,
    FirebaseAuth? firebaseAuth,
  })  : _repository = repository ?? PassengerTrackingRepository(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  /// Validates passenger authentication and verifies active participant authorization.
  Future<void> verifyTrackingAuthorization(String rideId) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw SecurityValidationException('Authentication required to access live ride tracking.');
    }

    final isDriver = await _repository.isRideDriver(
      rideId: rideId,
      userId: user.uid,
    );
    if (isDriver) return; // Driver is authorized to view tracking

    final isAccepted = await _repository.isPassengerAcceptedParticipant(
      rideId: rideId,
      passengerId: user.uid,
    );

    if (!isAccepted) {
      throw SecurityValidationException(
        'Unauthorized Access: Live tracking is restricted exclusively to confirmed ride participants.',
      );
    }
  }

  /// Fetches ride details for map rendering.
  Future<RideModel?> fetchRide(String rideId) async {
    return _repository.fetchRide(rideId);
  }

  /// Streams live driver location for authorized rides.
  Stream<DriverLocationModel?> streamDriverLocation(String rideId) {
    return _repository.streamDriverLocation(rideId);
  }
}
