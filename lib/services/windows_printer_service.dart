import 'dart:ffi';
import 'dart:typed_data';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:win32/win32.dart';
import 'package:ffi/ffi.dart';

/// Service untuk mencetak data ESC/POS di Windows menggunakan Win32 API.
class WindowsEscPosPrinter {
  WindowsEscPosPrinter({required this.printerName});

  /// Nama printer persis seperti di Control Panel (Devices & Printers)
  final String printerName;

  /// Contoh print sederhana. Kembalikan true jika sukses, false jika gagal.
  Future<bool> printTestTicket() async {
    try {
      final profile = await CapabilityProfile.load();
      final gen = Generator(PaperSize.mm58, profile);

      final bytes = <int>[];
      bytes.addAll(
        gen.text(
          '=== TEST PRINT ===',
          styles: PosStyles(bold: true, align: PosAlign.center),
        ),
      );
      bytes.addAll(gen.text('Tanggal: ${DateTime.now()}'));
      bytes.addAll(
        gen.text('Terima kasih!', styles: PosStyles(align: PosAlign.center)),
      );
      bytes.addAll(gen.cut());

      return _printRaw(Uint8List.fromList(bytes));
    } catch (e, st) {
      debugPrint('Print error: $e\n$st');
      return false;
    }
  }

  /// Cetak bytes mentah (RAW). Mengembalikan true jika berhasil.
  bool printBytes(Uint8List data) {
    return _printRaw(data);
  }

  /// Kirim bytes mentah ke printer (datatype RAW)
  bool _printRaw(Uint8List data) {
    final hPrinter = calloc<HANDLE>();
    final namePtr = printerName.toNativeUtf16();

    try {
      if (OpenPrinter(namePtr, hPrinter, nullptr) == 0) {
        debugPrint('Gagal buka printer: $printerName');
        return false;
      }

      final di = calloc<DOC_INFO_1>()
        ..ref.pDocName = TEXT('ESC/POS Print Job')
        ..ref.pOutputFile = nullptr
        ..ref.pDatatype = TEXT('RAW');

      if (StartDocPrinter(hPrinter.value, 1, di.cast()) == 0) {
        debugPrint('Gagal mulai dokumen');
        return false;
      }

      StartPagePrinter(hPrinter.value);

      final pBytes = calloc<Uint8>(data.length);
      final written = calloc<DWORD>();
      for (var i = 0; i < data.length; i++) {
        pBytes[i] = data[i];
      }

      final ok =
          WritePrinter(hPrinter.value, pBytes.cast(), data.length, written) !=
          0;

      EndPagePrinter(hPrinter.value);
      EndDocPrinter(hPrinter.value);

      calloc.free(pBytes);
      calloc.free(written);
      calloc.free(di);

      return ok;
    } finally {
      if (hPrinter.value != 0) {
        ClosePrinter(hPrinter.value);
      }
      calloc.free(hPrinter);
      calloc.free(namePtr);
    }
  }
}
