import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/portable_storage.dart';
import '../app_colors.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_sukses_dialog.dart';
import '../widgets/dashboard_summary_card.dart';
import '../widgets/bank_balance_card.dart';
import '../widgets/transaction_form_widget.dart';
import '../widgets/transaction_list_widget.dart';
import '../controllers/transaction_controller.dart';
import '../utils/currency_formatter.dart';
import '../providers/auth_provider.dart';
import 'print_setting_screen.dart';
import '../controller/printer_controller.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  _TransactionScreenState createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  late TransactionController _controller;

  // Real-time clock
  String _currentTime = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = TransactionController(context);

    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });

    // Load essential data first
    _loadAllData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _updateTime() {
    if (mounted) {
      final now = DateTime.now();
      setState(() {
        _currentTime =
            '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _loadAllData() async {
    // Load EDC machines, services, service fees, and bank fees first
    await Future.wait([
      _controller.loadEdcMachines(),
      _controller.loadServices(),
      _controller.loadServiceFees(),
      _controller.loadBankFees(),
    ]);

    // Then load transactions (which depends on EDC machines and services)
    await Future.wait([
      _controller.showOnlyTodayTransactions
          ? _controller.loadTodayTransactions()
          : _controller.loadTransactions(),
      _controller.loadDashboard(),
    ]);

    if (mounted) {
      setState(() {});
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showTransactionFormModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.9,
                child: Column(
                  children: [
                    // Modal Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.briBlue,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Form Transaksi Baru',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    // Modal Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: SingleChildScrollView(
                          child: TransactionFormWidget(
                            controller: _controller,
                            currentTime: _currentTime,
                            onFormChanged: () => setModalState(() {}),
                            onSubmit: () => _handleCreateTransaction(),
                            onReset: () {
                              _controller.resetForm(() => setModalState(() {}));
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleCreateTransaction() {
    _controller.createTransaction(
      onSuccess: () {
        // Don't close modal here - let onPrintCallback handle it
        debugPrint('Transaction success callback triggered');
      },
      onError: _showErrorDialog,
      onPrintCallback: (transactionData) {
        debugPrint(
          'Print callback triggered with data: ${transactionData['transaction_number']}',
        );
        // Close modal first
        Navigator.of(context).pop();

        // Then show success dialog
        CustomSuksesDialog.show(
          context: context,
          title: 'Transaksi Berhasil!',
          message: 'Transaksi Anda telah berhasil diproses.',
          transactionNumber: transactionData['transaction_number'] ?? '',
          amount: CurrencyFormatter.formatCurrencyNoDecimals(
            transactionData['total_amount'] ?? 0,
          ),
          transactionData: transactionData,
          onClose: () {
            _controller.resetForm(() {
              if (mounted) setState(() {});
            });
            // Refresh all data including dashboard cards after successful transaction
            _loadAllData();
          },
          onPrint: () async {
            await _handlePrintFromDialog(transactionData);
          },
        );
      },
    );
  }

  Future<void> _handlePrintFromDialog(
    Map<String, dynamic> transactionData,
  ) async {
    try {
      // Gunakan portable storage untuk printer settings
      final printerFilePath =
          await PortableStorage.getPrinterSettingsFilePath();
      final file = File(printerFilePath);
      String name = '';

      if (await file.exists()) {
        final data =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        name = data['printer_name'] as String? ?? '';
      }

      if (name.isNotEmpty) {
        final controller = PrinterController(printerName: name);
        final ok = await controller.printTransaction(transactionData);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ok ? 'Print berhasil' : 'Gagal print')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Printer belum dikonfigurasi')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error print: $e')));
      }
    }
  }

  void _handleDownloadPdf() {
    _controller.downloadTodayTransactionsPdf(
      onSuccess: (filePath) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF berhasil diunduh: $filePath'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      onError: (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mengunduh PDF: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  void _toggleTransactionFilter() {
    _controller.toggleTransactionFilter().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Dashboard Transaksi BRILink',
        showSearch: false,
        actions: [
          IconButton(
            onPressed: _handleDownloadPdf,
            icon: const Icon(Icons.download, color: Colors.white),
            tooltip: 'Download PDF Transaksi Hari Ini',
          ),
          IconButton(
            onPressed: () {
              _loadAllData();
            },
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Data',
          ),
          IconButton(
            onPressed: _toggleTransactionFilter,
            icon: Icon(
              _controller.showOnlyTodayTransactions
                  ? Icons.calendar_today
                  : Icons.calendar_view_week,
              color: Colors.white,
            ),
            tooltip: _controller.showOnlyTodayTransactions
                ? 'Tampilkan Semua Transaksi'
                : 'Tampilkan Transaksi Hari Ini',
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  insetPadding: const EdgeInsets.all(16),
                  backgroundColor: Colors.transparent,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.4,
                      height: MediaQuery.of(context).size.height * 0.8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.briBlue, width: 2),
                      ),
                      child: PrinterSettingsPage(),
                    ),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.print, color: Colors.white),
            tooltip: 'Konfigurasi Printer',
          ),
        ],
        onLogout: () {
          Provider.of<AuthProvider>(context, listen: false).logout();
          Navigator.pushReplacementNamed(context, '/login');
        },
      ),
      body: Container(
        color: AppColors.briDarkBlue,
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary cards centered
              Container(
                height: 110,
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DashboardSummaryCard(
                          title: 'Transaksi Hari Ini',
                          value: _controller.isLoadingDashboard
                              ? '...'
                              : _controller
                                        .dashboard?['total_transactions_today']
                                        ?.toString() ??
                                    '0',
                          color: AppColors.briBlue,
                          icon: Icons.receipt_long,
                        ),
                        const SizedBox(width: 12),
                        DashboardSummaryCard(
                          title: 'Kas Tunai Keluar',
                          value: _controller.isLoadingDashboard
                              ? '...'
                              : CurrencyFormatter.formatCurrencyNoDecimals(
                                  _controller.dashboard?['cash_out_today'],
                                ),
                          color: AppColors.briDarkBlue,
                          icon: Icons.money_off,
                        ),
                        const SizedBox(width: 12),
                        DashboardSummaryCard(
                          title: 'Total Transfer via EDC',
                          value: _controller.isLoadingDashboard
                              ? '...'
                              : CurrencyFormatter.formatCurrencyNoDecimals(
                                  _controller
                                      .dashboard?['total_transfer_via_edc'],
                                ),
                          color: AppColors.briBlue,
                          icon: Icons.sync_alt,
                        ),
                        const SizedBox(width: 12),
                        // New card: Uang Tunai Masuk (sourced from /api/cashier/uangmasuk)
                        DashboardSummaryCard(
                          title: 'Uang Tunai Masuk',
                          value: _controller.isLoadingUangMasuk
                              ? '...'
                              : CurrencyFormatter.formatCurrencyNoDecimals(
                                  _controller.uangMasuk,
                                ),
                          color: AppColors.briBlue,
                          icon: Icons.attach_money,
                        ),
                        const SizedBox(width: 12),
                        DashboardSummaryCard(
                          title: 'Kas Tunai di Tangan',
                          value: _controller.isLoadingDashboard
                              ? '...'
                              : CurrencyFormatter.formatCurrencyNoDecimals(
                                  _controller.dashboard?['cash_on_hand'],
                                ),
                          color: AppColors.briBlue,
                          icon: Icons.account_balance_wallet,
                        ),
                        const SizedBox(width: 12),
                        DashboardSummaryCard(
                          title: 'Total Fee Hari Ini',
                          value: _controller.isLoadingDashboard
                              ? '...'
                              : CurrencyFormatter.formatCurrencyNoDecimals(
                                  _controller.dashboard?['total_fees_today'],
                                ),
                          color: AppColors.briBlue,
                          icon: Icons.paid,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Button to show transaction form modal
              Center(
                child: ElevatedButton.icon(
                  onPressed: _showTransactionFormModal,
                  icon: const Icon(Icons.add),
                  label: const Text('Buat Transaksi Baru'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.briBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Transaction List - Full width
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daftar Transaksi ${_controller.showOnlyTodayTransactions ? '(Hari Ini)' : '(Semua)'}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.briDarkBlue,
                    ),
                  ),
                  Text(
                    'Total: ${_controller.transactions.length} transaksi',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TransactionListWidget(
                transactions: _controller.transactions,
                isLoading: _controller.isLoadingTransactions,
              ),
              const SizedBox(height: 16),
              Text(
                'Saldo EDC per Bank',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.briDarkBlue,
                ),
              ),
              const SizedBox(height: 12),
              // Saldo EDC per Bank (responsive) with fallback when empty
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: (_controller.edcMachines.isNotEmpty
                    ? _controller.edcMachines.map((m) {
                        final rawBal =
                            m['saldo'] ?? m['current_balance'] ?? m['balance'];
                        final display =
                            CurrencyFormatter.formatCurrencyNoDecimals(rawBal);
                        return SizedBox(
                          width: 220,
                          child: BankBalanceCard(
                            title: (m['name'] ?? 'EDC').toString(),
                            balance: display,
                          ),
                        );
                      }).toList()
                    : [
                        SizedBox(
                          width: 220,
                          child: BankBalanceCard(
                            title: 'Mesin EDC tidak tersedia',
                            balance: 'Rp0',
                          ),
                        ),
                      ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
