import 'package:firebase_auth/firebase_auth.dart';
import '../models/wallet_model.dart';
import '../models/wallet_transaction_model.dart';
import '../repositories/wallet_repository.dart';

class WalletService {
  final WalletRepository _repository;
  final FirebaseAuth _firebaseAuth;

  WalletService({
    WalletRepository? repository,
    FirebaseAuth? firebaseAuth,
  })  : _repository = repository ?? WalletRepository(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  /// Streams real-time wallet data for the authenticated user.
  Stream<WalletModel?> streamUserWallet() {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return Stream.value(null);
    }
    return _repository.streamUserWallet(user.uid);
  }

  /// Streams real-time wallet transactions for the authenticated user.
  Stream<List<WalletTransactionModel>> streamUserTransactions() {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }
    return _repository.streamUserTransactions(user.uid);
  }

  /// Fetches current wallet data for the authenticated user.
  Future<WalletModel> fetchUserWallet() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('Authentication required to access wallet.');
    }
    return _repository.fetchUserWallet(user.uid);
  }
}
