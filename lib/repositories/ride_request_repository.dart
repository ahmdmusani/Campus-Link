import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride_request_model.dart';
import '../models/ride_request_status.dart';

class RideRequestRepository {
  final FirebaseFirestore _firestore;

  RideRequestRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Creates a new ride request document using Firestore document ID as canonical requestId.
  Future<RideRequestModel> createRequest(RideRequestModel request) async {
    final docRef = _firestore.collection('ride_requests').doc();
    final canonicalRequest = request.copyWith(requestId: docRef.id);
    await docRef.set(canonicalRequest.toFirestore());
    return canonicalRequest;
  }

  /// Fetches a ride request document from Firestore by ID to verify persistence.
  Future<RideRequestModel?> fetchRequest(String requestId) async {
    final doc = await _firestore.collection('ride_requests').doc(requestId).get();
    if (!doc.exists || doc.data() == null) return null;
    return RideRequestModel.fromFirestore(doc);
  }

  /// Fetches any active pending request for a specific ride and passenger to prevent duplicate submissions.
  Future<RideRequestModel?> fetchPendingRequest({
    required String rideId,
    required String passengerId,
  }) async {
    final querySnapshot = await _firestore
        .collection('ride_requests')
        .where('rideId', isEqualTo: rideId)
        .where('passengerId', isEqualTo: passengerId)
        .where('requestStatus', isEqualTo: RideRequestStatus.pending.toMap())
        .get();

    if (querySnapshot.docs.isEmpty) return null;
    return RideRequestModel.fromFirestore(querySnapshot.docs.first);
  }

  /// Fetches all requests for a specific ride.
  Future<List<RideRequestModel>> fetchRequestsForRide(String rideId) async {
    final querySnapshot = await _firestore
        .collection('ride_requests')
        .where('rideId', isEqualTo: rideId)
        .get();

    return querySnapshot.docs
        .map((doc) => RideRequestModel.fromFirestore(doc))
        .toList();
  }
}
