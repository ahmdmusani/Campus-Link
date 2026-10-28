import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/pricing_config_model.dart';
import '../models/ride_model.dart';
import '../repositories/ride_repository.dart';
import '../services/ride_service.dart';
import '../services/routing_service.dart';
import '../utils/fare_calculator.dart';

class CreateRideScreen extends StatefulWidget {
  const CreateRideScreen({super.key});

  @override
  State<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Resolved Location GeoPoints
  GeoPoint? _pickupGeoPoint;
  GeoPoint? _destinationGeoPoint;

  // Autocomplete Suggestions State
  List<Map<String, dynamic>> _pickupSuggestions = [];
  List<Map<String, dynamic>> _destinationSuggestions = [];
  bool _showPickupSuggestions = false;
  bool _showDestinationSuggestions = false;
  bool _isSearchingPickup = false;
  bool _isSearchingDestination = false;

  // Date & Time Pickers
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Capacity & Options
  int _availableSeats = 2;
  String _vehicleType = 'Car';
  final List<String> _vehicleTypes = ['Car', 'SUV', 'Bike', 'Rickshaw'];

  // Route & Fare Calculation State
  RoutingResult? _routingResult;
  FareCalculationResult? _fareResult;
  PricingConfigModel? _pricingConfig;
  bool _isCalculatingRoute = false;
  String? _routeError;

  // Submission State
  bool _isSubmitting = false;

  // Services & Repositories
  final RideService _rideService = RideService();
  final RideRepository _rideRepository = RideRepository();
  final RoutingService _routingService = RoutingService();

  // Theme Constants
  static const Color _primary = Color(0xFF1A237E);
  static const Color _accent = Color(0xFF50C878);
  static const Color _bg = Color(0xFFF8F9FA);
  static const Color _cardBg = Colors.white;
  static const Color _errorRed = Color(0xFFEF4444);

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ─── MapTiler / OpenStreetMap Autocomplete Search ──────────────────────────

