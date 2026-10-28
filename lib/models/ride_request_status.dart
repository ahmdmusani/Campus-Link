enum RideRequestStatus {
  pending,
  accepted,
  declined,
  cancelled;

  String toMap() => name;

  static RideRequestStatus fromMap(String? status) {
    return RideRequestStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => RideRequestStatus.pending,
    );
  }
}
