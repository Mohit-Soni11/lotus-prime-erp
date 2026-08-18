import 'package:flutter/material.dart';

import '../../domain/gstr1_filing_models.dart';
import '../../domain/gst_report_models.dart';
import '../theme/gst_report_theme.dart';
import 'gstr1_invoice_register_section.dart';
import 'gstr1_portal_readiness_panel.dart';
import 'gstr1_portal_sections.dart';
import 'gstr1_return_summary_strip.dart';

class Gstr1RegisterView extends StatelessWidget {
  const Gstr1RegisterView({
    super.key,
    required this.snapshot,
    this.segment,
  });

  final GstReportSnapshot snapshot;
  final GstFilingSegment? segment;

  @override
  Widget build(BuildContext context) {
    final filing = Gstr1FilingSnapshot.fromReport(snapshot);

    if (segment == GstFilingSegment.b2b) {
      return _B2bWorkspace(snapshot: snapshot, filing: filing);
    }

    if (segment == GstFilingSegment.b2c) {
      return _B2cWorkspace(snapshot: snapshot, filing: filing);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Gstr1ReturnSummaryStrip(snapshot: snapshot),
        const SizedBox(height: 16),
        Gstr1PortalReadinessPanel(readiness: filing.readiness),
        const SizedBox(height: 16),
        _B2bRegister(snapshot: snapshot),
        const SizedBox(height: 16),
        _B2cLargeRegister(filing: filing),
        const SizedBox(height: 16),
        Gstr1B2cSmallSummarySection(rows: filing.b2cSmallSummary),
        const SizedBox(height: 16),
        _B2cRegister(snapshot: snapshot),
        const SizedBox(height: 16),
        Gstr1HsnSplitSummarySection(
          b2bRows: filing.hsnB2bSummary,
          b2cRows: filing.hsnB2cSummary,
        ),
        const SizedBox(height: 16),
        Gstr1DocumentIssuedSection(rows: filing.documentSummary),
        const SizedBox(height: 16),
        const Gstr1AdditionalTablesPanel(),
      ],
    );
  }
}

class _B2bWorkspace extends StatelessWidget {
  const _B2bWorkspace({
    required this.snapshot,
    required this.filing,
  });

  final GstReportSnapshot snapshot;
  final Gstr1FilingSnapshot filing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Gstr1PortalReadinessPanel(readiness: filing.readiness),
        const SizedBox(height: 16),
        _B2bRegister(snapshot: snapshot),
        const SizedBox(height: 16),
        Gstr1HsnSplitSummarySection(
          b2bRows: filing.hsnB2bSummary,
          b2cRows: const [],
          showB2c: false,
        ),
        const SizedBox(height: 16),
        Gstr1DocumentIssuedSection(rows: filing.documentSummary),
        const SizedBox(height: 16),
        const Gstr1AdditionalTablesPanel(),
      ],
    );
  }
}

class _B2cWorkspace extends StatelessWidget {
  const _B2cWorkspace({
    required this.snapshot,
    required this.filing,
  });

  final GstReportSnapshot snapshot;
  final Gstr1FilingSnapshot filing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Gstr1PortalReadinessPanel(readiness: filing.readiness),
        const SizedBox(height: 16),
        _B2cLargeRegister(filing: filing),
        const SizedBox(height: 16),
        Gstr1B2cSmallSummarySection(rows: filing.b2cSmallSummary),
        const SizedBox(height: 16),
        _B2cRegister(snapshot: snapshot),
        const SizedBox(height: 16),
        Gstr1HsnSplitSummarySection(
          b2bRows: const [],
          b2cRows: filing.hsnB2cSummary,
          showB2b: false,
        ),
        const SizedBox(height: 16),
        Gstr1DocumentIssuedSection(rows: filing.documentSummary),
        const SizedBox(height: 16),
        const Gstr1AdditionalTablesPanel(),
      ],
    );
  }
}

class _B2bRegister extends StatelessWidget {
  const _B2bRegister({required this.snapshot});

  final GstReportSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Gstr1InvoiceRegisterSection(
      title: 'B2B Registered Invoice Register',
      subtitle: 'GSTR-1 outward supplies for customers with GSTIN',
      rows: snapshot.gstr1B2bInvoices,
      accent: GstReportColors.information,
    );
  }
}

class _B2cLargeRegister extends StatelessWidget {
  const _B2cLargeRegister({required this.filing});

  final Gstr1FilingSnapshot filing;

  @override
  Widget build(BuildContext context) {
    return Gstr1InvoiceRegisterSection(
      title: 'B2C Large Invoice Register',
      subtitle: 'Inter-state unregistered invoices above the portal threshold',
      rows: filing.b2cLargeInvoices,
      accent: GstReportColors.warning,
    );
  }
}

class _B2cRegister extends StatelessWidget {
  const _B2cRegister({required this.snapshot});

  final GstReportSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Gstr1InvoiceRegisterSection(
      title: 'B2C Consumer Invoice Register',
      subtitle: 'GSTR-1 outward supplies for unregistered and walk-in customers',
      rows: snapshot.gstr1B2cInvoices,
      accent: GstReportColors.success,
    );
  }
}
