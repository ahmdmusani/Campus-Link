enum RideStatus {
  published,
  ongoing,
  completed,
  cancelled;

  String toMap() => name;

  static RideStatus fromMap(String? status) {
    return RideStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => RideStatus.published,
    );
  }
}
