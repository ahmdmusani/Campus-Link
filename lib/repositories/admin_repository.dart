import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin/admin_stats_model.dart';
import '../models/admin/user_management_model.dart';
import '../models/admin/complaint_model.dart';
import '../models/admin/admin_audit_log_model.dart';
import '../models/ride_model.dart';
import '../models/wallet_transaction_model.dart';

class AdminRepository {
  final FirebaseFirestore _firestore;

  AdminRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Verifies if the specified userId has admin role or claim in Firestore users collection.
  Future<bool> verifyAdminRole(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists || doc.data() == null) return false;
      final data = doc.data()!;
      final role = data['role'] as String?;
      final isAdmin = data['isAdmin'] as bool? ?? false;
      return role == 'admin' || isAdmin;
    } catch (_) {
      return false;
    }
  }

  /// Aggregates platform dashboard metrics across Firestore collections.
  Future<AdminStatsModel> fetchDashboardStats() async {
    final usersSnapshot = await _firestore.collection('users').get();
    final activeRidesSnapshot = await _firestore
        .collection('rides')
        .where('rideStatus', in: ['published', 'ongoing'])
        .get();
    final completedRidesSnapshot = await _firestore.collection('ride_history').get();
    final transactionsSnapshot = await _firestore.collection('wallet_transactions').get();

    double totalCommission = 0.0;
    for (final doc in transactionsSnapshot.docs) {
      final data = doc.data();
      final comm = (data['commissionDeducted'] as num?)?.toDouble() ?? 0.0;
      totalCommission += comm;
    }

    return AdminStatsModel(
      totalUsers: usersSnapshot.docs.length,
      activeRides: activeRidesSnapshot.docs.length,
      completedRides: completedRidesSnapshot.docs.length,
      totalTransactions: transactionsSnapshot.docs.length,
      totalCommissionEarned: totalCommission,
    );
  }

  /// Streams all managed user profiles in real time.
  Stream<List<UserManagementModel>> streamAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => UserManagementModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Atomically updates user status (active/suspended) and creates an immutable audit log entry.
  Future<void> updateUserStatus({
    required String userId,
    required String status,
    required String adminId,
    String? reason,
  }) async {
    final batch = _firestore.batch();

    final userRef = _firestore.collection('users').doc(userId);
    batch.update(userRef, {
      'userStatus': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final logRef = _firestore.collection('admin_audit_logs').doc();
    batch.set(logRef, {
      'logId': logRef.id,
      'adminId': adminId,
      'action': status == 'suspended' ? 'suspend_user' : 'reactivate_user',
      'targetId': userId,
      'details': reason ?? 'User status changed to $status by admin',
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Streams all rides in real time with optional status filter.
  Stream<List<RideModel>> streamAllRides({String? statusFilter}) {
    Query query = _firestore.collection('rides');
    if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
      query = query.where('rideStatus', isEqualTo: statusFilter);
    }
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => RideModel.fromFirestore(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Atomically cancels a pre-settlement ride by admin intervention and creates an audit log entry.
  Future<void> cancelRideByAdmin({
    required String rideId,
    required String adminId,
    String? reason,
  }) async {
    final batch = _firestore.batch();

    final rideRef = _firestore.collection('rides').doc(rideId);
    batch.update(rideRef, {
      'rideStatus': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Update active participant records to cancelled
    final participantsQuery = await _firestore
        .collection('ride_participants')
        .where('rideId', isEqualTo: rideId)
        .where('participantStatus', isEqualTo: 'active')
        .get();

    for (final doc in participantsQuery.docs) {
      batch.update(doc.reference, {
        'participantStatus': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    final logRef = _firestore.collection('admin_audit_logs').doc();
    batch.set(logRef, {
      'logId': logRef.id,
      'adminId': adminId,
      'action': 'cancel_ride',
      'targetId': rideId,
      'details': reason ?? 'Ride cancelled by admin intervention',
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Streams all complaint documents in real time.
  Stream<List<ComplaintModel>> streamComplaints({String? statusFilter}) {
    Query query = _firestore.collection('complaints');
    if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => ComplaintModel.fromFirestore(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Atomically updates complaint resolution status and creates an audit log entry.
  Future<void> updateComplaintStatus({
    required String complaintId,
    required String status,
    required String adminId,
    String? reason,
  }) async {
    final batch = _firestore.batch();

    final complaintRef = _firestore.collection('complaints').doc(complaintId);
    batch.update(complaintRef, {
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final logRef = _firestore.collection('admin_audit_logs').doc();
    batch.set(logRef, {
      'logId': logRef.id,
      'adminId': adminId,
      'action': status == 'resolved' ? 'resolve_complaint' : 'dismiss_complaint',
      'targetId': complaintId,
      'details': reason ?? 'Complaint marked as $status by admin',
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Streams all immutable admin audit log entries in real time.
  Stream<List<AdminAuditLogModel>> streamAuditLogs() {
    return _firestore.collection('admin_audit_logs').snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => AdminAuditLogModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  /// Streams all platform wallet transaction documents in real time.
  Stream<List<WalletTransactionModel>> streamAllWalletTransactions() {
    return _firestore.collection('wallet_transactions').snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => WalletTransactionModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}
