import 'package:flutter/material.dart';
import '../models/driver_pending_request_item.dart';
import '../services/ride_request_management_service.dart';

class DriverRequestsScreen extends StatefulWidget {
  const DriverRequestsScreen({super.key});

  @override
  State<DriverRequestsScreen> createState() => _DriverRequestsScreenState();
}

class _DriverRequestsScreenState extends State<DriverRequestsScreen> {
  final RideRequestManagementService _managementService = RideRequestManagementService();

  String? _processingRequestId;

  static const Color _primary = Color(0xFF1A237E);
  static const Color _accent = Color(0xFF50C878);
  static const Color _bg = Color(0xFFF8F9FA);
  static const Color _errorRed = Color(0xFFEF4444);

  Future<void> _handleAccept(DriverPendingRequestItem item) async {
    if (_processingRequestId != null) return;

    setState(() => _processingRequestId = item.request.requestId);

    try {
      await _managementService.acceptRequest(request: item.request);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 10),
                Text('Seat request accepted & participant confirmed!'),
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
            backgroundColor: _errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingRequestId = null);
      }
    }
  }

  Future<void> _handleDecline(DriverPendingRequestItem item) async {
    if (_processingRequestId != null) return;

    setState(() => _processingRequestId = item.request.requestId);

    try {
      await _managementService.declineRequest(request: item.request);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.remove_circle_outline, color: Colors.white),
                SizedBox(width: 10),
                Text('Ride seat request declined.'),
              ],
            ),
            backgroundColor: Colors.orange.shade800,
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
            backgroundColor: _errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingRequestId = null);
      }
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
          'Manage Driver Requests',
          style: TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<DriverPendingRequestItem>>(
        stream: _managementService.streamPendingRequestItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error loading requests: ${snapshot.error}',
                  style: const TextStyle(color: _errorRed, fontSize: 14),
                ),
              ),
            );
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
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
                              Icons.inbox_rounded,
                              size: 48,
                              color: _primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Pending Requests',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primary),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'There are currently no pending seat requests for your published rides.',
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
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildRequestCard(item);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(DriverPendingRequestItem item) {
    final req = item.request;
    final ride = item.ride;

    final isProcessing = _processingRequestId == req.requestId;
    final remainingSeats = ride.availableSeats - ride.bookedSeats;

    final dep = ride.departureTime;
    final departureStr =
        '${dep.day}/${dep.month}/${dep.year} at ${dep.hour.toString().padLeft(2, '0')}:${dep.minute.toString().padLeft(2, '0')}';

    final reqTime = req.createdAt;
    final requestTimeStr =
        '${reqTime.day}/${reqTime.month} ${reqTime.hour.toString().padLeft(2, '0')}:${reqTime.minute.toString().padLeft(2, '0')}';

    return Container(
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
        border: Border.all(color: _primary.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Passenger Info Header
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFE8EAF6),
                backgroundImage: (req.passengerProfileImage != null && req.passengerProfileImage!.isNotEmpty)
                    ? NetworkImage(req.passengerProfileImage!)
                    : null,
                child: (req.passengerProfileImage == null || req.passengerProfileImage!.isEmpty)
                    ? const Icon(Icons.person, size: 26, color: _primary)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.passengerName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _primary),
                    ),
                    Text(
                      'Requested at $requestTimeStr',
                      style: const TextStyle(fontSize: 11, color: Colors.black45),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${req.requestedSeats} Seat${req.requestedSeats > 1 ? 's' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2E8B57)),
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // Route Details
          Row(
            children: [
              const Icon(Icons.my_location, size: 16, color: _primary),
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
          const SizedBox(height: 12),

          // Schedule & Available Seats Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.black54),
                    const SizedBox(width: 4),
                    Text(
                      departureStr,
                      style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Text(
                  '$remainingSeats seats left',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons: Accept & Decline
          if (isProcessing)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(color: _primary, strokeWidth: 2.5),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _processingRequestId != null ? null : () => _handleDecline(item),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _errorRed,
                      side: const BorderSide(color: _errorRed),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _processingRequestId != null ? null : () => _handleAccept(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
