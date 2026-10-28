import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/ride_search_result.dart';
import '../services/ride_service.dart';
import '../widgets/ride_card.dart';

class RideSearchScreen extends StatefulWidget {
  final String? initialDestinationQuery;
  final GeoPoint? initialDestinationGeoPoint;

  const RideSearchScreen({
    super.key,
    this.initialDestinationQuery,
    this.initialDestinationGeoPoint,
  });

  @override
  State<RideSearchScreen> createState() => _RideSearchScreenState();
}

class _RideSearchScreenState extends State<RideSearchScreen> {
  final TextEditingController _destSearchController = TextEditingController();
  final RideService _rideService = RideService();

  // Passenger Default Pickup (Karachi Center default)
  final GeoPoint _passengerPickup = const GeoPoint(24.8607, 67.0011);

  // Selected Target Destination
  GeoPoint? _targetDestinationGeoPoint;

  // Autocomplete State
  List<Map<String, dynamic>> _suggestions = [];
  bool _showSuggestions = false;
  bool _isSearchingSuggestions = false;

  // Search Results State
  List<RideSearchResult> _searchResults = [];
  bool _isSearchingRides = false;
  bool _hasSearched = false;

  static const Color _primary = Color(0xFF1A237E);
  static const Color _bg = Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    if (widget.initialDestinationQuery != null && widget.initialDestinationQuery!.isNotEmpty) {
      _destSearchController.text = widget.initialDestinationQuery!;
    }
    if (widget.initialDestinationGeoPoint != null) {
      _targetDestinationGeoPoint = widget.initialDestinationGeoPoint;
      _executeRideSearch();
    }
  }

  @override
  void dispose() {
    _destSearchController.dispose();
    super.dispose();
  }

  // ─── Autocomplete Location Search ──────────────────────────────────────────

  Future<void> _fetchSuggestions(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    setState(() => _isSearchingSuggestions = true);

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(trimmed)},Karachi&format=json&limit=5',
    );

    try {
      final response = await http.get(url, headers: {'User-Agent': 'CampusLinkApp/1.0'});
      if (response.statusCode == 200 && mounted) {
        final List data = json.decode(response.body);
        final results = data.map((item) => {
          'display_name': item['display_name'] ?? '',
          'lat': double.tryParse(item['lat'] ?? '') ?? 0.0,
          'lon': double.tryParse(item['lon'] ?? '') ?? 0.0,
        }).toList();

        setState(() {
          _suggestions = List<Map<String, dynamic>>.from(results);
          _showSuggestions = results.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Search suggestions error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSearchingSuggestions = false);
      }
    }
  }

  void _selectSuggestion(Map<String, dynamic> suggestion) {
    final lat = suggestion['lat'] as double;
    final lon = suggestion['lon'] as double;
    final name = suggestion['display_name'] as String;

    setState(() {
      _destSearchController.text = name;
      _targetDestinationGeoPoint = GeoPoint(lat, lon);
      _suggestions = [];
      _showSuggestions = false;
    });

    _executeRideSearch();
  }

  // ─── Execute Two-Stage Ride Search ─────────────────────────────────────────

  Future<void> _executeRideSearch() async {
    if (_targetDestinationGeoPoint == null) return;

    setState(() {
      _isSearchingRides = true;
      _hasSearched = false;
    });

    try {
      final results = await _rideService.searchRidesByDestination(
        passengerPickup: _passengerPickup,
        targetDestination: _targetDestinationGeoPoint!,
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearchingRides = false;
          _hasSearched = true;
        });
      }
    } catch (e) {
      debugPrint('Ride search error: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearchingRides = false;
          _hasSearched = true;
        });
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
        automaticallyImplyLeading: false,
        title: const Text(
          'Passenger Ride Search',
          style: TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _executeRideSearch,
        color: _primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          children: [
            // Destination Autocomplete Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _destSearchController,
                onChanged: _fetchSuggestions,
                decoration: InputDecoration(
                  hintText: 'Enter your destination...',
                  hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: _primary),
                  suffixIcon: _isSearchingSuggestions
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : (_destSearchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.black45),
                              onPressed: () {
                                setState(() {
                                  _destSearchController.clear();
                                  _targetDestinationGeoPoint = null;
                                  _suggestions = [];
                                  _showSuggestions = false;
                                  _searchResults = [];
                                  _hasSearched = false;
                                });
                              },
                            )
                          : null),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            // Suggestions Dropdown
            if (_showSuggestions && _suggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black08),
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _suggestions[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.location_on_outlined, color: _primary, size: 20),
                      title: Text(
                        suggestion['display_name'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                      onTap: () => _selectSuggestion(suggestion),
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),

            // Content State Rendering
            if (_isSearchingRides)
              Container(
                padding: const EdgeInsets.all(30),
                child: const Column(
                  children: [
                    CircularProgressIndicator(color: _primary),
                    SizedBox(height: 16),
                    Text(
                      'Matching rides by road distance...',
                      style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )
            else if (_hasSearched && _searchResults.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(Icons.directions_off_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text(
                      'No Rides Found',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _primary),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'No available published rides match your target destination nearby. Try searching a different location.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black45, fontSize: 12),
                    ),
                  ],
                ),
              )
            else if (_searchResults.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available Matches (${_searchResults.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _primary),
                  ),
                  const Text(
                    'Sorted by road distance',
                    style: TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._searchResults.map((res) => RideCard(result: res)),
            ] else
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.search_rounded, size: 48, color: _primary),
                    SizedBox(height: 12),
                    Text(
                      'Search Rides by Destination',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _primary),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Enter your target destination in the search bar above to view matching published rides.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black45, fontSize: 12),
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
