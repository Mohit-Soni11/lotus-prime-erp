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

  @override
  void initState() {
    super.initState();
    _load();
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

    final nextIds = {...state.enabledFieldIds};
    if (enabled) {
      nextIds.add(field.id);
    } else {
      nextIds.remove(field.id);
    }

    setState(() => _state = state.copyWith(enabledFieldIds: nextIds));
  }

  Future<void> _save() async {
    final state = _state;
    if (state == null) return;

    setState(() => _isSaving = true);
    await _repository.save(state);
    if (!mounted) return;

    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text(
            'Shop print information settings saved.',
            style: TextStyle(color: Colors.white),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: BillingSetupColors.success,
        ),
      );
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
