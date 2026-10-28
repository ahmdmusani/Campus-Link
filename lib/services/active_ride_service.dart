import 'package:firebase_auth/firebase_auth.dart';
import '../models/enriched_participant_item.dart';
import '../models/ride_model.dart';
import '../repositories/active_ride_repository.dart';

class ActiveRideService {
  final ActiveRideRepository _activeRideRepository;
  final FirebaseAuth _firebaseAuth;

  ActiveRideService({
    ActiveRideRepository? activeRideRepository,
    FirebaseAuth? firebaseAuth,
  })  : _activeRideRepository = activeRideRepository ?? ActiveRideRepository(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  /// Returns current authenticated driver UID or throws Exception.
  String get currentDriverId {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('Driver must be authenticated.');
    }
    return user.uid;
  }

  /// Streams published active rides belonging to the current authenticated driver.
  Stream<List<RideModel>> streamDriverActiveRides() {
    final uid = currentDriverId;
    return _activeRideRepository.streamDriverActiveRides(uid);
  }

  /// Streams live RideModel document updates for a specific rideId after verifying driver ownership.
  Stream<RideModel?> streamActiveRide(String rideId) {
    final uid = currentDriverId;
    return _activeRideRepository.streamActiveRide(rideId).map((ride) {
      if (ride != null && ride.driverId != uid) {
        throw Exception('Unauthorized driver access to active ride.');
      }
      return ride;
    });
  }

  /// Streams active participants for a ride enriched with passenger profile names and avatars.
  Stream<List<EnrichedParticipantItem>> streamEnrichedParticipants(String rideId) {
    return _activeRideRepository.streamActiveParticipants(rideId).asyncMap((participants) async {
      final List<EnrichedParticipantItem> enrichedList = [];
      for (final p in participants) {
        String name = 'Passenger (${p.passengerId.length > 6 ? p.passengerId.substring(0, 6) : p.passengerId})';
        String? profileImg;

        try {
          final profileData = await _activeRideRepository.fetchPassengerProfile(p.passengerId);
          if (profileData != null) {
            name = profileData['fullName'] ?? profileData['name'] ?? name;
            profileImg = profileData['photoUrl'] as String?;
          }
        } catch (_) {}

        enrichedList.add(EnrichedParticipantItem(
          participant: p,
          passengerName: name,
          passengerProfileImage: profileImg,
        ));
      }
      return enrichedList;
    });
  }

  /// Calculates remaining seats for a ride.
  int calculateRemainingSeats(RideModel ride) {
    final remaining = ride.availableSeats - ride.bookedSeats;
    return remaining < 0 ? 0 : remaining;
  }
}
