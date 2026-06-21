import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/girvi/girvi_enums.dart';
import '../../models/girvi/girvi_loan_model.dart';

class GirviSettlementStatementPdfService {
  final NumberFormat _moneyFormat = NumberFormat('#,##,##0.00', 'en_IN');
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');

  static const PdfColor _navy = PdfColor.fromInt(0xFF172437);
  static const PdfColor _gold = PdfColor.fromInt(0xFFC89421);
  static const PdfColor _surface = PdfColor.fromInt(0xFFF6F8FB);
  static const PdfColor _line = PdfColor.fromInt(0xFFD8DEE8);
  static const PdfColor _ink = PdfColor.fromInt(0xFF172033);
  static const PdfColor _muted = PdfColor.fromInt(0xFF111111);
  static const PdfColor _green = PdfColor.fromInt(0xFF047857);
  static const PdfColor _red = PdfColor.fromInt(0xFFB91C1C);

  Future<Uint8List> build({
    required GirviLoanWithCustomer account,
    required List<GirviPaymentModel> payments,
  }) async {
    final document = pw.Document(
      title: 'Girvi Settlement Statement ${account.loan.ticketNo}',
      author: 'Lotus ERP',
      creator: 'Lotus ERP',
      subject: 'Girvi loan settlement and payment statement',
    );

    final sortedPayments = List<GirviPaymentModel>.from(payments)
      ..sort((a, b) {
        final byDate = a.paymentDate.compareTo(b.paymentDate);
        if (byDate != 0) return byDate;
        return a.id.compareTo(b.id);
      });

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 24, 28, 24),
        footer: (context) => _footer(context),
        build: (_) => [
          _hero(account),
          pw.SizedBox(height: 14),
          _statusStrip(account),
          pw.SizedBox(height: 14),
          _summaryGrid(account),
          pw.SizedBox(height: 14),
          _sectionTitle('Pledged Item'),
          _detailTable([
            ['Item Name', account.loan.itemDescription],
            ['Item Count', account.loan.itemCount.toString()],
            [
              'Metal / Purity',
              '${account.loan.metalTypeEnum.displayName} / ${account.loan.metalPurity}',
            ],
            ['Gross Weight', _weight(account.loan.grossWeight)],
            ['Less Weight', _weight(account.loan.stoneWeight)],
            ['Net Weight', _weight(account.loan.netWeight)],
            ['Rate Per Gram', _money(account.loan.ratePerGram)],
            ['Pledged Value', _money(account.loan.totalValue)],
          ]),
          pw.SizedBox(height: 14),
          _sectionTitle('Payment Ledger'),
          _paymentTable(sortedPayments),
          pw.SizedBox(height: 16),
          _deliveryPanel(account),
          pw.SizedBox(height: 22),
          _signatureBlock(),
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _hero(GirviLoanWithCustomer account) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: const pw.BoxDecoration(color: _navy),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'LOTUS ERP',
                style: pw.TextStyle(
                  color: PdfColors.grey300,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'GIRVI SETTLEMENT STATEMENT',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                '${account.customerName} | ${account.customerMobile}',
                style: const pw.TextStyle(
                  color: PdfColors.grey200,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                account.loan.ticketNo,
                style: pw.TextStyle(
                  color: _gold,
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Generated ${_dateTimeFormat.format(DateTime.now())}',
                style: const pw.TextStyle(
                  color: PdfColors.grey300,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _statusStrip(GirviLoanWithCustomer account) {
    final status = _accountStatus(account);
    final balanceColor = account.totalPayable <= 0.01 ? _green : _red;
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _surface,
        border: pw.Border.all(color: _line),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _miniMetric('Account Status', status, _ink),
          _miniMetric('Start Date', _date(account.loan.startDate), _ink),
          _miniMetric('Maturity Date', _date(account.loan.maturityDate), _ink),
          _miniMetric(
              'Net Payable', _money(account.totalPayable), balanceColor),
        ],
      ),
    );
  }

  pw.Widget _summaryGrid(GirviLoanWithCustomer account) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _detailTable([
            ['Original Principal', _money(account.originalPrincipal)],
            ['Current Principal', _money(account.loan.loanAmount)],
            [
              'Principal Repaid',
              _money(
                account.principalPaidTotal + account.legacyPrincipalRepaidTotal,
              ),
            ],
            ['Principal Discount', _money(account.principalDiscountTotal)],
            ['Principal Due', _money(account.principalDue)],
          ]),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: _detailTable([
            ['Monthly Interest Rate', '${account.loan.interestRate}%'],
            ['Total Interest Accrued', _money(account.grossInterestAccrued)],
            ['Interest Paid', _money(account.interestPaidTotal)],
            ['Interest Discount', _money(account.interestDiscountTotal)],
            ['Interest Due', _money(account.netInterestDue)],
          ]),
        ),
      ],
    );
  }

  pw.Widget _paymentTable(List<GirviPaymentModel> payments) {
    if (payments.isEmpty) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: _surface,
          border: pw.Border.all(color: _line),
        ),
        child: pw.Text(
          'No payment has been recorded for this account.',
          style: const pw.TextStyle(color: _ink, fontSize: 10),
        ),
      );
    }

    return pw.TableHelper.fromTextArray(
      headers: const [
        'Date',
        'Entry Type',
        'Mode',
        'Principal',
        'Interest',
        'Discount',
        'Received',
        'Balance',
        'Coverage',
      ],
      data: payments
          .map(
            (payment) => [
              _date(payment.paymentDate),
              payment.type.displayName,
              payment.mode.displayName,
              _money(payment.principalComponent),
              _money(payment.interestComponent),
              _money(payment.discountAmount),
              _money(payment.amount),
              _money(payment.balanceAfter),
              _coverage(payment),
            ],
          )
          .toList(),
      border: pw.TableBorder.all(color: _line, width: 0.6),
      headerDecoration: const pw.BoxDecoration(color: _navy),
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontSize: 7.2,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: const pw.TextStyle(color: _muted, fontSize: 7.2),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.1),
        1: pw.FlexColumnWidth(1.35),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(1),
        4: pw.FlexColumnWidth(1),
        5: pw.FlexColumnWidth(1),
        6: pw.FlexColumnWidth(1),
        7: pw.FlexColumnWidth(1),
        8: pw.FlexColumnWidth(1.7),
      },
    );
  }

  pw.Widget _deliveryPanel(GirviLoanWithCustomer account) {
    final loan = account.loan;
    final rows = [
      ['Release Date', _date(loan.releaseDate)],
      ['Expected Pickup', _date(loan.expectedDeliveryDate)],
      ['Delivered At', _dateTime(loan.deliveredAt)],
      ['Processed By', _emptyFallback(loan.releasedBy)],
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Delivery and Closure'),
        _detailTable(rows),
      ],
    );
  }

  pw.Widget _signatureBlock() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _signatureLine('Customer Signature'),
        _signatureLine('Authorized Signature'),
      ],
    );
  }

  pw.Widget _signatureLine(String label) {
    return pw.Container(
      width: 190,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(height: 1, color: _line),
          pw.SizedBox(height: 5),
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 8, color: _muted),
          ),
        ],
      ),
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(
          color: _navy,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _detailTable(List<List<String>> rows) {
    return pw.TableHelper.fromTextArray(
      headers: null,
      data: rows,
      border: pw.TableBorder.all(color: _line, width: 0.6),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      cellStyle: const pw.TextStyle(fontSize: 9, color: _ink),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.1),
        1: pw.FlexColumnWidth(1.4),
      },
      cellAlignments: const {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
      },
      oddRowDecoration: const pw.BoxDecoration(color: _surface),
    );
  }

  pw.Widget _miniMetric(String label, String value, PdfColor valueColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 7),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          value,
          style: pw.TextStyle(
            color: valueColor,
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  pw.Widget _footer(pw.Context context) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
      ),
    );
  }

  String _accountStatus(GirviLoanWithCustomer account) {
    final loan = account.loan;
    if (loan.deliveredAt != null) return 'Delivered and Closed';
    if (loan.girviStatus == GirviStatus.readyForDelivery) {
      return 'Settlement Complete - Delivery Pending';
    }
    if (loan.girviStatus == GirviStatus.partialRelease) {
      return 'Settlement Pending';
    }
    if (loan.girviStatus == GirviStatus.auctioned) return 'Auctioned';
    if (loan.girviStatus == GirviStatus.released) return 'Released';
    if (loan.isOverdue) return 'Overdue';
    return loan.statusLabel;
  }

  String _coverage(GirviPaymentModel payment) {
    final from = payment.interestFromDate;
    final to = payment.interestToDate;
    if (from != null && to != null) {
      return '${_date(from)} to ${_date(to)}';
    }

    final months = payment.monthsCovered ?? 0;
    if (months > 0) return '$months month${months == 1 ? '' : 's'}';
    return '-';
  }

  String _money(double value) => 'Rs ${_moneyFormat.format(value)}';

  String _date(DateTime? value) {
    if (value == null) return '-';
    return _dateFormat.format(value);
  }

  String _dateTime(DateTime? value) {
    if (value == null) return '-';
    return _dateTimeFormat.format(value);
  }

  String _weight(double value) => '${value.toStringAsFixed(2)} g';

  String _emptyFallback(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return '-';
    return trimmed;
  }
}
