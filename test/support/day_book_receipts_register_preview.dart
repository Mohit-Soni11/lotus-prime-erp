import 'day_book_demo_preview.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_receipts_register.dart';

/// Isolated design samples; never used by financial posting or exports.
class DayBookReceiptsRegisterPreview {
  const DayBookReceiptsRegisterPreview._();

  static DayBookReceiptsRegister forDate(DateTime date) {
    final expenses = DayBookDemoPreview.forDate(date).expenseRecords;
    return DayBookReceiptsRegister(
      dues: const [
        DayBookDueRow(
          reference: 'INV-26-000542',
          type: 'Sales',
          customerName: 'Mr. Rajesh Mehta',
          phone: '+91 98920 11334',
          totalValue: 124600,
          amountPaid: 100000,
          dueAmount: 24600,
          paidAgainstDue: 10000,
        ),
        DayBookDueRow(
          reference: 'INV-26-000543',
          type: 'Sales',
          customerName: 'Mrs. Kavita Desai',
          phone: '+91 97693 55882',
          totalValue: 95100,
          amountPaid: 61900,
          dueAmount: 33200,
          paidAgainstDue: 20000,
        ),
        DayBookDueRow(
          reference: 'INV-26-000544',
          type: 'GST',
          customerName: 'Mr. Amit Verma',
          phone: '+91 98112 77881',
          totalValue: 44600,
          amountPaid: 44600,
          dueAmount: 0,
          paidAgainstDue: 14600,
        ),
        DayBookDueRow(
          reference: 'INV-26-000545',
          type: 'Sales',
          customerName: 'Mrs. Neha Joshi',
          phone: '+91 98877 66554',
          totalValue: 25000,
          amountPaid: 25000,
          dueAmount: 0,
        ),
      ],
      received: const [
        DayBookReceivedRow(
          reference: 'REG-025',
          type: 'Sales',
          amount: 48000,
          mode: 'CASH',
          customerName: 'Mr. Ramesh Shah',
          phone: '98765 43210',
          totalValue: 48000,
        ),
        DayBookReceivedRow(
          reference: 'REG-026',
          type: 'Sales',
          amount: 24000,
          mode: 'UPI',
          customerName: 'Mrs. Priya Mehta',
          phone: '98250 67890',
          totalValue: 36000,
        ),
        DayBookReceivedRow(
          reference: 'TAX-030',
          type: 'GST',
          amount: 75000,
          mode: 'UPI',
          customerName: 'Ms. Kavita Jain',
          phone: '98700 11122',
          totalValue: 80000,
        ),
        DayBookReceivedRow(
          reference: 'ADV-041',
          type: 'Advance',
          amount: 40000,
          mode: 'CASH',
          customerName: 'Mr. Ravi Soni',
          phone: '98760 56565',
          totalValue: 40000,
        ),
        DayBookReceivedRow(
          reference: 'INV-011',
          type: 'Due',
          amount: 2500,
          mode: 'CASH',
          customerName: 'Mr. Sandeep Rao',
          phone: '98760 10101',
          totalValue: 15000,
        ),
        DayBookReceivedRow(
          reference: 'GRV-108',
          type: 'Girvi Release',
          amount: 30000,
          mode: 'BANK',
          customerName: 'Mr. Harish Jain',
          phone: '98760 90909',
          totalValue: 30000,
        ),
      ],
      expenses: expenses,
    );
  }
}
