import 'ride_participant_model.dart';

class EnrichedParticipantItem {
  final RideParticipantModel participant;
  final String passengerName;
  final String? passengerProfileImage;

  const EnrichedParticipantItem({
    required this.participant,
    required this.passengerName,
    this.passengerProfileImage,
  });
}
