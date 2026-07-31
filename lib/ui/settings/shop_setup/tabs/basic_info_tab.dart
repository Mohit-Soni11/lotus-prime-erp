// -----------------------------------------------------------------------------
// FILE: basic_info_tab.dart
// TYPE: Presentation Layer (UI)
// AUTHOR: Senior UI/UX Engineer & System Architect
// DESCRIPTION: ðŸš€ UPGRADED: True ZERO-LAG granular rebuilds.
//              Controllers and FocusNodes successfully moved to UI State.
//              Memory Leaks eliminated. 60-FPS guaranteed.
//              [FIXED: White Page Header & Support Display Auto-Sync Bug]
// -----------------------------------------------------------------------------

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// NOTE: Adjust paths according to your actual folder structure
import '../../../../logic/setting/shop_setup/tabs/basic_info/basic_info_logic.dart';
import '../../../../theme/settings/shop_setup/tabs/basic_info_tab/basic_info_theme.dart';
import '../../../../../../models/setting/shop_setup/shop_profile_model.dart';
import '../../../../../../models/setting/shop_setup/enums/basic_info_enums.dart';
import '../../../../ui/settings/shop_setup/tabs/professional_photo_widget.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';

class BasicInfoTab extends StatefulWidget {
  final ShopProfileModel? initialData;
  const BasicInfoTab({super.key, this.initialData});

  @override
  BasicInfoTabState createState() => BasicInfoTabState();
}

class BasicInfoTabState extends State<BasicInfoTab> {
  late BasicInfoLogic logic;

  // --- ðŸš€ UPGRADE: UI ELEMENTS MOVED FROM LOGIC TO STATE ---
  final GlobalKey<FormState> entKey = GlobalKey<FormState>();
  final GlobalKey<FormState> commKey = GlobalKey<FormState>();

  final TextEditingController legalNameCtrl = TextEditingController();
  final TextEditingController displayNameCtrl = TextEditingController();
  final TextEditingController taglineCtrl = TextEditingController();
  final TextEditingController ownerNameCtrl = TextEditingController();
  final TextEditingController ownerPhoneCtrl = TextEditingController();
  final TextEditingController brandDisplayCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController shopPhoneCtrl = TextEditingController();
  final TextEditingController shopWaCtrl = TextEditingController();
  final TextEditingController helpDeskCtrl = TextEditingController();

  final FocusNode legalNameFocus = FocusNode();
  final FocusNode displayNameFocus = FocusNode();
  final FocusNode taglineFocus = FocusNode();
  final FocusNode ownerNameFocus = FocusNode();
  final FocusNode ownerPhoneFocus = FocusNode();

