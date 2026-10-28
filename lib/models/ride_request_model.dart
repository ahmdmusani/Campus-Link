import 'package:cloud_firestore/cloud_firestore.dart';
import 'ride_request_status.dart';

class RideRequestModel {
  final String requestId;
  final String rideId;
  final String driverId;
  final String passengerId;
  final String passengerName;
  final String? passengerProfileImage;
  final int requestedSeats;
  final RideRequestStatus requestStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RideRequestModel({
    required this.requestId,
    required this.rideId,
    required this.driverId,
    required this.passengerId,
    required this.passengerName,
    this.passengerProfileImage,
    required this.requestedSeats,
    required this.requestStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RideRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RideRequestModel(
      requestId: doc.id,
      rideId: data['rideId'] ?? '',
      driverId: data['driverId'] ?? '',
      passengerId: data['passengerId'] ?? '',
      passengerName: data['passengerName'] ?? '',
      passengerProfileImage: data['passengerProfileImage'] as String?,
      requestedSeats: (data['requestedSeats'] as num?)?.toInt() ?? 1,
      requestStatus: RideRequestStatus.fromMap(data['requestStatus'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'requestId': requestId,
      'rideId': rideId,
      'driverId': driverId,
      'passengerId': passengerId,
      'passengerName': passengerName,
      'passengerProfileImage': passengerProfileImage,
      'requestedSeats': requestedSeats,
      'requestStatus': requestStatus.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  RideRequestModel copyWith({
    String? requestId,
    String? rideId,
    String? driverId,
    String? passengerId,
    String? passengerName,
    String? passengerProfileImage,
    int? requestedSeats,
    RideRequestStatus? requestStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RideRequestModel(
      requestId: requestId ?? this.requestId,
      rideId: rideId ?? this.rideId,
      driverId: driverId ?? this.driverId,
      passengerId: passengerId ?? this.passengerId,
      passengerName: passengerName ?? this.passengerName,
      passengerProfileImage: passengerProfileImage ?? this.passengerProfileImage,
      requestedSeats: requestedSeats ?? this.requestedSeats,
      requestStatus: requestStatus ?? this.requestStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RideRequestModel &&
          runtimeType == other.runtimeType &&
          requestId == other.requestId &&
          rideId == other.rideId &&
          driverId == other.driverId &&
          passengerId == other.passengerId &&
          passengerName == other.passengerName &&
          passengerProfileImage == other.passengerProfileImage &&
          requestedSeats == other.requestedSeats &&
          requestStatus == other.requestStatus &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      requestId.hashCode ^
      rideId.hashCode ^
      driverId.hashCode ^
      passengerId.hashCode ^
      passengerName.hashCode ^
      passengerProfileImage.hashCode ^
      requestedSeats.hashCode ^
      requestStatus.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;
}
