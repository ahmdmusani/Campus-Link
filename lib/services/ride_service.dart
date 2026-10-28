import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ride_model.dart';
import '../models/ride_status.dart';
import '../models/ride_search_result.dart';
import '../repositories/ride_repository.dart';
import '../services/routing_service.dart';
import '../utils/fare_calculator.dart';
import '../utils/haversine_calculator.dart';
import '../utils/ride_validator.dart';

class RideService {
  final RideRepository _rideRepository;
  final RoutingService _routingService;
  final FirebaseAuth _firebaseAuth;

  RideService({
    RideRepository? rideRepository,
    RoutingService? routingService,
    FirebaseAuth? firebaseAuth,
  })  : _rideRepository = rideRepository ?? RideRepository(),
        _routingService = routingService ?? RoutingService(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  /// Publishes a new ride by executing validation, routing, fare calculation, and persistence.
  Future<RideModel> publishRide({
    required String pickupName,
    required GeoPoint pickupGeoPoint,
    required String destinationName,
    required GeoPoint destinationGeoPoint,
    required DateTime departureTime,
    required int availableSeats,
  }) async {
    final currentUser = _firebaseAuth.currentUser;
    final driverId = currentUser?.uid;

    // 1. Validate Driver & Basic Parameters
    RideValidator.validateDriverAuth(driverId);
    RideValidator.validatePickup(pickupName: pickupName, pickupGeoPoint: pickupGeoPoint);
    RideValidator.validateDestination(
      destinationName: destinationName,
      destinationGeoPoint: destinationGeoPoint,
      pickupGeoPoint: pickupGeoPoint,
    );
    RideValidator.validateDepartureTime(departureTime);
    RideValidator.validateAvailableSeats(availableSeats);

    // 2. Load Pricing Configuration from Firestore
    final pricingConfig = await _rideRepository.fetchPricingConfig();
    RideValidator.validatePricingConfig(pricingConfig);

    // 3. Calculate Real Driving Route (Throws RoutingException if valid route cannot be calculated)
    final routeResult = await _routingService.calculateDrivingRoute(
      pickup: pickupGeoPoint,
      destination: destinationGeoPoint,
    );
    RideValidator.validateRoute(routeResult);

    // 4. Calculate Fare Metrics
    final fareResult = FareCalculator.calculateFare(
      distanceKm: routeResult.distanceKm,
      availableSeats: availableSeats,
      pricingConfig: pricingConfig!,
    );

    final now = DateTime.now();

    // 5. Construct Unpersisted RideModel
    final initialRide = RideModel(
      rideId: '', // Canonical ID will be assigned by Firestore document ID in repository
      driverId: driverId!,
      pickupName: pickupName.trim(),
      pickupGeoPoint: pickupGeoPoint,
      destinationName: destinationName.trim(),
      destinationGeoPoint: destinationGeoPoint,
      departureTime: departureTime,
      availableSeats: availableSeats,
      bookedSeats: 0,
      distanceKm: routeResult.distanceKm,
      estimatedDurationMinutes: routeResult.estimatedDurationMinutes,
      rideTotal: fareResult.rideTotal,
      farePerSeat: fareResult.farePerSeat,
      commissionPercent: pricingConfig.commissionPercent,
      commissionAmount: fareResult.commissionAmount,
      driverReceives: fareResult.driverReceives,
      rideStatus: RideStatus.published,
      createdAt: now,
      updatedAt: now,
    );

    // 6. Persist Ride via Repository (assigns canonical Firestore doc ID)
    final savedRide = await _rideRepository.createRide(initialRide);
    return savedRide;
  }

  /// Searches published rides using a two-stage geographic matching algorithm:
  /// Stage 1: Coarse Firestore bounding box & Haversine distance filtering.
  /// Stage 2: Real road network distance calculation via RoutingService (OSRM) for shortlisted rides.
  /// Sorting Priority:
  /// 1. Shortest real driving distance (KM)
  /// 2. Earliest departure time
  /// 3. Lowest fare per seat
  Future<List<RideSearchResult>> searchRidesByDestination({
    required GeoPoint passengerPickup,
    required GeoPoint targetDestination,
    double coarseRadiusKm = 15.0,
  }) async {
    // Stage 1: Fetch candidate rides within geographic bounding box
    final candidateRides = await _rideRepository.fetchCandidateRidesInBoundingBox(
      center: targetDestination,
      radiusKm: coarseRadiusKm,
    );

    // Coarse filter by Haversine distance
    final List<RideModel> shortlisted = [];
    for (final ride in candidateRides) {
      final coarseDist = HaversineCalculator.calculateDistanceKm(
        targetDestination,
        ride.destinationGeoPoint,
      );
      if (coarseDist <= coarseRadiusKm) {
        shortlisted.add(ride);
      }
    }

    // Stage 2: Real road network distance routing (OSRM) for shortlisted candidate rides
    final List<RideSearchResult> searchResults = [];
    for (final ride in shortlisted) {
      try {
        final route = await _routingService.calculateDrivingRoute(
          pickup: passengerPickup,
          destination: ride.destinationGeoPoint,
        );

        final proximityKm = HaversineCalculator.calculateDistanceKm(
          targetDestination,
          ride.destinationGeoPoint,
        );

        searchResults.add(RideSearchResult(
          ride: ride,
          realDrivingDistanceKm: route.distanceKm,
          estimatedDurationMinutes: route.estimatedDurationMinutes,
          destinationProximityKm: proximityKm,
        ));
      } catch (e) {
        // Skip candidate rides where road routing cannot be calculated
        debugPrint('Skipping candidate ride ${ride.rideId} due to routing calculation error: $e');
      }
    }

    // 3-Tier Sorting Priority:
    // 1. Shortest real driving distance (realDrivingDistanceKm)
    // 2. Earliest departure time (departureTime)
    // 3. Lowest fare per seat (farePerSeat)
    searchResults.sort((a, b) {
      final distCompare = a.realDrivingDistanceKm.compareTo(b.realDrivingDistanceKm);
      if (distCompare != 0) return distCompare;

      final timeCompare = a.ride.departureTime.compareTo(b.ride.departureTime);
      if (timeCompare != 0) return timeCompare;

      return a.ride.farePerSeat.compareTo(b.ride.farePerSeat);
    });

    return searchResults;
  }

  /// Fetches a ride by its canonical ID.
  Future<RideModel?> getRide(String rideId) {
    return _rideRepository.fetchRide(rideId);
  }

  /// Cancels a published ride by updating status to cancelled.
  Future<void> cancelRide(RideModel ride) async {
    final updatedRide = ride.copyWith(
      rideStatus: RideStatus.cancelled,
      updatedAt: DateTime.now(),
    );
    await _rideRepository.updateRide(updatedRide);
  }
}
