import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../utils/currency_formatter.dart';

class TransactionController {
  final BuildContext context;
  late final ApiService _api;

  bool get _isMounted {
    try {
      return context.mounted;
    } catch (e) {
      return false;
    }
  }

  // Data lists
  List<Map<String, dynamic>> edcMachines = [];
  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> serviceFees = [];
  List<Map<String, dynamic>> bankFees = [];
  Map<String, dynamic>? dashboard;

  // Pagination info
  int transactionsTotal = 0;
  int transactionsLimit = 20;
  int transactionsOffset = 0;

  // Loading states
  bool isLoadingMachines = true;
  bool isLoadingServices = true;
  bool isLoadingTransactions = true;
  bool isLoadingDashboard = true;
  bool isLoadingServiceFees = true;
  bool isLoadingBankFees = true;

  // Form data
  String selectedMachine = '-- Pilih Mesin --';
  String selectedService = '-- Pilih Layanan --';
  dynamic selectedMachineId;
  String serviceFeeDisplay = 'Rp0';
  String bankFeeDisplay = 'Rp0';

  // Formatting flags
  bool isFormattingNominal = false;
  bool isFormattingServiceFee = false;
  bool isFormattingBankFee = false;

  // Debounce timer
  Timer? _debounceTimer;

  // Controllers
  final nominalController = TextEditingController(text: '0');
  final tambahanController = TextEditingController(text: '0');
  final customerNameController = TextEditingController();
  final destinationNumberController = TextEditingController();
  final keteranganController = TextEditingController();
  final serviceFeeController = TextEditingController(text: '0');
  final bankFeeController = TextEditingController(text: '0');
  final totalFeesController = TextEditingController(text: 'Rp0');

  // Filter state
  bool showOnlyTodayTransactions = true;

  TransactionController(this.context) {
    // Gunakan ApiService dari AuthProvider yang sudah ter-update base URL-nya
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _api = authProvider.apiService;
  }

  void dispose() {
    _debounceTimer?.cancel();
    nominalController.dispose();
    tambahanController.dispose();
    customerNameController.dispose();
    destinationNumberController.dispose();
    keteranganController.dispose();
    serviceFeeController.dispose();
    bankFeeController.dispose();
    totalFeesController.dispose();
  }

  Future<void> loadEdcMachines() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.ensureSessionLoaded();

      final token = authProvider.token;
      final resp = await _api.fetchEdcMachines(token: token);
      final responseData = resp.data;

      List<dynamic> list = [];

      if (responseData is List) {
        list = responseData;
      } else if (responseData is Map) {
        if (responseData['data'] is List) {
          list = responseData['data'] as List<dynamic>;
        } else if (responseData['success'] == true &&
            responseData['data'] is List) {
          list = responseData['data'] as List<dynamic>;
        }
      }

