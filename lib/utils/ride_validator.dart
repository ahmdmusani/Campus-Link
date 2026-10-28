import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pricing_config_model.dart';
import '../services/routing_service.dart';

class RideValidationException implements Exception {
  final String message;
  RideValidationException(this.message);

  @override
  String toString() => message;
}

class RideValidator {
  static void validateDriverAuth(String? driverId) {
    if (driverId == null || driverId.trim().isEmpty) {
      throw RideValidationException('Driver must be authenticated to publish a ride.');
    }
  }

  static void validatePickup({
    required String pickupName,
    required GeoPoint pickupGeoPoint,
  }) {
    if (pickupName.trim().isEmpty) {
      throw RideValidationException('Pickup location name cannot be empty.');
    }
    if (pickupGeoPoint.latitude < -90 || pickupGeoPoint.latitude > 90 ||
        pickupGeoPoint.longitude < -180 || pickupGeoPoint.longitude > 180) {
      throw RideValidationException('Pickup coordinates are invalid.');
    }
  }

  static void validateDestination({
    required String destinationName,
    required GeoPoint destinationGeoPoint,
    required GeoPoint pickupGeoPoint,
  }) {
    if (destinationName.trim().isEmpty) {
      throw RideValidationException('Destination location name cannot be empty.');
    }
    if (destinationGeoPoint.latitude < -90 || destinationGeoPoint.latitude > 90 ||
        destinationGeoPoint.longitude < -180 || destinationGeoPoint.longitude > 180) {
      throw RideValidationException('Destination coordinates are invalid.');
    }
    if (pickupGeoPoint.latitude == destinationGeoPoint.latitude &&
        pickupGeoPoint.longitude == destinationGeoPoint.longitude) {
      throw RideValidationException('Destination cannot be identical to pickup location.');
    }
  }

  static void validateDepartureTime(DateTime departureTime) {
    if (departureTime.isBefore(DateTime.now())) {
      throw RideValidationException('Departure time must be scheduled in the future.');
    }
  }

  static void validateAvailableSeats(int seats) {
    if (seats < 1 || seats > 7) {
      throw RideValidationException('Available seats must be between 1 and 7.');
    }
  }

  static void validatePricingConfig(PricingConfigModel? config) {
    if (config == null) {
      throw RideValidationException('Pricing configuration could not be loaded from Firestore.');
    }
    if (config.baseFare < 0 || config.perKmRate < 0 || config.commissionPercent < 0) {
      throw RideValidationException('Invalid pricing configuration values.');
    }
  }

  static void validateRoute(RoutingResult? route) {
    if (route == null || route.distanceKm <= 0 || route.estimatedDurationMinutes <= 0) {
      throw RideValidationException('A valid driving route distance and duration could not be determined.');
    }
  }
}