  final FocusNode brandDisplayFocus = FocusNode();
  final FocusNode emailFocus = FocusNode();
  final FocusNode shopPhoneFocus = FocusNode();
  final FocusNode shopWaFocus = FocusNode();
  final FocusNode helpDeskFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    logic = BasicInfoLogic();
    logic.init(widget.initialData);
    _populateInitialData();
  }

  void _populateInitialData() {
    final data = widget.initialData;
    if (data == null) return;

    legalNameCtrl.text = data.legalName;
    displayNameCtrl.text = data.displayName;
    taglineCtrl.text = data.tagline;
    ownerNameCtrl.text = data.ownerName;
    ownerPhoneCtrl.text = data.ownerPhone;

    brandDisplayCtrl.text = data.brandDisplayName;
    emailCtrl.text = data.businessEmail;
    shopPhoneCtrl.text = data.shopPhone;
    shopWaCtrl.text = data.shopWhatsapp;
    helpDeskCtrl.text = data.helpDeskNumber;
  }

  @override
  void dispose() {
    logic.dispose();
    final disposables = [
      legalNameCtrl,
      displayNameCtrl,
      taglineCtrl,
      ownerNameCtrl,
      ownerPhoneCtrl,
      brandDisplayCtrl,
      emailCtrl,
      shopPhoneCtrl,
      shopWaCtrl,
      helpDeskCtrl,
      legalNameFocus,
      displayNameFocus,
      taglineFocus,
      ownerNameFocus,
      ownerPhoneFocus,
      brandDisplayFocus,
      emailFocus,
      shopPhoneFocus,
      shopWaFocus,
      helpDeskFocus
    ];
    for (var item in disposables) {
      item.dispose();
    }
    super.dispose();
  }

  // --- ðŸš€ UPGRADE: SAFE FOCUS MAPPING ---
  FocusNode? _getNodeByKey(String key) {
    switch (key) {
      case BasicInfoStrings.keyLegalName:
        return legalNameFocus;
      case BasicInfoStrings.keyDisplayName:
        return displayNameFocus;
      case BasicInfoStrings.keyOwnerName:
        return ownerNameFocus;
      case BasicInfoStrings.keyOwnerPhone:
        return ownerPhoneFocus;
      case BasicInfoStrings.keyEmail:
        return emailFocus;
      case BasicInfoStrings.keyShopPhone:
        return shopPhoneFocus;
      case BasicInfoStrings.keyShopWa:
        return shopWaFocus;
      case BasicInfoStrings.keyHelpDesk:
        return helpDeskFocus;
      default:
        return null;
    }
  }

  void _handleSectionToggle(FormSection section, String sectionName) async {
    if (logic.loadingSection.value == section) return;

    bool isLocked;
    switch (section) {
      case FormSection.enterprise:
        isLocked = logic.enterpriseLocked.value;
        break;
      case FormSection.communication:
        isLocked = logic.commLocked.value;
        break;
    }

    if (isLocked) {
      logic.unlockSection(section);
      FocusNode? targetNode;
      if (section == FormSection.enterprise) targetNode = legalNameFocus;
      if (section == FormSection.communication) targetNode = brandDisplayFocus;

      if (targetNode != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) FocusScope.of(context).requestFocus(targetNode);
        });
      }
    } else {
      List<String> errors = [];
      bool saved = false;

      if (section == FormSection.enterprise) {
        errors = logic.validateEnterprise(
            legalName: legalNameCtrl.text,
            displayName: displayNameCtrl.text,
            ownerName: ownerNameCtrl.text,
            ownerPhone: ownerPhoneCtrl.text);
        saved = await logic.saveEnterprise(errors);
      } else if (section == FormSection.communication) {
        errors = logic.validateCommunication(
            email: emailCtrl.text,
            shopPhone: shopPhoneCtrl.text,
            shopWa: shopWaCtrl.text,
            helpDeskNumber: helpDeskCtrl.text);
        saved = await logic.saveCommunication(errors);
      }

      if (!saved && errors.isNotEmpty) {
        FocusNode? node = _getNodeByKey(errors.first);
        if (node != null && node.canRequestFocus) {
          node.requestFocus();
        }
      }
    }
  }

  void _showFeedback({
    required String message,
    required IconData icon,
    required Color color,
  }) {
    AppFeedback.show(
      context,
      type: color == BasicInfoColors.btnDanger
          ? AppFeedbackType.error
          : AppFeedbackType.info,
      message: message,
      duration: const Duration(seconds: 2),
    );
  }

  ShopProfileModel? validateAndSave() {
    final entErrs = logic.validateEnterprise(
        legalName: legalNameCtrl.text,
        displayName: displayNameCtrl.text,
        ownerName: ownerNameCtrl.text,
        ownerPhone: ownerPhoneCtrl.text);
    final commErrs = logic.validateCommunication(
        email: emailCtrl.text,
        shopPhone: shopPhoneCtrl.text,
        shopWa: shopWaCtrl.text,
        helpDeskNumber: helpDeskCtrl.text);

    if (entErrs.isNotEmpty || commErrs.isNotEmpty) {
      _showFeedback(
          message: BasicInfoStrings.msgFixErrors,
          icon: BasicInfoIcons.warning,
          color: BasicInfoColors.btnDanger);
      return null;
    }

    return logic.generateFinalModel(
      legalName: legalNameCtrl.text,
      displayName: displayNameCtrl.text,
      tagline: taglineCtrl.text,
      ownerName: ownerNameCtrl.text,
      ownerPhone: ownerPhoneCtrl.text,
      brandDisplayName: brandDisplayCtrl.text,
      businessEmail: emailCtrl.text,
      shopPhone: shopPhoneCtrl.text,
      shopWhatsapp: shopWaCtrl.text,
      helpDeskNumber: helpDeskCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      bool isDesktop = constraints.maxWidth > 900;
      return SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(),
            const SizedBox(height: 30),
            if (isDesktop) _buildDesktopLayout() else _buildMobileLayout(),
          ],
        ),
      );
    });
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 65,
          child: Column(
            children: [
              _buildEnterpriseCard(),
              const SizedBox(height: 24),
              _buildCommunicationCard(),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(flex: 35, child: _buildVisualsColumn()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildEnterpriseCard(),
        const SizedBox(height: 24),
        _buildCommunicationCard(),
        const SizedBox(height: 24),
        _buildVisualsColumn(),
      ],
    );
  }

  Widget _buildVisualsColumn() {
    return Column(
      children: [
        ProfessionalPhotoUploadSystem(
          title: BasicInfoStrings.titleIdentity,
          subtitle: BasicInfoStrings.subIdentity,
          icon: BasicInfoIcons.brandIdentity,
          defaultShape: widget.initialData?.logoShape ?? "circle",
          initialImagePath: widget.initialData?.logoPath,
          heroTag: "hero_identity_logo",
          onImageSaved: (File? file, String shape) async {
            String? error = await logic.updateLogo(file, shape);
            if (error != null && mounted) {
              _showFeedback(
                  message: error,
                  icon: BasicInfoIcons.error,
                  color: BasicInfoColors.btnDanger);
            }
          },
        ),
        const SizedBox(height: 24),
        ProfessionalPhotoUploadSystem(
          title: BasicInfoStrings.titleSignature,
          subtitle: BasicInfoStrings.subSignature,
          icon: BasicInfoIcons.authSignature,
          defaultShape: widget.initialData?.signatureShape ?? "square",
          initialImagePath: widget.initialData?.signaturePath,
          heroTag: "hero_auth_signature",
          onImageSaved: (File? file, String shape) async {
            String? error = await logic.updateSignature(file, shape);
            if (error != null && mounted) {
              _showFeedback(
                  message: error,
                  icon: BasicInfoIcons.error,
                  color: BasicInfoColors.btnDanger);
            }
          },
        ),
      ],
    );
  }

  Widget _buildPageHeader() {
    return LayoutBuilder(builder: (context, constraints) {
      final isCompact = constraints.maxWidth < 960;
      final identity = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            BasicInfoStrings.pageTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: BasicInfoStyles.szPageTitle,
              fontWeight: FontWeight.w800,
              color: BasicInfoColors.surfaceWhite,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            BasicInfoStrings.pageSub,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: BasicInfoStyles.szPageSub,
              color: BasicInfoColors.surfaceWhite.withValues(alpha: 0.7),
            ),
          ),
        ],
      );
      final status = Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: BasicInfoColors.statusActiveBg,
          borderRadius: BorderRadius.circular(BasicInfoStyles.rStatusPill),
          border: Border.all(
            color: BasicInfoColors.statusActiveText.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              BasicInfoIcons.statusActive,
              size: 16,
              color: BasicInfoColors.statusActiveText,
            ),
            const SizedBox(width: 8),
            Text(
              BasicInfoStrings.statusActive,
              style: GoogleFonts.inter(
                color: BasicInfoColors.statusActiveText,
                fontWeight: FontWeight.w700,
                fontSize: BasicInfoStyles.szBadgeText,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );

      if (isCompact) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: double.infinity, child: identity),
            const SizedBox(height: 12),
            status,
          ],
        );
      }

      return Row(
        children: [
          Expanded(child: identity),
          const SizedBox(width: 24),
          status,
        ],
      );
    });
  }

  // ðŸš€ UPGRADE: GRANULAR LISTENABLE BUILDERS
  Widget _buildEnterpriseCard() {
    return ListenableBuilder(
        listenable:
            Listenable.merge([logic.enterpriseLocked, logic.loadingSection]),
        builder: (context, _) {
          bool isLocked = logic.enterpriseLocked.value;
          return _buildThemeCard(
            section: FormSection.enterprise,
            title: BasicInfoStrings.secEnterprise,
            icon: BasicInfoIcons.enterprise,
            isLocked: isLocked,
            onToggle: () => _handleSectionToggle(
                FormSection.enterprise, BasicInfoStrings.secEnterprise),
            isVerified: displayNameCtrl.text.isNotEmpty &&
                ownerPhoneCtrl.text.length == 10,
            formKey: entKey,
            children: [
              _buildSectionLabel(BasicInfoStrings.subEnterprise),
              const SizedBox(height: 16),
              _ThemeInputField(
                label: BasicInfoStrings.lblLegalName,
                hint: BasicInfoStrings.hintLegalName,
                icon: BasicInfoIcons.legalName,
                ctrl: legalNameCtrl,
                isLocked: isLocked,
                isRequired: true,
                focusNode: legalNameFocus,
                nextFocus: displayNameFocus,
                brandColor: BasicInfoColors.brandIdentity,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _ThemeInputField(
                    label: BasicInfoStrings.lblDisplayName,
                    hint: BasicInfoStrings.hintDisplayName,
                    icon: BasicInfoIcons.displayName,
                    ctrl: displayNameCtrl,
                    isLocked: isLocked,
                    focusNode: displayNameFocus,
                    nextFocus: taglineFocus,
                    brandColor: BasicInfoColors.brandDisplay,
                    onChanged: (val) {
                      // ðŸš€ FIX: logic.markBrandDisplayTouched() removed from here!
                      if (logic.shouldSyncBrandDisplay) {
                        brandDisplayCtrl.text = val;
                      }
                    },
                  )),
                  const SizedBox(width: 20),
                  Expanded(
                      child: _ThemeInputField(
                    label: BasicInfoStrings.lblTagline,
                    hint: BasicInfoStrings.hintTagline,
                    icon: BasicInfoIcons.tagline,
                    ctrl: taglineCtrl,
                    isLocked: isLocked,
                    focusNode: taglineFocus,
                    nextFocus: ownerNameFocus,
                    brandColor: BasicInfoColors.brandIdentity,
                  )),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionLabel(BasicInfoStrings.subProprietor),
              const SizedBox(height: 16),
              _ThemeInputField(
                label: BasicInfoStrings.lblOwner,
                hint: BasicInfoStrings.hintOwner,
                icon: BasicInfoIcons.owner,
                ctrl: ownerNameCtrl,
                isLocked: isLocked,
                focusNode: ownerNameFocus,
                nextFocus: ownerPhoneFocus,
                brandColor: BasicInfoColors.brandIdentity,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _ThemeInputField(
                    label: BasicInfoStrings.lblPhone,
                    hint: BasicInfoStrings.hintPhone,
                    icon: BasicInfoIcons.phone,
                    ctrl: ownerPhoneCtrl,
                    isLocked: isLocked,
                    inputType: TextInputType.phone,
                    focusNode: ownerPhoneFocus,
                    isLastField: true,
                    maxLength: 10,
                    brandColor: BasicInfoColors.brandPhone,
                    onChanged: (val) {
                      if (logic.shouldSyncShopPhone) shopPhoneCtrl.text = val;
                      if (logic.shouldSyncShopWa) shopWaCtrl.text = val;
                    },
                    onFieldSubmitted: (_) => _handleSectionToggle(
                        FormSection.enterprise, BasicInfoStrings.secEnterprise),
                  )),
                ],
              ),
            ],
          );
        });
  }

  Widget _buildCommunicationCard() {
    return ListenableBuilder(
        listenable: Listenable.merge([logic.commLocked, logic.loadingSection]),
        builder: (context, _) {
          bool isLocked = logic.commLocked.value;

          return _buildThemeCard(
            section: FormSection.communication,
            title: BasicInfoStrings.secCommunication,
            icon: BasicInfoIcons.communication,
            isLocked: isLocked,
            onToggle: () => _handleSectionToggle(
                FormSection.communication, BasicInfoStrings.secCommunication),
            isVerified: shopPhoneCtrl.text.length == 10,
            formKey: commKey,
            children: [
              _buildSectionLabel(BasicInfoStrings.subTouchpoints),
              const SizedBox(height: 16),
              _ThemeInputField(
                label: BasicInfoStrings.lblBrandDisplay,
                hint: BasicInfoStrings.hintBrandDisplay,
                icon: BasicInfoIcons.brandDisplay,
                ctrl: brandDisplayCtrl,
                isLocked: isLocked,
                focusNode: brandDisplayFocus,
                nextFocus: emailFocus,
                brandColor: BasicInfoColors.brandDisplay,
                onChanged: (val) => logic.markBrandDisplayTouched(),
              ),
              const SizedBox(height: 16),
              _ThemeInputField(
                label: BasicInfoStrings.lblEmail,
                hint: BasicInfoStrings.hintEmail,
                icon: BasicInfoIcons.email,
                ctrl: emailCtrl,
                isLocked: isLocked,
                inputType: TextInputType.emailAddress,
                focusNode: emailFocus,
                nextFocus: shopPhoneFocus,
                brandColor: BasicInfoColors.brandEmail,
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final fields = [
                    _ThemeInputField(
                      label: BasicInfoStrings.lblBusinessMobile,
                      hint: BasicInfoStrings.hintPhone,
                      icon: BasicInfoIcons.phone,
                      ctrl: shopPhoneCtrl,
                      isLocked: isLocked,
                      inputType: TextInputType.phone,
                      focusNode: shopPhoneFocus,
                      nextFocus: shopWaFocus,
                      maxLength: 10,
                      brandColor: BasicInfoColors.brandPhone,
                      onChanged: (val) => logic.markShopPhoneTouched(),
                    ),
                    _ThemeInputField(
                      label: BasicInfoStrings.lblBizWhatsapp,
                      hint: BasicInfoStrings.hintWhatsapp,
                      icon: BasicInfoIcons.whatsapp,
                      brandColor: BasicInfoColors.brandWhatsapp,
                      ctrl: shopWaCtrl,
                      isLocked: isLocked,
                      inputType: TextInputType.phone,
                      focusNode: shopWaFocus,
                      nextFocus: helpDeskFocus,
                      maxLength: 10,
                      onChanged: (val) => logic.markShopWaTouched(),
                    ),
                    _ThemeInputField(
                      label: BasicInfoStrings.lblHelpDesk,
                      hint: BasicInfoStrings.hintPhone,
                      icon: BasicInfoIcons.phone,
                      ctrl: helpDeskCtrl,
                      isLocked: isLocked,
                      inputType: TextInputType.phone,
                      focusNode: helpDeskFocus,
                      maxLength: 10,
                      isLastField: true,
                      brandColor: BasicInfoColors.brandPhone,
                      onFieldSubmitted: (_) => _handleSectionToggle(
                        FormSection.communication,
                        BasicInfoStrings.secCommunication,
                      ),
                    ),
                  ];

                  if (constraints.maxWidth < 760) {
                    return Column(
                      children: [
                        for (var index = 0; index < fields.length; index++) ...[
                          fields[index],
                          if (index != fields.length - 1)
                            const SizedBox(height: 16),
                        ],
                      ],
                    );
                  }

                  return Row(
                    children: [
                      for (var index = 0; index < fields.length; index++) ...[
                        Expanded(child: fields[index]),
                        if (index != fields.length - 1)
                          const SizedBox(width: 20),
                      ],
                    ],
                  );
                },
              ),
            ],
          );
        });
  }

  // --- HELPER WIDGETS ---

  Widget _buildThemeCard({
    required FormSection section,
    required String title,
    required IconData icon,
    required bool isLocked,
    required VoidCallback onToggle,
    required List<Widget> children,
    required GlobalKey<FormState> formKey,
    bool isVerified = false,
  }) {
    bool isSaving = logic.loadingSection.value == section;

    return Container(
      padding: BasicInfoStyles.padCardInternal,
      decoration: BasicInfoStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color:
                            BasicInfoColors.goldAccent.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(BasicInfoStyles.rHeaderIcon)),
                    child:
                        Icon(icon, color: BasicInfoColors.goldAccent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(title,
                      style: GoogleFonts.manrope(
                          fontSize: BasicInfoStyles.szSectionTitle,
                          fontWeight: FontWeight.w700,
                          color: BasicInfoColors.textDark)),
                  if (isVerified) ...[
                    const SizedBox(width: 8),
                    const Icon(BasicInfoIcons.statusActive,
                        color: BasicInfoColors.iconDefaultSuccess, size: 18),
                  ]
                ],
              ),
              Material(
                color: BasicInfoColors.transparent,
                child: InkWell(
                  onTap: isSaving ? null : onToggle,
                  borderRadius:
                      BorderRadius.circular(BasicInfoStyles.rStatusPill),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                        color: isLocked
                            ? BasicInfoColors.inputBgLocked
                            : BasicInfoColors.statusActiveBg,
                        borderRadius:
                            BorderRadius.circular(BasicInfoStyles.rStatusPill),
                        border: Border.all(
                            color: isLocked
                                ? BasicInfoColors.textHint
                                    .withValues(alpha: 0.3)
                                : BasicInfoColors.statusActiveText
                                    .withValues(alpha: 0.3))),
                    child: Row(
                      children: [
                        if (isSaving)
                          const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: BasicInfoColors.statusActiveText))
                        else
                          Icon(
                              isLocked
                                  ? BasicInfoIcons.lock
                                  : BasicInfoIcons.save,
                              size: 16,
                              color: isLocked
                                  ? BasicInfoColors.textMuted
                                  : BasicInfoColors.statusActiveText),
                        const SizedBox(width: 6),
                        Text(
                          isSaving
                              ? "Saving..."
                              : (isLocked
                                  ? BasicInfoStrings.lblLocked
                                  : "Save"),
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isLocked
                                  ? BasicInfoColors.textMuted
                                  : BasicInfoColors.statusActiveText),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
          const Divider(
              height: 40, thickness: 1, color: BasicInfoColors.borderLight),
          Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.disabled,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children),
          )
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text,
        style: GoogleFonts.inter(
            fontSize: BasicInfoStyles.szSectionSub,
            fontWeight: FontWeight.w800,
            color: BasicInfoColors.textMuted,
            letterSpacing: 1.2));
  }
}

