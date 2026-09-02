import 'package:flutter/material.dart';

import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_controller.dart';
import 'package:lotus_erp/features/sales/return_reversal/presentation/theme/return_reversal_design_tokens.dart';
import 'package:lotus_erp/features/sales/return_reversal/presentation/widgets/customer/return_reversal_customer_details_card.dart';
import 'package:lotus_erp/features/sales/return_reversal/presentation/widgets/document/return_reversal_document_status_card.dart';
import 'package:lotus_erp/features/sales/return_reversal/presentation/widgets/setup/return_reversal_operation_setup_card.dart';
import 'package:lotus_erp/features/sales/return_reversal/presentation/widgets/summary/return_reversal_invoice_summary_panel.dart';
import 'package:lotus_erp/features/sales/return_reversal/presentation/widgets/workflow/return_reversal_workflow_tabs.dart';

class ReturnReversalDeskBody extends StatelessWidget {
  final ReturnReversalController controller;

  const ReturnReversalDeskBody({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final useWorkspaceColumns = constraints.maxWidth >= 1240;

            if (useWorkspaceColumns) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  ReturnReversalDesignTokens.pagePadding,
                  22,
                  ReturnReversalDesignTokens.pagePadding,
                  34,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 70,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: _ReturnReversalPrimaryWorkspace(
                          controller: controller,
                          sideBySideHeader: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      flex: 30,
                      child: ReturnReversalInvoiceSummaryPanel(
                        controller: controller,
                      ),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                ReturnReversalDesignTokens.pagePadding,
                22,
                ReturnReversalDesignTokens.pagePadding,
                34,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ReturnReversalPrimaryWorkspace(
                    controller: controller,
                    sideBySideHeader: constraints.maxWidth > 980,
                  ),
                  const SizedBox(height: 18),
                  ReturnReversalInvoiceSummaryPanel(controller: controller),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ReturnReversalPrimaryWorkspace extends StatelessWidget {
  final ReturnReversalController controller;
  final bool sideBySideHeader;

  const _ReturnReversalPrimaryWorkspace({
    required this.controller,
    required this.sideBySideHeader,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sideBySideHeader
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReturnReversalOperationSetupCard(controller: controller),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ReturnReversalDocumentStatusCard(
                      controller: controller,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ReturnReversalOperationSetupCard(controller: controller),
                  const SizedBox(height: 12),
                  ReturnReversalDocumentStatusCard(controller: controller),
                ],
              ),
        const SizedBox(height: 14),
        ReturnReversalCustomerDetailsCard(controller: controller),
        const SizedBox(height: 16),
        ReturnReversalWorkflowTabs(controller: controller),
      ],
    );
  }
}
