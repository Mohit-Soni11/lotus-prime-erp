import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lotus_erp/features/settings/billing_setup/shop_info/data/shop_print_information_repository.dart';
import 'package:lotus_erp/features/settings/billing_setup/shop_info/domain/shop_print_information.dart';
import 'package:lotus_erp/features/settings/billing_setup/shop_info/presentation/widgets/shop_print_information_widgets.dart';
import 'package:lotus_erp/theme/settings/billing_setup/billing_setup_colors.dart';
import 'package:lotus_erp/ui/settings/billing_setup/billing_setup_app_bar.dart';
import 'package:lotus_erp/ui/settings/shop_setup/shop_setup_wizard.dart';

class ShopPrintInformationScreen extends StatefulWidget {
  const ShopPrintInformationScreen({super.key});

  @override
  State<ShopPrintInformationScreen> createState() =>
      _ShopPrintInformationScreenState();
}

class _ShopPrintInformationScreenState
    extends State<ShopPrintInformationScreen> {
  final ShopPrintInformationRepository _repository =
      ShopPrintInformationRepository();

  ShopPrintInformationState? _state;
  bool _isLoading = true;
  bool _isSaving = false;
  OverlayEntry? _saveConfirmationOverlay;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _saveConfirmationOverlay?.remove();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final state = await _repository.load();
    if (!mounted) return;
    setState(() {
      _state = state;
      _isLoading = false;
    });
  }

  void _toggleField(ShopPrintField field, bool enabled) {
    final state = _state;
    if (state == null) return;

    if (enabled && !field.isConfigured) {
      _showMissingFieldGuidance(field);
      return;
    }

    final nextIds = {...state.enabledFieldIds};
    if (enabled) {
      nextIds.add(field.id);
    } else {
      nextIds.remove(field.id);
    }

    setState(() => _state = state.copyWith(enabledFieldIds: nextIds));
  }

  void _showMissingFieldGuidance(ShopPrintField field) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Add ${field.label} in ${field.sourceSection} before enabling it for bill print.',
            style: const TextStyle(color: Colors.white),
          ),
          action: SnackBarAction(
            label: 'Open Profile',
            textColor: BillingSetupColors.onlineGreen,
            onPressed: _openShopProfile,
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 4),
          backgroundColor: BillingSetupColors.shellBg,
        ),
      );
  }

  Future<void> _save() async {
    final state = _state;
    if (state == null) return;

    setState(() => _isSaving = true);
    await _repository.save(state);
    if (!mounted) return;

    setState(() => _isSaving = false);
    _showSaveConfirmation();
  }

  void _showSaveConfirmation() {
    _saveConfirmationOverlay?.remove();

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => const _SaveConfirmationOverlay(),
    );

    _saveConfirmationOverlay = entry;
    overlay.insert(entry);

    Future<void>.delayed(const Duration(milliseconds: 1700), () {
      if (_saveConfirmationOverlay == entry) {
        entry.remove();
        _saveConfirmationOverlay = null;
      }
    });
  }

  Future<void> _openShopProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ShopSetupWizard()),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;

    return Scaffold(
      backgroundColor: BillingSetupColors.bodyBg,
      appBar: BillingSetupAppBar(
        screenTitle: 'Shop Print Information',
        screenSubtitle: 'Bill header, legal, contact and social print controls',
        onBack: () => Navigator.maybePop(context),
      ),
      body: SafeArea(
        top: false,
        child: _isLoading || state == null
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          ShopPrintInformationSummary(
                            state: state,
                            onOpenShopProfile: _openShopProfile,
                          ),
                          const SizedBox(height: 18),
                          for (final group in ShopPrintFieldGroup.values) ...[
                            ShopPrintInformationSection(
                              group: group,
                              fields: state.fields
                                  .where((field) => field.group == group)
                                  .toList(growable: false),
                              isEnabled: state.isEnabled,
                              onChanged: _toggleField,
                              onMissingFieldTap: _showMissingFieldGuidance,
                            ),
                            const SizedBox(height: 18),
                          ],
                          _SaveButton(
                            isSaving: _isSaving,
                            onPressed: _save,
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

class _SaveConfirmationOverlay extends StatelessWidget {
  const _SaveConfirmationOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        child: Material(
          color: Colors.black.withValues(alpha: 0.08),
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.94, end: 1),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                final opacity = ((value - 0.94) / 0.06).clamp(0.0, 1.0);

                return Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: value,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 330,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: BillingSetupColors.successBorder,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 34,
                      offset: Offset(0, 18),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: BillingSetupColors.successBg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: BillingSetupColors.successBorder,
                        ),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: BillingSetupColors.success,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Saved Successfully',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        color: BillingSetupColors.textDark,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Shop print information is ready for billing documents.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: BillingSetupColors.textBody,
                        fontSize: 12.5,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onPressed;

  const _SaveButton({
    required this.isSaving,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isSaving ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: BillingSetupColors.success,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'Save Shop Print Information',
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
      ),
    );
  }
}
