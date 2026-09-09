import 'package:flutter/material.dart';

import '../../../features/print_templates/domain/print_template_registry.dart';
import '../../../logic/booking_advance/booking_invoice_preview_controller.dart';
import '../../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import '../../../theme/booking_advance/booking_advance_theme.dart';

part 'booking_invoice_command_actions.dart';
part 'booking_invoice_command_design.dart';
part 'booking_invoice_command_format.dart';
part 'booking_invoice_command_header.dart';
part 'booking_invoice_command_printing.dart';
part 'booking_invoice_command_shared.dart';

class BookingInvoiceCommandPanel extends StatelessWidget {
  const BookingInvoiceCommandPanel({
    super.key,
    required this.controller,
    required this.isSharing,
    required this.isExporting,
    required this.isPrinting,
    required this.isCompleting,
    required this.isExported,
    required this.isPrinted,
    required this.onBack,
    required this.onShare,
    required this.onExport,
    required this.onPrint,
    required this.onSaveAndNew,
  });

  final BookingInvoicePreviewController controller;
  final bool isSharing;
  final bool isExporting;
  final bool isPrinting;
  final bool isCompleting;
  final bool isExported;
  final bool isPrinted;
  final VoidCallback onBack;
  final Future<void> Function() onShare;
  final Future<void> Function() onExport;
  final Future<void> Function() onPrint;
  final Future<void> Function() onSaveAndNew;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 440,
      decoration: const BoxDecoration(
        color: BookingAdvanceColors.shellBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 15,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _CommandHeader(controller: controller, onBack: onBack),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FormatSection(controller: controller),
                  const SizedBox(height: 24),
                  _DesignSection(controller: controller),
                  const SizedBox(height: 24),
                  _PrintControlsSection(controller: controller),
                ],
              ),
            ),
          ),
          _ActionFooter(
            controller: controller,
            isSharing: isSharing,
            isExporting: isExporting,
            isPrinting: isPrinting,
            isCompleting: isCompleting,
            isExported: isExported,
            isPrinted: isPrinted,
            onShare: onShare,
            onExport: onExport,
            onPrint: onPrint,
            onSaveAndNew: onSaveAndNew,
          ),
        ],
      ),
    );
  }
}
