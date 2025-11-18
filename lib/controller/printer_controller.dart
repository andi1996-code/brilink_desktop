import 'package:desktop_flutter_brilnik/services/windows_printer_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:esc_pos_utils/esc_pos_utils.dart';

class PrinterController {
  PrinterController({required this.printerName});

  final String printerName;

  Future<bool> printTest() async {
    try {
      final printer = WindowsEscPosPrinter(printerName: printerName);
      return await printer.printTestTicket();
    } catch (e, st) {
      debugPrint('PrinterController error: $e\n$st');
      return false;
    }
  }

  Future<bool> printTransaction(Map<String, dynamic> data) async {
    try {
      // Helper to parse dynamic values to int
      int toInt(dynamic v) {
        if (v is int) return v;
        if (v is num) return v.toInt();
        if (v is String) {
          final cleaned = v.replaceAll(RegExp(r'[^0-9\-]'), '');
          return int.tryParse(cleaned) ?? 0;
        }
        return 0;
      }

      // Format with thousand separators
      String fmt(int v) => v.toString().replaceAllMapped(
        RegExp(r"\B(?=(\d{3})+(?!\d))"),
        (m) => '.',
      );

      final amountVal = toInt(data['amount']);
      final bankFeeVal = toInt(data['bank_fee']);
      final serviceFeeVal = toInt(data['service_fee']);
      final extraFeeVal = toInt(data['extra_fee']);
      final printer = WindowsEscPosPrinter(printerName: printerName);
      final profile = await CapabilityProfile.load();
      final gen = Generator(PaperSize.mm58, profile);
      final bytes = <int>[];

      // Header with company name and spacing
      bytes.addAll(
        gen.text(
          'BRILINK',
          styles: PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          ),
        ),
      );
      bytes.addAll(
        gen.text(
          'TRANSAKSI',
          styles: PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          ),
        ),
      );
      bytes.addAll(gen.hr());

      // Informasi transaksi
      bytes.addAll(gen.text('NO TRANSAKSI', styles: PosStyles(bold: true)));
      bytes.addAll(gen.text('${data['transaction_number']}'));
      bytes.addAll(gen.text('TANGGAL', styles: PosStyles(bold: true)));
      String _fmtDateTime(dynamic v) {
        if (v is DateTime) {
          final d = v.toLocal();
          final parts = d.toIso8601String().split('T');
          return '${parts[0]} ${parts[1].split('.').first}';
        }
        if (v is String) {
          final dt = DateTime.tryParse(v);
          if (dt != null) {
            final d = dt.toLocal();
            final parts = d.toIso8601String().split('T');
            return '${parts[0]} ${parts[1].split('.').first}';
          }
          final m = RegExp(
            r'(\d{4}-\d{2}-\d{2}).*?(\d{2}:\d{2}:\d{2})',
          ).firstMatch(v);
          if (m != null) return '${m.group(1)} ${m.group(2)}';
          return v;
        }
        return v?.toString() ?? '';
      }

      bytes.addAll(gen.text(_fmtDateTime(data['created_at'])));
      bytes.addAll(gen.hr(ch: '-'));

      // Detail layanan
      bytes.addAll(
        gen.row([
          PosColumn(text: 'LAYANAN', width: 4, styles: PosStyles(bold: true)),
          PosColumn(
            text: '${data['service']?['name'] ?? '-'}',
            width: 8,
            styles: PosStyles(align: PosAlign.right),
          ),
        ]),
      );

      bytes.addAll(
        gen.row([
          PosColumn(text: 'MESIN EDC', width: 4, styles: PosStyles(bold: true)),
          PosColumn(
            text: '${data['edc_machine']?['name'] ?? '-'}',
            width: 8,
            styles: PosStyles(align: PosAlign.right),
          ),
        ]),
      );
      bytes.addAll(gen.hr(ch: '-'));

      // Section header
      bytes.addAll(
        gen.text(
          'RINCIAN BIAYA',
          styles: PosStyles(align: PosAlign.center, bold: true),
        ),
      );

