// -----------------------------------------------------------------------------
// FILE: tax_gst_tab.dart
// TYPE: Presentation Layer (UI)
// AUTHOR: Senior System Architect
// DESCRIPTION: 100% Theme injected, Zero-Lag UI powered by ListenableBuilder.
//              ðŸš€ UPGRADED: Added Auto-Fill Initial Data support.
// -----------------------------------------------------------------------------

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:path/path.dart' as p;

// --- THEME IMPORTS ---
// NOTE: Adjust paths according to your structure.
import '../../../../theme/settings/shop_setup/tabs/tax_gst/tax_gst_theme.dart';

// --- LOGIC IMPORTS ---
import '../../../../logic/setting/shop_setup/tabs/tax_gst/tax_gst_logic.dart';
import '../../../../logic/setting/shop_setup/tabs/tax_gst/document_crop_logic.dart';
import '../../../../models/setting/shop_setup/enums/tax_gst_enums.dart';
import '../../../../models/setting/shop_setup/tabs/tax_gst_model.dart';
import 'package:flutter/foundation.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';

class TaxGstTab extends StatefulWidget {
  // ðŸš€ NEW: Receive initial data from parent
  final Map<String, dynamic>? initialData;

  const TaxGstTab({super.key, this.initialData});

  @override
  State<TaxGstTab> createState() => TaxGstTabState();
}

class TaxGstTabState extends State<TaxGstTab> {
  late TaxGstLogic logic;

  @override
  void initState() {
    super.initState();
    logic = TaxGstLogic();

    // ðŸš€ NEW: AUTO-FILL LOGIC
    // Agar database se data mila hai, toh usko controllers aur logic mein set kar do
    if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      final parsedTaxData = TaxGstModel.fromJson(widget.initialData!);
      logic.gstinCtrl.text = widget.initialData!['gstin']?.toString() ?? '';
      logic.legalNameCtrl.text =
          widget.initialData!['legal_name']?.toString() ?? '';
      final legacyBisLicense =
          widget.initialData!['bis_license_no']?.toString() ?? '';
      logic.bisLicCtrl.text = parsedTaxData.bisLicenseNo.isNotEmpty
          ? parsedTaxData.bisLicenseNo
          : legacyBisLicense.trim();
      logic.goldBisLicCtrl.text = parsedTaxData.goldBisLicenseNo;
      logic.silverBisLicCtrl.text = parsedTaxData.silverBisLicenseNo;
      logic.setHallmarkingSelection(
        scope: parsedTaxData.hallmarkingScope,
        registrationMode: parsedTaxData.bisRegistrationMode,
      );

      if (widget.initialData!['reg_date'] != null) {
        logic.setRegDate(widget.initialData!['reg_date'].toString());
      }

      if (widget.initialData!['taxpayer_type'] != null) {
        logic.setTaxpayer(widget.initialData!['taxpayer_type'].toString());
      }

      if (widget.initialData!['gst_cert_path'] != null &&
          widget.initialData!['gst_cert_path'].toString().isNotEmpty) {
        logic.updateGstFile(
            File(widget.initialData!['gst_cert_path'].toString()));
      }

      if (widget.initialData!['bis_license_path'] != null &&
          widget.initialData!['bis_license_path'].toString().isNotEmpty) {
        logic.updateBisFile(
            File(widget.initialData!['bis_license_path'].toString()));
      }
    }
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  TaxGstModel? validateAndExport() {
    return logic.validateAndGenerateFinalModel();
  }

