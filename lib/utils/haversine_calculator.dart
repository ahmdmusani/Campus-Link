import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class HaversineCalculator {
  static const double _earthRadiusKm = 6371.0;

  /// Calculates geodesic straight-line distance in kilometers between two GeoPoints.
  /// Used for fast coarse filtering before performing OSRM road distance routing.
  static double calculateDistanceKm(GeoPoint point1, GeoPoint point2) {
    final lat1Rad = point1.latitude * (pi / 180.0);
    final lon1Rad = point1.longitude * (pi / 180.0);
    final lat2Rad = point2.latitude * (pi / 180.0);
    final lon2Rad = point2.longitude * (pi / 180.0);

    final dLat = lat2Rad - lat1Rad;
    final dLon = lon2Rad - lon1Rad;

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    final distance = _earthRadiusKm * c;
    return double.parse(distance.toStringAsFixed(2));
  }
}
