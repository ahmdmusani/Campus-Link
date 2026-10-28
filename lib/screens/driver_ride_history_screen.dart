import 'package:flutter/material.dart';
import '../models/completed_ride_item.dart';
import '../services/ride_history_service.dart';
import 'driver_rating_screen.dart';

class DriverRideHistoryScreen extends StatefulWidget {
  const DriverRideHistoryScreen({super.key});

  @override
  State<DriverRideHistoryScreen> createState() => _DriverRideHistoryScreenState();
}

class _DriverRideHistoryScreenState extends State<DriverRideHistoryScreen> {
  final RideHistoryService _historyService = RideHistoryService();

  late Future<List<CompletedRideItem>> _historyFuture;

  static const Color _primary = Color(0xFF1A237E);
  static const Color _accent = Color(0xFF50C878);
  static const Color _bg = Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _historyFuture = _historyService.fetchDriverCompletedRides();
    });
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
          'Driver Ride History',
          style: TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<CompletedRideItem>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _primary));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error loading driver history: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                ),
              ),
            );
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => _loadHistory(),
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
                              Icons.history_edu_rounded,
                              size: 48,
                              color: _primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Completed Driver Rides',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primary),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'You do not have any published completed rides yet.',
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
            onRefresh: () async => _loadHistory(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildDriverHistoryCard(item);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDriverHistoryCard(CompletedRideItem item) {
    final h = item.history;
    final comp = h.completedAt;
    final completedStr =
        '${comp.day}/${comp.month}/${comp.year} at ${comp.hour.toString().padLeft(2, '0')}:${comp.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: _primary.withOpacity(0.08)),
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
                    'Published Ride',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _primary),
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
                  'COMPLETED',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF2E8B57)),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          _locationRow(Icons.my_location, _primary, 'Pickup', h.pickupName),
          const Padding(
            padding: EdgeInsets.only(left: 7),
            child: SizedBox(
              height: 12,
              child: VerticalDivider(width: 1, color: Colors.black26),
            ),
          ),
          _locationRow(Icons.location_on, Colors.redAccent, 'Destination', h.destinationName),
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
                _statTile('Booked Seats', '${h.bookedSeats}', _primary),
                _statTile('Passengers', '${h.participantsCount}', Colors.purple.shade800),
                _statTile('Total Fare', 'Rs. ${h.totalFare.toStringAsFixed(2)}', _accent),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.event_available_rounded, size: 14, color: Colors.black45),
              const SizedBox(width: 6),
              Text(
                'Completed on $completedStr',
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DriverRatingScreen(rideHistory: h),
                  ),
                );
                if (result == true) {
                  _loadHistory();
                }
              },
              icon: const Icon(Icons.star_outline_rounded, color: Colors.amber, size: 18),
              label: const Text('Rate Passengers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _primary)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _primary.withOpacity(0.2)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationRow(IconData icon, Color color, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
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

  Widget _statTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.black45)),
      ],
    );
  }
}
