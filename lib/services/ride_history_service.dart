import 'package:firebase_auth/firebase_auth.dart';
import '../models/completed_ride_item.dart';
import '../repositories/ride_history_repository.dart';

class RideHistoryService {
  final RideHistoryRepository _repository;
  final FirebaseAuth _firebaseAuth;

  RideHistoryService({
    RideHistoryRepository? repository,
    FirebaseAuth? firebaseAuth,
  })  : _repository = repository ?? RideHistoryRepository(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  /// Fetches completed rides for the authenticated driver.
  Future<List<CompletedRideItem>> fetchDriverCompletedRides() async {
    final driver = _firebaseAuth.currentUser;
    if (driver == null) {
      throw Exception('Authentication required to access driver ride history.');
    }

    final historyList = await _repository.fetchDriverHistory(driver.uid);

    // Sort by completedAt descending
    historyList.sort((a, b) => b.completedAt.compareTo(a.completedAt));

    return historyList.map((h) => CompletedRideItem(history: h)).toList();
  }

  /// Fetches completed rides for the authenticated passenger.
  Future<List<CompletedRideItem>> fetchPassengerCompletedRides() async {
    final passenger = _firebaseAuth.currentUser;
    if (passenger == null) {
      throw Exception('Authentication required to access passenger ride history.');
    }

    final participants = await _repository.fetchPassengerParticipants(passenger.uid);
    final List<CompletedRideItem> items = [];

    for (final p in participants) {
      final history = await _repository.fetchHistoryByRideId(p.rideId);
      if (history != null) {
        items.add(CompletedRideItem(
          history: history,
          passengerRequestedSeats: p.requestedSeats,
        ));
      }
    }

    // Sort by completedAt descending
    items.sort((a, b) => b.history.completedAt.compareTo(a.history.completedAt));

    return items;
  }
}
