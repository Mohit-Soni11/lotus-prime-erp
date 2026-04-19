// -----------------------------------------------------------------------------
// FILE: tax_gst_tab.dart
// TYPE: Presentation Layer (UI)
// AUTHOR: Senior System Architect
// DESCRIPTION: 100% Theme injected, Zero-Lag UI powered by ListenableBuilder.
//              🚀 UPGRADED: Added Auto-Fill Initial Data support.
// -----------------------------------------------------------------------------

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crop_your_image/crop_your_image.dart';

// --- THEME IMPORTS ---
// NOTE: Adjust paths according to your structure.
import '../../../../theme/settings/shop_setup/tabs/tax_gst/tax_gst_theme.dart';

// --- LOGIC IMPORTS ---
import '../../../../logic/setting/shop_setup/tabs/tax_gst/tax_gst_logic.dart';
import '../../../../logic/setting/shop_setup/tabs/tax_gst/document_crop_logic.dart';

class TaxGstTab extends StatefulWidget {
  // 🚀 NEW: Receive initial data from parent
  final Map<String, dynamic>? initialData;
  
  const TaxGstTab({super.key, this.initialData});

  @override
  State<TaxGstTab> createState() => _TaxGstTabState();
}

class _TaxGstTabState extends State<TaxGstTab> {
  late TaxGstLogic logic;

