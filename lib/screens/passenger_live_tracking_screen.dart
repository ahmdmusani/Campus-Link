import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong2.dart';
import '../models/driver_location_model.dart';
import '../models/ride_model.dart';
import '../services/passenger_tracking_service.dart';

class PassengerLiveTrackingScreen extends StatefulWidget {
  final String rideId;

  const PassengerLiveTrackingScreen({
    super.key,
    required this.rideId,
  });

  @override
  State<PassengerLiveTrackingScreen> createState() => _PassengerLiveTrackingScreenState();
}

class _PassengerLiveTrackingScreenState extends State<PassengerLiveTrackingScreen> {
  final PassengerTrackingService _trackingService = PassengerTrackingService();
  final MapController _mapController = MapController();

  bool _isAuthorizing = true;
  bool _isAuthorized = false;
  String? _authError;
  RideModel? _ride;

  static const Color _primary = Color(0xFF1A237E);
  static const Color _accent = Color(0xFF50C878);
  static const Color _bg = Color(0xFFF8F9FA);
  static const Color _errorRed = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _initAuthorizationAndRide();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initAuthorizationAndRide() async {
    try {
      await _trackingService.verifyTrackingAuthorization(widget.rideId);
      final rideData = await _trackingService.fetchRide(widget.rideId);

      if (mounted) {
        setState(() {
          _isAuthorized = true;
          _ride = rideData;
          _isAuthorizing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAuthorized = false;
          _authError = e.toString().replaceAll('Exception: ', '').replaceAll('SecurityValidationException: ', '');
          _isAuthorizing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthorizing) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _primary),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Verifying Security...', style: TextStyle(color: _primary, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: _primary),
              SizedBox(height: 16),
              Text('Checking participant authorization...', style: TextStyle(color: Colors.black54, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    if (!_isAuthorized || _ride == null) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _primary),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Access Denied', style: TextStyle(color: _errorRed, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              padding: const EdgeInsets.all(24),
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
                border: Border.all(color: _errorRed.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _errorRed.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.security_rounded, size: 48, color: _errorRed),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Unauthorized Ride Tracking',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _authError ?? 'You are not an accepted participant for this ride.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Return to Ride Search'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final pickupLatLng = LatLng(_ride!.pickupGeoPoint.latitude, _ride!.pickupGeoPoint.longitude);
    final destLatLng = LatLng(_ride!.destinationGeoPoint.latitude, _ride!.destinationGeoPoint.longitude);

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
          'Live Driver Tracking',
          style: TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DriverLocationModel?>(
        stream: _trackingService.streamDriverLocation(widget.rideId),
        builder: (context, locSnapshot) {
          final driverLoc = locSnapshot.data;
          final driverLatLng = driverLoc != null
              ? LatLng(driverLoc.latitude, driverLoc.longitude)
              : pickupLatLng;

          final accuracyStr = driverLoc != null ? '± ${driverLoc.accuracy.toStringAsFixed(1)} m' : '± 5.0 m';
          final lastSyncStr = driverLoc != null
              ? '${driverLoc.lastUpdated.hour.toString().padLeft(2, '0')}:${driverLoc.lastUpdated.minute.toString().padLeft(2, '0')}:${driverLoc.lastUpdated.second.toString().padLeft(2, '0')}'
              : 'Waiting for GPS...';

          return Stack(
            children: [
              // FlutterMap Integration with MapTiler
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: driverLatLng,
                  initialZoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://api.maptiler.com/maps/basic-v2/{z}/{x}/{y}.png?key=f61Z7Zc0gLq4L4fX68xJ',
                    userAgentPackageName: 'com.campuslink.app',
                  ),
                  MarkerLayer(
                    markers: [
                      // Pickup Marker (Blue)
                      Marker(
                        point: pickupLatLng,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.my_location, color: _primary, size: 30),
                      ),
                      // Destination Marker (Red)
                      Marker(
                        point: destLatLng,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_on, color: Colors.redAccent, size: 34),
                      ),
                      // Live Driver Vehicle Marker (Green Animated Icon)
                      if (driverLoc != null)
                        Marker(
                          point: driverLatLng,
                          width: 50,
                          height: 50,
                          child: Container(
                            decoration: BoxDecoration(
                              color: _accent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _accent.withOpacity(0.4),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 28),
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              // Live Status Header Card overlay
              Positioned(
                top: 16,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.sensors_rounded, color: Color(0xFF2E8B57), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              driverLoc != null ? 'Driver Live Location Active' : 'Connecting Driver GPS...',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _primary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Accuracy: $accuracyStr  •  Synced: $lastSyncStr',
                              style: const TextStyle(fontSize: 11, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
