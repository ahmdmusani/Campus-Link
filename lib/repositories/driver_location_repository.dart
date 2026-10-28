import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/driver_location_model.dart';

class DriverLocationRepository {
  final FirebaseFirestore _firestore;

  DriverLocationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Publishes or updates the driver's live location in Firestore using rideId as document ID.
  Future<void> publishLocation({
    required String rideId,
    required String driverId,
    required double latitude,
    required double longitude,
    required double heading,
    required double speed,
    required double accuracy,
  }) async {
    final docRef = _firestore.collection('driver_locations').doc(rideId);
    await docRef.set({
      'rideId': rideId,
      'driverId': driverId,
      'latitude': latitude,
      'longitude': longitude,
      'heading': heading,
      'speed': speed,
      'accuracy': accuracy,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Fetches current location document for a rideId.
  Future<DriverLocationModel?> fetchLocation(String rideId) async {
    final doc = await _firestore.collection('driver_locations').doc(rideId).get();
    if (!doc.exists || doc.data() == null) return null;
    return DriverLocationModel.fromFirestore(doc);
  }

  /// Streams real-time driver location updates for a specific rideId.
  Stream<DriverLocationModel?> streamLocation(String rideId) {
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
