import 'package:firebase_auth/firebase_auth.dart';
import '../models/rating_model.dart';

import '../models/ride_status.dart';
import '../repositories/rating_repository.dart';
import '../utils/rating_validator.dart';
import 'notification_service.dart';

class RatingService {
  final RatingRepository _repository;
  final FirebaseAuth _firebaseAuth;

  RatingService({
    RatingRepository? repository,
    FirebaseAuth? firebaseAuth,
  })  : _repository = repository ?? RatingRepository(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  /// Submits a post-completed ride rating and review.
  Future<RatingModel> submitRating({
    required String rideId,
    required String toUserId,
    required String fromUserRole,
    required double ratingValue,
    required String reviewText,
    required RideStatus rideStatus,
  }) async {
    final user = _firebaseAuth.currentUser;
    final fromUserId = user?.uid;

    // 1. Validation
    RatingValidator.validateAuth(fromUserId);
    RatingValidator.validateNotSelfRating(fromUserId: fromUserId!, toUserId: toUserId);
    RatingValidator.validateRatingValue(ratingValue);
    RatingValidator.validateRideCompleted(rideStatus);

    // 2. Duplicate Rating Check
    final existingRating = await _repository.fetchExistingRating(
      rideId: rideId,
      fromUserId: fromUserId,
    );
    RatingValidator.validateNoDuplicateRating(existingRating);

    final now = DateTime.now();

    // 3. Construct RatingModel
    final initialRating = RatingModel(
      ratingId: '', // Assigned by Firestore document ID in repository
      rideId: rideId,
      fromUserId: fromUserId,
      toUserId: toUserId,
      fromUserRole: fromUserRole,
      ratingValue: ratingValue,
      reviewText: reviewText.trim(),
      createdAt: now,
    );

    // 4. Save to Firestore
    final createdRating = await _repository.createRating(initialRating);

    // 5. Trigger Push Notification to recipient
    try {
      await NotificationService().notifyNewRating(
        recipientId: toUserId,
        senderId: fromUserId,
        rideId: rideId,
        ratingValue: ratingValue,
      );
    } catch (_) {}

    return createdRating;
  }

  /// Checks if the authenticated user has already rated a specific ride.
  Future<bool> hasUserRatedRide({
    required String rideId,
    required String userId,
  }) async {
    final existing = await _repository.fetchExistingRating(
      rideId: rideId,
      fromUserId: userId,
    );
    return existing != null;
  }
}
