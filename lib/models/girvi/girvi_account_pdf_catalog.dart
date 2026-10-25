import 'girvi_loan_model.dart';

enum GirviAccountPdfKind {
  documentSet('Complete Girvi PDF',
      'Invoice, interest, release and delivery pages', 'document'),
  originalInvoice(
      'Original Girvi Invoice', 'Saved invoice issued at pledge', 'invoice'),
  formalNotice('Formal Notice', 'Saved customer notice', 'notice');

  const GirviAccountPdfKind(this.title, this.subtitle, this.fileSuffix);

  final String title;
  final String subtitle;
  final String fileSuffix;
}

class GirviAccountPdfCatalog {
  const GirviAccountPdfCatalog._();

  static List<GirviAccountPdfKind> available({
    required GirviLoanWithCustomer account,
    required bool hasFormalNotice,
  }) {
    return [
      GirviAccountPdfKind.documentSet,
      if (account.loan.invoiceGenerated) GirviAccountPdfKind.originalInvoice,
      if (hasFormalNotice) GirviAccountPdfKind.formalNotice,
    ];
  }
}
