import 'package:cloud_firestore/cloud_firestore.dart';

class RideHistoryModel {
  final String historyId;
  final String rideId;
  final String driverId;
  final String pickupName;
  final String destinationName;
  final DateTime departureTime;
  final DateTime completedAt;
  final double totalFare;
  final int bookedSeats;
  final int participantsCount;

  const RideHistoryModel({
    required this.historyId,
    required this.rideId,
    required this.driverId,
    required this.pickupName,
    required this.destinationName,
    required this.departureTime,
    required this.completedAt,
    required this.totalFare,
    required this.bookedSeats,
    required this.participantsCount,
  });

  factory RideHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RideHistoryModel(
      historyId: doc.id,
      rideId: data['rideId'] ?? '',
      driverId: data['driverId'] ?? '',
      pickupName: data['pickupName'] ?? '',
      destinationName: data['destinationName'] ?? '',
      departureTime: (data['departureTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalFare: (data['totalFare'] as num?)?.toDouble() ?? 0.0,
      bookedSeats: (data['bookedSeats'] as num?)?.toInt() ?? 0,
      participantsCount: (data['participantsCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'historyId': historyId,
      'rideId': rideId,
      'driverId': driverId,
      'pickupName': pickupName,
      'destinationName': destinationName,
      'departureTime': Timestamp.fromDate(departureTime),
      'completedAt': Timestamp.fromDate(completedAt),
      'totalFare': totalFare,
      'bookedSeats': bookedSeats,
      'participantsCount': participantsCount,
    };
  }

  RideHistoryModel copyWith({
    String? historyId,
    String? rideId,
    String? driverId,
    String? pickupName,
    String? destinationName,
    DateTime? departureTime,
    DateTime? completedAt,
    double? totalFare,
    int? bookedSeats,
    int? participantsCount,
  }) {
    return RideHistoryModel(
      historyId: historyId ?? this.historyId,
      rideId: rideId ?? this.rideId,
      driverId: driverId ?? this.driverId,
      pickupName: pickupName ?? this.pickupName,
      destinationName: destinationName ?? this.destinationName,
      departureTime: departureTime ?? this.departureTime,
      completedAt: completedAt ?? this.completedAt,
      totalFare: totalFare ?? this.totalFare,
      bookedSeats: bookedSeats ?? this.bookedSeats,
      participantsCount: participantsCount ?? this.participantsCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RideHistoryModel &&
          runtimeType == other.runtimeType &&
          historyId == other.historyId &&
          rideId == other.rideId &&
          driverId == other.driverId &&
          pickupName == other.pickupName &&
          destinationName == other.destinationName &&
          departureTime == other.departureTime &&
          completedAt == other.completedAt &&
          totalFare == other.totalFare &&
          bookedSeats == other.bookedSeats &&
          participantsCount == other.participantsCount;

  @override
  int get hashCode =>
      historyId.hashCode ^
      rideId.hashCode ^
      driverId.hashCode ^
      pickupName.hashCode ^
      destinationName.hashCode ^
      departureTime.hashCode ^
      completedAt.hashCode ^
      totalFare.hashCode ^
      bookedSeats.hashCode ^
      participantsCount.hashCode;
}
