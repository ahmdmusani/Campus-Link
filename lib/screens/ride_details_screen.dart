import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ride_search_result.dart';
import '../services/ride_request_service.dart';
import '../repositories/passenger_tracking_repository.dart';
import 'passenger_live_tracking_screen.dart';

class RideDetailsScreen extends StatefulWidget {
  final RideSearchResult result;

  const RideDetailsScreen({
    super.key,
    required this.result,
  });

  @override
  State<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends State<RideDetailsScreen> {
  final RideRequestService _requestService = RideRequestService();
  final PassengerTrackingRepository _trackingRepo = PassengerTrackingRepository();

  bool _isDriver = false;
  bool _hasPendingRequest = false;
  bool _isAcceptedParticipant = false;
  bool _isCheckingStatus = true;
  bool _isSubmitting = false;

  static const Color _primary = Color(0xFF1A237E);
  static const Color _accent = Color(0xFF50C878);
  static const Color _bg = Color(0xFFF8F9FA);
  static const Color _errorRed = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _checkPassengerRequestStatus();
  }

  Future<void> _checkPassengerRequestStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    final ride = widget.result.ride;

    if (user == null) {
      if (mounted) setState(() => _isCheckingStatus = false);
      return;
    }

    if (user.uid == ride.driverId) {
      if (mounted) {
        setState(() {
          _isDriver = true;
          _isCheckingStatus = false;
        });
      }
      return;
    }

    try {
      final pendingReq = await _requestService.checkExistingPendingRequest(
        rideId: ride.rideId,
        passengerId: user.uid,
      );
      final isAccepted = await _trackingRepo.isPassengerAcceptedParticipant(
        rideId: ride.rideId,
        passengerId: user.uid,
      );

      if (mounted) {
        setState(() {
          _hasPendingRequest = pendingReq != null;
          _isAcceptedParticipant = isAccepted;
          _isCheckingStatus = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isCheckingStatus = false);
    }
  }

  Future<void> _handleRequestSeat() async {
    setState(() => _isSubmitting = true);

    try {
      await _requestService.requestSeat(
        ride: widget.result.ride,
        requestedSeats: 1,
      );

      if (mounted) {
        setState(() {
          _hasPendingRequest = true;
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 10),
                Text('Ride seat request submitted & verified!'),
              ],
            ),
            backgroundColor: _accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: _errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.result.ride;
    final remainingSeats = ride.availableSeats - ride.bookedSeats;
    final dep = ride.departureTime;
    final formattedTime =
        '${dep.day}/${dep.month}/${dep.year} at ${dep.hour.toString().padLeft(2, '0')}:${dep.minute.toString().padLeft(2, '0')}';

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
          'Ride Inspection & Request',
          style: TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        children: [
          // Driver Details Card
          _infoCard(
            title: 'Driver Information',
            icon: Icons.person_outline_rounded,
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFFE8EAF6),
                  child: Icon(Icons.person, size: 30, color: _primary),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Driver ID: ${ride.driverId}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _primary),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Verified Campus Student',
                      style: TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Route & Location Card
          _infoCard(
            title: 'Route Details',
            icon: Icons.route_rounded,
            child: Column(
              children: [
                _locationRow(Icons.my_location, _primary, 'Pickup', ride.pickupName),
                const Padding(
                  padding: EdgeInsets.only(left: 7),
                  child: SizedBox(
                    height: 16,
                    child: VerticalDivider(width: 1, color: Colors.black26),
                  ),
                ),
                _locationRow(Icons.location_on, Colors.redAccent, 'Destination', ride.destinationName),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statColumn('Road Distance', '${widget.result.realDrivingDistanceKm} km', Icons.straighten),
                    _statColumn('Est. Duration', '${widget.result.estimatedDurationMinutes} mins', Icons.timer),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Schedule & Vehicle Card
          _infoCard(
            title: 'Schedule & Vehicle',
            icon: Icons.calendar_today_rounded,
            child: Column(
              children: [
                _detailTile('Departure Time', formattedTime, Icons.access_time),
                const SizedBox(height: 10),
                _detailTile('Vehicle Category', 'Car', Icons.directions_car),
                const SizedBox(height: 10),
                _detailTile('Available Seats', '$remainingSeats of ${ride.availableSeats} seats', Icons.event_seat),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Fare Details Card
          _infoCard(
            title: 'Fare Breakdown',
            icon: Icons.payments_outlined,
            child: Column(
              children: [
                _fareRow('Fare per Seat', 'Rs. ${ride.farePerSeat.toStringAsFixed(2)}', _accent, isBold: true),
                const SizedBox(height: 8),
                _fareRow('Total Ride Fare', 'Rs. ${ride.rideTotal.toStringAsFixed(2)}', Colors.black87),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Mandatory Interactive Element: Single Request Seat Button
          _requestSeatButton(remainingSeats: remainingSeats),

          // Live Driver Tracking Button for Accepted Passengers / Driver
          if (_isAcceptedParticipant || _isDriver) ...[
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PassengerLiveTrackingScreen(rideId: ride.rideId),
                  ),
                );
              },
              icon: const Icon(Icons.sensors_rounded, color: Colors.white),
              label: const Text(
                'Track Driver Live',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _requestSeatButton({required int remainingSeats}) {
    if (_isCheckingStatus) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final bool isUserDriver = _isDriver;
    final bool hasPending = _hasPendingRequest;
    final bool noSeats = remainingSeats <= 0;
    final bool canRequest = !isUserDriver && !hasPending && !noSeats && !_isSubmitting;

    String buttonLabel = 'Request Seat';
    IconData buttonIcon = Icons.airline_seat_reconcile_normal_rounded;

    if (isUserDriver) {
      buttonLabel = 'You are the driver of this ride';
      buttonIcon = Icons.info_outline;
    } else if (hasPending) {
      buttonLabel = 'Request Pending';
      buttonIcon = Icons.hourglass_top_rounded;
    } else if (noSeats) {
      buttonLabel = 'No Seats Available';
      buttonIcon = Icons.block;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 56,
      decoration: BoxDecoration(
        gradient: canRequest
            ? const LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: canRequest ? null : (hasPending ? _accent.withOpacity(0.15) : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(18),
        boxShadow: canRequest
            ? [
                BoxShadow(
                  color: const Color(0xFF1A237E).withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canRequest ? _handleRequestSeat : null,
          borderRadius: BorderRadius.circular(18),
          child: Center(
            child: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        buttonIcon,
                        color: canRequest
                            ? Colors.white
                            : (hasPending ? _accent : Colors.grey.shade600),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        buttonLabel,
                        style: TextStyle(
                          color: canRequest
                              ? Colors.white
                              : (hasPending ? _accent : Colors.grey.shade600),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _infoCard({required String title, required IconData icon, required Widget child}) {
    return Container(
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
              Icon(icon, color: _primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _primary),
              ),
            ],
          ),
          const Divider(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _locationRow(IconData icon, Color color, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.black45)),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: _primary),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _primary)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black45)),
      ],
    );
  }

  Widget _detailTile(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _primary),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  Widget _fareRow(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: isBold ? Colors.black87 : Colors.black54, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
