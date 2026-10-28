import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride_model.dart';
import '../models/ride_request_model.dart';
import '../models/ride_request_status.dart';

class DriverRequestRepository {
  final FirebaseFirestore _firestore;

  DriverRequestRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Returns a real-time stream of pending ride requests for a specific driver.
  Stream<List<RideRequestModel>> streamPendingRequestsForDriver(String driverId) {
    return _firestore
        .collection('ride_requests')
        .where('driverId', isEqualTo: driverId)
        .where('requestStatus', isEqualTo: RideRequestStatus.pending.toMap())
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RideRequestModel.fromFirestore(doc))
            .toList());
  }

  /// Fetches a single ride by ID.
  Future<RideModel?> fetchRide(String rideId) async {
    final doc = await _firestore.collection('rides').doc(rideId).get();
    if (!doc.exists || doc.data() == null) return null;
    return RideModel.fromFirestore(doc);
  }

  /// Executes an atomic Firestore transaction to ACCEPT a passenger ride request.
  /// Locks accepted requests, prevents race conditions, checks remaining seats inside transaction,
  /// uses FieldValue.serverTimestamp(), increments bookedSeats, and creates a ride_participants document.
  Future<void> acceptRequestTransaction({
    required String requestId,
    required String rideId,
    required String driverId,
    required String passengerId,
    required int requestedSeats,
  }) async {
    await _firestore.runTransaction((transaction) async {
      // 1. Reload latest ride document inside transaction
      final rideRef = _firestore.collection('rides').doc(rideId);
      final rideDoc = await transaction.get(rideRef);

      if (!rideDoc.exists || rideDoc.data() == null) {
        throw Exception('The published ride no longer exists.');
      }

      final rideData = rideDoc.data()!;
      final currentRideStatus = rideData['rideStatus'] as String?;
      final rideDriverId = rideData['driverId'] as String?;
      final availableSeats = (rideData['availableSeats'] as num?)?.toInt() ?? 0;
      final bookedSeats = (rideData['bookedSeats'] as num?)?.toInt() ?? 0;

      if (rideDriverId != driverId) {
        throw Exception('You are not authorized to manage requests for this ride.');
      }
      if (currentRideStatus != RideStatus.published.toMap()) {
        throw Exception('Ride is no longer active for accepting requests.');
      }

      final remainingSeats = availableSeats - bookedSeats;
      if (remainingSeats < requestedSeats) {
        throw Exception('Insufficient available seats. Remaining: $remainingSeats, Requested: $requestedSeats.');
      }

      // 2. Reload latest request document inside transaction
      final requestRef = _firestore.collection('ride_requests').doc(requestId);
      final requestDoc = await transaction.get(requestRef);

      if (!requestDoc.exists || requestDoc.data() == null) {
        throw Exception('The ride request no longer exists.');
      }

      final currentRequestStatus = requestDoc.data()!['requestStatus'] as String?;
      if (currentRequestStatus != RideRequestStatus.pending.toMap()) {
        throw Exception('This request has already been processed or is no longer pending.');
      }

      // 3. Create new document reference in ride_participants
      final participantRef = _firestore.collection('ride_participants').doc();

      // 4. Perform atomic writes inside transaction
      // A. Lock & update request status
      transaction.update(requestRef, {
        'requestStatus': RideRequestStatus.accepted.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // B. Increment bookedSeats on ride document
      transaction.update(rideRef, {
        'bookedSeats': bookedSeats + requestedSeats,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // C. Create ride_participants document using docRef.id as canonical participantId
      transaction.set(participantRef, {
        'participantId': participantRef.id,
        'rideId': rideId,
        'driverId': driverId,
        'passengerId': passengerId,
        'requestedSeats': requestedSeats,
        'participantStatus': 'active',
        'joinedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Executes an atomic Firestore transaction to DECLINE a passenger ride request.
  Future<void> declineRequestTransaction({
    required String requestId,
    required String driverId,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final requestRef = _firestore.collection('ride_requests').doc(requestId);
      final requestDoc = await transaction.get(requestRef);

      if (!requestDoc.exists || requestDoc.data() == null) {
        throw Exception('The ride request no longer exists.');
      }

      final requestData = requestDoc.data()!;
      final requestDriverId = requestData['driverId'] as String?;
      final currentRequestStatus = requestData['requestStatus'] as String?;

      if (requestDriverId != driverId) {
        throw Exception('You are not authorized to manage requests for this ride.');
      }
      if (currentRequestStatus != RideRequestStatus.pending.toMap()) {
        throw Exception('This request has already been processed or is no longer pending.');
      }

      // Update request status to declined with server timestamp
      transaction.update(requestRef, {
        'requestStatus': RideRequestStatus.declined.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
