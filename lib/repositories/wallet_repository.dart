import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wallet_model.dart';
import '../models/wallet_transaction_model.dart';

class WalletRepository {
  final FirebaseFirestore _firestore;

  WalletRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetches a user's wallet document. Initializes zero-balance wallet if non-existent.
  Future<WalletModel> fetchUserWallet(String userId) async {
    final docRef = _firestore.collection('wallets').doc(userId);
    final doc = await docRef.get();

    if (!doc.exists || doc.data() == null) {
      final initialWallet = WalletModel(
        walletId: userId,
        userId: userId,
        balance: 0.0,
        totalEarned: 0.0,
        totalSpent: 0.0,
        updatedAt: DateTime.now(),
      );
      await docRef.set({
        'walletId': userId,
        'userId': userId,
        'balance': 0.0,
        'totalEarned': 0.0,
        'totalSpent': 0.0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return initialWallet;
    }

    return WalletModel.fromFirestore(doc);
  }

  /// Streams real-time updates for a user's wallet document.
  Stream<WalletModel?> streamUserWallet(String userId) {
    return _firestore.collection('wallets').doc(userId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return WalletModel.fromFirestore(doc);
    });
  }

  /// Streams real-time wallet transactions for a specific user.
  Stream<List<WalletTransactionModel>> streamUserTransactions(String userId) {
    return _firestore
        .collection('wallet_transactions')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => WalletTransactionModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}
