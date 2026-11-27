enum InvoiceCenterTab { all, regular, gst, due, advance, cancelled }

enum InvoiceCenterDocumentKind { sales, booking, cancellation }

class InvoiceCenterMetric {
  const InvoiceCenterMetric({required this.count, required this.amount});

  final int count;
  final double amount;
}

class InvoiceCenterSummary {
  const InvoiceCenterSummary(this.metrics);

  final Map<InvoiceCenterTab, InvoiceCenterMetric> metrics;

  InvoiceCenterMetric forTab(InvoiceCenterTab tab) =>
      metrics[tab] ?? const InvoiceCenterMetric(count: 0, amount: 0);
}

class InvoiceCenterRow {
  const InvoiceCenterRow({
    required this.kind,
    required this.id,
    required this.number,
    required this.issuedAt,
    required this.customerName,
    required this.mobile,
    required this.customerId,
    required this.metals,
    required this.category,
    required this.status,
    required this.total,
    required this.paid,
    required this.due,
  });

  final InvoiceCenterDocumentKind kind;
  final int id;
  final String number;
  final DateTime issuedAt;
  final String customerName;
  final String mobile;
  final int? customerId;
  final String metals;
  final InvoiceCenterTab category;
  final String status;
  final double total;
  final double paid;
  final double due;
}

class InvoiceCenterQuery {
  const InvoiceCenterQuery({
    required this.tab,
    required this.month,
    required this.page,
    required this.pageSize,
    this.search = '',
    this.metal = '',
    this.status = '',
    this.minAmount,
    this.maxAmount,
  });

  final InvoiceCenterTab tab;
  final DateTime month;
  final int page;
  final int pageSize;
  final String search;
  final String metal;
  final String status;
  final double? minAmount;
  final double? maxAmount;

  bool get usesMonth =>
      tab != InvoiceCenterTab.due && tab != InvoiceCenterTab.advance;
}

class InvoiceCenterSnapshot {
  const InvoiceCenterSnapshot({
    required this.summary,
    required this.rows,
    required this.totalRows,
    required this.metals,
  });

  final InvoiceCenterSummary summary;
  final List<InvoiceCenterRow> rows;
  final int totalRows;
  final List<String> metals;
}
