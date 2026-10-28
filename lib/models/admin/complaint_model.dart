import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintModel {
  final String complaintId;
  final String reporterId;
  final String reportedUserId;
  final String rideId;
  final String category;
  final String description;
  final String status; // 'pending', 'resolved', 'dismissed'
  final DateTime createdAt;

  const ComplaintModel({
    required this.complaintId,
    required this.reporterId,
    required this.reportedUserId,
    required this.rideId,
    required this.category,
    required this.description,
    this.status = 'pending',
    required this.createdAt,
  });

  factory ComplaintModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ComplaintModel(
      complaintId: doc.id,
      reporterId: data['reporterId'] ?? '',
      reportedUserId: data['reportedUserId'] ?? '',
      rideId: data['rideId'] ?? '',
      category: data['category'] ?? 'General',
      description: data['description'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'complaintId': complaintId,
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'rideId': rideId,
      'category': category,
      'description': description,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ComplaintModel copyWith({
    String? complaintId,
    String? reporterId,
    String? reportedUserId,
    String? rideId,
    String? category,
    String? description,
    String? status,
    DateTime? createdAt,
  }) {
    return ComplaintModel(
      complaintId: complaintId ?? this.complaintId,
      reporterId: reporterId ?? this.reporterId,
      reportedUserId: reportedUserId ?? this.reportedUserId,
      rideId: rideId ?? this.rideId,
      category: category ?? this.category,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
