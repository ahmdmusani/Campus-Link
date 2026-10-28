import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride_model.dart';
import '../models/ride_status.dart';
import '../models/pricing_config_model.dart';

class RideRepository {
  final FirebaseFirestore _firestore;

  RideRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Creates a new ride document in Firestore using document ID as canonical rideId.
  Future<RideModel> createRide(RideModel ride) async {
    final docRef = _firestore.collection('rides').doc();
    final canonicalRide = ride.copyWith(rideId: docRef.id);
    await docRef.set(canonicalRide.toFirestore());
    return canonicalRide;
  }

  /// Updates an existing ride document in Firestore.
  Future<void> updateRide(RideModel ride) async {
    await _firestore
        .collection('rides')
        .doc(ride.rideId)
        .update(ride.toFirestore());
  }

  /// Deletes a ride document from Firestore by ID.
  Future<void> deleteRide(String rideId) async {
    await _firestore.collection('rides').doc(rideId).delete();
  }

  /// Fetches a ride document from Firestore by ID.
  Future<RideModel?> fetchRide(String rideId) async {
    final doc = await _firestore.collection('rides').doc(rideId).get();
    if (!doc.exists || doc.data() == null) return null;
    return RideModel.fromFirestore(doc);
  }

  /// Fetches pricing configuration document from Firestore (`ride_pricing/config`).
  Future<PricingConfigModel?> fetchPricingConfig() async {
    final doc = await _firestore.collection('ride_pricing').doc('config').get();
    if (!doc.exists || doc.data() == null) return null;
    return PricingConfigModel.fromFirestore(doc.data()!);
  }

  /// Queries published candidate rides from Firestore within a geographic bounding box.
  /// Reduces Firestore document reads for high-scale environments.
  Future<List<RideModel>> fetchCandidateRidesInBoundingBox({
    required GeoPoint center,
    double radiusKm = 15.0,
  }) async {
    final latDelta = radiusKm / 111.0;
    final minLat = center.latitude - latDelta;
    final maxLat = center.latitude + latDelta;

    final querySnapshot = await _firestore
        .collection('rides')
        .where('rideStatus', isEqualTo: RideStatus.published.toMap())
        .get();

    return querySnapshot.docs
        .map((doc) => RideModel.fromFirestore(doc))
        .where((ride) {
          final lat = ride.destinationGeoPoint.latitude;
          final hasSeats = ride.availableSeats > ride.bookedSeats;
          return hasSeats && lat >= minLat && lat <= maxLat;
        })
        .toList();
  }
}
