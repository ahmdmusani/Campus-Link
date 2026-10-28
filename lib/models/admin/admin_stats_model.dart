class AdminStatsModel {
  final int totalUsers;
  final int activeRides;
  final int completedRides;
  final int totalTransactions;
  final double totalCommissionEarned;

  const AdminStatsModel({
    required this.totalUsers,
    required this.activeRides,
    required this.completedRides,
    required this.totalTransactions,
    required this.totalCommissionEarned,
  });

  factory AdminStatsModel.empty() {
    return const AdminStatsModel(
      totalUsers: 0,
      activeRides: 0,
      completedRides: 0,
      totalTransactions: 0,
      totalCommissionEarned: 0.0,
    );
  }
}
