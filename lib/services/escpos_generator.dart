// Helper to generate ESC/POS bytes using esc_pos_utils and image packages.
// Platform-agnostic byte generation; printing handled by WindowsPrinterService.

import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as im;

class EscposGenerator {
  const EscposGenerator();

  /// Generate a simple test receipt (58mm by default) with optional logo from assets.
  /// Ensure the asset path exists in pubspec.yaml (e.g., assets/images/logo.png)
  Future<List<int>> generateTestTicket({
    String? assetLogoPath = 'assets/images/logo.png',
    PaperSize paper = PaperSize.mm58,
    String storeName = 'Test Store',
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(paper, profile);
    final bytes = <int>[];

    bytes.addAll(generator.reset());

    if (assetLogoPath != null) {
      try {
        final logoData = await rootBundle.load(assetLogoPath);
        final logo = im.decodeImage(logoData.buffer.asUint8List());
        if (logo != null) {
          // Resize logo to fit printer width reasonably
          final resized = im.copyResize(
            logo,
            width: paper == PaperSize.mm58 ? 300 : 400,
          );
          bytes.addAll(generator.image(resized));
        }
      } catch (_) {
        // ignore missing logo
      }
    }

    bytes.addAll(
      generator.text(
        storeName,
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
          bold: true,
        ),
        linesAfter: 1,
      ),
    );

    bytes.addAll(generator.hr());

    // Sample lines
    bytes.addAll(generator.text('Item A        x1      10.000'));
    bytes.addAll(generator.text('Item B        x2       8.000'));
    bytes.addAll(generator.text('--------------------------------'));
    bytes.addAll(
      generator.text(
        'TOTAL                 18.000',
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    );
    bytes.addAll(generator.hr(ch: '='));

    bytes.addAll(
      generator.text(
        'Terima kasih!',
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    bytes.addAll(generator.feed(3));

    // Most thermal printers require cut or partial cut
    bytes.addAll(generator.cut());

    return bytes;
  }
}
