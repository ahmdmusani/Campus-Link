import 'package:flutter/material.dart';
import '../../models/admin/admin_stats_model.dart';
import '../../models/admin/user_management_model.dart';
import '../../models/admin/complaint_model.dart';
import '../../models/admin/admin_audit_log_model.dart';
import '../../models/ride_model.dart';
import '../../models/wallet_transaction_model.dart';
import '../../services/admin_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  late TabController _tabController;

  bool _isCheckingAdmin = true;
  bool _isAdminAuthorized = false;

  late Future<AdminStatsModel> _statsFuture;
  final TextEditingController _userSearchController = TextEditingController();
  String _userSearchQuery = '';
  String _rideFilter = 'all';

  static const Color _primary = Color(0xFF1A237E);
  static const Color _accent = Color(0xFF50C878);
  static const Color _bg = Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _checkAdminAccess();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _userSearchController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminAccess() async {
    final isAuthorized = await _adminService.verifyAdminAccess();
    if (mounted) {
      setState(() {
        _isAdminAuthorized = isAuthorized;
        _isCheckingAdmin = false;
        if (isAuthorized) {
          _statsFuture = _adminService.fetchDashboardStats();
        }
      });
    }
  }

  void _reloadStats() {
    setState(() {
      _statsFuture = _adminService.fetchDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAdmin) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _primary)),
      );
    }

    if (!_isAdminAuthorized) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _primary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.gpp_maybe_rounded, size: 54, color: Colors.redAccent),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Access Denied',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.redAccent),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Administrative role authorization required. Your account does not have admin permissions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Admin Operations Hub',
          style: TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: _primary,
          unselectedLabelColor: Colors.black45,
          indicatorColor: _primary,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded), text: 'Overview'),
            Tab(icon: Icon(Icons.people_rounded), text: 'Users'),
            Tab(icon: Icon(Icons.directions_car_rounded), text: 'Rides'),
            Tab(icon: Icon(Icons.report_problem_rounded), text: 'Complaints'),
            Tab(icon: Icon(Icons.shield_rounded), text: 'Audit Logs'),
            Tab(icon: Icon(Icons.account_balance_wallet_rounded), text: 'Wallet Audit'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildUsersTab(),
          _buildRidesTab(),
          _buildComplaintsTab(),
          _buildAuditLogsTab(),
          _buildWalletAuditTab(),
        ],
      ),
    );
  }

  // 1. OVERVIEW TAB
  Widget _buildOverviewTab() {
    return FutureBuilder<AdminStatsModel>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _primary));
        }

        final stats = snapshot.data ?? AdminStatsModel.empty();

        return RefreshIndicator(
          onRefresh: () async => _reloadStats(),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Platform Overview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primary),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.3,
                children: [
                  _statCard('Total Users', '${stats.totalUsers}', Icons.people_rounded, _primary),
                  _statCard('Active Rides', '${stats.activeRides}', Icons.directions_car_rounded, Colors.orange.shade800),
                  _statCard('Completed Rides', '${stats.completedRides}', Icons.task_alt_rounded, _accent),
                  _statCard('Transactions', '${stats.totalTransactions}', Icons.receipt_long_rounded, Colors.purple.shade800),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A237E), Color(0xFF303F9F)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Platform Revenue (Commission)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 6),
                    Text(
                      'Rs. ${stats.totalCommissionEarned.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // 2. USERS TAB
  Widget _buildUsersTab() {
    return StreamBuilder<List<UserManagementModel>>(
      stream: _adminService.streamAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _primary));
        }

        final allUsers = snapshot.data ?? [];
        final filteredUsers = allUsers.where((u) {
          final query = _userSearchQuery.toLowerCase();
          return u.name.toLowerCase().contains(query) ||
              u.email.toLowerCase().contains(query) ||
              u.userId.toLowerCase().contains(query);
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: TextField(
                controller: _userSearchController,
                onChanged: (val) => setState(() => _userSearchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search users by name, email, or ID...',
                  prefixIcon: const Icon(Icons.search, color: _primary),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: _primary.withOpacity(0.1)),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  final isSuspended = user.userStatus == 'suspended';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSuspended ? Colors.red.shade200 : _primary.withOpacity(0.08)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isSuspended ? Colors.red.shade50 : _primary.withOpacity(0.08),
                          child: Icon(
                            isSuspended ? Icons.person_off_rounded : Icons.person_rounded,
                            color: isSuspended ? Colors.redAccent : _primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _primary.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      user.role.toUpperCase(),
                                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _primary),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(user.email, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _toggleUserStatus(user),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSuspended ? _accent : Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(isSuspended ? 'Reactivate' : 'Suspend', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleUserStatus(UserManagementModel user) async {
    final isSuspended = user.userStatus == 'suspended';
    final targetStatus = isSuspended ? 'active' : 'suspended';
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${isSuspended ? "Reactivate" : "Suspend"} User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to $targetStatus user "${user.name}"?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for action (Audit Log)',
                hintText: 'Enter reason...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: isSuspended ? _accent : Colors.redAccent),
            child: Text(isSuspended ? 'Reactivate' : 'Suspend'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminService.updateUserStatus(
          userId: user.userId,
          status: targetStatus,
          reason: reasonController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User "${user.name}" status updated to $targetStatus.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  // 3. RIDES TAB
  Widget _buildRidesTab() {
    return StreamBuilder<List<RideModel>>(
      stream: _adminService.streamAllRides(statusFilter: _rideFilter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _primary));
        }

        final rides = snapshot.data ?? [];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filter Status:', style: TextStyle(fontWeight: FontWeight.bold, color: _primary)),
                  DropdownButton<String>(
                    value: _rideFilter,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                      DropdownMenuItem(value: 'published', child: Text('Published')),
                      DropdownMenuItem(value: 'ongoing', child: Text('Ongoing')),
                      DropdownMenuItem(value: 'completed', child: Text('Completed')),
                      DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _rideFilter = val);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: rides.length,
                itemBuilder: (context, index) {
                  final ride = rides[index];
                  final statusStr = ride.status.toMap();
                  final isPreSettlement = statusStr == 'published' || statusStr == 'ongoing';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _primary.withOpacity(0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Ride #${ride.rideId}', style: const TextStyle(fontWeight: FontWeight.bold, color: _primary)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(statusStr.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _primary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('${ride.pickupName} ➔ ${ride.destinationName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (isPreSettlement)
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton(
                              onPressed: () => _cancelRide(ride),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                              child: const Text('Cancel Ride', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelRide(RideModel ride) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Ride (Admin Intervention)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to cancel ride #${ride.rideId}?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'Reason for cancellation'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Cancel Ride'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminService.cancelRideByAdmin(rideId: ride.rideId, reason: reasonController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ride cancelled successfully.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.redAccent));
        }
      }
    }
  }

  // 4. COMPLAINTS TAB
  Widget _buildComplaintsTab() {
    return StreamBuilder<List<ComplaintModel>>(
      stream: _adminService.streamComplaints(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _primary));
        }

        final complaints = snapshot.data ?? [];

        if (complaints.isEmpty) {
          return const Center(child: Text('No Complaints Recorded'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: complaints.length,
          itemBuilder: (context, index) {
            final c = complaints[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _primary.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(c.category, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                      Text(c.status.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(c.description, style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _updateComplaint(c, 'dismissed'),
                        child: const Text('Dismiss', style: TextStyle(color: Colors.black45, fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _updateComplaint(c, 'resolved'),
                        style: ElevatedButton.styleFrom(backgroundColor: _accent),
                        child: const Text('Resolve', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateComplaint(ComplaintModel complaint, String status) async {
    try {
      await _adminService.updateComplaintStatus(complaintId: complaint.complaintId, status: status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Complaint marked as $status.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  // 5. AUDIT LOGS TAB
  Widget _buildAuditLogsTab() {
    return StreamBuilder<List<AdminAuditLogModel>>(
      stream: _adminService.streamAuditLogs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _primary));
        }

        final logs = snapshot.data ?? [];

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _primary.withOpacity(0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(log.action.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _primary)),
                      Text('${log.timestamp.day}/${log.timestamp.month} ${log.timestamp.hour}:${log.timestamp.minute}', style: const TextStyle(fontSize: 10, color: Colors.black38)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Target: ${log.targetId}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                  Text('Details: ${log.details}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 6. WALLET AUDIT TAB
  Widget _buildWalletAuditTab() {
    return StreamBuilder<List<WalletTransactionModel>>(
      stream: _adminService.streamAllWalletTransactions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _primary));
        }

        final transactions = snapshot.data ?? [];

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final tx = transactions[index];
            final isCredit = tx.transactionType == 'credit';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _primary.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  Icon(isCredit ? Icons.add_circle : Icons.remove_circle, color: isCredit ? _accent : Colors.redAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tx.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('User: ${tx.userId}', style: const TextStyle(fontSize: 10, color: Colors.black45)),
                      ],
                    ),
                  ),
                  Text('${isCredit ? '+' : '-'}Rs. ${tx.amount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: isCredit ? _accent : Colors.redAccent)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
