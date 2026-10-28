import '../models/rating_model.dart';
import '../models/ride_status.dart';

class RatingValidationException implements Exception {
  final String message;
  RatingValidationException(this.message);

  @override
  String toString() => message;
}

class RatingValidator {
  static void validateAuth(String? fromUserId) {
    if (fromUserId == null || fromUserId.trim().isEmpty) {
      throw RatingValidationException('You must be logged in to submit a rating.');
    }
  }

  static void validateNotSelfRating({required String fromUserId, required String toUserId}) {
    if (fromUserId == toUserId) {
      throw RatingValidationException('You cannot rate yourself.');
    }
  }

  static void validateRatingValue(double value) {
    if (value < 1.0 || value > 5.0) {
      throw RatingValidationException('Rating score must be between 1 and 5 stars.');
    }
  }

  static void validateRideCompleted(RideStatus rideStatus) {
    if (rideStatus != RideStatus.completed) {
      throw RatingValidationException('Ratings can only be submitted for completed rides.');
    }
  }

  static void validateNoDuplicateRating(RatingModel? existingRating) {
    if (existingRating != null) {
      throw RatingValidationException('You have already submitted a rating for this ride.');
    }
  }
}
