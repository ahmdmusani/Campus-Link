import 'package:firebase_auth/firebase_auth.dart';
import '../models/admin/admin_stats_model.dart';
import '../models/admin/user_management_model.dart';
import '../models/admin/complaint_model.dart';
import '../models/admin/admin_audit_log_model.dart';
import '../models/ride_model.dart';
import '../models/wallet_transaction_model.dart';
import '../repositories/admin_repository.dart';

class AdminService {
  final AdminRepository _repository;
  final FirebaseAuth _firebaseAuth;

  AdminService({
    AdminRepository? repository,
    FirebaseAuth? firebaseAuth,
  })  : _repository = repository ?? AdminRepository(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  /// Verifies current user authentication and admin authorization.
  Future<bool> verifyAdminAccess() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return false;
    return _repository.verifyAdminRole(user.uid);
  }

  Future<void> _enforceAdminAuth() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('Authentication required to perform admin operations.');
    }
    final isAdmin = await _repository.verifyAdminRole(user.uid);
    if (!isAdmin) {
      throw Exception('Access Denied: Administrative role authorization required.');
    }
  }

  Future<AdminStatsModel> fetchDashboardStats() async {
    await _enforceAdminAuth();
    return _repository.fetchDashboardStats();
  }

  Stream<List<UserManagementModel>> streamAllUsers() {
    return _repository.streamAllUsers();
  }

  Future<void> updateUserStatus({
    required String userId,
    required String status,
    String? reason,
  }) async {
    await _enforceAdminAuth();
    final admin = _firebaseAuth.currentUser!;
    await _repository.updateUserStatus(
      userId: userId,
      status: status,
      adminId: admin.uid,
      reason: reason,
    );
  }

  Stream<List<RideModel>> streamAllRides({String? statusFilter}) {
    return _repository.streamAllRides(statusFilter: statusFilter);
  }

  Future<void> cancelRideByAdmin({
    required String rideId,
    String? reason,
  }) async {
    await _enforceAdminAuth();
    final admin = _firebaseAuth.currentUser!;
    await _repository.cancelRideByAdmin(
      rideId: rideId,
      adminId: admin.uid,
      reason: reason,
    );
  }

  Stream<List<ComplaintModel>> streamComplaints({String? statusFilter}) {
    return _repository.streamComplaints(statusFilter: statusFilter);
  }

  Future<void> updateComplaintStatus({
    required String complaintId,
    required String status,
    String? reason,
  }) async {
    await _enforceAdminAuth();
    final admin = _firebaseAuth.currentUser!;
    await _repository.updateComplaintStatus(
      complaintId: complaintId,
      status: status,
      adminId: admin.uid,
      reason: reason,
    );
  }

  Stream<List<AdminAuditLogModel>> streamAuditLogs() {
    return _repository.streamAuditLogs();
  }

  Stream<List<WalletTransactionModel>> streamAllWalletTransactions() {
    return _repository.streamAllWalletTransactions();
  }
}