      // Nominal
      bytes.addAll(
        gen.row([
          PosColumn(text: 'NOMINAL', width: 4, styles: PosStyles(bold: true)),
          PosColumn(
            text: 'Rp ${fmt(amountVal)}',
            width: 8,
            styles: PosStyles(align: PosAlign.right),
          ),
        ]),
      );

      // Biaya admin
      if (bankFeeVal > 0) {
        bytes.addAll(
          gen.row([
            PosColumn(
              text: 'ADMIN BANK',
              width: 4,
              styles: PosStyles(bold: true),
            ),
            PosColumn(
              text: 'Rp ${fmt(bankFeeVal)}',
              width: 8,
              styles: PosStyles(align: PosAlign.right),
            ),
          ]),
        );
      }

      // Biaya layanan
      if (serviceFeeVal > 0) {
        bytes.addAll(
          gen.row([
            PosColumn(text: 'LAYANAN', width: 4, styles: PosStyles(bold: true)),
            PosColumn(
              text: 'Rp ${fmt(serviceFeeVal)}',
              width: 8,
              styles: PosStyles(align: PosAlign.right),
            ),
          ]),
        );
      }

      // Biaya tambahan
      if (extraFeeVal > 0) {
        bytes.addAll(
          gen.row([
            PosColumn(
              text: 'TAMBAHAN',
              width: 4,
              styles: PosStyles(bold: true),
            ),
            PosColumn(
              text: 'Rp ${fmt(extraFeeVal)}',
              width: 8,
              styles: PosStyles(align: PosAlign.right),
            ),
          ]),
        );
      }

      // (Removed extra spacing)
      bytes.addAll(gen.hr(ch: '='));

      // Total
      final total = amountVal + bankFeeVal + serviceFeeVal + extraFeeVal;
      bytes.addAll(
        gen.row([
          PosColumn(
            text: 'TOTAL',
            width: 4,
            styles: PosStyles(bold: true, height: PosTextSize.size2),
          ),
          PosColumn(
            text: 'Rp ${fmt(total)}',
            width: 8,
            styles: PosStyles(
              align: PosAlign.right,
              bold: true,
              height: PosTextSize.size2,
            ),
          ),
        ]),
      );
      // Reduce final feed to one line
      bytes.addAll(gen.feed(1));

      // Informasi pelanggan
      bytes.addAll(
        gen.text(
          'INFORMASI PELANGGAN',
          styles: PosStyles(align: PosAlign.center, bold: true),
        ),
      );
      bytes.addAll(
        gen.row([
          PosColumn(text: 'NAMA', width: 4, styles: PosStyles(bold: true)),
          PosColumn(
            text: '${data['customer_name'] ?? '-'}',
            width: 8,
            styles: PosStyles(align: PosAlign.right),
          ),
        ]),
      );

      if (data['reference_number'] != null &&
          data['reference_number'].toString().isNotEmpty) {
        final ref = data['reference_number'].toString();
        final displayRef = ref.length > 6 ? '${ref.substring(0, 6)}.....' : ref;
        bytes.addAll(
          gen.row([
            PosColumn(
              text: 'NO. TUJUAN',
              width: 4,
              styles: PosStyles(bold: true),
            ),
            PosColumn(
              text: displayRef,
              width: 8,
              styles: PosStyles(align: PosAlign.right),
            ),
          ]),
        );
      }

      bytes.addAll(
        gen.row([
          PosColumn(text: 'KASIR', width: 4, styles: PosStyles(bold: true)),
          PosColumn(
            text: '${data['user']?['name'] ?? 'System'}',
            width: 8,
            styles: PosStyles(align: PosAlign.right),
          ),
        ]),
      );
      bytes.addAll(gen.hr());

      // Footer
      bytes.addAll(
        gen.text(
          'TERIMA KASIH',
          styles: PosStyles(align: PosAlign.center, bold: true),
        ),
      );
      bytes.addAll(
        gen.text(
          'PASTIKAN MENGHITUNG ULANG',
          styles: PosStyles(align: PosAlign.center),
        ),
      );
      bytes.addAll(gen.cut());

      return printer.printBytes(Uint8List.fromList(bytes));
    } catch (e, st) {
      debugPrint('Print transaction error: $e\n$st');
      return false;
    }
  }
}
