// =============================================================================
// FILE        : booking_advance_screen.dart
// MODULE      : Sales -> Booking & Advance
// DESCRIPTION : Main booking workspace shell.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../logic/booking_advance/booking_advance_controller.dart';
import '../../../theme/booking_advance/booking_advance_theme.dart';
import 'booking_advance_app_bar.dart';
import 'booking_customer_panel.dart';
import 'booking_items_table.dart';
import 'booking_right_panel.dart';
import 'booking_scrap_table.dart';
import 'booking_status_bar.dart';
import 'booking_top_control_bar.dart';

class BookingAdvanceScreen extends StatefulWidget {
  const BookingAdvanceScreen({
    super.key,
    this.onBack,
    this.editOrderId,
  });

  final VoidCallback? onBack;
  final int? editOrderId;

  @override
  State<BookingAdvanceScreen> createState() => _BookingAdvanceScreenState();
}

class _BookingAdvanceScreenState extends State<BookingAdvanceScreen> {
  late final BookingAdvanceController _ctrl;
  final ScrollController _scrollCtrl = ScrollController();
  bool _isLoadingEditOrder = false;
  String? _editLoadError;

  @override
  void initState() {
    super.initState();
    _ctrl = BookingAdvanceController();

    final editOrderId = widget.editOrderId;
    if (editOrderId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadEditOrder(editOrderId);
      });
    }
  }

  Future<void> _loadEditOrder(int orderId) async {
    if (!mounted) return;
    setState(() {
      _isLoadingEditOrder = true;
      _editLoadError = null;
    });

    final loaded = await _ctrl.initializeForEdit(orderId);
    if (!mounted) return;

    setState(() {
      _isLoadingEditOrder = false;
      _editLoadError = loaded
          ? null
          : _ctrl.editLoadError ??
              'Advance order could not be loaded for editing.';
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: BookingAdvanceColors.bodyBg,
        appBar: BookingAdvanceAppBar(
          onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
          title: widget.editOrderId != null
              ? 'EDIT ADVANCE ORDER'
              : BookingAdvanceStrings.appBarTitle,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingEditOrder) {
      return const Center(
        child: CircularProgressIndicator(color: BookingAdvanceColors.brandGold),
      );
    }

    if (_editLoadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.pending_actions_rounded,
              color: BookingAdvanceColors.bodyTextMuted,
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              _editLoadError!,
              style: const TextStyle(
                color: BookingAdvanceColors.bodyTextMain,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed:
                  widget.onBack ?? () => Navigator.of(context).maybePop(),
              child: const Text('Back'),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 70,
              child: SingleChildScrollView(
                controller: _scrollCtrl,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(
                      builder: (_, constraints) {
                        final sideBySide = constraints.maxWidth > 720;
                        if (sideBySide) {
                          return IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                BookingTopControlBar(ctrl: _ctrl),
                                const SizedBox(width: 16),
                                Expanded(child: BookingStatusBar(ctrl: _ctrl)),
                              ],
                            ),
                          );
                        }
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            BookingTopControlBar(ctrl: _ctrl),
                            const SizedBox(height: 12),
                            BookingStatusBar(ctrl: _ctrl),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    BookingCustomerPanel(ctrl: _ctrl),
                    const SizedBox(height: 16),
                    BookingItemsTable(ctrl: _ctrl),
                    const SizedBox(height: 16),
                    BookingScrapTable(ctrl: _ctrl),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              flex: 30,
              child: BookingRightPanel(
                ctrl: _ctrl,
                onSaved: (message, isSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      backgroundColor: isSuccess
                          ? BookingAdvanceColors.success
                          : BookingAdvanceColors.danger,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
