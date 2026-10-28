import 'ride_history_model.dart';

class CompletedRideItem {
  final RideHistoryModel history;
  final int passengerRequestedSeats;
  final String? driverName;

  const CompletedRideItem({
    required this.history,
    this.passengerRequestedSeats = 1,
    this.driverName,
  });
}