  Future<void> _fetchSuggestions(String query, bool isPickup) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) {
      setState(() {
        if (isPickup) {
          _pickupSuggestions = [];
          _showPickupSuggestions = false;
        } else {
          _destinationSuggestions = [];
          _showDestinationSuggestions = false;
        }
      });
      return;
    }

    setState(() {
      if (isPickup) {
        _isSearchingPickup = true;
      } else {
        _isSearchingDestination = true;
      }
    });

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(trimmed)},Karachi&format=json&limit=5',
    );

    try {
      final response = await http.get(url, headers: {'User-Agent': 'CampusLinkApp/1.0'});
      if (response.statusCode == 200 && mounted) {
        final List data = json.decode(response.body);
        final suggestions = data.map((item) => {
          'display_name': item['display_name'] ?? '',
          'lat': double.tryParse(item['lat'] ?? '') ?? 0.0,
          'lon': double.tryParse(item['lon'] ?? '') ?? 0.0,
        }).toList();

        setState(() {
          if (isPickup) {
            _pickupSuggestions = List<Map<String, dynamic>>.from(suggestions);
            _showPickupSuggestions = suggestions.isNotEmpty;
          } else {
            _destinationSuggestions = List<Map<String, dynamic>>.from(suggestions);
            _showDestinationSuggestions = suggestions.isNotEmpty;
          }
        });
      }
    } catch (e) {
      debugPrint('Autocomplete search error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSearchingPickup = false;
          _isSearchingDestination = false;
        });
      }
    }
  }

  void _selectPickupSuggestion(Map<String, dynamic> suggestion) {
    setState(() {
      _pickupController.text = suggestion['display_name'] ?? '';
      _pickupGeoPoint = GeoPoint(suggestion['lat'] as double, suggestion['lon'] as double);
      _pickupSuggestions = [];
      _showPickupSuggestions = false;
    });
    _calculateRouteAndFareIfReady();
  }

  void _selectDestinationSuggestion(Map<String, dynamic> suggestion) {
    setState(() {
      _destinationController.text = suggestion['display_name'] ?? '';
      _destinationGeoPoint = GeoPoint(suggestion['lat'] as double, suggestion['lon'] as double);
      _destinationSuggestions = [];
      _showDestinationSuggestions = false;
    });
    _calculateRouteAndFareIfReady();
  }

  // ─── Automatic Route & Fare Calculation ──────────────────────────────────────

  Future<void> _calculateRouteAndFareIfReady() async {
    // Only calculate after BOTH Pickup and Destination have been selected
    if (_pickupGeoPoint == null || _destinationGeoPoint == null) {
      return;
    }

    if (_pickupGeoPoint!.latitude == _destinationGeoPoint!.latitude &&
        _pickupGeoPoint!.longitude == _destinationGeoPoint!.longitude) {
      setState(() {
        _routeError = 'Destination cannot be identical to pickup location.';
        _routingResult = null;
        _fareResult = null;
      });
      return;
    }

    setState(() {
      _isCalculatingRoute = true;
      _routeError = null;
    });

    try {
      // 1. Fetch Pricing Configuration from Firestore
      _pricingConfig ??= await _rideRepository.fetchPricingConfig();
      if (_pricingConfig == null) {
        throw Exception('Pricing configuration could not be loaded from Firestore.');
      }

      // 2. Calculate Driving Route via RoutingService
      final route = await _routingService.calculateDrivingRoute(
        pickup: _pickupGeoPoint!,
        destination: _destinationGeoPoint!,
      );

      // 3. Calculate Fare Breakdown via FareCalculator
      final fare = FareCalculator.calculateFare(
        distanceKm: route.distanceKm,
        availableSeats: _availableSeats,
        pricingConfig: _pricingConfig!,
      );

      if (mounted) {
        setState(() {
          _routingResult = route;
          _fareResult = fare;
          _isCalculatingRoute = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _routeError = e.toString().replaceAll('Exception: ', '');
          _routingResult = null;
          _fareResult = null;
          _isCalculatingRoute = false;
        });
      }
    }
  }

  // ─── Date & Time Pickers ───────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _primary),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _primary),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  DateTime? get _departureDateTime {
    if (_selectedDate == null || _selectedTime == null) return null;
    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
  }

  // ─── Validation & Submission ───────────────────────────────────────────────

  bool get _isPublishEnabled {
    final currentUser = FirebaseAuth.instance.currentUser;
    final departure = _departureDateTime;

    if (currentUser == null) return false;
    if (_pickupGeoPoint == null || _destinationGeoPoint == null) return false;
    if (_routingResult == null || _routingResult!.distanceKm <= 0) return false;
    if (_fareResult == null || _pricingConfig == null) return false;
    if (departure == null || departure.isBefore(DateTime.now())) return false;
    if (_availableSeats < 1 || _availableSeats > 7) return false;
    if (_routeError != null || _isCalculatingRoute || _isSubmitting) return false;

    return true;
  }

  Future<void> _submitRide() async {
    if (!_isPublishEnabled) return;

    setState(() => _isSubmitting = true);

    try {
      final departure = _departureDateTime!;

      // 1. Publish Ride via RideService
      final RideModel publishedRide = await _rideService.publishRide(
        pickupName: _pickupController.text.trim(),
        pickupGeoPoint: _pickupGeoPoint!,
        destinationName: _destinationController.text.trim(),
        destinationGeoPoint: _destinationGeoPoint!,
        departureTime: departure,
        availableSeats: _availableSeats,
      );

      // 2. Firestore Write Verification: Verify the document exists in Firestore
      final RideModel? verifiedRide = await _rideRepository.fetchRide(publishedRide.rideId);

      if (verifiedRide != null && verifiedRide.rideId == publishedRide.rideId) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white),
                  SizedBox(width: 10),
                  Text('Ride published & verified successfully!'),
                ],
              ),
              backgroundColor: _accent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          // Return to Home Dashboard ONLY after successful persistence verification
          Navigator.pop(context);
        }
      } else {
        throw Exception('Firestore write verification failed. Document was not found.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Publish failed: ${e.toString()}'),
            backgroundColor: _errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // ─── Build Method ──────────────────────────────────────────────────────────

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
          'Publish a Ride',
          style: TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            _sectionHeader('Route Locations', Icons.route_rounded),
            const SizedBox(height: 12),

            // Pickup Autocomplete Field
            _autocompleteField(
              controller: _pickupController,
              label: 'Pickup Location',
              icon: Icons.my_location_rounded,
              iconColor: _primary,
              isSearching: _isSearchingPickup,
              isSelected: _pickupGeoPoint != null,
              suggestions: _pickupSuggestions,
              showSuggestions: _showPickupSuggestions,
              onChanged: (val) {
                setState(() => _pickupGeoPoint = null);
                _fetchSuggestions(val, true);
              },
              onSelectSuggestion: _selectPickupSuggestion,
            ),
            const SizedBox(height: 12),

            // Destination Autocomplete Field
            _autocompleteField(
              controller: _destinationController,
              label: 'Destination',
              icon: Icons.location_on_rounded,
              iconColor: Colors.redAccent,
              isSearching: _isSearchingDestination,
              isSelected: _destinationGeoPoint != null,
              suggestions: _destinationSuggestions,
              showSuggestions: _showDestinationSuggestions,
              onChanged: (val) {
                setState(() => _destinationGeoPoint = null);
                _fetchSuggestions(val, false);
              },
              onSelectSuggestion: _selectDestinationSuggestion,
            ),
            const SizedBox(height: 20),

            // Automatic Route & Fare Live Preview Card
            _buildLiveRouteAndFarePreview(),
            const SizedBox(height: 24),

            _sectionHeader('Departure Schedule', Icons.schedule_rounded),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _pickerTile(
                    label: _selectedDate == null
                        ? 'Select Date'
                        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                    icon: Icons.calendar_today_outlined,
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _pickerTile(
                    label: _selectedTime == null ? 'Select Time' : _selectedTime!.format(context),
                    icon: Icons.access_time_rounded,
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _sectionHeader('Capacity & Options', Icons.directions_car_rounded),
            const SizedBox(height: 12),

            // Seats Counter Stepper
            _seatsStepper(),
            const SizedBox(height: 12),

            // Vehicle Type Dropdown
            _vehicleTypeDropdown(),
            const SizedBox(height: 12),

            // Optional Notes Field
            _notesField(),
            const SizedBox(height: 32),

            // Publish Ride Button
            _publishButton(),
          ],
        ),
      ),
    );
  }

  // ─── UI Helper Components ──────────────────────────────────────────────────

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primary),
        ),
      ],
    );
  }

  Widget _autocompleteField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
    required bool isSearching,
    required bool isSelected,
    required List<Map<String, dynamic>> suggestions,
    required bool showSuggestions,
    required ValueChanged<String> onChanged,
    required ValueChanged<Map<String, dynamic>> onSelectSuggestion,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: label,
              hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
              prefixIcon: Icon(icon, color: iconColor),
              suffixIcon: isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : (isSelected
                      ? const Icon(Icons.check_circle_rounded, color: _accent)
                      : null),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        if (showSuggestions && suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 180),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black08),
              itemCount: suggestions.length,
              itemBuilder: (context, i) {
                final suggestion = suggestions[i];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on_outlined, color: _primary, size: 18),
                  title: Text(
                    suggestion['display_name'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                  onTap: () => onSelectSuggestion(suggestion),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildLiveRouteAndFarePreview() {
    if (_isCalculatingRoute) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _primary.withOpacity(0.1)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(width: 12),
            Text(
              'Calculating driving route & fare preview...',
              style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    if (_routeError != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _errorRed.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: _errorRed, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _routeError!,
                style: const TextStyle(color: _errorRed, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    if (_routingResult == null || _fareResult == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _primary.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _primary.withOpacity(0.08)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: _primary, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Select both Pickup and Destination locations to preview driving route and fare breakdown.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          ],
        ),
      );
    }

    // Active Live Route & Fare Breakdown Preview Card
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: _accent.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.insights_rounded, color: _accent, size: 20),
              SizedBox(width: 8),
              Text(
                'Live Route & Fare Preview',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _primary),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metricColumn('Distance', '${_routingResult!.distanceKm} km', Icons.straighten_rounded),
              _metricColumn('Est. Duration', '${_routingResult!.estimatedDurationMinutes} mins', Icons.timer_outlined),
              _metricColumn('Fare / Seat', 'Rs. ${_fareResult!.farePerSeat.toStringAsFixed(2)}', Icons.airline_seat_reconcile_normal_rounded),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _fareTile('Total Ride Fare', 'Rs. ${_fareResult!.rideTotal.toStringAsFixed(2)}', Colors.black87),
                _fareTile('Commission', 'Rs. ${_fareResult!.commissionAmount.toStringAsFixed(2)}', Colors.orange.shade800),
                _fareTile('Driver Payout', 'Rs. ${_fareResult!.driverReceives.toStringAsFixed(2)}', _accent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: _primary),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _primary)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black45)),
      ],
    );
  }

  Widget _fareTile(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.black45, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _pickerTile({required String label, required IconData icon, required VoidCallback onTap}) {
    final isSelected = !label.startsWith('Select');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: _primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected ? Colors.black87 : Colors.black38,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seatsStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.event_seat_rounded, color: _primary, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Available Seats', style: TextStyle(fontSize: 14, color: Colors.black87)),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: _primary),
                onPressed: _availableSeats > 1
                    ? () {
                        setState(() => _availableSeats--);
                        _calculateRouteAndFareIfReady();
                      }
                    : null,
              ),
              Text(
                '$_availableSeats',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primary),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: _primary),
                onPressed: _availableSeats < 7
                    ? () {
                        setState(() => _availableSeats++);
                        _calculateRouteAndFareIfReady();
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vehicleTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _vehicleType,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _primary),
          isExpanded: true,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          items: _vehicleTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Row(
                children: [
                  const Icon(Icons.directions_car_outlined, size: 18, color: _primary),
                  const SizedBox(width: 10),
                  Text(type),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) => setState(() => _vehicleType = val ?? 'Car'),
        ),
      ),
    );
  }

  Widget _notesField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _notesController,
        maxLength: 200,
        maxLines: 2,
        decoration: const InputDecoration(
          hintText: 'Additional notes for passengers (optional, max 200 chars)',
          hintStyle: TextStyle(color: Colors.black38, fontSize: 13),
          border: InputBorder.none,
          counterStyle: TextStyle(fontSize: 10),
        ),
      ),
    );
  }

  Widget _publishButton() {
    final enabled = _isPublishEnabled;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 56,
      decoration: BoxDecoration(
        gradient: enabled
            ? const LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: enabled ? null : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(18),
        boxShadow: enabled
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
          onTap: enabled ? _submitRide : null,
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
                        Icons.publish_rounded,
                        color: enabled ? Colors.white : Colors.grey.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Publish Ride',
                        style: TextStyle(
                          color: enabled ? Colors.white : Colors.grey.shade600,
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
}
