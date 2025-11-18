class CurrencyFormatter {
  /// Format number with thousand separator (dots)
  static String formatNumberNoDecimals(double value) {
    final intVal = value.round();
    final s = intVal.toString();
    // insert dot as thousand separator
    return s.replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => '.');
  }

  /// Parse numeric value from JSON fields and drop any fractional part (remove .00)
  static double parseAmountWithoutDecimals(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble().roundToDouble();
    var s = v.toString();

    // Handle different decimal/thousand separator patterns
    if (s.contains('.')) {
      // Check if the dot is likely a decimal separator (2-3 digits after last dot)
      final parts = s.split('.');
      final lastPart = parts.last;

      if (lastPart.length <= 3 && parts.length == 2) {
        // Likely decimal separator (e.g., "1900.00" or "1900.5")
        // Drop the decimal part
        s = parts.first;
      } else {
        // Likely thousand separators (e.g., "1.900.000" or multiple dots)
        // Remove all dots
        s = s.replaceAll('.', '');
      }
    }

    // If has comma as decimal separator, drop fractional part
    if (s.contains(',')) {
      s = s.split(',').first;
    }

    // keep only digits and optional minus
    s = s.replaceAll(RegExp(r'[^0-9\-]'), '');
    return double.tryParse(s) ?? 0.0;
  }

  /// Format any dynamic amount as Rupiah without decimals
  static String formatCurrencyNoDecimals(dynamic v) {
    final amount = parseAmountWithoutDecimals(v).round();
    final s = amount.toString();
    final formatted = s.replaceAllMapped(
      RegExp(r"\B(?=(\d{3})+(?!\d))"),
      (m) => '.',
    );
    return 'Rp$formatted';
  }

  /// Parse Rupiah string back to integer
  static int parseRpToInt(String s) {
    final cleaned = s.replaceAll('Rp', '').replaceAll('.', '');
    return int.tryParse(cleaned) ?? 0;
  }
}
