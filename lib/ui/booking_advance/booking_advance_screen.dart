// =============================================================================
// FILE        : booking_advance_screen.dart
// MODULE      : Sales -> Booking & Advance
// DESCRIPTION : Main booking workspace shell.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../logic/booking_advance/booking_advance_controller.dart';
import '../../../theme/booking_advance/booking_advance_theme.dart';
import 'booking_advance_app_bar.dart';
import 'widgets/booking_workspace_layout.dart';

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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: BookingAdvanceColors.bodyBg,
          appBar: BookingAdvanceAppBar(
            onBack: _handleBack,
            title: widget.editOrderId != null
                ? 'EDIT ADVANCE ORDER'
                : BookingAdvanceStrings.appBarTitle,
          ),
          body: _buildBody(),
        ),
      ),
    );
  }

  void _handleBack() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
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
              onPressed: _handleBack,
              child: const Text('Back'),
            ),
          ],
        ),
      );
    }

    return BookingWorkspaceLayout(
      controller: _ctrl,
      scrollController: _scrollCtrl,
    );
  }
}
