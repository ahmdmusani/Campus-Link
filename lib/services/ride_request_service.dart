import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ride_model.dart';
import '../models/ride_request_model.dart';
import '../models/ride_request_status.dart';
import '../repositories/ride_request_repository.dart';
import '../utils/ride_request_validator.dart';
import 'notification_service.dart';

class RideRequestService {
  final RideRequestRepository _requestRepository;
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  RideRequestService({
    RideRequestRepository? requestRepository,
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _requestRepository = requestRepository ?? RideRequestRepository(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Submits a new passenger seat request for a published ride.
  Future<RideRequestModel> requestSeat({
    required RideModel ride,
    int requestedSeats = 1,
  }) async {
    final currentUser = _firebaseAuth.currentUser;
    final passengerId = currentUser?.uid;

    // 1. Validation
    RideRequestValidator.validatePassengerAuth(passengerId);
    RideRequestValidator.validateRidePublished(ride);
    RideRequestValidator.validateNotDriver(
      passengerId: passengerId!,
      driverId: ride.driverId,
    );
    RideRequestValidator.validateRequestedSeats(requestedSeats);

    // 2. Check existing pending request
    final existingPending = await _requestRepository.fetchPendingRequest(
      rideId: ride.rideId,
      passengerId: passengerId,
    );
    RideRequestValidator.validateNoDuplicatePendingRequest(existingPending);

    // 3. Fetch Passenger Profile Info
    String passengerName = currentUser.displayName ?? 'Student Passenger';
    String? passengerProfileImage;

    try {
      final userDoc = await _firestore.collection('users').doc(passengerId).get();
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        passengerName = data['fullName'] ?? data['name'] ?? passengerName;
        passengerProfileImage = data['photoUrl'] as String?;
      }
    } catch (_) {
      // Fallback to Auth displayName
    }

    final now = DateTime.now();

    // 4. Construct unpersisted request model
    final initialRequest = RideRequestModel(
      requestId: '', // Canonical ID will be assigned by Firestore document ID in repository
      rideId: ride.rideId,
      driverId: ride.driverId,
      passengerId: passengerId,
      passengerName: passengerName,
      passengerProfileImage: passengerProfileImage,
      requestedSeats: requestedSeats,
      requestStatus: RideRequestStatus.pending,
      createdAt: now,
      updatedAt: now,
    );

    // 5. Persist Request in Firestore
    final savedRequest = await _requestRepository.createRequest(initialRequest);

    // 6. Firestore Write Verification
    final verifiedDoc = await _requestRepository.fetchRequest(savedRequest.requestId);
    if (verifiedDoc == null || verifiedDoc.requestId != savedRequest.requestId) {
      throw Exception('Firestore request write verification failed. Document was not found.');
    }

    // 7. Trigger Push Notification to Driver
    try {
      await NotificationService().notifyRequestCreated(
        driverId: ride.driverId,
        passengerId: passengerId,
        passengerName: passengerName,
        rideId: ride.rideId,
      );
    } catch (_) {}

    return verifiedDoc;
  }

  /// Checks if the passenger has an active pending request for a ride.
  Future<RideRequestModel?> checkExistingPendingRequest({
    required String rideId,
    required String passengerId,
  }) {
    return _requestRepository.fetchPendingRequest(
      rideId: rideId,
      passengerId: passengerId,
    );
  }
}
