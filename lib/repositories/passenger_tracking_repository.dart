import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/driver_location_model.dart';
import '../models/ride_model.dart';

class PassengerTrackingRepository {
  final FirebaseFirestore _firestore;

  PassengerTrackingRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Checks if the passenger has a confirmed active participant record for a ride.
  Future<bool> isPassengerAcceptedParticipant({
    required String rideId,
    required String passengerId,
  }) async {
    final query = await _firestore
        .collection('ride_participants')
        .where('rideId', isEqualTo: rideId)
        .where('passengerId', isEqualTo: passengerId)
        .where('participantStatus', isEqualTo: 'active')
        .get();

    return query.docs.isNotEmpty;
  }

  /// Checks if the user is the driver of the ride.
  Future<bool> isRideDriver({
    required String rideId,
    required String userId,
  }) async {
    final doc = await _firestore.collection('rides').doc(rideId).get();
    if (!doc.exists || doc.data() == null) return false;
    final driverId = doc.data()!['driverId'] as String?;
    return driverId == userId;
  }

  /// Fetches a ride by ID.
  Future<RideModel?> fetchRide(String rideId) async {
    final doc = await _firestore.collection('rides').doc(rideId).get();
    if (!doc.exists || doc.data() == null) return null;
    return RideModel.fromFirestore(doc);
  }

  /// Returns real-time stream of the driver location document (driver_locations/{rideId}).
  Stream<DriverLocationModel?> streamDriverLocation(String rideId) {
    return _firestore
        .collection('driver_locations')
        .doc(rideId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return DriverLocationModel.fromFirestore(doc);
    });
  }
}
