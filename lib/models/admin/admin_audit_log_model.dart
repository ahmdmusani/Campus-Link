import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAuditLogModel {
  final String logId;
  final String adminId;
  final String action; // e.g. 'suspend_user', 'reactivate_user', 'cancel_ride', 'resolve_complaint'
  final String targetId;
  final String details;
  final DateTime timestamp;

  const AdminAuditLogModel({
    required this.logId,
    required this.adminId,
    required this.action,
    required this.targetId,
    required this.details,
    required this.timestamp,
  });

  factory AdminAuditLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminAuditLogModel(
      logId: doc.id,
      adminId: data['adminId'] ?? '',
      action: data['action'] ?? '',
      targetId: data['targetId'] ?? '',
      details: data['details'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'logId': logId,
      'adminId': adminId,
      'action': action,
      'targetId': targetId,
      'details': details,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
