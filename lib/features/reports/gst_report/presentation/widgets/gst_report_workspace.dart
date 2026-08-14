import 'package:flutter/material.dart';

import '../../application/gst_report_controller.dart';
import '../../domain/gst_report_models.dart';
import 'gst_audit_view.dart';
import 'gst_dashboard_view.dart';
import 'gstr1_register_view.dart';
import 'gstr3b_summary_view.dart';
import 'hsn_gst_register_view.dart';

class GstReportWorkspace extends StatelessWidget {
  const GstReportWorkspace({
    super.key,
    required this.controller,
    required this.snapshot,
  });

  final GstReportController controller;
  final GstReportSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    switch (controller.selectedTab) {
      case GstReportTab.dashboard:
        return GstDashboardView(snapshot: snapshot);
      case GstReportTab.gstr1:
        return Gstr1RegisterView(snapshot: snapshot);
      case GstReportTab.gstr3b:
        return Gstr3bSummaryView(snapshot: snapshot);
      case GstReportTab.hsnRegister:
        return HsnGstRegisterView(snapshot: snapshot);
      case GstReportTab.audit:
        return GstAuditView(snapshot: snapshot);
    }
  }
}
