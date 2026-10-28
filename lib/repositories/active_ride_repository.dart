import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride_model.dart';
import '../models/ride_participant_model.dart';
import '../models/ride_status.dart';

class ActiveRideRepository {
  final FirebaseFirestore _firestore;

  ActiveRideRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Returns real-time stream of a specific ride document by rideId.
  Stream<RideModel?> streamActiveRide(String rideId) {
    return _firestore.collection('rides').doc(rideId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return RideModel.fromFirestore(doc);
    });
  }

  /// Returns real-time stream of published active rides for a specific driver.
  Stream<List<RideModel>> streamDriverActiveRides(String driverId) {
    return _firestore
        .collection('rides')
        .where('driverId', isEqualTo: driverId)
        .where('rideStatus', isEqualTo: RideStatus.published.toMap())
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RideModel.fromFirestore(doc))
            .toList());
  }

  /// Returns real-time stream of active participants for a specific rideId.
  Stream<List<RideParticipantModel>> streamActiveParticipants(String rideId) {
    return _firestore
        .collection('ride_participants')
        .where('rideId', isEqualTo: rideId)
        .where('participantStatus', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RideParticipantModel.fromFirestore(doc))
            .toList());
  }

  /// Fetches passenger user profile document data by passengerId.
  Future<Map<String, dynamic>?> fetchPassengerProfile(String passengerId) async {
    final doc = await _firestore.collection('users').doc(passengerId).get();
    if (!doc.exists || doc.data() == null) return null;
    return doc.data();
  }
}
