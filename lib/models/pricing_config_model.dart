class PricingConfigModel {
  final double baseFare;
  final double perKmRate;
  final double commissionPercent;

  const PricingConfigModel({
    required this.baseFare,
    required this.perKmRate,
    required this.commissionPercent,
  });

  factory PricingConfigModel.fromFirestore(Map<String, dynamic> data) {
    return PricingConfigModel(
      baseFare: (data['baseFare'] as num?)?.toDouble() ?? 50.0,
      perKmRate: (data['perKmRate'] as num?)?.toDouble() ?? 15.0,
      commissionPercent: (data['commissionPercent'] as num?)?.toDouble() ?? 10.0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'baseFare': baseFare,
      'perKmRate': perKmRate,
      'commissionPercent': commissionPercent,
    };
  }

  PricingConfigModel copyWith({
    double? baseFare,
    double? perKmRate,
    double? commissionPercent,
  }) {
    return PricingConfigModel(
      baseFare: baseFare ?? this.baseFare,
      perKmRate: perKmRate ?? this.perKmRate,
      commissionPercent: commissionPercent ?? this.commissionPercent,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PricingConfigModel &&
          runtimeType == other.runtimeType &&
          baseFare == other.baseFare &&
          perKmRate == other.perKmRate &&
          commissionPercent == other.commissionPercent;

  @override
  int get hashCode => baseFare.hashCode ^ perKmRate.hashCode ^ commissionPercent.hashCode;
}
