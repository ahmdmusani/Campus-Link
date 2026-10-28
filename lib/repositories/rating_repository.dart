import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rating_model.dart';

class RatingRepository {
  final FirebaseFirestore _firestore;

  RatingRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Creates a rating document in Firestore ratings collection using Firestore document ID as canonical ratingId.
  Future<RatingModel> createRating(RatingModel rating) async {
    final docRef = _firestore.collection('ratings').doc();
    final canonicalRating = rating.copyWith(ratingId: docRef.id);

    await docRef.set({
      'ratingId': canonicalRating.ratingId,
      'rideId': canonicalRating.rideId,
      'fromUserId': canonicalRating.fromUserId,
      'toUserId': canonicalRating.toUserId,
      'fromUserRole': canonicalRating.fromUserRole,
      'ratingValue': canonicalRating.ratingValue,
      'reviewText': canonicalRating.reviewText,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return canonicalRating;
  }

  /// Fetches existing rating submitted by a specific user for a specific ride.
  Future<RatingModel?> fetchExistingRating({
    required String rideId,
    required String fromUserId,
  }) async {
    final querySnapshot = await _firestore
        .collection('ratings')
        .where('rideId', isEqualTo: rideId)
        .where('fromUserId', isEqualTo: fromUserId)
        .get();

    if (querySnapshot.docs.isEmpty) return null;
    return RatingModel.fromFirestore(querySnapshot.docs.first);
  }

  /// Fetches ratings received by a specific user (toUserId).
  Future<List<RatingModel>> fetchRatingsForUser(String toUserId) async {
    final querySnapshot = await _firestore
        .collection('ratings')
        .where('toUserId', isEqualTo: toUserId)
        .get();

    return querySnapshot.docs
        .map((doc) => RatingModel.fromFirestore(doc))
        .toList();
  }
}
