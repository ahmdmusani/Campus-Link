import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride_history_model.dart';
import '../models/ride_participant_model.dart';

class RideHistoryRepository {
  final FirebaseFirestore _firestore;

  RideHistoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetches completed ride history records for a specific driver.
  Future<List<RideHistoryModel>> fetchDriverHistory(String driverId) async {
    final querySnapshot = await _firestore
        .collection('ride_history')
        .where('driverId', isEqualTo: driverId)
        .get();

    return querySnapshot.docs
        .map((doc) => RideHistoryModel.fromFirestore(doc))
        .toList();
  }

  /// Fetches active participant records for a specific passenger.
  Future<List<RideParticipantModel>> fetchPassengerParticipants(String passengerId) async {
    final querySnapshot = await _firestore
        .collection('ride_participants')
        .where('passengerId', isEqualTo: passengerId)
        .where('participantStatus', isEqualTo: 'active')
        .get();

    return querySnapshot.docs
        .map((doc) => RideParticipantModel.fromFirestore(doc))
        .toList();
  }

  /// Fetches the ride history record for a specific rideId.
  Future<RideHistoryModel?> fetchHistoryByRideId(String rideId) async {
    final querySnapshot = await _firestore
        .collection('ride_history')
        .where('rideId', isEqualTo: rideId)
        .get();

    if (querySnapshot.docs.isEmpty) return null;
    return RideHistoryModel.fromFirestore(querySnapshot.docs.first);
  }
}
