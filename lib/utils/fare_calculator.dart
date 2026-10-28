import '../models/pricing_config_model.dart';

class FareCalculationResult {
  final double rideTotal;
  final double farePerSeat;
  final double commissionAmount;
  final double driverReceives;

  const FareCalculationResult({
    required this.rideTotal,
    required this.farePerSeat,
    required this.commissionAmount,
    required this.driverReceives,
  });
}

class FareCalculator {
  static double _round(double value) {
    return double.parse(value.toStringAsFixed(2));
  }

  static FareCalculationResult calculateFare({
    required double distanceKm,
    required int availableSeats,
    required PricingConfigModel pricingConfig,
  }) {
    if (availableSeats <= 0) {
      throw ArgumentError('Available seats must be greater than zero.');
    }
    if (distanceKm <= 0) {
      throw ArgumentError('Distance must be greater than zero.');
    }

    final rawTotal = pricingConfig.baseFare + (distanceKm * pricingConfig.perKmRate);
    final rideTotal = _round(rawTotal);
    final farePerSeat = _round(rideTotal / availableSeats);
    final commissionAmount = _round(rideTotal * (pricingConfig.commissionPercent / 100.0));
    final driverReceives = _round(rideTotal - commissionAmount);

    return FareCalculationResult(
      rideTotal: rideTotal,
      farePerSeat: farePerSeat,
      commissionAmount: commissionAmount,
      driverReceives: driverReceives,
    );
  }
}
