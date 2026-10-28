import 'package:flutter/material.dart';
import '../models/ride_model.dart';
import '../services/active_ride_service.dart';
import 'driver_active_ride_screen.dart';

class DriverActiveRidesListScreen extends StatefulWidget {
  const DriverActiveRidesListScreen({super.key});

  @override
  State<DriverActiveRidesListScreen> createState() => _DriverActiveRidesListScreenState();
}

class _DriverActiveRidesListScreenState extends State<DriverActiveRidesListScreen> {
  final ActiveRideService _activeRideService = ActiveRideService();

  static const Color _primary = Color(0xFF1A237E);
  static const Color _accent = Color(0xFF50C878);
  static const Color _bg = Color(0xFFF8F9FA);

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
          'My Active Published Rides',
          style: TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<RideModel>>(
        stream: _activeRideService.streamDriverActiveRides(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: _primary));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error loading active rides: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                ),
              ),
            );
          }

          final rides = snapshot.data ?? [];

          if (rides.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => setState(() {}),
              child: ListView(
                children: [
                  const SizedBox(height: 100),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: _primary.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.directions_car_rounded,
                              size: 48,
                              color: _primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Active Published Rides',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primary),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'You do not have any published active rides currently.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black45, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              itemCount: rides.length,
              itemBuilder: (context, index) {
                final ride = rides[index];
                final remaining = _activeRideService.calculateRemainingSeats(ride);
                final dep = ride.departureTime;
                final departureStr =
                    '${dep.day}/${dep.month}/${dep.year} at ${dep.hour.toString().padLeft(2, '0')}:${dep.minute.toString().padLeft(2, '0')}';

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DriverActiveRideScreen(rideId: ride.rideId),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
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
                      border: Border.all(color: _primary.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.my_location, size: 16, color: _primary),
                                const SizedBox(width: 8),
                                Text(
                                  ride.pickupName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _primary),
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
                                '$remaining seats available',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF2E8B57)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                ride.destinationName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 14, color: Colors.black45),
                                const SizedBox(width: 4),
                                Text(departureStr, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                              ],
                            ),
                            const Row(
                              children: [
                                Text('View Participants', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _primary)),
                                Icon(Icons.arrow_forward_ios_rounded, size: 12, color: _primary),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
