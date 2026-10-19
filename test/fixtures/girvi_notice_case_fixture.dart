import 'package:lotus_erp/models/girvi/contact_recovery_model.dart';
import 'package:lotus_erp/models/girvi/girvi_customer_response_model.dart';
import 'package:lotus_erp/models/girvi/girvi_interest_period_snapshot.dart';
import 'package:lotus_erp/models/girvi/girvi_loan_model.dart';

ContactRecoveryCase createNoticeCase({
  bool simple = true,
  double interestPaid = 0,
  double interestDiscount = 0,
}) {
  final start = DateTime(2025, 4, 4);
  final now = DateTime(2026, 10, 4);
  final interestType = simple
      ? GirviInterestCalculationType.simple
      : GirviInterestCalculationType.compound;
  return ContactRecoveryCase(
    account: GirviLoanWithCustomer(
      loan: GirviLoanModel(
        id: 1,
        ticketNo: 'GRV-DEMO-001',
        customerId: 1,
        itemDescription: '#1 ring | Gold | 22KT | 1 pcs | Net 10.000 g',
        itemCount: 1,
        metalType: 'Gold',
        metalPurity: '22KT',
        grossWeight: 10,
        stoneWeight: 0,
        netWeight: 10,
        loanAmount: 100000,
        interestRate: 1,
        durationMonths: 6,
        disbursementMode: 'Cash',
        startDate: start,
        maturityDate: DateTime(2025, 10, 4),
        createdAt: start,
      ),
      customerName: 'Sample Customer',
      customerMobile: '0000000000',
      customerAddress: 'Sample address, Patna',
      interestType: interestType,
      interestPaidTotal: interestPaid,
      interestDiscountTotal: interestDiscount,
    ),
    noticePeriodDays: 7,
    now: now,
    paymentHistory: [
      if (interestPaid > 0 || interestDiscount > 0)
        GirviPaymentModel(
          id: 1,
          girviId: 1,
          paymentDate: DateTime(2026, 1, 4),
          amount: interestPaid,
          paymentType: 'INTEREST',
          paymentMode: 'CASH',
          interestComponent: interestPaid,
          interestDiscountComponent: interestDiscount,
          balanceAfter: 0,
          createdAt: DateTime(2026, 1, 4),
        ),
    ],
    interestPeriodSnapshots: [
      GirviInterestPeriodSnapshot(
        id: 1,
        girviId: 1,
        sequence: 1,
        periodFrom: start,
        periodTo: simple ? now : DateTime(2026, 4, 4),
        interestType: interestType,
        openingAmount: 100000,
        monthlyRatePercent: 1,
        interestPerMonth: 1000,
        chargeableMonths: simple ? 18 : 12,
        periodInterest: simple ? 18000 : 12000,
        closingAmount: simple ? 118000 : 112000,
        finalized: !simple,
        source: 'TEST',
      ),
      if (!simple)
        GirviInterestPeriodSnapshot(
          id: 2,
          girviId: 1,
          sequence: 2,
          periodFrom: DateTime(2026, 4, 4),
          periodTo: now,
          interestType: interestType,
          openingAmount: 112000,
          monthlyRatePercent: 1,
          interestPerMonth: 1120,
          chargeableMonths: 6,
          periodInterest: 6720,
          closingAmount: 118720,
          finalized: false,
          source: 'TEST',
        ),
    ],
    customerResponses: [
      GirviCustomerResponse(
        id: 1,
        girviId: 1,
        noticeStage: 1,
        kind: GirviCustomerResponseKind.willVisit,
        channel: GirviContactChannel.phoneCall,
        responseText: 'I will visit the shop on Friday.',
        status: GirviPromiseStatus.open,
        promiseDueAt: DateTime(2026, 9, 26),
        receivedAt: DateTime(2026, 9, 20),
        createdAt: DateTime(2026, 9, 20),
      ),
    ],
  );
}
