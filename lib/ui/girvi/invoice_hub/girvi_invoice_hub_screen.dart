import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../logic/girvi/girvi_invoice_hub_controller.dart';
import '../../../logic/girvi/girvi_invoice_pdf_service.dart';
import '../../../models/girvi/girvi_invoice_draft.dart';
import '../../../theme/girvi/girvi_theme.dart';

part 'parts/girvi_invoice_hub_actions.dart';
part 'parts/girvi_invoice_hub_controls.dart';
part 'parts/girvi_invoice_hub_header.dart';
part 'parts/girvi_invoice_hub_preview.dart';

class GirviInvoiceHubScreen extends StatefulWidget {
  const GirviInvoiceHubScreen({
    super.key,
    required this.draft,
    required this.onFinalize,
  });

  final GirviInvoiceDraft draft;
  final Future<bool> Function() onFinalize;

  static Future<bool?> push(
    BuildContext context, {
    required GirviInvoiceDraft draft,
    required Future<bool> Function() onFinalize,
  }) {
    return Navigator.of(context).push<bool>(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => GirviInvoiceHubScreen(
          draft: draft,
          onFinalize: onFinalize,
        ),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }

  @override
  State<GirviInvoiceHubScreen> createState() => _GirviInvoiceHubScreenState();
}

class _GirviInvoiceHubScreenState extends State<GirviInvoiceHubScreen> {
  late final GirviInvoiceHubController _controller;
  bool _exported = false;

  @override
  void initState() {
    super.initState();
    _controller = GirviInvoiceHubController(
      draft: widget.draft,
      onFinalize: widget.onFinalize,
    )..addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.generatePreview();
    });
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _markExported() {
    if (mounted) setState(() => _exported = true);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _closeHub() {
    Navigator.of(context).pop(_controller.isFinalized);
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? GirviColors.danger : GirviColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GirviColors.bodyBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 900) {
              return Column(
                children: [
                  _buildCompactHeader(),
                  Expanded(child: _buildRightPreviewPanel()),
                  SizedBox(
                    height: 290,
                    child: _buildControlPanel(compact: true),
                  ),
                ],
              );
            }
            return Row(
              children: [
                SizedBox(
                  width: 430,
                  child: _buildControlPanel(),
                ),
                Expanded(child: _buildRightPreviewPanel()),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildControlPanel({bool compact = false}) {
    return Container(
      decoration: const BoxDecoration(
        color: GirviColors.shellBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          if (!compact) _buildHubHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(compact ? 14 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetectedProfile(),
                  const SizedBox(height: 20),
                  _buildFormatSelector(),
                  const SizedBox(height: 20),
                  _buildOutputOptions(),
                  if (_controller.errorMessage != null) ...[
                    const SizedBox(height: 14),
                    _buildErrorNotice(_controller.errorMessage!),
                  ],
                ],
              ),
            ),
          ),
          _buildActionFooter(compact: compact),
        ],
      ),
    );
  }
}
