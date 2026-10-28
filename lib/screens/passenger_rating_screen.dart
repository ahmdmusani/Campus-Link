import 'package:flutter/material.dart';
import '../models/ride_history_model.dart';
import '../models/ride_status.dart';
import '../services/rating_service.dart';

class PassengerRatingScreen extends StatefulWidget {
  final RideHistoryModel rideHistory;

  const PassengerRatingScreen({
    super.key,
    required this.rideHistory,
  });

  @override
  State<PassengerRatingScreen> createState() => _PassengerRatingScreenState();
}

class _PassengerRatingScreenState extends State<PassengerRatingScreen> {
  final RatingService _ratingService = RatingService();
  final TextEditingController _reviewController = TextEditingController();

  double _selectedRating = 5.0;
  bool _isSubmitting = false;

  static const Color _primary = Color(0xFF1A237E);
  static const Color _accent = Color(0xFF50C878);
  static const Color _bg = Color(0xFFF8F9FA);

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmitRating() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      await _ratingService.submitRating(
        rideId: widget.rideHistory.rideId,
        toUserId: widget.rideHistory.driverId,
        fromUserRole: 'passenger',
        ratingValue: _selectedRating,
        reviewText: _reviewController.text,
        rideStatus: RideStatus.completed,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.star_rounded, color: Colors.amber),
                SizedBox(width: 10),
                Text('Rating and review submitted successfully!'),
              ],
            ),
            backgroundColor: _accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        Navigator.pop(context, true); // Return true to indicate rating submitted
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.rideHistory;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Rate Driver',
          style: TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        children: [
          // Driver & Ride Information Summary Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 22,
                      backgroundColor: Color(0xFFE8EAF6),
                      child: Icon(Icons.person, size: 28, color: _primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Driver ID: ${h.driverId}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _primary),
                          ),
                          const Text(
                            'Completed Campus Ride',
                            style: TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    const Icon(Icons.my_location, size: 14, color: _primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(h.pickupName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                    ),
                    const Icon(Icons.arrow_forward, size: 12, color: Colors.black38),
                    const SizedBox(width: 4),
                    const Icon(Icons.location_on, size: 14, color: Colors.redAccent),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(h.destinationName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Star Rating Selector Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'How was your ride experience?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _primary),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starValue = index + 1.0;
                    return IconButton(
                      iconSize: 36,
                      icon: Icon(
                        starValue <= _selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                        color: Colors.amber,
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedRating = starValue;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_selectedRating.toInt()} Out of 5 Stars',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Review Comment Text Field
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _reviewController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Share optional feedback about driver punctuality, driving, or behavior...',
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 13, color: Colors.black38),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Submit Rating Button
          ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _handleSubmitRating,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded, color: Colors.white),
            label: Text(
              _isSubmitting ? 'Submitting...' : 'Submit Rating',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
