import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride_status.dart';

class RideLifecycleRepository {
  final FirebaseFirestore _firestore;

  RideLifecycleRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Executes an atomic Firestore transaction to START a published ride (published -> ongoing).
  Future<void> startRideTransaction({
    required String rideId,
    required String driverId,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final rideRef = _firestore.collection('rides').doc(rideId);
      final rideDoc = await transaction.get(rideRef);

      if (!rideDoc.exists || rideDoc.data() == null) {
        throw Exception('The ride no longer exists.');
      }

      final rideData = rideDoc.data()!;
      final currentDriverId = rideData['driverId'] as String?;
      final currentStatus = rideData['rideStatus'] as String?;

      if (currentDriverId != driverId) {
        throw Exception('Unauthorized driver ownership check failed.');
      }

      if (currentStatus != RideStatus.published.toMap()) {
        throw Exception('Only published rides can be started. Current status: $currentStatus.');
      }

      transaction.update(rideRef, {
        'rideStatus': RideStatus.ongoing.toMap(),
        'startedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Executes a SINGLE ATOMIC FIRESTORE TRANSACTION to COMPLETE an ongoing ride (ongoing -> completed),
  /// perform financial settlement (driver net credit, passenger debit, commission math), update settlementStatus='settled',
  /// log transaction documents, and create an immutable record in ride_history collection.
  Future<void> completeRideTransaction({
    required String rideId,
    required String driverId,
  }) async {
    // 1. Fetch active participants & pricing configuration
    final participantsQuery = await _firestore
        .collection('ride_participants')
        .where('rideId', isEqualTo: rideId)
        .where('participantStatus', isEqualTo: 'active')
        .get();

    double commissionPercent = 5.0; // Default 5% platform commission
    try {
      final configDoc = await _firestore.collection('pricing_config').doc('config').get();
      if (configDoc.exists && configDoc.data() != null) {
        commissionPercent = (configDoc.data()!['commissionPercent'] as num?)?.toDouble() ?? 5.0;
      }
    } catch (_) {}

    await _firestore.runTransaction((transaction) async {
      final rideRef = _firestore.collection('rides').doc(rideId);
      final rideDoc = await transaction.get(rideRef);

      if (!rideDoc.exists || rideDoc.data() == null) {
        throw Exception('The ride no longer exists.');
      }

      final rideData = rideDoc.data()!;
      final currentDriverId = rideData['driverId'] as String?;
      final currentStatus = rideData['rideStatus'] as String?;
      final settlementStatus = rideData['settlementStatus'] as String? ?? 'unsettled';

      if (currentDriverId != driverId) {
        throw Exception('Unauthorized driver ownership check failed.');
      }

      if (currentStatus != RideStatus.ongoing.toMap()) {
        throw Exception('Only ongoing rides can be completed. Current status: $currentStatus.');
      }

      if (settlementStatus == 'settled') {
        throw Exception('This ride has already been settled and completed.');
      }

      final bookedSeats = (rideData['bookedSeats'] as num?)?.toInt() ?? 0;
      final farePerSeat = (rideData['farePerSeat'] as num?)?.toDouble() ?? 0.0;
      final grossRideFare = bookedSeats * farePerSeat;

      final platformCommission = grossRideFare * (commissionPercent / 100.0);
      final driverNetEarnings = grossRideFare - platformCommission;

      // 2. Read driver wallet inside transaction
      final driverWalletRef = _firestore.collection('wallets').doc(driverId);
      final driverWalletDoc = await transaction.get(driverWalletRef);

      double driverCurrentBalance = 0.0;
      double driverCurrentEarned = 0.0;
      double driverCurrentSpent = 0.0;

      if (driverWalletDoc.exists && driverWalletDoc.data() != null) {
        final dData = driverWalletDoc.data()!;
        driverCurrentBalance = (dData['balance'] as num?)?.toDouble() ?? 0.0;
        driverCurrentEarned = (dData['totalEarned'] as num?)?.toDouble() ?? 0.0;
        driverCurrentSpent = (dData['totalSpent'] as num?)?.toDouble() ?? 0.0;
      }

      // 3. Process Passenger Wallets and Verification
      for (final pDoc in participantsQuery.docs) {
        final pData = pDoc.data();
        final passengerId = pData['passengerId'] as String?;
        final requestedSeats = (pData['requestedSeats'] as num?)?.toInt() ?? 1;
        final passengerFare = requestedSeats * farePerSeat;

        if (passengerId != null && passengerId.isNotEmpty) {
          final passengerWalletRef = _firestore.collection('wallets').doc(passengerId);
          final passengerWalletDoc = await transaction.get(passengerWalletRef);

          double pBalance = 0.0;
          double pSpent = 0.0;
          double pEarned = 0.0;

          if (passengerWalletDoc.exists && passengerWalletDoc.data() != null) {
            final pwData = passengerWalletDoc.data()!;
            pBalance = (pwData['balance'] as num?)?.toDouble() ?? 0.0;
            pSpent = (pwData['totalSpent'] as num?)?.toDouble() ?? 0.0;
            pEarned = (pwData['totalEarned'] as num?)?.toDouble() ?? 0.0;
          }

          // Debit passenger wallet
          transaction.set(passengerWalletRef, {
            'walletId': passengerId,
            'userId': passengerId,
            'balance': pBalance - passengerFare,
            'totalEarned': pEarned,
            'totalSpent': pSpent + passengerFare,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          // Log passenger debit transaction
          final pTxRef = _firestore.collection('wallet_transactions').doc();
          transaction.set(pTxRef, {
            'transactionId': pTxRef.id,
            'userId': passengerId,
            'rideId': rideId,
            'amount': passengerFare,
            'transactionType': 'debit',
            'description': 'Fare payment for $requestedSeats seat(s)',
            'commissionDeducted': 0.0,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // 4. Credit Driver Wallet
      transaction.set(driverWalletRef, {
        'walletId': driverId,
        'userId': driverId,
        'balance': driverCurrentBalance + driverNetEarnings,
        'totalEarned': driverCurrentEarned + driverNetEarnings,
        'totalSpent': driverCurrentSpent,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 5. Log Driver Credit Transaction
      final dTxRef = _firestore.collection('wallet_transactions').doc();
      transaction.set(dTxRef, {
        'transactionId': dTxRef.id,
        'userId': driverId,
        'rideId': rideId,
        'amount': driverNetEarnings,
        'transactionType': 'credit',
        'description': 'Driver net earnings (${commissionPercent.toStringAsFixed(1)}% platform commission deducted)',
        'commissionDeducted': platformCommission,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 6. Update Ride Document Status & Settlement Status (Idempotency Protection)
      transaction.update(rideRef, {
        'rideStatus': RideStatus.completed.toMap(),
        'settlementStatus': 'settled',
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 7. Create immutable ride_history document
      final historyRef = _firestore.collection('ride_history').doc();
      transaction.set(historyRef, {
        'historyId': historyRef.id,
        'rideId': rideId,
        'driverId': driverId,
        'pickupName': rideData['pickupName'] ?? '',
        'destinationName': rideData['destinationName'] ?? '',
        'departureTime': rideData['departureTime'] ?? FieldValue.serverTimestamp(),
        'completedAt': FieldValue.serverTimestamp(),
        'totalFare': grossRideFare,
        'bookedSeats': bookedSeats,
        'participantsCount': participantsQuery.docs.length,
      });
    });
  }
}
