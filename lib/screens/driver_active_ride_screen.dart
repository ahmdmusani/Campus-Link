import 'package:flutter/material.dart';
import '../models/driver_location_model.dart';
import '../models/driver_location_status.dart';
import '../models/enriched_participant_item.dart';
import '../models/ride_model.dart';
import '../models/ride_status.dart';
import '../services/active_ride_service.dart';
import '../services/driver_location_service.dart';
import '../services/ride_lifecycle_service.dart';

class DriverActiveRideScreen extends StatefulWidget {
  final String rideId;

  const DriverActiveRideScreen({
    super.key,
    required this.rideId,
  });

  @override
  State<DriverActiveRideScreen> createState() => _DriverActiveRideScreenState();
}

class _DriverActiveRideScreenState extends State<DriverActiveRideScreen> {
  final ActiveRideService _activeRideService = ActiveRideService();
  final DriverLocationService _locationService = DriverLocationService();
  final RideLifecycleService _lifecycleService = RideLifecycleService();

  bool _isLocationSharingStarted = false;
  bool _isUpdatingStatus = false;

  static const Color _primary = Color(0xFF1A237E);
  static const Color _accent = Color(0xFF50C878);
  static const Color _bg = Color(0xFFF8F9FA);

  @override
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }

  void _initLocationSharing(RideModel ride) {
    if (!_isLocationSharingStarted) {
      _isLocationSharingStarted = true;
      _locationService.startSharing(ride).catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Active Ride Management',
          style: TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<RideModel?>(
        stream: _activeRideService.streamActiveRide(widget.rideId),
        builder: (context, rideSnapshot) {
          if (rideSnapshot.connectionState == ConnectionState.waiting && !rideSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: _primary));
          }

          if (rideSnapshot.hasError || rideSnapshot.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  rideSnapshot.hasError
                      ? 'Error loading ride details: ${rideSnapshot.error}'
                      : 'The requested active ride was not found.',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                ),
              ),
            );
          }

          final ride = rideSnapshot.data!;
          final remainingSeats = _activeRideService.calculateRemainingSeats(ride);

          // Automatically initialize live location sharing for valid active ride
          _initLocationSharing(ride);

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              children: [
                // 1. Live Location Status Card (Phase 7 Requirement)
                _buildLiveLocationStatusCard(),
                const SizedBox(height: 16),

                // 2. Ride Summary Card (Updates automatically via StreamBuilder)
                _buildRideSummaryCard(ride, remainingSeats),
                const SizedBox(height: 24),

                // 3. Accepted Participants Section (Real-time StreamBuilder)
                _buildParticipantsSection(),
                const SizedBox(height: 24),

                // 4. Ride Lifecycle Action Controls (Start / Complete / Completed Badge)
                _buildRideActionsSection(ride),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLiveLocationStatusCard() {
    return StreamBuilder<DriverLocationStatus>(
      stream: _locationService.statusStream,
      initialData: _locationService.currentStatus,
      builder: (context, statusSnapshot) {
        final status = statusSnapshot.data ?? DriverLocationStatus.waitingForPermission;
        final isSharing = status == DriverLocationStatus.sharingLiveLocation;

        Color badgeColor = Colors.orange;
        if (isSharing) {
          badgeColor = _accent;
        } else if (status == DriverLocationStatus.connectionLost) {
          badgeColor = Colors.redAccent;
        }

        return StreamBuilder<DriverLocationModel?>(
          stream: _locationService.streamLocation(widget.rideId),
          builder: (context, locSnapshot) {
            final locationData = locSnapshot.data;
            final accuracyStr = locationData != null
                ? '± ${locationData.accuracy.toStringAsFixed(1)} m'
                : '± 5.0 m';
            final lastUpdatedStr = locationData != null
                ? '${locationData.lastUpdated.hour.toString().padLeft(2, '0')}:${locationData.lastUpdated.minute.toString().padLeft(2, '0')}:${locationData.lastUpdated.second.toString().padLeft(2, '0')}'
                : 'Syncing...';

            return Container(
              padding: const EdgeInsets.all(16),
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
                border: Border.all(color: badgeColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSharing ? Icons.sensors_rounded : Icons.sensors_off_rounded,
                      color: badgeColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              status.label,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isSharing ? _primary : badgeColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: badgeColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Accuracy: $accuracyStr  •  Synced: $lastUpdatedStr',
                          style: const TextStyle(fontSize: 11, color: Colors.black45),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRideSummaryCard(RideModel ride, int remainingSeats) {
    final dep = ride.departureTime;
    final departureStr =
        '${dep.day}/${dep.month}/${dep.year} at ${dep.hour.toString().padLeft(2, '0')}:${dep.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: _primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.directions_car_rounded, color: _primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Active Ride Summary',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _primary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  ride.rideStatus.name.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF2E8B57)),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          _locationRow(Icons.my_location, _primary, 'Pickup Location', ride.pickupName),
          const Padding(
            padding: EdgeInsets.only(left: 7),
            child: SizedBox(
              height: 14,
              child: VerticalDivider(width: 1, color: Colors.black26),
            ),
          ),
          _locationRow(Icons.location_on, Colors.redAccent, 'Destination', ride.destinationName),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 16, color: Colors.black54),
              const SizedBox(width: 8),
              Text(
                'Departure: $departureStr',
                style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _seatStatTile('Total Seats', '${ride.availableSeats}', _primary),
                _seatStatTile('Booked Seats', '${ride.bookedSeats}', Colors.orange.shade800),
                _seatStatTile('Remaining', '$remainingSeats', _accent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.people_alt_rounded, color: _primary, size: 20),
            SizedBox(width: 8),
            Text(
              'Accepted Passengers',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _primary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<EnrichedParticipantItem>>(
          stream: _activeRideService.streamEnrichedParticipants(widget.rideId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(color: _primary),
                ),
              );
            }

            if (snapshot.hasError) {
              return Text(
                'Error loading participants: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              );
            }

            final participants = snapshot.data ?? [];

            if (participants.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Colors.black38, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No accepted passengers yet for this ride.',
                        style: TextStyle(color: Colors.black45, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: participants.map((item) => _buildParticipantCard(item)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildParticipantCard(EnrichedParticipantItem item) {
    final p = item.participant;
    final joinTime = p.joinedAt;
    final joinTimeStr =
        '${joinTime.day}/${joinTime.month} at ${joinTime.hour.toString().padLeft(2, '0')}:${joinTime.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: _accent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFE8EAF6),
            backgroundImage: (item.passengerProfileImage != null && item.passengerProfileImage!.isNotEmpty)
                ? NetworkImage(item.passengerProfileImage!)
                : null,
            child: (item.passengerProfileImage == null || item.passengerProfileImage!.isEmpty)
                ? const Icon(Icons.person, size: 24, color: _primary)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.passengerName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _primary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Joined $joinTimeStr',
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${p.requestedSeats} Seat${p.requestedSeats > 1 ? 's' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF2E8B57)),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                p.participantStatus.toUpperCase(),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _accent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleStartRide() async {
    if (_isUpdatingStatus) return;
    setState(() => _isUpdatingStatus = true);

    try {
      await _lifecycleService.startRide(widget.rideId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.play_circle_fill_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text('Ride status updated to ONGOING! Live GPS active.'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  Future<void> _handleCompleteRide() async {
    if (_isUpdatingStatus) return;
    setState(() => _isUpdatingStatus = true);

    try {
      await _lifecycleService.completeRide(widget.rideId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text('Ride COMPLETED & history record logged!'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  Widget _buildRideActionsSection(RideModel ride) {
    if (_isUpdatingStatus) {
      return Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(color: _primary, strokeWidth: 2.5),
          ),
        ),
      );
    }

    if (ride.rideStatus == RideStatus.published) {
      return ElevatedButton.icon(
        onPressed: _handleStartRide,
        icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
        label: const Text('Start Ride', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      );
    }

    if (ride.rideStatus == RideStatus.ongoing) {
      return ElevatedButton.icon(
        onPressed: _handleCompleteRide,
        icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 24),
        label: const Text('Complete Ride', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _accent.withOpacity(0.3)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_rounded, color: Color(0xFF2E8B57), size: 22),
          SizedBox(width: 8),
          Text(
            'Ride Completed & Saved to History',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2E8B57)),
          ),
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
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.black45)),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _seatStatTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.black45)),
      ],
    );
  }
}
