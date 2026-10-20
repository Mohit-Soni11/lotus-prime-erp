import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/logic/girvi/girvi_receipt_financial_summary.dart';
import 'package:lotus_erp/models/girvi/girvi_interest_calculator.dart';
import 'package:lotus_erp/models/girvi/girvi_invoice_draft.dart';

void main() {
  test('release statement separates earlier cash, settlement cash and waiver',
      () {
    final day = DateTime(2026, 10, 19);
    final draft = GirviInvoiceDraft(
      ticketNo: 'GRV-0019',
      createdAt: day,
      customerName: 'Customer',
      customerMobile: '',
      customerCity: '',
      items: const [],
      loanAmount: 3000,
      interestRate: 5,
      durationMonths: 5,
      startDate: DateTime(2025, 5, 5),
      maturityDate: DateTime(2025, 10, 5),
      payments: const [],
      disbursementSummary: '',
      ledgerEntries: [
        GirviInvoiceLedgerEntry(
          date: day,
          typeLabel: 'Partial Principal',
          modeLabel: 'Cash',
          amount: 500,
        ),
        GirviInvoiceLedgerEntry(
          date: day,
          typeLabel: 'Interest Payment',
          modeLabel: 'Cash',
          amount: 2000,
          interestAmount: 2000,
        ),
        GirviInvoiceLedgerEntry(
          date: day,
          typeLabel: 'Final Release',
          modeLabel: 'UPI',
          amount: 3740,
          principalAmount: 2500,
          interestAmount: 1240,
          discountAmount: 100,
        ),
      ],
      mode: GirviReceiptMode.release,
    );

    final summary = GirviReceiptFinancialSummary.fromDraft(draft);
    expect(summary.priorPrincipal, 500);
    expect(summary.priorInterest, 2000);
    expect(summary.previouslyCollected, 2500);
    expect(summary.settlementPrincipal, 2500);
    expect(summary.settlementInterest, 1240);
    expect(summary.collectedAtSettlement, 3740);
    expect(summary.principalReceived, 3000);
    expect(summary.interestReceived, 3240);
    expect(summary.totalReceived, 6240);
    expect(summary.discount, 100);
    expect(summary.settlementModes, 'UPI');
    expect(summary.interestEntries, hasLength(2));
  });

  test('gross compound closing keeps payment adjustments out of the table', () {
    final day = DateTime(2026, 10, 19);
    final quote = GirviInterestCalculator.quoteAt(
      principal: 3000,
      monthlyRatePercent: 5,
      startDate: DateTime(2025, 5, 5),
      asOf: day,
      adjustments: [
        GirviInterestAdjustment(date: day, paid: 2000),
        GirviInterestAdjustment(date: day, paid: 1240),
      ],
    );

    expect(quote.cycles, hasLength(2));
    expect(quote.cycles.last.principalBase, 4800);
    expect(quote.cycles.last.interestAmount, 1440);
    expect(quote.cycles.first.grossClosingAmount, 4800);
    expect(quote.cycles.last.grossClosingAmount, 6240);
    expect(quote.cycles.last.closingAmount, 3000);
  });
}
