import 'ride_model.dart';

class RideSearchResult {
  final RideModel ride;
  final double realDrivingDistanceKm;
  final double estimatedDurationMinutes;
  final double destinationProximityKm;

  const RideSearchResult({
    required this.ride,
    required this.realDrivingDistanceKm,
    required this.estimatedDurationMinutes,
    required this.destinationProximityKm,
  });
}
