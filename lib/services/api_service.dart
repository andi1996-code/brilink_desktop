import 'package:dio/dio.dart';

/// ApiService handles network requests using Dio.
class ApiService {
  late final Dio _dio;

  /// Initialize dengan baseUrl yang wajib diberikan
  /// Base URL akan selalu dinamis dari login form atau session
  ApiService({String? baseUrl}) {
    final url = baseUrl ?? 'temp://placeholder';
    _dio = Dio(
      BaseOptions(
        baseUrl: url,
        connectTimeout: Duration(seconds: 10), // increased timeout
        receiveTimeout: Duration(seconds: 10),
      ),
    );
  }

  /// Update base URL for existing instance
  void updateBaseUrl(String newBaseUrl) {
    _dio.options.baseUrl = newBaseUrl;
  }

  /// Get current base URL for debugging
  String get currentBaseUrl => _dio.options.baseUrl;

  /// Example: fetch transactions list
  Future<Response> fetchTransactions({
    String? token,
    int limit = 20,
    int offset = 0,
  }) async {
    final options = token != null
        ? Options(
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
        : Options(headers: {'Accept': 'application/json'});
    return _dio.get(
      '/api/transactions',
      queryParameters: {'limit': limit, 'offset': offset},
      options: options,
    );
  }

  /// Create a new transaction
  /// POST /api/transactions
  Future<Response> createTransaction({
    required int edcMachineId,
    required int serviceId,
    required int amount,
    required double extraFee,
    String? targetNumber,
    String? referenceNumber,
    String? customerName,
    String? cashierName,
    String? token,
  }) async {
    final options = Options(
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    final data = {
      'edc_machine_id': edcMachineId,
      'service_id': serviceId,
      'amount': amount,
      'extra_fee': extraFee,
      if (targetNumber != null && targetNumber.isNotEmpty)
        'target_number': targetNumber,
      if (referenceNumber != null && referenceNumber.isNotEmpty)
        'reference_number': referenceNumber,
      if (customerName != null && customerName.isNotEmpty)
        'customer_name': customerName,
      if (cashierName != null && cashierName.isNotEmpty)
        'user_name': cashierName,
    };

    return _dio.post('/api/transactions', data: data, options: options);
  }

  /// Authenticate user login
  Future<Response> login(
    String email,
    String password, {
    String? authToken,
  }) async {
    final options = Options(
      headers: {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      },
    );
    return _dio.post(
      '/api/auth/login',
      data: {'email': email, 'password': password},
      options: options,
    );
  }

  /// Fetch list of EDC machines, with optional Bearer token for auth
  Future<Response> fetchEdcMachines({String? token}) async {
    final options = token != null
        ? Options(
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
        : Options(headers: {'Accept': 'application/json'});

    return _dio.get('/api/edc-machines', options: options);
  }

  /// Fetch available services from the backend
  Future<Response> fetchServices({String? token}) async {
    final options = token != null
        ? Options(headers: {'Authorization': 'Bearer $token'})
        : null;
    return _dio.get('/api/services', options: options);
  }

  /// Fetch service fees list
  Future<Response> fetchServiceFees({String? token}) async {
    final options = token != null
        ? Options(
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
        : Options(headers: {'Accept': 'application/json'});
    return _dio.get('/api/service-fees', options: options);
  }

  /// Fetch bank fees list
  Future<Response> fetchBankFees({String? token}) async {
    final options = token != null
        ? Options(
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
        : Options(headers: {'Accept': 'application/json'});
    return _dio.get('/api/bank-fees', options: options);
  }

  /// Logout endpoint - POST /api/logout (Accept: application/json)
  Future<Response> logout({String? token}) async {
    final options = Options(
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    return _dio.post('/api/logout', options: options);
  }

  /// Calculate service and bank fees for a given service, amount and EDC machine
  /// Example: /api/services/{serviceId}/calculate-fee?amount=123000&edc_machine_id=2&service_id=1
  Future<Response> calculateFee({
    required dynamic serviceId,
    required int amount,
    dynamic edcMachineId,
    String? token,
  }) async {
    final options = Options(
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    final query = <String, dynamic>{
      'amount': amount,
      if (edcMachineId != null) 'edc_machine_id': edcMachineId,
      if (serviceId != null) 'service_id': serviceId,
    };
    final path = '/api/services/$serviceId/calculate-fee';
    return _dio.get(path, queryParameters: query, options: options);
  }

  /// Fetch uang masuk (transfer only) for the cashier dashboard
  Future<Response> fetchUangMasuk({String? token}) async {
    final options = token != null
        ? Options(
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
        : Options(headers: {'Accept': 'application/json'});
    return _dio.get('/api/cashier/uangmasuk', options: options);
  }

  /// Fetch dashboard cashier summary
  Future<Response> fetchDashboardCashier({String? token}) async {
    final options = token != null
        ? Options(
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
        : Options(headers: {'Accept': 'application/json'});
    return _dio.get('/api/dashboard/cashier', options: options);
  }

  /// Fetch cashier transactions for today only
  /// GET /api/dashboard/cashier-transactions
  Future<Response> fetchCashierTransactions({String? token}) async {
    final options = token != null
        ? Options(
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
        : Options(headers: {'Accept': 'application/json'});
    return _dio.get('/api/dashboard/cashier-transactions', options: options);
  }

  /// Download today's transactions as PDF
  /// GET /api/transactions/report/daily/pdf
  Future<Response> downloadTodayTransactionsPdf({String? token}) async {
    final options = token != null
        ? Options(
            headers: {
              'Accept': 'application/pdf',
              'Authorization': 'Bearer $token',
            },
            responseType: ResponseType.bytes, // Important for binary data
          )
        : Options(
            headers: {'Accept': 'application/pdf'},
            responseType: ResponseType.bytes,
          );
    return _dio.get('/api/transactions/report/daily/pdf', options: options);
  }

  /// Fetch today's transactions
  /// GET /api/transactions/today
  Future<Response> fetchTodayTransactions({String? token}) async {
    final options = token != null
        ? Options(
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
        : Options(headers: {'Accept': 'application/json'});
    return _dio.get('/api/transactions/today', options: options);
  }

  // Add other API methods as needed
}
