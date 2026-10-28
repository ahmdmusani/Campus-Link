import 'package:cloud_firestore/cloud_firestore.dart';
import 'ride_status.dart';

class RideModel {
  final String rideId;
  final String driverId;
  final String pickupName;
  final GeoPoint pickupGeoPoint;
  final String destinationName;
  final GeoPoint destinationGeoPoint;
  final DateTime departureTime;
  final int availableSeats;
  final int bookedSeats;
  final double distanceKm;
  final double estimatedDurationMinutes;
  final double rideTotal;
  final double farePerSeat;
  final double commissionPercent;
  final double commissionAmount;
  final double driverReceives;
  final RideStatus rideStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RideModel({
    required this.rideId,
    required this.driverId,
    required this.pickupName,
    required this.pickupGeoPoint,
    required this.destinationName,
    required this.destinationGeoPoint,
    required this.departureTime,
    required this.availableSeats,
    required this.bookedSeats,
    required this.distanceKm,
    required this.estimatedDurationMinutes,
    required this.rideTotal,
    required this.farePerSeat,
    required this.commissionPercent,
    required this.commissionAmount,
    required this.driverReceives,
    required this.rideStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RideModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RideModel(
      rideId: doc.id,
      driverId: data['driverId'] ?? '',
      pickupName: data['pickupName'] ?? '',
      pickupGeoPoint: data['pickupGeoPoint'] as GeoPoint? ?? const GeoPoint(0, 0),
      destinationName: data['destinationName'] ?? '',
      destinationGeoPoint: data['destinationGeoPoint'] as GeoPoint? ?? const GeoPoint(0, 0),
      departureTime: (data['departureTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      availableSeats: (data['availableSeats'] as num?)?.toInt() ?? 1,
      bookedSeats: (data['bookedSeats'] as num?)?.toInt() ?? 0,
      distanceKm: (data['distanceKm'] as num?)?.toDouble() ?? 0.0,
      estimatedDurationMinutes: (data['estimatedDurationMinutes'] as num?)?.toDouble() ?? 0.0,
      rideTotal: (data['rideTotal'] as num?)?.toDouble() ?? 0.0,
      farePerSeat: (data['farePerSeat'] as num?)?.toDouble() ?? 0.0,
      commissionPercent: (data['commissionPercent'] as num?)?.toDouble() ?? 0.0,
      commissionAmount: (data['commissionAmount'] as num?)?.toDouble() ?? 0.0,
      driverReceives: (data['driverReceives'] as num?)?.toDouble() ?? 0.0,
      rideStatus: RideStatus.fromMap(data['rideStatus'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'rideId': rideId,
      'driverId': driverId,
      'pickupName': pickupName,
      'pickupGeoPoint': pickupGeoPoint,
      'destinationName': destinationName,
      'destinationGeoPoint': destinationGeoPoint,
      'departureTime': Timestamp.fromDate(departureTime),
      'availableSeats': availableSeats,
      'bookedSeats': bookedSeats,
      'distanceKm': distanceKm,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'rideTotal': rideTotal,
      'farePerSeat': farePerSeat,
      'commissionPercent': commissionPercent,
      'commissionAmount': commissionAmount,
      'driverReceives': driverReceives,
      'rideStatus': rideStatus.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  RideModel copyWith({
    String? rideId,
    String? driverId,
    String? pickupName,
    GeoPoint? pickupGeoPoint,
    String? destinationName,
    GeoPoint? destinationGeoPoint,
    DateTime? departureTime,
    int? availableSeats,
    int? bookedSeats,
    double? distanceKm,
    double? estimatedDurationMinutes,
    double? rideTotal,
    double? farePerSeat,
    double? commissionPercent,
    double? commissionAmount,
    double? driverReceives,
    RideStatus? rideStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RideModel(
      rideId: rideId ?? this.rideId,
      driverId: driverId ?? this.driverId,
      pickupName: pickupName ?? this.pickupName,
      pickupGeoPoint: pickupGeoPoint ?? this.pickupGeoPoint,
      destinationName: destinationName ?? this.destinationName,
      destinationGeoPoint: destinationGeoPoint ?? this.destinationGeoPoint,
      departureTime: departureTime ?? this.departureTime,
      availableSeats: availableSeats ?? this.availableSeats,
      bookedSeats: bookedSeats ?? this.bookedSeats,
      distanceKm: distanceKm ?? this.distanceKm,
      estimatedDurationMinutes: estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      rideTotal: rideTotal ?? this.rideTotal,
      farePerSeat: farePerSeat ?? this.farePerSeat,
      commissionPercent: commissionPercent ?? this.commissionPercent,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      driverReceives: driverReceives ?? this.driverReceives,
      rideStatus: rideStatus ?? this.rideStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RideModel &&
          runtimeType == other.runtimeType &&
          rideId == other.rideId &&
          driverId == other.driverId &&
          pickupName == other.pickupName &&
          pickupGeoPoint == other.pickupGeoPoint &&
          destinationName == other.destinationName &&
          destinationGeoPoint == other.destinationGeoPoint &&
          departureTime == other.departureTime &&
          availableSeats == other.availableSeats &&
          bookedSeats == other.bookedSeats &&
          distanceKm == other.distanceKm &&
          estimatedDurationMinutes == other.estimatedDurationMinutes &&
          rideTotal == other.rideTotal &&
          farePerSeat == other.farePerSeat &&
          commissionPercent == other.commissionPercent &&
          commissionAmount == other.commissionAmount &&
          driverReceives == other.driverReceives &&
          rideStatus == other.rideStatus &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      rideId.hashCode ^
      driverId.hashCode ^
      pickupName.hashCode ^
      pickupGeoPoint.hashCode ^
      destinationName.hashCode ^
      destinationGeoPoint.hashCode ^
      departureTime.hashCode ^
      availableSeats.hashCode ^
      bookedSeats.hashCode ^
      distanceKm.hashCode ^
      estimatedDurationMinutes.hashCode ^
      rideTotal.hashCode ^
      farePerSeat.hashCode ^
      commissionPercent.hashCode ^
      commissionAmount.hashCode ^
      driverReceives.hashCode ^
      rideStatus.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;
}
