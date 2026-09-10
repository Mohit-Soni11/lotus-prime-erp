import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../core/feedback/app_feedback.dart';
import '../../../../../../theme/settings/billing_setup/billing_setup_colors.dart';
import '../../../../../../ui/settings/billing_setup/billing_setup_app_bar.dart';
import '../../application/booking_advance_billing_controller.dart';
import '../../domain/booking_advance_billing_input.dart';
import '../widgets/booking_advance_billing_form.dart';

class BookingAdvanceBillingWorkspaceScreen extends StatefulWidget {
  const BookingAdvanceBillingWorkspaceScreen({super.key});

  @override
  State<BookingAdvanceBillingWorkspaceScreen> createState() =>
      _BookingAdvanceBillingWorkspaceScreenState();
}

class _BookingAdvanceBillingWorkspaceScreenState
    extends State<BookingAdvanceBillingWorkspaceScreen> {
  late final BookingAdvanceBillingController _controller;
  final _termsController = TextEditingController();
  final _footerController = TextEditingController();
  bool _editorsSynced = false;

  @override
  void initState() {
    super.initState();
    _controller = BookingAdvanceBillingController()
      ..addListener(_handleControllerChanged);
    _controller.load();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleControllerChanged)
      ..dispose();
    _termsController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    final input = _controller.state.input;
    if (!_editorsSynced && input != null) {
      _syncEditors(input);
    }
    if (mounted) setState(() {});
  }

  void _syncEditors(BookingAdvanceBillingInput input) {
    _editorsSynced = true;
    _termsController.text = input.termsAndConditions;
    _footerController.text = input.footerMessage;
  }

  void _forceEditorSync() {
    final input = _controller.state.input;
    if (input != null) _syncEditors(input);
  }

  Future<void> _save() async {
    final saved = await _controller.save();
    if (!mounted) return;
    if (saved) _forceEditorSync();

    AppFeedback.show(
      context,
      type: saved ? AppFeedbackType.success : AppFeedbackType.error,
      message: saved
          ? 'Booking and advance billing settings saved!'
          : 'Please review the highlighted Booking & Advance issues.',
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    final model = state.settings;
    final input = state.input;

    return Scaffold(
      backgroundColor: BillingSetupColors.bodyBg,
      appBar: BillingSetupAppBar(
        screenTitle: 'Booking & Advance',
        screenSubtitle:
            state.isLoading ? 'Loading settings...' : 'Terms and footer copy',
        onBack: () => Navigator.maybePop(context),
      ),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            if (state.isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (model == null || input == null)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'Booking and advance billing settings are unavailable.',
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      _ValidationBanner(messages: state.validationMessages),
                      if (state.validationMessages.isNotEmpty)
                        const SizedBox(height: 18),
                      BookingAdvanceBillingForm(
                        model: model,
                        input: input,
                        termsController: _termsController,
                        footerController: _footerController,
                        onInputChanged: _controller.updateInput,
                        onPrintTermsChanged: _controller.updatePrintTerms,
                        onPrintFooterChanged: _controller.updatePrintFooter,
                      ),
                      const SizedBox(height: 24),
                      _ActionBar(
                        isSaving: state.isSaving,
                        isDirty: state.isDirty,
                        onSave: _save,
                        onReset: () {
                          _controller.resetToDefaults();
                          _forceEditorSync();
                        },
                        onDiscard: () {
                          _controller.discardChanges();
                          _forceEditorSync();
                        },
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ValidationBanner extends StatelessWidget {
  final List<String> messages;

  const _ValidationBanner({required this.messages});

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Required',
            style: GoogleFonts.manrope(
              color: const Color(0xFF991B1B),
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          for (final message in messages)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: const Color(0xFF7F1D1D),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final bool isSaving;
  final bool isDirty;
  final VoidCallback onSave;
  final VoidCallback onReset;
  final VoidCallback onDiscard;

  const _ActionBar({
    required this.isSaving,
    required this.isDirty,
    required this.onSave,
    required this.onReset,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final resetButton = OutlinedButton.icon(
      onPressed: isSaving ? null : onReset,
      icon: const Icon(Icons.restart_alt_rounded, size: 18),
      label: const Text('Reset Defaults'),
      style: OutlinedButton.styleFrom(
        foregroundColor: _BookingAccent.main,
        side: const BorderSide(color: _BookingAccent.soft),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
    final discardButton = OutlinedButton.icon(
      onPressed: isSaving || !isDirty ? null : onDiscard,
      icon: const Icon(Icons.undo_rounded, size: 18),
      label: const Text('Discard'),
      style: OutlinedButton.styleFrom(
        foregroundColor: BillingSetupColors.textDark,
        side: const BorderSide(color: BillingSetupColors.cardBorder),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
    final saveButton = ElevatedButton.icon(
      onPressed: isSaving ? null : onSave,
      icon: isSaving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.save_rounded, size: 18),
      label: Text(isSaving ? 'Saving...' : 'Save Booking Settings'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _BookingAccent.main,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 680) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              saveButton,
              const SizedBox(height: 10),
              resetButton,
              const SizedBox(height: 10),
              discardButton,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: resetButton),
            const SizedBox(width: 12),
            Expanded(child: discardButton),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: saveButton,
            ),
          ],
        );
      },
    );
  }
}

class _BookingAccent {
  static const Color main = Color(0xFF0F766E);
  static const Color soft = Color(0x3320A39E);
}
