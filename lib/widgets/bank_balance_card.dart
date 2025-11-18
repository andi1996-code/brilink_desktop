import 'package:flutter/material.dart';
import '../app_colors.dart';

class BankBalanceCard extends StatelessWidget {
  final String title;
  final String balance;

  const BankBalanceCard({Key? key, required this.title, required this.balance})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance, size: 16, color: AppColors.briBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              balance,
              style: TextStyle(
                fontSize: 18,
                color: AppColors.briBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: 0.3,
              color: AppColors.briBlue,
              backgroundColor: Colors.grey.shade200,
            ),
            const SizedBox(height: 8),
            const Text(
              '0 transaksi',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
