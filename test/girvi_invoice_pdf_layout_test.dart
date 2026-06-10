import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/logic/girvi/girvi_invoice_pdf_service.dart';
import 'package:lotus_erp/models/girvi/girvi_invoice_draft.dart';

void main() {
  test('Girvi customer invoice renders a populated premium layout', () async {
    final photoPath = _previewPhotoPath();
    final outputPath = Platform.environment['GIRVI_PREVIEW_OUTPUT'];
    final photos = photoPath == null ? <String>[] : [photoPath];
    final draft = GirviInvoiceDraft(
      ticketNo: 'GRV-2026-00128',
      createdAt: DateTime(2026, 6, 9),
      customerName: 'Rahul Kumar Sharma',
      customerMobile: '98765 43210',
      customerCity: 'Kolkata, West Bengal',
      items: [
        GirviInvoiceItemDraft(
          serialNo: 1,
          metal: 'Gold',
          description: 'Traditional bridal necklace with pendant',
          purity: '22K',
          pieces: 1,
          grossWeight: 38.75,
          lessWeight: 2.15,
          netWeight: 36.60,
          valuationPurity: '91.60%',
          fineWeight: 33.52,
          ratePerGram: 6823,
          huid: '6H8K2P',
          value: 228700,
          photoPaths: photos,
        ),
        GirviInvoiceItemDraft(
          serialNo: 2,
          metal: 'Gold',
          description: 'Pair of designer bangles',
          purity: '22K',
          pieces: 2,
          grossWeight: 24.50,
          lessWeight: 0.80,
          netWeight: 23.70,
          valuationPurity: '91.60%',
          fineWeight: 21.71,
          ratePerGram: 6823,
          huid: '8B4M7Q',
          value: 148100,
          photoPaths: photos,
        ),
        GirviInvoiceItemDraft(
          serialNo: 3,
          metal: 'Gold',
          description: 'Ladies ring with stone setting',
          purity: '18K',
          pieces: 1,
          grossWeight: 6.35,
          lessWeight: 0.65,
          netWeight: 5.70,
          valuationPurity: '75.00%',
          fineWeight: 4.28,
          ratePerGram: 5585,
          huid: '',
          value: 23880,
          photoPaths: photos,
        ),
        const GirviInvoiceItemDraft(
          serialNo: 4,
          metal: 'Silver',
          description: 'Silver anklet pair',
          purity: '92.5',
          pieces: 2,
          grossWeight: 118.40,
          lessWeight: 1.20,
          netWeight: 117.20,
          valuationPurity: '92.50%',
          fineWeight: 108.41,
          ratePerGram: 95,
          huid: '-',
          value: 10299,
        ),
      ],
      totalValue: 410979,
      loanAmount: 250000,
      interestRate: 1.50,
      durationMonths: 12,
      startDate: DateTime(2026, 6, 9),
      maturityDate: DateTime(2027, 6, 9),
      monthlyInterest: 3750,
      totalInterest: 45000,
      totalDue: 295000,
      payments: const [
        GirviInvoicePayment(label: 'Cash', amount: 100000),
        GirviInvoicePayment(label: 'UPI', amount: 150000),
      ],
      disbursementSummary: 'Cash + UPI',
    );

    final bytes = await GirviInvoicePdfService().build(
      draft: draft,
      format: GirviInvoiceFormat.a4,
    );

    expect(bytes, isNotEmpty);
    if (outputPath != null && outputPath.isNotEmpty) {
      await File(outputPath).writeAsBytes(bytes);
    }
  });

  test('Girvi invoice keeps table and photo flow stable across pages',
      () async {
    final photoPath = _previewPhotoPath();
    final outputPath = Platform.environment['GIRVI_STRESS_OUTPUT'];
    final a5OutputPath = Platform.environment['GIRVI_STRESS_A5_OUTPUT'];
    final items = List.generate(
      28,
      (index) => GirviInvoiceItemDraft(
        serialNo: index + 1,
        metal: index % 6 == 0 ? 'Silver' : 'Gold',
        description:
            'Pledged jewellery item ${index + 1} with detailed description',
        purity: index % 4 == 0 ? '18K' : '22K',
        pieces: (index % 3) + 1,
        grossWeight: 5.25 + index,
        lessWeight: 0.15 + (index % 4) * 0.10,
        netWeight: 5.10 + index - (index % 4) * 0.10,
        valuationPurity: '91.60%',
        fineWeight: 4.75 + index,
        ratePerGram: 6823,
        huid: index % 5 == 0 ? '' : 'HUID${1000 + index}',
        value: 25000 + index * 1200,
        photoPaths: photoPath != null && index < 8 ? [photoPath] : const [],
      ),
    );
    final draft = GirviInvoiceDraft(
      ticketNo: 'GRV-2026-00999',
      createdAt: DateTime(2026, 6, 9),
      customerName: 'Multipage Layout Test Customer',
      customerMobile: '99999 99999',
      customerCity: 'Kolkata, West Bengal',
      items: items,
      totalValue: 850000,
      loanAmount: 500000,
      interestRate: 1.75,
      durationMonths: 12,
      startDate: DateTime(2026, 6, 9),
      maturityDate: DateTime(2027, 6, 9),
      monthlyInterest: 8750,
      totalInterest: 105000,
      totalDue: 605000,
      payments: const [],
      disbursementSummary: '',
    );
    final service = GirviInvoicePdfService();

    final a4Bytes = await service.build(
      draft: draft,
      format: GirviInvoiceFormat.a4,
    );
    final a5Bytes = await service.build(
      draft: draft,
      format: GirviInvoiceFormat.compactA5,
    );

    expect(a4Bytes, isNotEmpty);
    expect(a5Bytes, isNotEmpty);
    expect(
      GirviInvoiceFormat.compactA5.pageFormat.width,
      greaterThan(GirviInvoiceFormat.compactA5.pageFormat.height),
    );
    if (outputPath != null && outputPath.isNotEmpty) {
      await File(outputPath).writeAsBytes(a4Bytes);
    }
    if (a5OutputPath != null && a5OutputPath.isNotEmpty) {
      await File(a5OutputPath).writeAsBytes(a5Bytes);
    }
  });
}

String? _previewPhotoPath() {
  final requested = Platform.environment['GIRVI_PREVIEW_PHOTO'];
  if (requested != null && File(requested).existsSync()) return requested;

  final bundledSample = File('lib/logo/gold.jpeg');
  return bundledSample.existsSync() ? bundledSample.absolute.path : null;
}