      edcMachines = list.map((e) {
        if (e is Map) {
          return Map<String, dynamic>.from(e.cast<String, dynamic>());
        }
        return {'name': e.toString()};
      }).toList();
    } catch (e) {
      edcMachines = [];
    }

    isLoadingMachines = false;
  }

  Future<void> loadServices() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.ensureSessionLoaded();

      final token = authProvider.token;
      final resp = await _api.fetchServices(token: token);
      final responseData = resp.data;

      List<dynamic> list = [];

      if (responseData is List) {
        list = responseData;
      } else if (responseData is Map) {
        if (responseData['data'] is List) {
          list = responseData['data'] as List<dynamic>;
        }
      }

      services = list.map((e) {
        if (e is Map) {
          return Map<String, dynamic>.from(e.cast<String, dynamic>());
        }
        return {'name': e.toString()};
      }).toList();
    } catch (e) {
      // Silent error handling
    }

    isLoadingServices = false;
  }

  Future<void> loadServiceFees() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.ensureSessionLoaded();

      final token = authProvider.token;
      final resp = await _api.fetchServiceFees(token: token);
      final responseData = resp.data;

      List<dynamic> list = [];

      if (responseData is List) {
        list = responseData;
      } else if (responseData is Map && responseData['data'] is List) {
        list = responseData['data'] as List<dynamic>;
      }

      serviceFees = list.map((e) {
        if (e is Map) {
          return Map<String, dynamic>.from(e.cast<String, dynamic>());
        }
        return <String, dynamic>{};
      }).toList();
    } catch (e) {
      serviceFees = [];
    }

    isLoadingServiceFees = false;
  }

  Future<void> loadBankFees() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.ensureSessionLoaded();

      final token = authProvider.token;
      final resp = await _api.fetchBankFees(token: token);
      final responseData = resp.data;

      List<dynamic> list = [];

      if (responseData is List) {
        list = responseData;
      } else if (responseData is Map && responseData['data'] is List) {
        list = responseData['data'] as List<dynamic>;
      }

      bankFees = list.map((e) {
        if (e is Map) {
          return Map<String, dynamic>.from(e.cast<String, dynamic>());
        }
        return <String, dynamic>{};
      }).toList();
    } catch (e) {
      bankFees = [];
    }

    isLoadingBankFees = false;
  }

  Future<void> loadTransactions() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.ensureSessionLoaded();

      final token = authProvider.token;
      final resp = await _api.fetchTransactions(
        token: token,
        limit: 50,
        offset: 0,
      );

      final responseData = resp.data;
      List<dynamic> list = [];

      if (responseData is Map) {
        if (responseData.containsKey('data') && responseData['data'] is Map) {
          final data = responseData['data'] as Map<String, dynamic>;
          if (data.containsKey('transactions') &&
              data['transactions'] is List) {
            list = data['transactions'] as List<dynamic>;
            transactionsTotal = data['total'] ?? 0;
            transactionsLimit = data['limit'] ?? 50;
            transactionsOffset = data['offset'] ?? 0;
          }
        } else if (responseData.containsKey('transactions') &&
            responseData['transactions'] is List) {
          list = responseData['transactions'] as List<dynamic>;
          transactionsTotal = responseData['total'] ?? 0;
          transactionsLimit = responseData['limit'] ?? 50;
          transactionsOffset = responseData['offset'] ?? 0;
        }
      } else if (responseData is List) {
        list = responseData;
      }

      transactions = list.map((e) {
        if (e is Map) {
          final txn = Map<String, dynamic>.from(e.cast<String, dynamic>());

          final edcId = txn['edc_machine_id'];
          final edcMatch = edcMachines.firstWhere(
            (m) => m['id'] == edcId,
            orElse: () => <String, dynamic>{},
          );
          final edcName = edcMatch.isNotEmpty
              ? (edcMatch['name']?.toString() ?? 'Unknown')
              : 'EDC $edcId';

          final svcId = txn['service_id'];
          final svcMatch = services.firstWhere(
            (s) => s['id'] == svcId,
            orElse: () => <String, dynamic>{},
          );
          final svcName = svcMatch.isNotEmpty
              ? (svcMatch['name']?.toString() ?? 'Unknown')
              : 'Service $svcId';

          txn['edc_machine'] = {'id': edcId, 'name': edcName};
          txn['service'] = {'id': svcId, 'name': svcName};

          return txn;
        }
        return <String, dynamic>{};
      }).toList();
    } catch (e) {
      // Silent error handling
    }

    isLoadingTransactions = false;
  }

  /// Load only today's transactions for the cashier
  Future<void> loadTodayTransactions() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.ensureSessionLoaded();

      final token = authProvider.token;
      final resp = await _api.fetchTodayTransactions(token: token);
      final responseData = resp.data;

      List<dynamic> list = [];

      if (responseData is Map) {
        if (responseData.containsKey('data') && responseData['data'] is Map) {
          final dataMap = responseData['data'] as Map<String, dynamic>;
          if (dataMap.containsKey('transactions') &&
              dataMap['transactions'] is List) {
            list = dataMap['transactions'] as List<dynamic>;
          }
        } else if (responseData.containsKey('transactions') &&
            responseData['transactions'] is List) {
          list = responseData['transactions'] as List<dynamic>;
        }
      } else if (responseData is List) {
        list = responseData;
      }

      transactions = list.map((e) {
        if (e is Map) {
          final txn = Map<String, dynamic>.from(e.cast<String, dynamic>());

          final edcId = txn['edc_machine_id'];
          final edcMatch = edcMachines.firstWhere(
            (m) => m['id'] == edcId,
            orElse: () => <String, dynamic>{},
          );
          final edcName = edcMatch.isNotEmpty
              ? (edcMatch['name']?.toString() ?? 'Unknown')
              : 'EDC $edcId';

          final svcId = txn['service_id'];
          final svcMatch = services.firstWhere(
            (s) => s['id'] == svcId,
            orElse: () => <String, dynamic>{},
          );
          final svcName = svcMatch.isNotEmpty
              ? (svcMatch['name']?.toString() ?? 'Unknown')
              : 'Service $svcId';

          txn['edc_machine'] = {'id': edcId, 'name': edcName};
          txn['service'] = {'id': svcId, 'name': svcName};

          return txn;
        }
        return <String, dynamic>{};
      }).toList();

      debugPrint('Loaded ${transactions.length} today transactions');
    } catch (e) {
      transactions = [];
    }

    isLoadingTransactions = false;
  }

  Future<void> loadDashboard() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.ensureSessionLoaded();

      final token = authProvider.token;
      final resp = await _api.fetchDashboardCashier(token: token);
      final data = resp.data;

      if (data is Map<String, dynamic>) {
        // Extract the actual dashboard data from the 'data' key
        if (data.containsKey('data') && data['data'] is Map) {
          dashboard = data['data'] as Map<String, dynamic>;
        } else {
          dashboard = data;
        }
      }
    } catch (e) {
      // Silent error handling - dashboard error won't block other features
    }

    isLoadingDashboard = false;
    // Notify UI to update
    if (_isMounted) {
      // This will trigger a rebuild in the UI
    }
  }

  void onNominalInput(VoidCallback onStateChanged) {
    if (isFormattingNominal) return;
    final raw = nominalController.text;
    // keep only digits
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      isFormattingNominal = true;
      nominalController.text = '0';
      nominalController.selection = TextSelection.collapsed(
        offset: nominalController.text.length,
      );
      isFormattingNominal = false;
      debouncedComputeServiceFee(onStateChanged);
      return;
    }
    final value = double.tryParse(digits) ?? 0.0;
    final formatted = CurrencyFormatter.formatNumberNoDecimals(value);
    isFormattingNominal = true;
    nominalController.text = formatted;
    nominalController.selection = TextSelection.collapsed(
      offset: nominalController.text.length,
    );
    isFormattingNominal = false;
    debouncedComputeServiceFee(onStateChanged);
  }

  void onTambahanInput(VoidCallback onStateChanged) {
    // Only trigger recalculation if we have valid service and nominal
    final raw = nominalController.text;
    final cleaned = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final nominal = double.tryParse(cleaned) ?? 0.0;

    final service = services.firstWhere(
      (s) => (s['name'] ?? '').toString() == selectedService,
      orElse: () => {},
    );

    if (service.isNotEmpty && nominal > 0) {
      debouncedComputeServiceFee(onStateChanged);
    } else {
      // Just update total biaya without calling API
      updateTotalBiaya();
      if (_isMounted) {
        onStateChanged();
      }
    }
  }

  void onServiceFeeInput(VoidCallback onStateChanged) {
    if (isFormattingServiceFee) return;
    final raw = serviceFeeController.text;
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      isFormattingServiceFee = true;
      serviceFeeController.text = '0';
      serviceFeeController.selection = TextSelection.collapsed(
        offset: serviceFeeController.text.length,
      );
      isFormattingServiceFee = false;
      updateTotalBiaya();
      if (_isMounted) {
        onStateChanged();
      }
      return;
    }
    final value = double.tryParse(digits) ?? 0.0;
    final formatted = CurrencyFormatter.formatNumberNoDecimals(value);
    isFormattingServiceFee = true;
    serviceFeeController.text = formatted;
    serviceFeeController.selection = TextSelection.collapsed(
      offset: serviceFeeController.text.length,
    );
    isFormattingServiceFee = false;
    updateTotalBiaya();
    if (_isMounted) {
      onStateChanged();
    }
  }

  void onBankFeeInput(VoidCallback onStateChanged) {
    if (isFormattingBankFee) return;
    final raw = bankFeeController.text;
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      isFormattingBankFee = true;
      bankFeeController.text = '0';
      bankFeeController.selection = TextSelection.collapsed(
        offset: bankFeeController.text.length,
      );
      isFormattingBankFee = false;
      updateTotalBiaya();
      if (_isMounted) {
        onStateChanged();
      }
      return;
    }
    final value = double.tryParse(digits) ?? 0.0;
    final formatted = CurrencyFormatter.formatNumberNoDecimals(value);
    isFormattingBankFee = true;
    bankFeeController.text = formatted;
    bankFeeController.selection = TextSelection.collapsed(
      offset: bankFeeController.text.length,
    );
    isFormattingBankFee = false;
    updateTotalBiaya();
    if (_isMounted) {
      onStateChanged();
    }
  }

  void updateTotalBiaya() {
    // Parse current values - use consistent parsing for all fields
    final raw = nominalController.text;
    final cleaned = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final nominal = double.tryParse(cleaned) ?? 0.0;

    final extraRaw = tambahanController.text;
    final extraCleaned = extraRaw.replaceAll(RegExp(r'[^0-9]'), '');
    final extraFee = double.tryParse(extraCleaned) ?? 0.0;

    // Parse fees using same method as nominal (remove all non-digits)
    final serviceFeeRaw = serviceFeeController.text;
    final serviceFeeDigits = serviceFeeRaw.replaceAll(RegExp(r'[^0-9]'), '');
    final serviceFeeNum = double.tryParse(serviceFeeDigits) ?? 0.0;

    final bankFeeRaw = bankFeeController.text;
    final bankFeeDigits = bankFeeRaw.replaceAll(RegExp(r'[^0-9]'), '');
    final bankFeeNum = double.tryParse(bankFeeDigits) ?? 0.0;

    final totalNum = nominal + bankFeeNum + serviceFeeNum + extraFee;

    // Only update controller - no need for separate display variable
    totalFeesController.text = CurrencyFormatter.formatCurrencyNoDecimals(
      totalNum,
    );
  }

  void debouncedComputeServiceFee(VoidCallback onStateChanged) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      computeServiceFee(onStateChanged);
    });
  }

  void onServiceChanged(String? v, VoidCallback onStateChanged) {
    if (v == null) return;
    selectedService = v;
    if (_isMounted) {
      onStateChanged();
    }
    debouncedComputeServiceFee(onStateChanged);
  }

  void onMachineChanged(String? v, VoidCallback onStateChanged) {
    if (v == null) return;
    selectedMachine = v;
    final found = edcMachines.firstWhere(
      (m) => (m['name'] ?? '').toString() == v,
      orElse: () => <String, dynamic>{},
    );
    selectedMachineId = found.isNotEmpty ? found['id'] : null;
    if (_isMounted) {
      onStateChanged();
    }
    debouncedComputeServiceFee(onStateChanged);
  }

  Future<void> computeServiceFee(VoidCallback onStateChanged) async {
    // Cancel any previous debounce timer
    _debounceTimer?.cancel();

    // parse nominal safely (remove dots and non-digits)
    final raw = nominalController.text;
    final cleaned = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final nominal = double.tryParse(cleaned) ?? 0.0;

    // find service id by name
    final service = services.firstWhere(
      (s) => (s['name'] ?? '').toString() == selectedService,
      orElse: () => <String, dynamic>{},
    );

    // require a valid service selection and a positive nominal to call server
    if (service.isEmpty || nominal <= 0) {
      // Reset fees when no valid service/nominal
      serviceFeeDisplay = 'Rp0';
      bankFeeDisplay = 'Rp0';

      // Update controllers
      serviceFeeController.text = '0';
      bankFeeController.text = '0';

      // Use updateTotalBiaya for consistent calculation
      updateTotalBiaya();

      // Safe state change - check if context is still mounted
      if (_isMounted) {
        try {
          onStateChanged();
        } catch (e) {
          debugPrint('setState error ignored: $e');
        }
      }
      return;
    }

    final serviceId = service['id'];

    // Calculate fees based on loaded service fees and bank fees
    double serviceFeeAmount = 0.0;
    double bankFeeAmount = 0.0;

    // Find matching service fee based on service_id and amount range
    for (final sf in serviceFees) {
      if (sf['service_id'] == serviceId) {
        final minAmount = (sf['min_amount'] as num?)?.toDouble() ?? 0.0;
        final maxAmount =
            (sf['max_amount'] as num?)?.toDouble() ?? double.infinity;

        if (nominal >= minAmount && nominal <= maxAmount) {
          serviceFeeAmount = (sf['fee'] as num?)?.toDouble() ?? 0.0;
          break;
        }
      }
    }

    // Find matching bank fee based on service_id and edc_machine_id
    if (selectedMachineId != null) {
      for (final bf in bankFees) {
        if (bf['service_id'] == serviceId &&
            bf['edc_machine_id'] == selectedMachineId) {
          bankFeeAmount = (bf['fee'] as num?)?.toDouble() ?? 0.0;
          break;
        }
      }
    }

    // Format the fees
    final serviceFeeFormatted = CurrencyFormatter.formatNumberNoDecimals(
      serviceFeeAmount,
    );
    final bankFeeFormatted = CurrencyFormatter.formatNumberNoDecimals(
      bankFeeAmount,
    );

    // Update state
    serviceFeeDisplay = 'Rp$serviceFeeFormatted';
    bankFeeDisplay = 'Rp$bankFeeFormatted';
    serviceFeeController.text = serviceFeeFormatted;
    bankFeeController.text = bankFeeFormatted;

    // Use updateTotalBiaya for consistent calculation
    updateTotalBiaya();

    // Safe state change - check if context is still mounted
    if (_isMounted) {
      try {
        onStateChanged();
      } catch (e) {
        debugPrint('setState error ignored: $e');
      }
    }
  }

  void resetForm(VoidCallback onStateChanged) {
    selectedMachine = '-- Pilih Mesin --';
    selectedService = '-- Pilih Layanan --';
    selectedMachineId = null;
    nominalController.text = '0';
    tambahanController.text = '0';
    customerNameController.clear();
    destinationNumberController.clear();
    keteranganController.clear();
    serviceFeeDisplay = 'Rp0';
    bankFeeDisplay = 'Rp0';

    // Reset fee controllers (editable numeric values)
    serviceFeeController.text = '0';
    bankFeeController.text = '0';
    totalFeesController.text = 'Rp0';

    if (_isMounted) {
      onStateChanged();
    }
  }

  Future<void> createTransaction({
    required VoidCallback onSuccess,
    required Function(String) onError,
    required Function(Map<String, dynamic>) onPrintCallback,
  }) async {
    try {
      // Validate required fields
      if (selectedMachine == '-- Pilih Mesin --') {
        onError('Pilih mesin EDC terlebih dahulu');
        return;
      }

      if (selectedService == '-- Pilih Layanan --') {
        onError('Pilih jenis layanan terlebih dahulu');
        return;
      }

      // Parse nominal
      final raw = nominalController.text;
      final cleaned = raw.replaceAll(RegExp(r'[^0-9]'), '');
      final nominal = double.tryParse(cleaned) ?? 0.0;

      if (nominal <= 0) {
        onError('Masukkan nominal yang valid');
        return;
      }

      // Parse extra fee (biaya tambahan)
      final extraRaw = tambahanController.text;
      final extraCleaned = extraRaw.replaceAll(RegExp(r'[^0-9]'), '');
      final extraFee = double.tryParse(extraCleaned) ?? 0.0;

      // Get service and machine IDs
      final service = services.firstWhere(
        (s) => (s['name'] ?? '').toString() == selectedService,
        orElse: () => {},
      );

      if (service.isEmpty) {
        onError('Service tidak ditemukan');
        return;
      }

      final serviceId = service['id'];
      final machineId = selectedMachineId;

      if (machineId == null) {
        onError('Mesin EDC tidak ditemukan');
        return;
      }

      // Parse fees using same method as updateTotalBiaya (remove all non-digits)
      final serviceFeeRaw = serviceFeeController.text;
      final serviceFeeDigits = serviceFeeRaw.replaceAll(RegExp(r'[^0-9]'), '');
      final serviceFeeNum = double.tryParse(serviceFeeDigits) ?? 0.0;

      final bankFeeRaw = bankFeeController.text;
      final bankFeeDigits = bankFeeRaw.replaceAll(RegExp(r'[^0-9]'), '');
      final bankFeeNum = double.tryParse(bankFeeDigits) ?? 0.0;

      // Get auth data
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final cashierName =
          authProvider.user?['name'] ??
          authProvider.user?['username'] ??
          'Cashier';

      final resp = await _api.createTransaction(
        edcMachineId: machineId,
        serviceId: serviceId,
        amount: nominal.toInt(),
        extraFee: extraFee,
        targetNumber: destinationNumberController.text.trim(),
        referenceNumber: null, // Let server generate this
        customerName: customerNameController.text.trim(),
        cashierName: cashierName,
        token: token,
      );

      // Prepare complete transaction data for success callback
      final transactionData = resp.data;

      // Parse response data structure
      Map<String, dynamic> actualData = {};
      if (transactionData is Map) {
        if (transactionData.containsKey('data')) {
          actualData = transactionData['data'] as Map<String, dynamic>;
        } else {
          actualData = Map<String, dynamic>.from(transactionData);
        }
      }

      final totalAmount = nominal + serviceFeeNum + bankFeeNum + extraFee;

      final completeTransactionData = Map<String, dynamic>.from({
        ...actualData,
        'amount': nominal.toInt(),
        'service_fee': serviceFeeNum.toInt(),
        'bank_fee': bankFeeNum.toInt(),
        'extra_fee': extraFee.toInt(),
        'customer_name': customerNameController.text.trim(),
        'target_number': destinationNumberController.text.trim(),
        'reference_number': actualData['reference_number'] ?? '',
        'created_at':
            actualData['created_at'] ?? DateTime.now().toIso8601String(),
        'service': {'name': selectedService},
        'edc_machine': {'name': selectedMachine},
        'user': authProvider.user ?? {'name': 'Cashier'},
        'transaction_number': actualData['transaction_number'] ?? '',
        'total_amount': totalAmount.toInt(),
        'total_amount_formatted': CurrencyFormatter.formatCurrencyNoDecimals(
          totalAmount.toInt(),
        ),
      });

      onPrintCallback(completeTransactionData);
      onSuccess();
    } catch (e) {
      // Extract error message from response
      String errorMessage = 'Gagal membuat transaksi';
      if (e is DioException && e.response?.data is Map) {
        final responseData = e.response?.data as Map<String, dynamic>;
        errorMessage =
            responseData['message'] ??
            responseData['error'] ??
            'Gagal membuat transaksi (${e.response?.statusCode})';
      }
      onError(errorMessage);
    }
  }

  /// Download today's transactions as PDF
  Future<void> downloadTodayTransactionsPdf({
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final resp = await _api.downloadTodayTransactionsPdf(token: token);

      if (resp.data != null) {
        // Get downloads directory
        final directory =
            await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();

        // Create filename with today's date
        final now = DateTime.now();
        final dateStr =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final fileName = 'transaksi_hari_ini_$dateStr.pdf';
        final filePath = '${directory.path}/$fileName';

        // Write PDF bytes to file
        final file = File(filePath);
        final bytes = resp.data as Uint8List;
        await file.writeAsBytes(bytes);

        onSuccess(filePath);
      } else {
        onError('Gagal mengunduh PDF: Data kosong');
      }
    } catch (e) {
      onError('Gagal mengunduh PDF: $e');
    }
  }

  /// Toggle between showing all transactions or only today's transactions
  Future<void> toggleTransactionFilter() async {
    showOnlyTodayTransactions = !showOnlyTodayTransactions;
    isLoadingTransactions = true;

    if (showOnlyTodayTransactions) {
      await loadTodayTransactions();
    } else {
      await loadTransactions();
    }
  }
}
