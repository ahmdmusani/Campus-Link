import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/driver_location_model.dart';
import '../models/driver_location_status.dart';
import '../models/ride_model.dart';
import '../models/ride_status.dart';
import '../repositories/driver_location_repository.dart';
import '../utils/haversine_calculator.dart';

class DriverLocationService {
  final DriverLocationRepository _repository;
  final FirebaseAuth _firebaseAuth;

  final StreamController<DriverLocationStatus> _statusController =
      StreamController<DriverLocationStatus>.broadcast();
  Stream<DriverLocationStatus> get statusStream => _statusController.stream;

  DriverLocationStatus _currentStatus = DriverLocationStatus.waitingForPermission;
  DriverLocationStatus get currentStatus => _currentStatus;

  Timer? _gpsPublishTimer;
  GeoPoint? _lastPublishedLocation;
  DateTime? _lastPublishedTime;

  // Intelligent Throttling Constants
  static const double _minDistanceMeters = 15.0; // Distance threshold (15m)
  static const Duration _minTimeInterval = Duration(seconds: 10); // Time threshold (10s)

  DriverLocationService({
    DriverLocationRepository? repository,
    FirebaseAuth? firebaseAuth,
  })  : _repository = repository ?? DriverLocationRepository(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  void _updateStatus(DriverLocationStatus newStatus) {
    _currentStatus = newStatus;
    if (!_statusController.isClosed) {
      _statusController.add(newStatus);
    }
  }

  /// Starts live location sharing for an active published ride owned by the authenticated driver.
  Future<void> startSharing(RideModel ride) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      _updateStatus(DriverLocationStatus.connectionLost);
      throw Exception('Driver must be authenticated.');
    }

    if (ride.driverId != user.uid) {
      _updateStatus(DriverLocationStatus.connectionLost);
      throw Exception('Unauthorized driver ownership check failed.');
    }

    if (ride.rideStatus != RideStatus.published) {
      _updateStatus(DriverLocationStatus.connectionLost);
      throw Exception('Location sharing is only active for published rides.');
    }

    _updateStatus(DriverLocationStatus.connecting);

    // Initial publish lock
    final initialPickup = ride.pickupGeoPoint;
    await _publishLocationIfThrottled(
      rideId: ride.rideId,
      driverId: user.uid,
      currentLocation: initialPickup,
      heading: 0.0,
      speed: 0.0,
      accuracy: 5.0,
      forcePublish: true,
    );

    _updateStatus(DriverLocationStatus.sharingLiveLocation);

    // Periodic GPS simulation stream timer adhering to throttling rules
    _gpsPublishTimer?.cancel();
    _gpsPublishTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null || currentUser.uid != ride.driverId) {
        stopSharing();
        return;
      }

      // Live location updates sampled from current location
      await _publishLocationIfThrottled(
        rideId: ride.rideId,
        driverId: currentUser.uid,
        currentLocation: ride.pickupGeoPoint,
        heading: 0.0,
        speed: 0.0,
        accuracy: 5.0,
        forcePublish: false,
      );
    });
  }

  /// Evaluates intelligent distance and time throttling before writing location to Firestore.
  Future<void> _publishLocationIfThrottled({
    required String rideId,
    required String driverId,
    required GeoPoint currentLocation,
    required double heading,
    required double speed,
    required double accuracy,
    required bool forcePublish,
  }) async {
    final now = DateTime.now();

    if (!forcePublish && _lastPublishedLocation != null && _lastPublishedTime != null) {
      final elapsed = now.difference(_lastPublishedTime!);
      final distanceKm = HaversineCalculator.calculateDistanceKm(
        _lastPublishedLocation!,
        currentLocation,
      );
      final distanceMeters = distanceKm * 1000.0;

      // Throttle Rule: Skip write if movement is less than 15m AND less than 10 seconds elapsed
      if (distanceMeters < _minDistanceMeters && elapsed < _minTimeInterval) {
        return;
      }
    }

    try {
      await _repository.publishLocation(
        rideId: rideId,
        driverId: driverId,
        latitude: currentLocation.latitude,
        longitude: currentLocation.longitude,
        heading: heading,
        speed: speed,
        accuracy: accuracy,
      );

      _lastPublishedLocation = currentLocation;
      _lastPublishedTime = now;
      _updateStatus(DriverLocationStatus.sharingLiveLocation);
    } catch (_) {
      _updateStatus(DriverLocationStatus.connectionLost);
    }
  }

  /// Streams real-time driver location updates from Firestore for a rideId.
  Stream<DriverLocationModel?> streamLocation(String rideId) {
    return _repository.streamLocation(rideId);
  }

  /// Stops live location sharing and releases resources.
  void stopSharing() {
    _gpsPublishTimer?.cancel();
    _gpsPublishTimer = null;
    _lastPublishedLocation = null;
    _lastPublishedTime = null;
    _updateStatus(DriverLocationStatus.connectionLost);
  }

  /// Disposes controllers and timers.
  void dispose() {
    stopSharing();
    _statusController.close();
  }
}