  // --- SMART TOGGLE HANDLING FOR FORM ---
  void _handleSectionToggle(String sectionId, String sectionName) async {
    if (logic.loadingSection == sectionId) return;

    if (logic.isSectionLocked(sectionId)) {
      FocusNode? targetNode = logic.unlockSection(sectionId);
      if (targetNode != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) FocusScope.of(context).requestFocus(targetNode);
        });
      }
    } else {
      bool success = await logic.saveSection(sectionId);
      if (success && mounted) {
        _showSaveFeedback(TaxGstStrings.feedbackTaxSyncDone);
      }
    }
  }

  // --- DATE PICKER LOGIC ---
  Future<void> _selectDate(TextEditingController controller) async {
    if (logic.isGstLocked && controller == logic.regDateCtrl) return;

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      helpText: TaxGstStrings.dlgSelectDate,
      cancelText: TaxGstStrings.btnCancel,
      confirmText: TaxGstStrings.btnConfirm,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: TaxGstColors.goldAccent,
              onPrimary: TaxGstColors.cardBg,
              surface: TaxGstColors.cardBg,
              onSurface: TaxGstColors.textDark,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: TaxGstColors.cardBg,
              elevation: 24,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TaxGstStyles.rDialog)),
              headerBackgroundColor: TaxGstColors.goldAccent,
              headerForegroundColor: TaxGstColors.cardBg,
              headerHeadlineStyle: TaxGstStyles.dialogTitle,
            ),
            dialogTheme:
                const DialogThemeData(backgroundColor: TaxGstColors.cardBg),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      String formattedDate =
          "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      if (controller == logic.regDateCtrl) {
        logic.setRegDate(formattedDate);
      }
    }
  }

  void _showSaveFeedback(String msg, {bool isError = false}) {
    if (!mounted) return;
    AppFeedback.show(
      context,
      type: isError ? AppFeedbackType.error : AppFeedbackType.success,
      message: msg,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      bool isDesktop = constraints.maxWidth > 1000;
      return SingleChildScrollView(
        padding: TaxGstStyles.padPageBottom,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(),
            const SizedBox(height: TaxGstStyles.gapSection),
            ListenableBuilder(
                listenable: logic,
                builder: (context, child) {
                  return isDesktop
                      ? _buildDesktopLayout()
                      : _buildMobileLayout();
                }),
          ],
        ),
      );
    });
  }

  Widget _buildPageHeader() {
    final statusBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: TaxGstColors.statusActiveBg,
        borderRadius: BorderRadius.circular(TaxGstStyles.rStatusPill),
        border: Border.all(color: TaxGstColors.statusActiveText30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(TaxGstIcons.statusShield,
              size: 16, color: TaxGstColors.statusActiveText),
          const SizedBox(width: 8),
          Text(TaxGstStrings.badgeComplianceActive,
              style: TaxGstStyles.statusPill),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackHeader = constraints.maxWidth < 680;
        final titleBlock = Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: TaxGstColors.goldAccent10,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TaxGstColors.goldAccent30),
              ),
              child: const Icon(
                TaxGstIcons.secGst,
                color: TaxGstColors.goldAccent,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TaxGstStrings.pageTitle,
                    style: TaxGstStyles.pageTitle.copyWith(
                      color: TaxGstColors.surfaceWhite,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    TaxGstStrings.pageSubtitle,
                    style: TaxGstStyles.pageSubtitle.copyWith(
                      color: TaxGstColors.textHint,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );

        if (stackHeader) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 12),
              statusBadge,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: 16),
            statusBadge,
          ],
        );
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 60, child: _buildGstCard()),
            const SizedBox(width: TaxGstStyles.gapCard),
            Expanded(
                flex: 40,
                child: EnterpriseDocumentWidget(
                  title: TaxGstStrings.docGstTitle,
                  subtitle: TaxGstStrings.docGstSub,
                  icon: TaxGstIcons.secGst,
                  currentFile: logic.gstCertFile,
                  isInitiallyLocked: logic.isGstLocked,
                  onImageSaved: logic.updateGstFile,
                  useTallPreview: true,
                )),
          ],
        ),
        const SizedBox(height: TaxGstStyles.gapCard),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 60, child: _buildBisCard()),
            const SizedBox(width: TaxGstStyles.gapCard),
            Expanded(
                flex: 40,
                child: EnterpriseDocumentWidget(
                  title: TaxGstStrings.docBisTitle,
                  subtitle: TaxGstStrings.docBisSub,
                  icon: TaxGstIcons.secBis,
                  currentFile: logic.bisLicenseFile,
                  isInitiallyLocked: logic.isBisLocked,
                  onImageSaved: logic.updateBisFile,
                  useTallPreview: true,
                )),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildGstCard(),
        const SizedBox(height: TaxGstStyles.gapCard),
        EnterpriseDocumentWidget(
          title: TaxGstStrings.docGstTitle,
          subtitle: TaxGstStrings.docGstSub,
          icon: TaxGstIcons.secGst,
          currentFile: logic.gstCertFile,
          isInitiallyLocked: logic.isGstLocked,
          onImageSaved: logic.updateGstFile,
        ),
        const SizedBox(height: TaxGstStyles.gapCard),
        _buildBisCard(),
        const SizedBox(height: TaxGstStyles.gapCard),
        EnterpriseDocumentWidget(
          title: TaxGstStrings.docBisTitle,
          subtitle: TaxGstStrings.docBisSub,
          icon: TaxGstIcons.secBis,
          currentFile: logic.bisLicenseFile,
          isInitiallyLocked: logic.isBisLocked,
          onImageSaved: logic.updateBisFile,
        ),
      ],
    );
  }

  Widget _buildGstCard() {
    return Container(
      padding: TaxGstStyles.padCardInternal,
      decoration: TaxGstStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
              "gst",
              TaxGstStrings.secGstTitle,
              TaxGstIcons.secGst,
              logic.isGstLocked,
              () => _handleSectionToggle('gst', TaxGstStrings.secGstTitle)),
          const Divider(
              height: 40, thickness: 1, color: TaxGstColors.borderLight),
          _buildSectionLabel(TaxGstStrings.secGstLabel),
          const SizedBox(height: TaxGstStyles.gapInput),
          _buildThemeInput(
            label: TaxGstStrings.lblGstin,
            hint: TaxGstStrings.hintGstin,
            icon: TaxGstIcons.gstNum,
            ctrl: logic.gstinCtrl,
            isLocked: logic.isGstLocked,
            focusNode: logic.gstinFocus,
            nextFocus: logic.legalNameFocus,
            maxLength: 15,
            isCapital: true,
            brandColor: TaxGstColors.brandGstin,
          ),
          const SizedBox(height: TaxGstStyles.gapInput),
          _buildThemeInput(
            label: TaxGstStrings.lblLegalName,
            hint: TaxGstStrings.hintLegalName,
            icon: TaxGstIcons.gstLegalName,
            ctrl: logic.legalNameCtrl,
            isLocked: logic.isGstLocked,
            focusNode: logic.legalNameFocus,
            brandColor: TaxGstColors.brandLegal,
          ),
          const SizedBox(height: TaxGstStyles.gapInput),
          Row(
            children: [
              Expanded(
                  child: _buildDateInput(
                      label: TaxGstStrings.lblRegDate,
                      hint: TaxGstStrings.hintDate,
                      icon: TaxGstIcons.calendar,
                      ctrl: logic.regDateCtrl,
                      isLocked: logic.isGstLocked,
                      focusNode: logic.regDateFocus)),
              const SizedBox(width: 20),
              Expanded(
                  child: _buildDropdownInput(
                      label: TaxGstStrings.lblTaxpayerType,
                      icon: TaxGstIcons.taxpayer,
                      value: logic.selectedTaxpayer.displayName,
                      items: logic.taxpayerTypes,
                      isLocked: logic.isGstLocked,
                      onChanged: (val) => logic.setTaxpayer(val!))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBisCard() {
    return Container(
      padding: TaxGstStyles.padCardInternal,
      decoration: TaxGstStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
              "bis",
              TaxGstStrings.secBisTitle,
              TaxGstIcons.secBis,
              logic.isBisLocked,
              () => _handleSectionToggle('bis', TaxGstStrings.secBisTitle)),
          const Divider(
              height: 40, thickness: 1, color: TaxGstColors.borderLight),
          _buildSectionLabel(TaxGstStrings.secBisLabel),
          const SizedBox(height: TaxGstStyles.gapInput),
          _buildHallmarkingScopeSelector(isLocked: logic.isBisLocked),
          if (logic.usesSharedBisRegistration) ...[
            const SizedBox(height: TaxGstStyles.gapInput),
            _buildThemeInput(
              label: TaxGstStrings.lblBisLic,
              hint: TaxGstStrings.hintBisLic,
              icon: TaxGstIcons.bisVerified,
              ctrl: logic.bisLicCtrl,
              isLocked: logic.isBisLocked,
              focusNode: logic.bisLicFocus,
              isCapital: true,
              brandColor: TaxGstColors.brandBis,
            ),
          ],
          if (logic.showsGoldBisRegistration) ...[
            const SizedBox(height: TaxGstStyles.gapInput),
            _buildThemeInput(
              label: TaxGstStrings.lblGoldBisLic,
              hint: TaxGstStrings.hintGoldBisLic,
              icon: TaxGstIcons.bisVerified,
              ctrl: logic.goldBisLicCtrl,
              isLocked: logic.isBisLocked,
              focusNode: logic.goldBisLicFocus,
              nextFocus: logic.showsSilverBisRegistration
                  ? logic.silverBisLicFocus
                  : null,
              isCapital: true,
              brandColor: TaxGstColors.goldAccent,
            ),
          ],
          if (logic.showsSilverBisRegistration) ...[
            const SizedBox(height: TaxGstStyles.gapInput),
            _buildThemeInput(
              label: TaxGstStrings.lblSilverBisLic,
              hint: TaxGstStrings.hintSilverBisLic,
              icon: TaxGstIcons.bisVerified,
              ctrl: logic.silverBisLicCtrl,
              isLocked: logic.isBisLocked,
              focusNode: logic.silverBisLicFocus,
              isCapital: true,
              brandColor: TaxGstColors.textMuted,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThemeInput({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController ctrl,
    required bool isLocked,
    FocusNode? focusNode,
    FocusNode? nextFocus,
    int? maxLength,
    bool isCapital = false,
    Color? brandColor,
  }) {
    bool isActive = !isLocked && (focusNode?.hasFocus ?? false);
    Color iconColor = isActive
        ? TaxGstColors.goldAccent
        : (ctrl.text.isNotEmpty
            ? (brandColor ?? TaxGstColors.iconSuccess)
            : TaxGstColors.textHint);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TaxGstStyles.fieldLabel),
        const SizedBox(height: 8),
        Container(
          height: TaxGstStyles.hInputField,
          decoration: isActive
              ? TaxGstStyles.activeInputDecoration
              : TaxGstStyles.inputDecoration(isLocked),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(icon,
                      key: ValueKey(iconColor), size: 20, color: iconColor)),
              const SizedBox(width: 12),
              Container(width: 1, height: 24, color: TaxGstColors.borderLight),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: ctrl,
                  readOnly: isLocked,
                  focusNode: focusNode,
                  textCapitalization: isCapital
                      ? TextCapitalization.characters
                      : TextCapitalization.none,
                  maxLength: maxLength,
                  inputFormatters: maxLength != null
                      ? [LengthLimitingTextInputFormatter(maxLength)]
                      : [],
                  onFieldSubmitted: (_) => nextFocus != null
                      ? FocusScope.of(context).requestFocus(nextFocus)
                      : null,
                  style: TaxGstStyles.fieldText,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    counterText: "",
                    hintText: hint,
                    hintStyle: TaxGstStyles.fieldHint,
                    contentPadding: const EdgeInsets.only(bottom: 2),
                  ),
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildDateInput(
      {required String label,
      required String hint,
      required IconData icon,
      required TextEditingController ctrl,
      required bool isLocked,
      required FocusNode focusNode}) {
    bool isActive = !isLocked && focusNode.hasFocus;
    Color iconColor = isActive
        ? TaxGstColors.goldAccent
        : (ctrl.text.isNotEmpty
            ? TaxGstColors.iconSuccess
            : TaxGstColors.textHint);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TaxGstStyles.fieldLabel),
        const SizedBox(height: 8),
        InkWell(
          onTap: isLocked ? null : () => _selectDate(ctrl),
          child: Container(
            height: TaxGstStyles.hInputField,
            decoration: isActive
                ? TaxGstStyles.activeInputDecoration
                : TaxGstStyles.inputDecoration(isLocked),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Icon(icon,
                        key: ValueKey(iconColor), size: 20, color: iconColor)),
                const SizedBox(width: 12),
                Container(
                    width: 1, height: 24, color: TaxGstColors.borderLight),
                const SizedBox(width: 12),
                Expanded(
                  child: IgnorePointer(
                    child: TextFormField(
                      controller: ctrl,
                      readOnly: true,
                      focusNode: focusNode,
                      style: TaxGstStyles.fieldText,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: hint,
                        hintStyle: TaxGstStyles.fieldHint,
                        contentPadding: const EdgeInsets.only(bottom: 2),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildDropdownInput(
      {required String label,
      required IconData icon,
      required String value,
      required List<String> items,
      required bool isLocked,
      required Function(String?) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TaxGstStyles.fieldLabel),
        const SizedBox(height: 8),
        Container(
          height: TaxGstStyles.hInputField,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: TaxGstStyles.inputDecoration(isLocked),
          child: Row(
            children: [
              Icon(icon,
                  size: 20,
                  color: isLocked
                      ? TaxGstColors.textHint
                      : TaxGstColors.iconSuccess),
              const SizedBox(width: 12),
              Container(width: 1, height: 24, color: TaxGstColors.borderLight),
              const SizedBox(width: 12),
              Expanded(
                child: isLocked
                    ? Container(
                        alignment: Alignment.centerLeft,
                        child: Text(value, style: TaxGstStyles.fieldText),
                      )
                    : DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: TaxGstColors.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          value: items.contains(value) ? value : items[0],
                          isExpanded: true,
                          icon: const Icon(TaxGstIcons.arrowRight,
                              color: TaxGstColors.textBody),
                          style: TaxGstStyles.fieldText,
                          onChanged: onChanged,
                          items: items
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                        ),
                      ),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildHallmarkingScopeSelector({required bool isLocked}) {
    final choices = isLocked
        ? [_selectedHallmarkingChoice()]
        : const [
            _HallmarkingChoice(
              label: TaxGstStrings.scopeGold,
              scope: HallmarkingScope.gold,
              mode: BisRegistrationMode.single,
              color: TaxGstColors.goldAccent,
            ),
            _HallmarkingChoice(
              label: TaxGstStrings.scopeSilver,
              scope: HallmarkingScope.silver,
              mode: BisRegistrationMode.single,
              color: TaxGstColors.textMuted,
            ),
            _HallmarkingChoice(
              label: TaxGstStrings.scopeBoth,
              scope: HallmarkingScope.goldAndSilver,
              mode: BisRegistrationMode.single,
              color: TaxGstColors.iconSuccess,
            ),
            _HallmarkingChoice(
              label: TaxGstStrings.scopeSeparate,
              scope: HallmarkingScope.goldAndSilver,
              mode: BisRegistrationMode.separate,
              color: TaxGstColors.brandBis,
            ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(TaxGstStrings.lblHallmarkingScope, style: TaxGstStyles.fieldLabel),
        const SizedBox(height: 8),
        Container(
          constraints:
              const BoxConstraints(minHeight: TaxGstStyles.hInputField),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: TaxGstStyles.inputDecoration(isLocked),
          child: Row(
            children: [
              Icon(
                TaxGstIcons.hallmarkingScope,
                size: 20,
                color:
                    isLocked ? TaxGstColors.textHint : TaxGstColors.iconSuccess,
              ),
              const SizedBox(width: 12),
              Container(width: 1, height: 24, color: TaxGstColors.borderLight),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: choices
                      .map(
                        (choice) => _buildScopeChip(
                          label: choice.label,
                          selected: _isHallmarkingChoiceSelected(choice),
                          isLocked: isLocked,
                          color: choice.color,
                          onTap: () => logic.setHallmarkingSelection(
                            scope: choice.scope,
                            registrationMode: choice.mode,
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  _HallmarkingChoice _selectedHallmarkingChoice() {
    if (logic.selectedHallmarkingScope == HallmarkingScope.gold) {
      return const _HallmarkingChoice(
        label: TaxGstStrings.scopeGold,
        scope: HallmarkingScope.gold,
        mode: BisRegistrationMode.single,
        color: TaxGstColors.goldAccent,
      );
    }
    if (logic.selectedHallmarkingScope == HallmarkingScope.silver) {
      return const _HallmarkingChoice(
        label: TaxGstStrings.scopeSilver,
        scope: HallmarkingScope.silver,
        mode: BisRegistrationMode.single,
        color: TaxGstColors.textMuted,
      );
    }
    if (logic.selectedBisRegistrationMode == BisRegistrationMode.separate) {
      return const _HallmarkingChoice(
        label: TaxGstStrings.scopeSeparate,
        scope: HallmarkingScope.goldAndSilver,
        mode: BisRegistrationMode.separate,
        color: TaxGstColors.brandBis,
      );
    }
    return const _HallmarkingChoice(
      label: TaxGstStrings.scopeBoth,
      scope: HallmarkingScope.goldAndSilver,
      mode: BisRegistrationMode.single,
      color: TaxGstColors.iconSuccess,
    );
  }

  bool _isHallmarkingChoiceSelected(_HallmarkingChoice choice) {
    return logic.selectedHallmarkingScope == choice.scope &&
        logic.selectedBisRegistrationMode == choice.mode;
  }

  Widget _buildScopeChip({
    required String label,
    required bool selected,
    required bool isLocked,
    required Color color,
    required VoidCallback onTap,
  }) {
    final textColor =
        selected ? TaxGstColors.surfaceWhite : TaxGstColors.textBody;
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: isLocked ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? color : TaxGstColors.cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? color : TaxGstColors.borderLight,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(
                  TaxGstIcons.check,
                  size: 14,
                  color: TaxGstColors.surfaceWhite,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(String sectionId, String title, IconData icon,
      bool isLocked, VoidCallback onToggle) {
    bool isSaving = logic.loadingSection == sectionId;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: TaxGstColors.goldAccent10,
                    borderRadius:
                        BorderRadius.circular(TaxGstStyles.rHeaderIcon)),
                child: Icon(icon, color: TaxGstColors.goldAccent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TaxGstStyles.sectionTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: TaxGstColors.transparent,
          child: InkWell(
            onTap: isSaving ? null : onToggle,
            borderRadius: BorderRadius.circular(TaxGstStyles.rStatusPill),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                  color: isLocked
                      ? TaxGstColors.lockedBg
                      : TaxGstColors.statusActiveBg,
                  borderRadius: BorderRadius.circular(TaxGstStyles.rStatusPill),
                  border: Border.all(
                      color: isLocked
                          ? TaxGstColors.lockedBorder
                          : TaxGstColors.statusActiveText30)),
              child: Row(
                children: [
                  if (isSaving)
                    const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: TaxGstColors.statusActiveText))
                  else
                    Icon(isLocked ? TaxGstIcons.lock : TaxGstIcons.save,
                        size: 16,
                        color: isLocked
                            ? TaxGstColors.lockedIcon
                            : TaxGstColors.statusActiveText),
                  const SizedBox(width: 6),
                  Text(
                      isSaving
                          ? TaxGstStrings.btnSaving
                          : (isLocked
                              ? TaxGstStrings.btnLocked
                              : TaxGstStrings.btnSave),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isLocked
                              ? TaxGstColors.lockedIcon
                              : TaxGstColors.statusActiveText)),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text, style: TaxGstStyles.sectionSub);
  }
}

class _HallmarkingChoice {
  final String label;
  final HallmarkingScope scope;
  final BisRegistrationMode mode;
  final Color color;

  const _HallmarkingChoice({
    required this.label,
    required this.scope,
    required this.mode,
    required this.color,
  });
}

// =========================================================================
// WIDGET: ENTERPRISE DOCUMENT
// =========================================================================
class EnterpriseDocumentWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final File? currentFile;
  final Function(File?) onImageSaved;
  final bool isInitiallyLocked;
  final bool useTallPreview;

  const EnterpriseDocumentWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.currentFile,
    required this.onImageSaved,
    this.isInitiallyLocked = true,
    this.useTallPreview = false,
  });

  @override
  State<EnterpriseDocumentWidget> createState() =>
      _EnterpriseDocumentWidgetState();
}

class _EnterpriseDocumentWidgetState extends State<EnterpriseDocumentWidget> {
  final DocumentCropLogic _logic = DocumentCropLogic();
  late bool _isLocked;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _isLocked = widget.isInitiallyLocked;
  }

  @override
  void didUpdateWidget(covariant EnterpriseDocumentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isInitiallyLocked != oldWidget.isInitiallyLocked) {
      _isLocked = widget.isInitiallyLocked;
    }
  }

  Future<void> _handleDocumentUpload() async {
    setState(() => _isProcessing = true);

    try {
      File? originalFile = await _logic.pickDocumentFromGallery();

      if (originalFile == null) {
        if (mounted) setState(() => _isProcessing = false);
        return;
      }

      if (_logic.isPdfDocument(originalFile)) {
        if (mounted) {
          setState(() => _isProcessing = false);
          widget.onImageSaved(originalFile);
        }
        return;
      }

      bool isDesktop =
          Platform.isWindows || Platform.isMacOS || Platform.isLinux;

      if (isDesktop) {
        final bytes = await originalFile.readAsBytes();
        if (mounted) {
          setState(() => _isProcessing = false);
          _showDesktopCropDialog(bytes);
        }
      } else {
        File? croppedFile = await _logic.cropDocumentMobile(
            originalFile, TaxGstColors.goldAccent);
        if (mounted) {
          setState(() => _isProcessing = false);
          if (croppedFile != null) widget.onImageSaved(croppedFile);
        }
      }
    } on FormatException catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        if (e.message == "FILE_TOO_LARGE") {
          AppFeedback.show(
            context,
            type: AppFeedbackType.error,
            message: TaxGstStrings.errFileTooLarge,
          );
        } else if (e.message == "UNSUPPORTED_FILE") {
          AppFeedback.show(
            context,
            type: AppFeedbackType.error,
            message: TaxGstStrings.errUnsupportedDocument,
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showDesktopCropDialog(Uint8List originalImageBytes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final CropController localController = CropController();
        bool isLocallyProcessing = false;

        return StatefulBuilder(
          builder: (context, setStateInternal) {
            return Scaffold(
              backgroundColor: TaxGstColors.overlayDark,
              appBar: AppBar(
                backgroundColor: TaxGstColors.overlayDark,
                elevation: 0,
                leading: IconButton(
                    icon: const Icon(TaxGstIcons.close,
                        color: TaxGstColors.cardBg),
                    onPressed: () => Navigator.pop(context)),
                title: const Text(TaxGstStrings.dlgCropDoc,
                    style: TextStyle(
                        color: TaxGstColors.cardBg,
                        fontWeight: FontWeight.bold)),
                actions: [
                  if (isLocallyProcessing)
                    const Center(
                        child: Padding(
                            padding: EdgeInsets.only(right: 20.0),
                            child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: TaxGstColors.goldAccent,
                                    strokeWidth: 2))))
                  else
                    IconButton(
                        icon: const Icon(TaxGstIcons.check,
                            color: TaxGstColors.goldAccent, size: 28),
                        onPressed: () {
                          setStateInternal(() => isLocallyProcessing = true);
                          localController.crop();
                        })
                ],
              ),
              body: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Crop(
                    image: originalImageBytes,
                    controller: localController,
                    onCropped: (croppedData) async {
                      if (croppedData.isNotEmpty) {
                        File savedFile =
                            await _logic.saveCroppedBitmap(croppedData);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        widget.onImageSaved(savedFile);
                      } else {
                        setStateInternal(() => isLocallyProcessing = false);
                      }
                    },
                    aspectRatio: null,
                    baseColor: TaxGstColors.overlayDark,
                    maskColor: TaxGstColors.overlayDark80,
                    interactive: true,
                    cornerDotBuilder: (size, edgeAlignment) =>
                        const DotControl(color: TaxGstColors.goldAccent),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPreviewDialog() {
    if (!_hasCurrentFile) return;
    if (_isCurrentPdf) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: TaxGstColors.cardBg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(TaxGstIcons.filePdf,
                  size: 48, color: TaxGstColors.goldAccent),
              const SizedBox(height: 14),
              Text(
                _documentFileName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: TaxGstColors.textDark,
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Container(
          color: TaxGstColors.overlayDark90,
          child: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 1,
              maxScale: 4,
              child: Image.file(widget.currentFile!, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  void _showDocumentOptions() {
    if (_isLocked) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: TaxGstColors.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(TaxGstStyles.rBottomSheet))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 40, height: 4, color: TaxGstColors.borderLight),
                const SizedBox(height: 20),
                const Text(TaxGstStrings.dlgDocOptions,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: TaxGstColors.textDark)),
                const SizedBox(height: 20),
                _buildOptionTile(
                    icon: TaxGstIcons.uploadFile,
                    label: TaxGstStrings.optUploadNew,
                    color: TaxGstColors.goldAccent,
                    onTap: () {
                      Navigator.pop(context);
                      _handleDocumentUpload();
                    }),
                if (_hasCurrentFile)
                  _buildOptionTile(
                      icon: TaxGstIcons.previewEye,
                      label: TaxGstStrings.optPreview,
                      color: TaxGstColors.iconSuccess,
                      onTap: () {
                        Navigator.pop(context);
                        _showPreviewDialog();
                      }),
                if (_hasCurrentFile)
                  _buildOptionTile(
                      icon: TaxGstIcons.removeTrash,
                      label: TaxGstStrings.optRemove,
                      color: TaxGstColors.btnDanger,
                      onTap: () {
                        Navigator.pop(context);
                        widget.onImageSaved(null);
                      }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionTile(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 22)),
      title: Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: TaxGstColors.textBody,
              fontSize: 15)),
      trailing: const Icon(TaxGstIcons.arrowRight,
          size: 16, color: TaxGstColors.textHint),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasFile = _hasCurrentFile;
    final hasPdf = _isCurrentPdf;
    final isDesktop = MediaQuery.sizeOf(context).width >= 1000;
    final previewHeight = widget.useTallPreview && isDesktop ? 300.0 : 220.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: TaxGstStyles.cardDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: TaxGstColors.goldAccent10,
                    borderRadius: BorderRadius.circular(12)),
                child:
                    Icon(widget.icon, size: 22, color: TaxGstColors.goldAccent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: TaxGstColors.textDark)),
                    const SizedBox(height: 2),
                    Text(widget.subtitle,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: TaxGstColors.textMuted)),
                  ],
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(TaxGstStyles.rStatusPill),
                onTap: () => setState(() => _isLocked = !_isLocked),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                      color: _isLocked
                          ? TaxGstColors.uploadZoneBg
                          : TaxGstColors.goldAccent10,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: _isLocked
                              ? TaxGstColors.borderLight
                              : TaxGstColors.goldAccent30)),
                  child: Row(
                    children: [
                      Icon(_isLocked ? TaxGstIcons.lock : TaxGstIcons.unlock,
                          size: 16,
                          color: _isLocked
                              ? TaxGstColors.lockedIcon
                              : TaxGstColors.goldAccent),
                      const SizedBox(width: 6),
                      Text(
                          _isLocked
                              ? TaxGstStrings.btnLocked
                              : TaxGstStrings.btnEdit,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _isLocked
                                  ? TaxGstColors.lockedIcon
                                  : TaxGstColors.goldAccent)),
                    ],
                  ),
                ),
              )
            ],
          ),
          const Divider(height: 36, color: TaxGstColors.borderLight),
          SizedBox(
            height: previewHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: _isLocked ? 0.6 : 1.0,
                  child: InkWell(
                    onTap: hasFile ? _showPreviewDialog : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: hasFile
                            ? TaxGstColors.transparent
                            : TaxGstColors.uploadZoneBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: TaxGstColors.borderLight, width: 1),
                        image: hasFile && !hasPdf
                            ? DecorationImage(
                                image: FileImage(widget.currentFile!),
                                fit: BoxFit.contain)
                            : null,
                      ),
                      child: !hasFile
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(TaxGstIcons.filePdf,
                                    size: 40, color: TaxGstColors.textHint),
                                SizedBox(height: 12),
                                Text(TaxGstStrings.docEmpty,
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: TaxGstColors.textHint))
                              ],
                            )
                          : hasPdf
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(TaxGstIcons.filePdf,
                                        size: 42,
                                        color: TaxGstColors.goldAccent),
                                    const SizedBox(height: 12),
                                    Text(
                                      _documentFileName,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: TaxGstColors.textBody,
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                    ),
                  ),
                ),
                if (_isProcessing)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: TaxGstColors.overlayDark60,
                        borderRadius: BorderRadius.circular(12)),
                    child: const Center(
                        child: CircularProgressIndicator(
                            color: TaxGstColors.goldAccent)),
                  )
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isLocked
                ? const SizedBox.shrink()
                : Column(
                    children: [
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              _isProcessing ? null : _showDocumentOptions,
                          icon: Icon(
                              hasFile
                                  ? TaxGstIcons.edit
                                  : TaxGstIcons.uploadFile,
                              size: 18,
                              color: TaxGstColors.cardBg),
                          label: Text(
                              hasFile
                                  ? TaxGstStrings.btnManageDoc
                                  : TaxGstStrings.btnUploadDoc,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: TaxGstColors.cardBg)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TaxGstColors.goldAccent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            elevation: 2,
                            shadowColor: TaxGstColors.goldAccent40,
                          ),
                        ),
                      ),
                    ],
                  ),
          )
        ],
      ),
    );
  }

  bool get _hasCurrentFile {
    final file = widget.currentFile;
    return file != null && file.existsSync();
  }

  bool get _isCurrentPdf {
    final file = widget.currentFile;
    return file != null && _logic.isPdfDocument(file);
  }

  String get _documentFileName {
    final path = widget.currentFile?.path;
    if (path == null || path.trim().isEmpty) return 'PDF Document';
    return p.basename(path);
  }
}
