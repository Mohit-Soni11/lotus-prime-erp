import '../../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';

const double posInvoiceMoneyEpsilon = 0.005;
const double posInvoiceDueEpsilon = 0.5;

class PosInvoicePaymentEntry {
  final String label;
  final double amount;

  const PosInvoicePaymentEntry({
    required this.label,
    required this.amount,
  });
}

class PosInvoiceAmountSummaryEntry {
  final String label;
  final double amount;
  final bool isDeduction;
  final bool isEmphasized;

  const PosInvoiceAmountSummaryEntry({
    required this.label,
    required this.amount,
    this.isDeduction = false,
    this.isEmphasized = false,
  });
}

class PosInvoiceStatusView {
  final String label;
  final bool isDue;
  final bool isPaid;
  final bool isCredit;

  const PosInvoiceStatusView({
    required this.label,
    required this.isDue,
    required this.isPaid,
    required this.isCredit,
  });
}

class PosInvoiceFinancialBreakdown {
  PosInvoiceFinancialBreakdown._();

  static PosInvoiceStatusView status(PosInvoiceModel invoice) {
    switch (invoice.paymentStatus) {
      case PaymentStatus.paid:
        return const PosInvoiceStatusView(
          label: 'PAID',
          isDue: false,
          isPaid: true,
          isCredit: false,
        );
      case PaymentStatus.due:
        return const PosInvoiceStatusView(
          label: 'DUE',
          isDue: true,
          isPaid: false,
          isCredit: false,
        );
      case PaymentStatus.credit:
        return const PosInvoiceStatusView(
          label: 'CREDIT',
          isDue: false,
          isPaid: false,
          isCredit: true,
        );
    }
  }

  static bool hasDue(PosInvoiceModel invoice) {
    return invoice.balanceDue > posInvoiceDueEpsilon;
  }

  static List<PosInvoicePaymentEntry> payments(PosInvoiceModel invoice) {
    return [
      if (invoice.cashPaid > posInvoiceMoneyEpsilon)
        PosInvoicePaymentEntry(label: 'Cash', amount: invoice.cashPaid),
      if (invoice.upiPaid > posInvoiceMoneyEpsilon)
        PosInvoicePaymentEntry(
          label: 'UPI / Bank Transfer',
          amount: invoice.upiPaid,
        ),
      if (invoice.cardPaid > posInvoiceMoneyEpsilon)
        PosInvoicePaymentEntry(label: 'Card', amount: invoice.cardPaid),
      if (invoice.advancePaid > posInvoiceMoneyEpsilon)
        PosInvoicePaymentEntry(
          label: 'Customer Advance',
          amount: invoice.advancePaid,
        ),
    ];
  }

  static List<PosInvoiceAmountSummaryEntry> summaryRows(
    PosInvoiceModel invoice, {
    required bool showGstBreakup,
  }) {
    return [
      PosInvoiceAmountSummaryEntry(
        label: 'Gross Sale Value',
        amount: invoice.grossAmount,
      ),
      if (invoice.discountAmount > posInvoiceMoneyEpsilon)
        PosInvoiceAmountSummaryEntry(
          label: 'Invoice Discount',
          amount: invoice.discountAmount,
          isDeduction: true,
        ),
      PosInvoiceAmountSummaryEntry(
        label: 'Taxable Value',
        amount: invoice.taxableAmount,
      ),
      if (invoice.billType == BillType.gst &&
          showGstBreakup &&
          invoice.totalGst > posInvoiceMoneyEpsilon) ...[
        if (invoice.hasIgstBreakup)
          PosInvoiceAmountSummaryEntry(
            label: 'IGST',
            amount: invoice.igst,
          )
        else ...[
          if (invoice.cgst > posInvoiceMoneyEpsilon)
            PosInvoiceAmountSummaryEntry(
              label: 'CGST',
              amount: invoice.cgst,
            ),
          if (invoice.sgst > posInvoiceMoneyEpsilon)
            PosInvoiceAmountSummaryEntry(
              label: 'SGST',
              amount: invoice.sgst,
            ),
        ],
      ],
      if (invoice.totalTradeInDeduction > posInvoiceMoneyEpsilon)
        PosInvoiceAmountSummaryEntry(
          label: 'Customer Metal Settlement',
          amount: invoice.totalTradeInDeduction,
          isDeduction: true,
        ),
      if (invoice.crossMetalAdjustmentDeduction > posInvoiceMoneyEpsilon)
        PosInvoiceAmountSummaryEntry(
          label: 'Cross-Metal Settlement',
          amount: invoice.crossMetalAdjustmentDeduction,
          isDeduction: true,
        ),
      if (invoice.roundOffAmount.abs() > posInvoiceMoneyEpsilon)
        PosInvoiceAmountSummaryEntry(
          label: 'Rounding Adjustment',
          amount: invoice.roundOffAmount.abs(),
          isDeduction: invoice.roundOffAmount < 0,
        ),
      PosInvoiceAmountSummaryEntry(
        label: invoice.netPayable < -posInvoiceDueEpsilon
            ? 'Customer Credit'
            : 'Net Payable',
        amount: invoice.netPayable.abs(),
        isEmphasized: true,
      ),
    ];
  }

  static String paymentModeSummary(PosInvoiceModel invoice) {
    final labels = payments(invoice).map((entry) => entry.label).toList();
    return labels.isEmpty ? 'No Payment Recorded' : labels.join(' + ');
  }
}