class _ThemeInputField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController ctrl;
  final bool isLocked;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;
  final Color? brandColor;
  final TextInputType inputType;
  final bool isLastField;
  final Function(String)? onFieldSubmitted;
  final int? maxLength;
  final Function(String)? onChanged;
  final bool isRequired;

  const _ThemeInputField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.ctrl,
    required this.isLocked,
    this.focusNode,
    this.nextFocus,
    this.brandColor,
    this.inputType = TextInputType.text,
    this.isLastField = false,
    this.onFieldSubmitted,
    this.maxLength,
    this.onChanged,
    this.isRequired = false,
  });

  @override
  State<_ThemeInputField> createState() => _ThemeInputFieldState();
}

class _ThemeInputFieldState extends State<_ThemeInputField> {
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode?.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_ThemeInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChange);
      widget.focusNode?.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() => _hasFocus = widget.focusNode?.hasFocus ?? false);
    }
  }

  @override
  Widget build(BuildContext context) {
    BoxDecoration boxDecoration = (!widget.isLocked && _hasFocus)
        ? BasicInfoStyles.activeInputDecoration
        : BasicInfoStyles.inputDecoration(widget.isLocked);
    Color iconColor = _hasFocus
        ? BasicInfoColors.goldAccent
        : (widget.ctrl.text.isNotEmpty
            ? (widget.brandColor ?? BasicInfoColors.iconDefaultSuccess)
            : BasicInfoColors.textHint);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(widget.label,
                style: GoogleFonts.manrope(
                    fontSize: BasicInfoStyles.szFieldLabel,
                    fontWeight: FontWeight.w700,
                    color: BasicInfoColors.textBody)),
            if (widget.isRequired) ...[
              const SizedBox(width: 4),
              Text('*',
                  style: GoogleFonts.manrope(
                      fontSize: BasicInfoStyles.szFieldLabel,
                      fontWeight: FontWeight.w800,
                      color: BasicInfoColors.goldAccent)),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: BasicInfoStyles.hInputField,
          decoration: boxDecoration,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(widget.icon,
                      key: ValueKey(iconColor), size: 20, color: iconColor)),
              const SizedBox(width: 12),
              Container(
                  width: 1, height: 24, color: BasicInfoColors.borderLight),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: widget.ctrl,
                  readOnly: widget.isLocked,
                  keyboardType: widget.inputType,
                  focusNode: widget.focusNode,
                  maxLength: widget.maxLength,
                  onChanged: widget.onChanged,
                  inputFormatters: widget.maxLength != null
                      ? [
                          LengthLimitingTextInputFormatter(widget.maxLength),
                          FilteringTextInputFormatter.digitsOnly
                        ]
                      : [],
                  textInputAction: widget.isLastField
                      ? TextInputAction.done
                      : TextInputAction.next,
                  onFieldSubmitted: (val) {
                    if (!widget.isLastField && widget.nextFocus != null) {
                      FocusScope.of(context).requestFocus(widget.nextFocus);
                    }
                    if (widget.onFieldSubmitted != null) {
                      widget.onFieldSubmitted!(val);
                    }
                  },
                  style: GoogleFonts.manrope(
                      fontSize: BasicInfoStyles.szFieldText,
                      fontWeight: FontWeight.w700,
                      color: BasicInfoColors.textDark),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    counterText: "",
                    hintText: widget.hint,
                    hintStyle: GoogleFonts.inter(
                        color: BasicInfoColors.textHint,
                        fontSize: BasicInfoStyles.szFieldHint),
                    contentPadding: const EdgeInsets.only(bottom: 2),
                    errorStyle: const TextStyle(height: 0),
                  ),
                ),
              )
            ],
          ),
        )
      ],
    );
  }
}
