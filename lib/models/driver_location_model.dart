import 'package:cloud_firestore/cloud_firestore.dart';

class DriverLocationModel {
  final String rideId;
  final String driverId;
  final double latitude;
  final double longitude;
  final double heading;
  final double speed;
  final double accuracy;
  final DateTime lastUpdated;

  const DriverLocationModel({
    required this.rideId,
    required this.driverId,
    required this.latitude,
    required this.longitude,
    required this.heading,
    required this.speed,
    required this.accuracy,
    required this.lastUpdated,
  });

  factory DriverLocationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DriverLocationModel(
      rideId: doc.id,
      driverId: data['driverId'] ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      heading: (data['heading'] as num?)?.toDouble() ?? 0.0,
      speed: (data['speed'] as num?)?.toDouble() ?? 0.0,
      accuracy: (data['accuracy'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'rideId': rideId,
      'driverId': driverId,
      'latitude': latitude,
      'longitude': longitude,
      'heading': heading,
      'speed': speed,
      'accuracy': accuracy,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  DriverLocationModel copyWith({
    String? rideId,
    String? driverId,
    double? latitude,
    double? longitude,
    double? heading,
    double? speed,
    double? accuracy,
    DateTime? lastUpdated,
  }) {
    return DriverLocationModel(
      rideId: rideId ?? this.rideId,
      driverId: driverId ?? this.driverId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      accuracy: accuracy ?? this.accuracy,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DriverLocationModel &&
          runtimeType == other.runtimeType &&
          rideId == other.rideId &&
          driverId == other.driverId &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          heading == other.heading &&
          speed == other.speed &&
          accuracy == other.accuracy &&
          lastUpdated == other.lastUpdated;

  @override
  int get hashCode =>
      rideId.hashCode ^
      driverId.hashCode ^
      latitude.hashCode ^
      longitude.hashCode ^
      heading.hashCode ^
      speed.hashCode ^
      accuracy.hashCode ^
      lastUpdated.hashCode;
}
