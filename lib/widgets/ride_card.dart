import 'package:flutter/material.dart';
import '../models/ride_search_result.dart';
import '../screens/ride_details_screen.dart';

class RideCard extends StatelessWidget {
  final RideSearchResult result;

  const RideCard({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final ride = result.ride;
    final remainingSeats = ride.availableSeats - ride.bookedSeats;
    final dep = ride.departureTime;
    final formattedTime =
        '${dep.day}/${dep.month}/${dep.year} at ${dep.hour.toString().padLeft(2, '0')}:${dep.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RideDetailsScreen(result: result),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
          border: Border.all(color: const Color(0xFF1A237E).withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Driver & Vehicle Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFFE8EAF6),
                      child: Icon(Icons.person, size: 22, color: Color(0xFF1A237E)),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Driver',
                          style: TextStyle(fontSize: 11, color: Colors.black45),
                        ),
                        Text(
                          ride.driverId.length > 8
                              ? 'Driver (${ride.driverId.substring(0, 8)})'
                              : 'Driver (${ride.driverId})',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A237E).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_car_outlined, size: 14, color: Color(0xFF1A237E)),
                      const SizedBox(width: 4),
                      Text(
                        'Car',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Route Pickup & Destination
            Row(
              children: [
                const Icon(Icons.my_location, size: 16, color: Color(0xFF1A237E)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ride.pickupName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(left: 7),
              child: SizedBox(
                height: 12,
                child: VerticalDivider(width: 1, color: Colors.black26),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ride.destinationName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Route Metrics & Schedule
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: Colors.black45),
                    const SizedBox(width: 4),
                    Text(
                      formattedTime,
                      style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.near_me_outlined, size: 14, color: Color(0xFF50C878)),
                    const SizedBox(width: 4),
                    Text(
                      '${result.realDrivingDistanceKm} km (${result.estimatedDurationMinutes} mins)',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF2E8B57), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Fare & Seats Footer Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.airline_seat_reconcile_normal_rounded, size: 16, color: Color(0xFF1A237E)),
                      const SizedBox(width: 6),
                      Text(
                        '$remainingSeats seats available',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                      ),
                    ],
                  ),
                  Text(
                    'Rs. ${ride.farePerSeat.toStringAsFixed(2)} / seat',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF50C878),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