  @override
  void initState() {
    super.initState();
    logic = TaxGstLogic();
    
    // 🚀 NEW: AUTO-FILL LOGIC
    // Agar database se data mila hai, toh usko controllers aur logic mein set kar do
    if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      logic.gstinCtrl.text = widget.initialData!['gstin']?.toString() ?? '';
      logic.legalNameCtrl.text = widget.initialData!['legal_name']?.toString() ?? '';
      logic.bisLicCtrl.text = widget.initialData!['bis_license_no']?.toString() ?? '';
      
      if (widget.initialData!['reg_date'] != null) {
        logic.setRegDate(widget.initialData!['reg_date'].toString());
      }
      
      logic.setBisDates(
        widget.initialData!['bis_valid_from']?.toString() ?? '', 
        widget.initialData!['bis_valid_upto']?.toString() ?? ''
      );

      if (widget.initialData!['taxpayer_type'] != null) {
        logic.setTaxpayer(widget.initialData!['taxpayer_type'].toString());
      }
      
      if (widget.initialData!['gst_cert_path'] != null && widget.initialData!['gst_cert_path'].toString().isNotEmpty) {
        logic.updateGstFile(File(widget.initialData!['gst_cert_path'].toString()));
      }
      
      if (widget.initialData!['bis_license_path'] != null && widget.initialData!['bis_license_path'].toString().isNotEmpty) {
        logic.updateBisFile(File(widget.initialData!['bis_license_path'].toString()));
      }
    }
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
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
         _showSaveSnack(TaxGstStrings.snackTaxSyncDone);
      }
    }
  }

  // --- DATE PICKER LOGIC ---
  Future<void> _selectDate(TextEditingController controller) async {
    if (logic.isGstLocked && controller == logic.regDateCtrl) return;
    if (logic.isBisLocked && (controller == logic.validFromCtrl || controller == logic.validUptoCtrl)) return;

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
            dialogBackgroundColor: TaxGstColors.cardBg,
            datePickerTheme: DatePickerThemeData(
              backgroundColor: TaxGstColors.cardBg,
              elevation: 24,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TaxGstStyles.rDialog)),
              headerBackgroundColor: TaxGstColors.goldAccent,
              headerForegroundColor: TaxGstColors.cardBg,
              headerHeadlineStyle: TaxGstStyles.dialogTitle,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      String formattedDate = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      if (controller == logic.regDateCtrl) {
        logic.setRegDate(formattedDate);
      } else if (controller == logic.validFromCtrl) {
        logic.setBisDates(formattedDate, "");
      } else if (controller == logic.validUptoCtrl) {
        logic.setBisDates("", formattedDate);
      }
    }
  }

  void _showSaveSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? TaxGstIcons.error : TaxGstIcons.check, color: TaxGstColors.cardBg, size: 20), 
            const SizedBox(width: 8), 
            Text(msg, style: const TextStyle(color: TaxGstColors.cardBg))
          ]
        ),
        backgroundColor: isError ? TaxGstColors.btnDanger : TaxGstColors.saveBtn,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TaxGstStyles.rInput)),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
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
                  return isDesktop ? _buildDesktopLayout() : _buildMobileLayout();
                }
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildPageHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(TaxGstStrings.pageTitle, style: TaxGstStyles.pageTitle),
            const SizedBox(height: 4),
            Text(TaxGstStrings.pageSubtitle, style: TaxGstStyles.pageSubtitle),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: TaxGstColors.statusActiveBg,
            borderRadius: BorderRadius.circular(TaxGstStyles.rStatusPill),
            border: Border.all(color: TaxGstColors.statusActiveText30),
          ),
          child: Row(
            children: [
              const Icon(TaxGstIcons.statusShield, size: 16, color: TaxGstColors.statusActiveText),
              const SizedBox(width: 8),
              Text(TaxGstStrings.badgeComplianceActive, style: TaxGstStyles.statusPill),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch, 
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
                )
              ),
            ],
          ),
        ),
        const SizedBox(height: TaxGstStyles.gapCard),
        
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                )
              ),
            ],
          ),
        ),
        const SizedBox(height: TaxGstStyles.gapCard),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 60, child: _buildTaxStructureCard()),
            const SizedBox(width: TaxGstStyles.gapCard),
            const Expanded(flex: 40, child: SizedBox()), 
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
        const SizedBox(height: TaxGstStyles.gapCard),
        _buildTaxStructureCard(),
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
          _buildCardHeader("gst", TaxGstStrings.secGstTitle, TaxGstIcons.secGst, logic.isGstLocked, () => _handleSectionToggle('gst', TaxGstStrings.secGstTitle)),
          const Divider(height: 40, thickness: 1, color: TaxGstColors.borderLight),
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
              Expanded(child: _buildDateInput(label: TaxGstStrings.lblRegDate, hint: TaxGstStrings.hintDate, icon: TaxGstIcons.calendar, ctrl: logic.regDateCtrl, isLocked: logic.isGstLocked, focusNode: logic.regDateFocus)),
              const SizedBox(width: 20),
              Expanded(child: _buildDropdownInput(label: TaxGstStrings.lblTaxpayerType, icon: TaxGstIcons.taxpayer, value: logic.selectedTaxpayer.displayName, items: logic.taxpayerTypes, isLocked: logic.isGstLocked, onChanged: (val) => logic.setTaxpayer(val!))),
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
          _buildCardHeader("bis", TaxGstStrings.secBisTitle, TaxGstIcons.secBis, logic.isBisLocked, () => _handleSectionToggle('bis', TaxGstStrings.secBisTitle)),
          const Divider(height: 40, thickness: 1, color: TaxGstColors.borderLight),
          _buildSectionLabel(TaxGstStrings.secBisLabel),
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
          const SizedBox(height: TaxGstStyles.gapInput),
          Row(
            children: [
              Expanded(child: _buildDateInput(label: TaxGstStrings.lblValidFrom, hint: TaxGstStrings.hintDate, icon: TaxGstIcons.dateRange, ctrl: logic.validFromCtrl, isLocked: logic.isBisLocked, focusNode: logic.validFromFocus)),
              const SizedBox(width: 20),
              Expanded(child: _buildDateInput(label: TaxGstStrings.lblValidUpto, hint: TaxGstStrings.hintDate, icon: TaxGstIcons.dateRange, ctrl: logic.validUptoCtrl, isLocked: logic.isBisLocked, focusNode: logic.validUptoFocus)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTaxStructureCard() {
    bool isSavingHsn = logic.loadingSection == 'hsn';

    return Container(
      padding: TaxGstStyles.padCardInternal,
      decoration: TaxGstStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(TaxGstIcons.secHsn, color: TaxGstColors.goldAccent, size: 22),
                  const SizedBox(width: 12),
                  Text(TaxGstStrings.secHsnTitle, style: TaxGstStyles.sectionTitle),
                ],
              ),
              InkWell(
                onTap: isSavingHsn ? null : () async {
                  if (logic.isHsnLocked) {
                    logic.toggleHsnLock(); 
                  } else {
                    await logic.toggleHsnLock(); 
                    _showSaveSnack(TaxGstStrings.snackTaxSyncDone);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: logic.isHsnLocked ? TaxGstColors.badgeRedBg : TaxGstColors.statusActiveBg, borderRadius: BorderRadius.circular(6)),
                  child: Row(
                    children: [
                      if (isSavingHsn)
                         const SizedBox(
                           width: 12, height: 12,
                           child: CircularProgressIndicator(strokeWidth: 2, color: TaxGstColors.statusActiveText)
                         )
                      else
                         Icon(logic.isHsnLocked ? TaxGstIcons.hsnSync : TaxGstIcons.edit, size: 12, color: logic.isHsnLocked ? TaxGstColors.badgeRedText : TaxGstColors.statusActiveText),
                      const SizedBox(width: 4),
                      Text(
                        isSavingHsn ? TaxGstStrings.btnSyncing : (logic.isHsnLocked ? TaxGstStrings.btnLiveSync : TaxGstStrings.btnEditing), 
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: logic.isHsnLocked ? TaxGstColors.badgeRedText : TaxGstColors.statusActiveText)
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 5),
          Text(TaxGstStrings.secHsnSubtitle, style: TaxGstStyles.sectionSub.copyWith(fontStyle: FontStyle.italic)),
          const Divider(height: 30, thickness: 1, color: TaxGstColors.borderLight),
          ...logic.hsnList.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['title'], style: TaxGstStyles.fieldText),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 90, height: 38, alignment: Alignment.center,
                      decoration: BoxDecoration(color: TaxGstColors.inputBg, borderRadius: BorderRadius.circular(6), border: Border.all(color: TaxGstColors.borderLight)),
                      child: Text(item['label'], style: TaxGstStyles.fieldHint.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _buildSmallGridInput(item['code'], isCenter: false)),
                    const SizedBox(width: 10),
                    SizedBox(width: 70, child: _buildSmallGridInput(item['rate'], isCenter: true, highlight: true)),
                  ],
                )
              ],
            ),
          )).toList(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildActionBtn(TaxGstStrings.btnFetchLatest, TaxGstIcons.cloudUp, false)),
              const SizedBox(width: 12),
              Expanded(child: _buildActionBtn(TaxGstStrings.btnMarkVerified, TaxGstIcons.verifyCheck, true)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSmallGridInput(String val, {bool isCenter = false, bool highlight = false}) {
    return Container(
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: logic.isHsnLocked ? TaxGstColors.cardBg : TaxGstColors.inputBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: highlight ? TaxGstColors.goldAccent : TaxGstColors.borderLight),
      ),
      child: TextFormField(
        initialValue: val,
        readOnly: logic.isHsnLocked,
        textAlign: isCenter ? TextAlign.center : TextAlign.start,
        style: TaxGstStyles.fieldText.copyWith(fontSize: 13, color: highlight ? TaxGstColors.textDark : TaxGstColors.textBody),
        decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.only(left: isCenter ? 0 : 12, bottom: 14)),
      ),
    );
  }

  Widget _buildThemeInput({
    required String label, required String hint, required IconData icon, required TextEditingController ctrl,
    required bool isLocked, FocusNode? focusNode, FocusNode? nextFocus, int? maxLength, bool isCapital = false,
    Color? brandColor,
  }) {
    bool isActive = !isLocked && (focusNode?.hasFocus ?? false);
    Color iconColor = isActive ? TaxGstColors.goldAccent : (ctrl.text.isNotEmpty ? (brandColor ?? TaxGstColors.iconSuccess) : TaxGstColors.textHint);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TaxGstStyles.fieldLabel),
        const SizedBox(height: 8),
        Container(
          height: TaxGstStyles.hInputField,
          decoration: isActive ? TaxGstStyles.activeInputDecoration : TaxGstStyles.inputDecoration(isLocked),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: Icon(icon, key: ValueKey(iconColor), size: 20, color: iconColor)),
              const SizedBox(width: 12),
              Container(width: 1, height: 24, color: TaxGstColors.borderLight),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: ctrl,
                  readOnly: isLocked,
                  focusNode: focusNode,
                  textCapitalization: isCapital ? TextCapitalization.characters : TextCapitalization.none,
                  maxLength: maxLength,
                  inputFormatters: maxLength != null ? [LengthLimitingTextInputFormatter(maxLength)] : [],
                  onFieldSubmitted: (_) => nextFocus != null ? FocusScope.of(context).requestFocus(nextFocus) : null,
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

  Widget _buildDateInput({required String label, required String hint, required IconData icon, required TextEditingController ctrl, required bool isLocked, required FocusNode focusNode}) {
    bool isActive = !isLocked && focusNode.hasFocus;
    Color iconColor = isActive ? TaxGstColors.goldAccent : (ctrl.text.isNotEmpty ? TaxGstColors.iconSuccess : TaxGstColors.textHint);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TaxGstStyles.fieldLabel),
        const SizedBox(height: 8),
        InkWell(
          onTap: isLocked ? null : () => _selectDate(ctrl),
          child: Container(
            height: TaxGstStyles.hInputField,
            decoration: isActive ? TaxGstStyles.activeInputDecoration : TaxGstStyles.inputDecoration(isLocked),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: Icon(icon, key: ValueKey(iconColor), size: 20, color: iconColor)),
                const SizedBox(width: 12),
                Container(width: 1, height: 24, color: TaxGstColors.borderLight),
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

  Widget _buildDropdownInput({required String label, required IconData icon, required String value, required List<String> items, required bool isLocked, required Function(String?) onChanged}) {
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
              Icon(icon, size: 20, color: isLocked ? TaxGstColors.textHint : TaxGstColors.iconSuccess),
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
                        icon: const Icon(TaxGstIcons.arrowRight, color: TaxGstColors.textBody),
                        style: TaxGstStyles.fieldText,
                        onChanged: onChanged,
                        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      ),
                    ),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildCardHeader(String sectionId, String title, IconData icon, bool isLocked, VoidCallback onToggle) {
    bool isSaving = logic.loadingSection == sectionId;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: TaxGstColors.goldAccent10, borderRadius: BorderRadius.circular(TaxGstStyles.rHeaderIcon)),
              child: Icon(icon, color: TaxGstColors.goldAccent, size: 22),
            ),
            const SizedBox(width: 12),
            Text(title, style: TaxGstStyles.sectionTitle),
          ],
        ),
        Material(
          color: TaxGstColors.transparent,
          child: InkWell(
            onTap: isSaving ? null : onToggle,
            borderRadius: BorderRadius.circular(TaxGstStyles.rStatusPill),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isLocked ? TaxGstColors.lockedBg : TaxGstColors.statusActiveBg, 
                borderRadius: BorderRadius.circular(TaxGstStyles.rStatusPill),
                border: Border.all(color: isLocked ? TaxGstColors.lockedBorder : TaxGstColors.statusActiveText30)
              ),
              child: Row(
                children: [
                  if (isSaving)
                     const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: TaxGstColors.statusActiveText))
                  else
                     Icon(isLocked ? TaxGstIcons.lock : TaxGstIcons.save, size: 16, color: isLocked ? TaxGstColors.lockedIcon : TaxGstColors.statusActiveText),
                  const SizedBox(width: 6),
                  Text(
                    isSaving ? TaxGstStrings.btnSaving : (isLocked ? TaxGstStrings.btnLocked : TaxGstStrings.btnSave), 
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isLocked ? TaxGstColors.lockedIcon : TaxGstColors.statusActiveText)
                  ),
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
  
  Widget _buildActionBtn(String label, IconData icon, bool isPrimary) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(TaxGstStyles.rBtn),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: isPrimary ? TaxGstColors.goldAccent : TaxGstColors.transparent, border: Border.all(color: TaxGstColors.goldAccent), borderRadius: BorderRadius.circular(TaxGstStyles.rBtn)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isPrimary ? TaxGstColors.cardBg : TaxGstColors.textDark),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isPrimary ? TaxGstColors.cardBg : TaxGstColors.textDark)),
          ],
        ),
      ),
    );
  }
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

  const EnterpriseDocumentWidget({
    super.key, 
    required this.title, 
    required this.subtitle, 
    required this.icon,
    required this.currentFile,
    required this.onImageSaved,
    this.isInitiallyLocked = true,
  });

  @override
  State<EnterpriseDocumentWidget> createState() => _EnterpriseDocumentWidgetState();
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

      bool isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;

      if (isDesktop) {
        final bytes = await originalFile.readAsBytes();
        if (mounted) {
          setState(() => _isProcessing = false);
          _showDesktopCropDialog(bytes);
        }
      } else {
        File? croppedFile = await _logic.cropDocumentMobile(originalFile, TaxGstColors.goldAccent);
        if (mounted) {
          setState(() => _isProcessing = false);
          if (croppedFile != null) widget.onImageSaved(croppedFile);
        }
      }
    } on FormatException catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        if (e.message == "FILE_TOO_LARGE") {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(TaxGstStrings.errFileTooLarge, style: TextStyle(color: TaxGstColors.cardBg)),
              backgroundColor: TaxGstColors.btnDanger,
            )
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
                leading: IconButton(icon: const Icon(TaxGstIcons.close, color: TaxGstColors.cardBg), onPressed: () => Navigator.pop(context)),
                title: const Text(TaxGstStrings.dlgCropDoc, style: TextStyle(color: TaxGstColors.cardBg, fontWeight: FontWeight.bold)),
                actions: [
                  if (isLocallyProcessing)
                    const Center(child: Padding(padding: EdgeInsets.only(right: 20.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: TaxGstColors.goldAccent, strokeWidth: 2))))
                  else
                    IconButton(icon: const Icon(TaxGstIcons.check, color: TaxGstColors.goldAccent, size: 28), onPressed: () {
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
                        File savedFile = await _logic.saveCroppedBitmap(croppedData);
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
                    cornerDotBuilder: (size, edgeAlignment) => const DotControl(color: TaxGstColors.goldAccent),
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
    if (widget.currentFile == null) return;
    showDialog(
      context: context,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Container(
          color: TaxGstColors.overlayDark90,
          child: Center(
            child: InteractiveViewer(
              panEnabled: true, minScale: 1, maxScale: 4,
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(TaxGstStyles.rBottomSheet))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, color: TaxGstColors.borderLight),
                const SizedBox(height: 20),
                const Text(TaxGstStrings.dlgDocOptions, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: TaxGstColors.textDark)),
                const SizedBox(height: 20),
                _buildOptionTile(icon: TaxGstIcons.uploadFile, label: TaxGstStrings.optUploadNew, color: TaxGstColors.goldAccent, onTap: () { Navigator.pop(context); _handleDocumentUpload(); }),
                if (widget.currentFile != null) _buildOptionTile(icon: TaxGstIcons.previewEye, label: TaxGstStrings.optPreview, color: TaxGstColors.iconSuccess, onTap: () { Navigator.pop(context); _showPreviewDialog(); }),
                if (widget.currentFile != null) _buildOptionTile(icon: TaxGstIcons.removeTrash, label: TaxGstStrings.optRemove, color: TaxGstColors.btnDanger, onTap: () { Navigator.pop(context); widget.onImageSaved(null); }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 22)),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: TaxGstColors.textBody, fontSize: 15)),
      trailing: const Icon(TaxGstIcons.arrowRight, size: 16, color: TaxGstColors.textHint),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasFile = widget.currentFile != null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: TaxGstStyles.cardDecoration,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: TaxGstColors.goldAccent10, borderRadius: BorderRadius.circular(12)),
                child: Icon(widget.icon, size: 22, color: TaxGstColors.goldAccent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: TaxGstColors.textDark)),
                    const SizedBox(height: 2),
                    Text(widget.subtitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: TaxGstColors.textMuted)),
                  ],
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(TaxGstStyles.rStatusPill),
                onTap: () => setState(() => _isLocked = !_isLocked),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isLocked ? TaxGstColors.uploadZoneBg : TaxGstColors.goldAccent10,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: _isLocked ? TaxGstColors.borderLight : TaxGstColors.goldAccent30)
                  ),
                  child: Row(
                    children: [
                      Icon(_isLocked ? TaxGstIcons.lock : TaxGstIcons.unlock, size: 16, color: _isLocked ? TaxGstColors.lockedIcon : TaxGstColors.goldAccent),
                      const SizedBox(width: 6),
                      Text(_isLocked ? TaxGstStrings.btnLocked : TaxGstStrings.btnEdit, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _isLocked ? TaxGstColors.lockedIcon : TaxGstColors.goldAccent)),
                    ],
                  ),
                ),
              )
            ],
          ),
          const Divider(height: 36, color: TaxGstColors.borderLight),
          
          Expanded(
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
                        color: hasFile ? TaxGstColors.transparent : TaxGstColors.uploadZoneBg, 
                        borderRadius: BorderRadius.circular(12), 
                        border: Border.all(color: TaxGstColors.borderLight, width: 1),
                        image: hasFile 
                          ? DecorationImage(image: FileImage(widget.currentFile!), fit: BoxFit.contain) 
                          : null,
                      ),
                      child: !hasFile 
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(TaxGstIcons.filePdf, size: 40, color: TaxGstColors.textHint),
                              SizedBox(height: 12),
                              Text(TaxGstStrings.docEmpty, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: TaxGstColors.textHint))
                            ],
                          )
                        : null,
                    ),
                  ),
                ),
                if (_isProcessing)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(color: TaxGstColors.overlayDark60, borderRadius: BorderRadius.circular(12)),
                    child: const Center(child: CircularProgressIndicator(color: TaxGstColors.goldAccent)),
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
                        onPressed: _isProcessing ? null : _showDocumentOptions, 
                        icon: Icon(hasFile ? TaxGstIcons.edit : TaxGstIcons.uploadFile, size: 18, color: TaxGstColors.cardBg),
                        label: Text(
                          hasFile ? TaxGstStrings.btnManageDoc : TaxGstStrings.btnUploadDoc,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: TaxGstColors.cardBg)
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TaxGstColors.goldAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
}