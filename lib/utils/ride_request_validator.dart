import '../models/ride_model.dart';
import '../models/ride_request_model.dart';
import '../models/ride_status.dart';

class RideRequestValidationException implements Exception {
  final String message;
  RideRequestValidationException(this.message);

  @override
  String toString() => message;
}

class RideRequestValidator {
  static void validatePassengerAuth(String? passengerId) {
    if (passengerId == null || passengerId.trim().isEmpty) {
      throw RideRequestValidationException('You must be logged in to request a ride seat.');
    }
  }

  static void validateRidePublished(RideModel ride) {
    if (ride.rideStatus != RideStatus.published) {
      throw RideRequestValidationException('This ride is no longer available for seat requests.');
    }
  }

  static void validateNotDriver({required String passengerId, required String driverId}) {
    if (passengerId == driverId) {
      throw RideRequestValidationException('You cannot request a seat in your own published ride.');
    }
  }

  static void validateRequestedSeats(int seats) {
    if (seats <= 0) {
      throw RideRequestValidationException('Requested seats must be greater than zero.');
    }
  }

  static void validateNoDuplicatePendingRequest(RideRequestModel? existingPending) {
    if (existingPending != null) {
      throw RideRequestValidationException('You already have a pending seat request for this ride.');
    }
  }
}
