import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/core/printing/lotus_pdf_print_dispatcher.dart';
import 'package:printing/printing.dart';

void main() {
  group('LotusPdfPrintDispatcher', () {
    const dispatcher = LotusPdfPrintDispatcher();

    test('detects common virtual PDF printers', () {
      expect(
        dispatcher.isVirtualPdfPrinter(
          const Printer(
            url: 'winspool://Microsoft Print to PDF',
            name: 'Microsoft Print to PDF',
          ),
        ),
        isTrue,
      );
      expect(
        dispatcher.isVirtualPdfPrinter(
          const Printer(
            url: 'winspool://xps',
            name: 'Microsoft XPS Document Writer',
          ),
        ),
        isTrue,
      );
      expect(
        dispatcher.isVirtualPdfPrinter(
          const Printer(
            url: 'winspool://note',
            name: 'Send To OneNote',
          ),
        ),
        isTrue,
      );
    });

    test('keeps physical printers on direct print path', () {
      expect(
        dispatcher.isVirtualPdfPrinter(
          const Printer(
            url: 'ipp://192.168.1.20/printers/hp-laserjet',
            name: 'HP LaserJet Pro',
            model: 'LaserJet MFP',
          ),
        ),
        isFalse,
      );
    });

    test('marks only completed print results as completed', () {
      expect(LotusPdfPrintResult.printed.completed, isTrue);
      expect(LotusPdfPrintResult.savedVirtualOutput.completed, isTrue);
      expect(LotusPdfPrintResult.cancelled.completed, isFalse);
      expect(LotusPdfPrintResult.failed.completed, isFalse);
    });
  });
}
