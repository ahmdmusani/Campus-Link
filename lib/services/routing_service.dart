import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class RoutingResult {
  final double distanceKm;
  final double estimatedDurationMinutes;

  const RoutingResult({
    required this.distanceKm,
    required this.estimatedDurationMinutes,
  });
}

class RoutingException implements Exception {
  final String message;
  RoutingException(this.message);

  @override
  String toString() => message;
}

class RoutingService {
  final http.Client _httpClient;

  RoutingService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  Future<RoutingResult> calculateDrivingRoute({
    required GeoPoint pickup,
    required GeoPoint destination,
  }) async {
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${pickup.longitude},${pickup.latitude};'
      '${destination.longitude},${destination.latitude}'
      '?overview=false',
    );

    try {
      final response = await _httpClient.get(
        url,
        headers: {'User-Agent': 'CampusLinkApp/1.0'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final firstRoute = routes[0] as Map<String, dynamic>;
          final distanceMeters = (firstRoute['distance'] as num?)?.toDouble() ?? 0.0;
          final durationSeconds = (firstRoute['duration'] as num?)?.toDouble() ?? 0.0;

          if (distanceMeters > 0 && durationSeconds > 0) {
            final distanceKm = double.parse((distanceMeters / 1000.0).toStringAsFixed(2));
            final durationMinutes = double.parse((durationSeconds / 60.0).toStringAsFixed(1));

            return RoutingResult(
              distanceKm: distanceKm,
              estimatedDurationMinutes: durationMinutes,
            );
          }
        }
      }

      throw RoutingException(
        'Unable to calculate a valid driving route between pickup and destination locations.',
      );
    } catch (e) {
      if (e is RoutingException) rethrow;
      throw RoutingException(
        'Routing service request failed: ${e.toString()}',
      );
    }
  }
}
