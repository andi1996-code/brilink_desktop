import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

/// Provider for managing BRILink transactions via API
class TransactionProvider extends ChangeNotifier {
  final ApiService apiService;

  TransactionProvider({ApiService? service})
    : apiService = service ?? ApiService();

  List<dynamic> transactions = [];
  bool isLoading = false;
  String? error;

  /// Fetch transactions from API
  Future<void> loadTransactions() async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await apiService.fetchTransactions();
      transactions = response.data as List<dynamic>;
      error = null;
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  /// Create a new transaction via API
  Future<void> addTransaction({
    required int edcMachineId,
    required int serviceId,
    required int amount,
    required double extraFee,
    String? targetNumber,
    String? referenceNumber,
    String? customerName,
    String? token,
  }) async {
    try {
      await apiService.createTransaction(
        edcMachineId: edcMachineId,
        serviceId: serviceId,
        amount: amount,
        extraFee: extraFee,
        targetNumber: targetNumber,
        referenceNumber: referenceNumber,
        customerName: customerName,
        token: token,
      );
      await loadTransactions();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }
}
