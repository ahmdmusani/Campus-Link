import 'package:flutter/material.dart';
import '../models/wallet_model.dart';
import '../models/wallet_transaction_model.dart';
import '../services/wallet_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _walletService = WalletService();

  static const Color _primary = Color(0xFF1A237E);
  static const Color _accent = Color(0xFF50C878);
  static const Color _bg = Color(0xFFF8F9FA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'CampusLink Wallet',
          style: TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<WalletModel?>(
        stream: _walletService.streamUserWallet(),
        builder: (context, walletSnapshot) {
          if (walletSnapshot.connectionState == ConnectionState.waiting && !walletSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: _primary));
          }

          final wallet = walletSnapshot.data ??
              WalletModel(
                walletId: '',
                userId: '',
                balance: 0.0,
                totalEarned: 0.0,
                totalSpent: 0.0,
                updatedAt: DateTime.now(),
              );

          return StreamBuilder<List<WalletTransactionModel>>(
            stream: _walletService.streamUserTransactions(),
            builder: (context, txSnapshot) {
              final transactions = txSnapshot.data ?? [];

              return RefreshIndicator(
                onRefresh: () async => setState(() {}),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                  children: [
                    // Balance & Earnings Summary Card
                    _buildBalanceCard(wallet),
                    const SizedBox(height: 24),

                    // Section Title
                    const Text(
                      'Transaction History',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: _primary),
                    ),
                    const SizedBox(height: 14),

                    if (transactions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: _primary.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 44,
                                color: _primary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'No Transactions Yet',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primary),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Your ride payments and driver earnings will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black45, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    else
                      ...transactions.map((tx) => _buildTransactionCard(tx)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(WalletModel wallet) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF283593)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Available Balance',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.security, size: 12, color: _accent),
                    SizedBox(width: 4),
                    Text(
                      'SECURED',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Rs. ${wallet.balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('Total Earned', style: TextStyle(color: Colors.white60, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      'Rs. ${wallet.totalEarned.toStringAsFixed(2)}',
                      style: const TextStyle(color: _accent, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                Container(height: 24, width: 1, color: Colors.white24),
                Column(
                  children: [
                    const Text('Total Spent', style: TextStyle(color: Colors.white60, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      'Rs. ${wallet.totalSpent.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(WalletTransactionModel tx) {
    final isCredit = tx.transactionType == 'credit';
    final color = isCredit ? _accent : Colors.redAccent;
    final icon = isCredit ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded;
    final timeStr =
        '${tx.createdAt.day}/${tx.createdAt.month}/${tx.createdAt.year} at ${tx.createdAt.hour.toString().padLeft(2, '0')}:${tx.createdAt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: _primary.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ride ID: ${tx.rideId}',
                  style: const TextStyle(color: Colors.black45, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  timeStr,
                  style: const TextStyle(color: Colors.black38, fontSize: 10),
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}Rs. ${tx.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
