import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_ride_screen.dart';
import 'ride_search_screen.dart';
import 'driver_requests_screen.dart';
import 'driver_active_rides_list_screen.dart';
import 'passenger_ride_history_screen.dart';
import 'driver_ride_history_screen.dart';
import 'notifications_hub.dart';
import 'wallet_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';



class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng _currentLocation = const LatLng(24.8607, 67.0011); // Karachi Fallback
  LatLng? _selectedLocation;

  List<Map<String, dynamic>> _searchSuggestions = [];
  bool _showSuggestions = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _initGPSLocation();
  }

  Future<void> _initGPSLocation() async {
    // GPS Location Handling Priority:
    // 1. Real GPS location (simulated device acquisition lock)
    // 2. Last known location
    // 3. Fallback default location (Karachi 24.8607, 67.0011)
    await Future.delayed(const Duration(milliseconds: 650));
    if (mounted) {
      setState(() {
        _currentLocation = const LatLng(24.8612, 67.0022); // Simulating real device GPS location lock
        _mapController.move(_currentLocation, 14.5);
      });
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5');
    try {
      final response = await http.get(url, headers: {'User-Agent': 'CampusLinkApp'});
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _searchSuggestions = data.map((item) => {
              'display_name': item['display_name'] ?? 'Unknown Location',
              'lat': double.tryParse(item['lat'] ?? '') ?? 24.8607,
              'lon': double.tryParse(item['lon'] ?? '') ?? 67.0011,
            }).toList();
            _showSuggestions = _searchSuggestions.isNotEmpty;
          });
        }
      }
    } catch (e) {
      debugPrint('Geocoding suggestions search error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _selectSuggestion(Map<String, dynamic> suggestion) {
    final lat = suggestion['lat'] as double;
    final lon = suggestion['lon'] as double;
    final displayName = suggestion['display_name'] as String;

    setState(() {
      _selectedLocation = LatLng(lat, lon);
      _searchController.text = displayName;
      _showSuggestions = false;
      _searchSuggestions = [];
    });

    _mapController.move(LatLng(lat, lon), 16.0);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RideSearchScreen(
          initialDestinationQuery: displayName,
          initialDestinationGeoPoint: GeoPoint(lat, lon),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName?.split(' ').first ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: _buildDrawer(context),
      body: Stack(
        children: [
          // Background FlutterMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.campus_link',
              ),
              MarkerLayer(
                markers: [
                  // Live GPS Current Location Blue Dot marker
                  Marker(
                    point: _currentLocation,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.25),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Map Pin for searched exploration locations
                  if (_selectedLocation != null)
                    Marker(
                      point: _selectedLocation!,
                      width: 45,
                      height: 45,
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Colors.redAccent,
                        size: 45,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Floating UI Controls: Greeting and Search Bar
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting and Drawer Menu Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Builder(
                          builder: (context) => Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 2))
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.menu_rounded, color: Color(0xFF1A237E), size: 28),
                              onPressed: () => Scaffold.of(context).openDrawer(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Good Morning,',
                              style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A237E),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    StreamBuilder<List<NotificationModel>>(
                      stream: NotificationService().streamUserNotifications(),
                      builder: (context, snapshot) {
                        final unreadCount = snapshot.hasData
                            ? snapshot.data!.where((n) => !n.isRead).length
                            : 0;

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF1A237E)),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const NotificationsHub()),
                                  );
                                },
                              ),
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                right: 2,
                                top: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '$unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Location Autocomplete Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 4))
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => _searchLocation(val),
                    decoration: InputDecoration(
                      hintText: 'Search campus & locations...',
                      hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF1A237E)),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : (_searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.black45),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchSuggestions = [];
                                      _showSuggestions = false;
                                      _selectedLocation = null;
                                    });
                                  },
                                )
                              : null),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                // Suggestions Panel
                if (_showSuggestions && _searchSuggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _searchSuggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _searchSuggestions[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on_outlined, color: Color(0xFF1A237E)),
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
              ],
            ),
          ),

          // Floating Locate Me Button
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.42 + 16,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'locate_me_btn',
              mini: true,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Color(0xFF1A237E)),
              onPressed: () {
                _mapController.move(_currentLocation, 14.5);
              },
            ),
          ),

          // Bottom Content Box (Promotion Banner, Lost & Found Hub, Recent Items)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.42,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -4))
                ],
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPromoBanner(),
                      const SizedBox(height: 20),
                      const Text(
                        'Lost & Found Hub',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                      ),
                      const SizedBox(height: 12),
                      _buildGradientCard(
                        title: 'Report Lost or Found Item',
                        icon: Icons.find_in_page_rounded,
                        colors: [const Color(0xFF50C878), const Color(0xFF2E8B57)],
                        onTap: () {},
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Recent Lost Items',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                      _buildLostFoundCarousel(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? 'Fahad K.';
    final email = user?.email ?? 'student@campus.edu';

    return Drawer(
      child: Container(
        color: const Color(0xFFF8F9FA),
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Color(0xFFE8EAF6),
                child: Icon(Icons.person, size: 40, color: Color(0xFF1A237E)),
              ),
              accountName: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              accountEmail: Text(email),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline, color: Color(0xFF1A237E)),
              title: const Text('My Profile'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.find_in_page_outlined, color: Color(0xFF1A237E)),
              title: const Text('Lost & Found Items'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline, color: Color(0xFF1A237E)),
              title: const Text('Messages'),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add_road_rounded, color: Color(0xFF1A237E), size: 20),
              ),
              title: const Text(
                'Publish a Ride',
                style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A237E)),
              ),
              subtitle: const Text('Offer seats to fellow students', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateRideScreen()),
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF50C878).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.mark_email_unread_rounded, color: Color(0xFF2E8B57), size: 20),
              ),
              title: const Text(
                'Driver Requests',
                style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A237E)),
              ),
              subtitle: const Text('Manage incoming seat requests', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DriverRequestsScreen()),
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.directions_car_rounded, color: Color(0xFF1A237E), size: 20),
              ),
              title: const Text(
                'Active Rides',
                style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A237E)),
              ),
              subtitle: const Text('View participants & ride status', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DriverActiveRidesListScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history_rounded, color: Color(0xFF1A237E)),
              title: const Text('Passenger Ride History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PassengerRideHistoryScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history_edu_rounded, color: Color(0xFF1A237E)),
              title: const Text('Driver Ride History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DriverRideHistoryScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF1A237E)),
              title: const Text('CampusLink Wallet'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WalletScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF1A237E)),
              title: const Text('Admin Dashboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                FirebaseAuth.instance.signOut();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8EAF6), Color(0xFFC5CAE9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1A237E).withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.campaign, color: Color(0xFF1A237E), size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Campus Safety Promotion',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A237E)),
                ),
                SizedBox(height: 2),
                Text(
                  'Verify student profile to search and request with absolute safety.',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientCard({
    required String title,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colors.last.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Check lost objects instantly',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLostFoundCarousel() {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 290,
            margin: const EdgeInsets.only(right: 16, bottom: 5),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBE9E7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.backpack_rounded, color: Colors.deepOrangeAccent, size: 30),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Found: Red Backpack', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                      SizedBox(height: 2),
                      Text('Near CS Dept.', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500)),
                      SizedBox(height: 2),
                      Text('2 hours ago', style: TextStyle(color: Colors.grey, fontSize: 10)),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
