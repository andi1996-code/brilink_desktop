import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../utils/currency_formatter.dart';
import '../utils/portable_storage.dart';
import '../controller/printer_controller.dart';

class TransactionListWidget extends StatefulWidget {
  final List<Map<String, dynamic>> transactions;
  final bool isLoading;

  const TransactionListWidget({
    Key? key,
    required this.transactions,
    required this.isLoading,
  }) : super(key: key);

  @override
  State<TransactionListWidget> createState() => _TransactionListWidgetState();
}

class _TransactionListWidgetState extends State<TransactionListWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daftar Transaksi Hari Ini',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.briDarkBlue,
              ),
            ),
            const SizedBox(height: 16),
            // Scrollable Table with scroll indicator
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  // Scroll hint
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.swipe_left,
                          size: 16,
                          color: Colors.blue[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Geser ke kanan untuk melihat kolom lainnya',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Scrollable content
                  Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: MediaQuery.of(context).size.width - 120,
                        ),
                        child: IntrinsicWidth(
                          child: Column(
                            children: [
                              // Table header
                              _buildTableHeader(),
                              // Transaction data or placeholder
                              widget.isLoading
                                  ? Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(40),
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  : widget.transactions.isEmpty
                                  ? _buildEmptyState()
                                  : Column(
                                      children: widget.transactions.map((
                                        transaction,
                                      ) {
                                        return _buildTransactionRow(
                                          context,
                                          transaction,
                                        );
                                      }).toList(),
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      decoration: BoxDecoration(color: AppColors.briBlue.withOpacity(0.1)),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              'EDC',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          SizedBox(
            width: 140,
            child: Text(
              'NO. TRANS',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              'KASIR',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              'LAYANAN',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              'NO TUJUAN',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              'NOMINAL',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              'FEE',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              'ADMIN',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              'TAMBAHAN',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          SizedBox(
            width: 150,
            child: Text(
              'NAMA PELANGGAN',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              'ACTION',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(color: Colors.grey[50]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'Belum ada transaksi hari ini',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Transaksi yang Anda buat akan muncul di sini',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(
    BuildContext context,
    Map<String, dynamic> transaction,
  ) {
    final edcName = transaction['edc_machine']?['name'] ?? '-';
    final transactionNumber = transaction['transaction_number'] ?? '-';
    final kasirName =
        transaction['cashier_name'] ?? transaction['user']?['name'] ?? '-';
    final serviceName = transaction['service']?['name'] ?? '-';
    final targetNumber = transaction['reference_number'] ?? '-';
    final amount = CurrencyFormatter.formatCurrencyNoDecimals(
      transaction['amount'],
    );
    final serviceFee = CurrencyFormatter.formatCurrencyNoDecimals(
      transaction['service_fee'],
    );
    final bankFee = CurrencyFormatter.formatCurrencyNoDecimals(
      transaction['bank_fee'],
    );
    final extraFee = CurrencyFormatter.formatCurrencyNoDecimals(
      transaction['extra_fee'],
    );
    final customerName = transaction['customer_name'] ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // EDC
          SizedBox(
            width: 80,
            child: Text(
              edcName,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // NO. TRANS
          SizedBox(
            width: 140,
            child: Text(
              transactionNumber,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // KASIR
          SizedBox(
            width: 100,
            child: Text(
              kasirName,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // LAYANAN
          SizedBox(
            width: 120,
            child: Text(
              serviceName,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // NO TUJUAN
          SizedBox(
            width: 120,
            child: Text(
              targetNumber,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // NOMINAL
          SizedBox(
            width: 120,
            child: Text(
              amount,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // FEE
          SizedBox(
            width: 80,
            child: Text(
              serviceFee,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // ADMIN
          SizedBox(
            width: 80,
            child: Text(
              bankFee,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // TAMBAHAN
          SizedBox(
            width: 100,
            child: Text(
              extraFee,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // NAMA PELANGGAN
          SizedBox(
            width: 150,
            child: Text(
              customerName,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // ACTION
          SizedBox(
            width: 120,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _handlePrintTransaction(
                    context,
                    transaction,
                    amount,
                    serviceFee,
                    bankFee,
                    extraFee,
                  ),
                  icon: Icon(Icons.print, size: 16, color: Colors.green[600]),
                  tooltip: 'Print Struk',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePrintTransaction(
    BuildContext context,
    Map<String, dynamic> transaction,
    String amount,
    String serviceFee,
    String bankFee,
    String extraFee,
  ) async {
    try {
      final printerFilePath =
          await PortableStorage.getPrinterSettingsFilePath();
      final file = File(printerFilePath);
      String printerName = '';
      if (await file.exists()) {
        final settings =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        printerName = settings['printer_name'] as String? ?? '';
      }
      if (printerName.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Printer belum dikonfigurasi')));
        return;
      }

      final printerController = PrinterController(printerName: printerName);

      // Prepare normalized data for printing
      final amtVal = CurrencyFormatter.parseRpToInt(amount);
      final feeVal = CurrencyFormatter.parseRpToInt(serviceFee);
      final bankVal = CurrencyFormatter.parseRpToInt(bankFee);
      final extraVal = CurrencyFormatter.parseRpToInt(extraFee);

      final printData = {
        'transaction_number': transaction['transaction_number'],
        'created_at':
            transaction['created_at'] ?? DateTime.now().toIso8601String(),
        'edc_machine': transaction['edc_machine'],
        'service': transaction['service'],
        'amount': amtVal,
        'bank_fee': bankVal,
        'service_fee': feeVal,
        'extra_fee': extraVal,
        'customer_name': transaction['customer_name'],
        'reference_number': transaction['reference_number'],
        'user': transaction['user'],
      };

      final success = await printerController.printTransaction(printData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Struk berhasil dicetak' : 'Gagal mencetak struk',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error print: $e')));
    }
  }
}
