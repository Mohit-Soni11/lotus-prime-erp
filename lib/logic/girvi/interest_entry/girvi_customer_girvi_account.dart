import '../../../models/girvi/girvi_loan_model.dart';

class GirviCustomerGirviAccount {
  const GirviCustomerGirviAccount({
    required this.customerId,
    required this.customerName,
    required this.customerMobile,
    required this.customerCity,
    required this.loans,
  });

  final int customerId;
  final String customerName;
  final String customerMobile;
  final String? customerCity;
  final List<GirviLoanWithCustomer> loans;

  int get ticketCount => loans.length;

  double get outstandingPrincipal => loans.fold<double>(
        0,
        (sum, item) => sum + item.principalDue,
      );

  double get interestDue => loans.fold<double>(
        0,
        (sum, item) => sum + item.netInterestDue,
      );

  int get overdueTicketCount =>
      loans.where((item) => item.loan.isOverdue).length;

  bool get hasOverdueTickets => overdueTicketCount > 0;

  DateTime get latestActivity {
    DateTime latest = loans.first.loan.updatedAt ?? loans.first.loan.startDate;
    for (final item in loans.skip(1)) {
      final current = item.loan.updatedAt ?? item.loan.startDate;
      if (current.isAfter(latest)) latest = current;
    }
    return latest;
  }
}
