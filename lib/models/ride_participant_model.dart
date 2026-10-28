import 'package:cloud_firestore/cloud_firestore.dart';

class RideParticipantModel {
  final String participantId;
  final String rideId;
  final String driverId;
  final String passengerId;
  final int requestedSeats;
  final String participantStatus;
  final DateTime joinedAt;

  const RideParticipantModel({
    required this.participantId,
    required this.rideId,
    required this.driverId,
    required this.passengerId,
    required this.requestedSeats,
    required this.participantStatus,
    required this.joinedAt,
  });

  factory RideParticipantModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RideParticipantModel(
      participantId: doc.id,
      rideId: data['rideId'] ?? '',
      driverId: data['driverId'] ?? '',
      passengerId: data['passengerId'] ?? '',
      requestedSeats: (data['requestedSeats'] as num?)?.toInt() ?? 1,
      participantStatus: data['participantStatus'] ?? 'active',
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participantId': participantId,
      'rideId': rideId,
      'driverId': driverId,
      'passengerId': passengerId,
      'requestedSeats': requestedSeats,
      'participantStatus': participantStatus,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  RideParticipantModel copyWith({
    String? participantId,
    String? rideId,
    String? driverId,
    String? passengerId,
    int? requestedSeats,
    String? participantStatus,
    DateTime? joinedAt,
  }) {
    return RideParticipantModel(
      participantId: participantId ?? this.participantId,
      rideId: rideId ?? this.rideId,
      driverId: driverId ?? this.driverId,
      passengerId: passengerId ?? this.passengerId,
      requestedSeats: requestedSeats ?? this.requestedSeats,
      participantStatus: participantStatus ?? this.participantStatus,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RideParticipantModel &&
          runtimeType == other.runtimeType &&
          participantId == other.participantId &&
          rideId == other.rideId &&
          driverId == other.driverId &&
          passengerId == other.passengerId &&
          requestedSeats == other.requestedSeats &&
          participantStatus == other.participantStatus &&
          joinedAt == other.joinedAt;

  @override
  int get hashCode =>
      participantId.hashCode ^
      rideId.hashCode ^
      driverId.hashCode ^
      passengerId.hashCode ^
      requestedSeats.hashCode ^
      participantStatus.hashCode ^
      joinedAt.hashCode;
}
