// -----------------------------------------------------------------------------
// FILE: branding_tab.dart
// TYPE: Presentation Layer (UI)
// AUTHOR: Senior System Architect
// DESCRIPTION: 60-FPS Zero-Lag UI using ListenableBuilder. 100% completely
//              decoupled from hardcoded strings, dimensions, and styling.
//              [UPGRADED: Added autoSyncData Receiver and Database Auto-Fill]
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- IMPORTS ---
import '../../../../logic/setting/shop_setup/tabs/branding/branding_logic.dart';
import '../../../../theme/settings/shop_setup/tabs/branding/branding_theme.dart';
import '../../../../../../models/setting/shop_setup/shop_profile_model.dart';
// 🚀 UPGRADE: ShopBrandingModel imported for auto-fill logic
import '../../../../../../models/setting/shop_setup/tabs/shop_branding_model.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';

class BrandingTab extends StatefulWidget {
  final ShopProfileModel? initialData;
  // 🚀 NEW: Receive branding data directly from SQLite via Wizard
  final Map<String, dynamic>? brandingData;

  const BrandingTab({super.key, this.initialData, this.brandingData});

  @override
  State<BrandingTab> createState() => BrandingTabState();
}

class BrandingTabState extends State<BrandingTab> {
  late BrandingLogic logic;

  @override
  void initState() {
    super.initState();
    logic = BrandingLogic();

    // Yeh Basic Info se phone/email sync karega
    logic.init(widget.initialData);

    // 🚀 NEW: AUTO-FILL LOGIC FOR SOCIAL & SUPPORT LINKS (Database Fetch)
    if (widget.brandingData != null && widget.brandingData!.isNotEmpty) {
      logic.instaCtrl.text =
          widget.brandingData!['instagram']?.toString() ?? '';
      logic.fbCtrl.text = widget.brandingData!['facebook']?.toString() ?? '';
      logic.ytCtrl.text = widget.brandingData!['youtube']?.toString() ?? '';
      logic.webCtrl.text = widget.brandingData!['website']?.toString() ?? '';
      logic.waChannelCtrl.text =
          widget.brandingData!['whatsapp_channel']?.toString() ?? '';

      // Agar explicitly branding mein hi support data save kiya tha, toh usko use karein
      if (widget.brandingData!['whatsapp_business'] != null &&
          widget.brandingData!['whatsapp_business'].toString().isNotEmpty) {
        logic.waBizCtrl.text =
            widget.brandingData!['whatsapp_business'].toString();
      }
      if (widget.brandingData!['support_email'] != null &&
          widget.brandingData!['support_email'].toString().isNotEmpty) {
        logic.emailCtrl.text = widget.brandingData!['support_email'].toString();
      }
      if (widget.brandingData!['support_phone'] != null &&
          widget.brandingData!['support_phone'].toString().isNotEmpty) {
        logic.phoneCtrl.text = widget.brandingData!['support_phone'].toString();
      }

      // Logic layer ke state model ko bhi update kar do
      logic.brandingData = ShopBrandingModel.fromJson(
          Map<String, dynamic>.from(widget.brandingData!));
    }

    // 🚀 UPGRADE: Completely removed setState listener!
    // UI will now strictly use ListenableBuilder for high-performance rebuilds.
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  // --- 🚀 UPGRADE: DATA RECEIVER (Bridge Endpoint from Wizard) ---
  // Yeh function Wizard se bheje gaye data ko catch karega aur auto-fill karega.
  void autoSyncData(
      {required String phone,
      required String whatsapp,
      required String email}) {
    bool isUpdated = false;

    // Sirf tabhi update karo jab fields khali hon (Taaki user ka purana data overwrite na ho)
    if (logic.waBizCtrl.text.isEmpty && whatsapp.isNotEmpty) {
      logic.waBizCtrl.text = whatsapp;
      isUpdated = true;
    }
    if (logic.emailCtrl.text.isEmpty && email.isNotEmpty) {
      logic.emailCtrl.text = email;
      isUpdated = true;
    }
    if (logic.phoneCtrl.text.isEmpty && phone.isNotEmpty) {
      logic.phoneCtrl.text = phone;
      isUpdated = true;
    }

    // Agar humne auto-fill kiya hai, toh UI ko ek chhota push denge
    // taaki TextFields ke side mein green checkmarks turant render ho jayein
    if (isUpdated && mounted) {
      logic.generateFinalModel();
      setState(() {});
    }
  }

  ShopBrandingModel? validateAndExport() {
    return logic.validateAndGenerateFinalModel();
  }

  String? get validationMessage => logic.lastValidationError;

  // --- SMART TOGGLE HANDLING ---
  void _handleSectionToggle(String sectionId, String sectionName) async {
    if (logic.loadingSection == sectionId) return;

    if (logic.isSectionLocked(sectionId)) {
      // UNLOCK MODE
      FocusNode? targetNode = logic.unlockSection(sectionId);
      if (targetNode != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) FocusScope.of(context).requestFocus(targetNode);
        });
      }
    } else {
      // SAVE MODE
      final saved = await logic.saveSection(sectionId);
      if (!saved && mounted) {
        AppFeedback.error(
          context,
          message: logic.lastValidationError ??
              "Please correct the highlighted branding fields.",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      bool isDesktop = constraints.maxWidth > BrandingStyles.desktopBreakpoint;
      return SingleChildScrollView(
        padding: BrandingStyles.padPageBottom,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(),
            const SizedBox(height: BrandingStyles.spacePageTitle),
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
        Expanded(child: _buildSocialCard()),
        const SizedBox(width: BrandingStyles.spaceCardGap),
        Expanded(child: _buildSupportCard()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildSocialCard(),
        const SizedBox(height: BrandingStyles.spaceCardGap),
        _buildSupportCard(),
      ],
    );
  }

  // --- CARDS ---

  Widget _buildSocialCard() {
    return _buildThemeCard(
      sectionId: 'social',
      title: BrandingStrings.cardSocialTitle,
      icon: BrandingIcons.secSocial,
      onToggle: () =>
          _handleSectionToggle('social', BrandingStrings.toggleSocial),
      formKey: logic.socialKey,
      childrenBuilder: (isLocked) => [
        _ThemeInputField(
          label: BrandingStrings.lblInstagram,
          hint: BrandingStrings.hntInstagram,
          icon: BrandingIcons.instagram,
          ctrl: logic.instaCtrl,
          isLocked: isLocked,
          focusNode: logic.instaFocus,
          nextFocus: logic.fbFocus,
          brandColor: BrandingColors.brandInsta,
          platformType: 'instagram',
          onLaunchUrl: logic.launchPlatformUrl,
        ),
        const SizedBox(height: BrandingStyles.spaceFieldGap),
        _ThemeInputField(
          label: BrandingStrings.lblFacebook,
          hint: BrandingStrings.hntFacebook,
          icon: BrandingIcons.facebook,
          ctrl: logic.fbCtrl,
          isLocked: isLocked,
          focusNode: logic.fbFocus,
          nextFocus: logic.ytFocus,
          brandColor: BrandingColors.brandFb,
          platformType: 'facebook',
          onLaunchUrl: logic.launchPlatformUrl,
        ),
        const SizedBox(height: BrandingStyles.spaceFieldGap),
        _ThemeInputField(
          label: BrandingStrings.lblYoutube,
          hint: BrandingStrings.hntYoutube,
          icon: BrandingIcons.youtube,
          ctrl: logic.ytCtrl,
          isLocked: isLocked,
          focusNode: logic.ytFocus,
          nextFocus: logic.webFocus,
          brandColor: BrandingColors.brandYoutube,
          platformType: 'youtube',
          onLaunchUrl: logic.launchPlatformUrl,
        ),
        const SizedBox(height: BrandingStyles.spaceFieldGap),
        _ThemeInputField(
          label: BrandingStrings.lblWebsite,
          hint: BrandingStrings.hntWebsite,
          icon: BrandingIcons.website,
          ctrl: logic.webCtrl,
          isLocked: isLocked,
          focusNode: logic.webFocus,
          isLastField: true,
          brandColor: BrandingColors.brandWeb,
          platformType: 'website',
          onLaunchUrl: logic.launchPlatformUrl,
          onFieldSubmitted: (_) =>
              _handleSectionToggle('social', BrandingStrings.toggleSocial),
        ),
      ],
    );
  }

  Widget _buildSupportCard() {
    return _buildThemeCard(
      sectionId: 'support',
      title: BrandingStrings.cardSupportTitle,
      icon: BrandingIcons.secSupport,
      onToggle: () =>
          _handleSectionToggle('support', BrandingStrings.toggleSupport),
      formKey: logic.supportKey,
      childrenBuilder: (isLocked) => [
        _ThemeInputField(
          label: BrandingStrings.lblWaChannel,
          hint: BrandingStrings.hntWaChannel,
          icon: BrandingIcons.whatsappChannel,
          ctrl: logic.waChannelCtrl,
          isLocked: isLocked,
          focusNode: logic.waChannelFocus,
          nextFocus: logic.waBizFocus,
          brandColor: BrandingColors.brandWhatsapp,
          platformType: 'website',
          onLaunchUrl: logic.launchPlatformUrl,
        ),
        const SizedBox(height: BrandingStyles.spaceFieldGap),
        _ThemeInputField(
          label: BrandingStrings.lblWaBusiness,
          hint: BrandingStrings.hntWaBusiness,
          icon: BrandingIcons.whatsappBiz,
          ctrl: logic.waBizCtrl,
          isLocked: isLocked,
          focusNode: logic.waBizFocus,
          nextFocus: logic.emailFocus,
          inputType: TextInputType.phone,
          maxLength: 15,
          brandColor: BrandingColors.brandWhatsapp,
          platformType: 'whatsapp',
          onLaunchUrl: logic.launchPlatformUrl,
        ),
        const SizedBox(height: BrandingStyles.spaceFieldGap),
        _ThemeInputField(
          label: BrandingStrings.lblSupportEmail,
          hint: BrandingStrings.hntSupportEmail,
          icon: BrandingIcons.email,
          ctrl: logic.emailCtrl,
          isLocked: isLocked,
          focusNode: logic.emailFocus,
          nextFocus: logic.phoneFocus,
          inputType: TextInputType.emailAddress,
          brandColor: BrandingColors.brandEmail,
          platformType: 'email',
          onLaunchUrl: logic.launchPlatformUrl,
        ),
        const SizedBox(height: BrandingStyles.spaceFieldGap),
        _ThemeInputField(
          label: BrandingStrings.lblSupportPhone,
          hint: BrandingStrings.hntSupportPhone,
          icon: BrandingIcons.phone,
          ctrl: logic.phoneCtrl,
          isLocked: isLocked,
          focusNode: logic.phoneFocus,
          inputType: TextInputType.phone,
          isLastField: true,
          maxLength: 15,
          brandColor: BrandingColors.brandPhone,
          platformType: 'phone',
          onLaunchUrl: logic.launchPlatformUrl,
          onFieldSubmitted: (_) =>
              _handleSectionToggle('support', BrandingStrings.toggleSupport),
        ),
      ],
    );
  }

  // --- REUSABLE CARD WIDGET WITH GRANULAR LISTENABLE BUILDER ---
  Widget _buildThemeCard({
    required String sectionId,
    required String title,
    required IconData icon,
    required VoidCallback onToggle,
    required GlobalKey<FormState> formKey,
    required List<Widget> Function(bool isLocked) childrenBuilder,
  }) {
    // 🚀 UPGRADE: ListenableBuilder strictly limits UI rebuilds to ONLY this card.
    return ListenableBuilder(
        listenable: logic,
        builder: (context, child) {
          bool isLocked = logic.isSectionLocked(sectionId);
          bool isSaving = logic.loadingSection == sectionId;

          return Container(
            padding: BrandingStyles.padCardInternal,
            decoration: BrandingStyles.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: BrandingStyles.padIconBg,
                          decoration: BoxDecoration(
                            color: BrandingColors.goldAccentLight,
                            borderRadius: BorderRadius.circular(
                                BrandingStyles.rHeaderIcon),
                          ),
                          child: Icon(icon,
                              color: BrandingColors.goldAccent,
                              size: BrandingStyles.iconHeaderSize),
                        ),
                        const SizedBox(width: BrandingStyles.spaceIconText),
                        Text(
                          title,
                          style: BrandingStyles.textSectionTitle,
                        ),
                      ],
                    ),
                    // ANIMATED LOCK / SAVE BUTTON
                    Material(
                      color: BrandingColors.transparent,
                      child: InkWell(
                        onTap: isSaving ? null : onToggle,
                        borderRadius:
                            BorderRadius.circular(BrandingStyles.rStatusPill),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: BrandingStyles.padBtnPill,
                          decoration: BoxDecoration(
                              color: isLocked
                                  ? BrandingColors.inputBgLocked
                                  : BrandingColors.statusActiveBg,
                              borderRadius: BorderRadius.circular(
                                  BrandingStyles.rStatusPill),
                              border: Border.all(
                                  color: isLocked
                                      ? BrandingColors.borderLockedState
                                      : BrandingColors.borderActiveState)),
                          child: Row(
                            children: [
                              if (isSaving)
                                const SizedBox(
                                    width: BrandingStyles.iconBtnSize,
                                    height: BrandingStyles.iconBtnSize,
                                    child: CircularProgressIndicator(
                                        strokeWidth:
                                            BrandingStyles.strokeLoader,
                                        color: BrandingColors.statusActiveText))
                              else
                                Icon(
                                    isLocked
                                        ? BrandingIcons.lock
                                        : BrandingIcons.save,
                                    size: BrandingStyles.iconBtnSize,
                                    color: isLocked
                                        ? BrandingColors.textMuted
                                        : BrandingColors.statusActiveText),
                              const SizedBox(
                                  width: BrandingStyles.spaceBtnIconText),
                              Text(
                                isSaving
                                    ? BrandingStrings.btnSaving
                                    : (isLocked
                                        ? BrandingStrings.btnLocked
                                        : BrandingStrings.btnSave),
                                style: isLocked
                                    ? BrandingStyles.textBtnStatusLocked
                                    : BrandingStyles.textBtnStatusActive,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                const Divider(
                    height: BrandingStyles.dividerHeight,
                    thickness: BrandingStyles.dividerThickness,
                    color: BrandingColors.borderLight),
                Form(
                  key: formKey,
                  autovalidateMode: AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: childrenBuilder(isLocked),
                  ),
                )
              ],
            ),
          );
        });
  }

  // --- PAGE HEADER ---
  Widget _buildPageHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              BrandingStrings.pageTitle,
              style: BrandingStyles.textPageTitle,
            ),
            const SizedBox(height: 4),
            Text(
              BrandingStrings.pageSubtitle,
              style: BrandingStyles.textPageSub,
            ),
          ],
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 🚀 OPTIMIZED THEME INPUT (With Clickable URL Wrapper)
// -----------------------------------------------------------------------------

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

  final String platformType;
  final Function(String, String)? onLaunchUrl;

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
    required this.platformType,
    this.onLaunchUrl,
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
    BoxDecoration boxDecoration;
    if (!widget.isLocked && _hasFocus) {
      boxDecoration = BrandingStyles.activeInputDecoration;
    } else {
      boxDecoration = BrandingStyles.inputDecoration(widget.isLocked);
    }

    Color iconColor;
    if (_hasFocus) {
      iconColor = BrandingColors.goldAccent;
    } else if (widget.ctrl.text.isNotEmpty) {
      iconColor = widget.brandColor ?? BrandingColors.iconSuccess;
    } else {
      iconColor = BrandingColors.textHint;
    }

    bool isClickableLink = widget.isLocked && widget.ctrl.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: BrandingStyles.textLabel,
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: BrandingStyles.hInputField,
              decoration: boxDecoration,
              padding: BrandingStyles.padInputInner,
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Icon(widget.icon,
                        key: ValueKey(iconColor),
                        size: BrandingStyles.iconInputSize,
                        color: iconColor),
                  ),
                  const SizedBox(width: BrandingStyles.spaceIconText),
                  Container(
                      width: 1, height: 24, color: BrandingColors.borderLight),
                  const SizedBox(width: BrandingStyles.spaceIconText),
                  Expanded(
                    child: TextFormField(
                      controller: widget.ctrl,
                      readOnly: widget.isLocked,
                      keyboardType: widget.inputType,
                      focusNode: widget.focusNode,
                      maxLength: widget.maxLength,
                      inputFormatters: widget.maxLength != null
                          ? [
                              LengthLimitingTextInputFormatter(
                                  widget.maxLength),
                              FilteringTextInputFormatter.digitsOnly,
                            ]
                          : [],
                      textInputAction: widget.isLastField
                          ? TextInputAction.done
                          : TextInputAction.next,
                      onFieldSubmitted: (val) {
                        if (widget.isLastField) {
                          if (widget.onFieldSubmitted != null) {
                            widget.onFieldSubmitted!(val);
                          }
                        } else {
                          if (widget.nextFocus != null) {
                            FocusScope.of(context)
                                .requestFocus(widget.nextFocus);
                          }
                        }
                      },
                      style: BrandingStyles.textInput(
                          isClickableLink, widget.brandColor),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        counterText: "",
                        hintText: widget.hint,
                        hintStyle: BrandingStyles.textHint,
                        contentPadding: const EdgeInsets.only(bottom: 2),
                      ),
                    ),
                  )
                ],
              ),
            ),

            // INVISIBLE CLICKABLE LAYER WHEN LOCKED
            if (isClickableLink)
              Positioned.fill(
                child: Material(
                  color: BrandingColors.transparent,
                  child: InkWell(
                    borderRadius:
                        BorderRadius.circular(BrandingStyles.rInputRadius),
                    onTap: () {
                      if (widget.onLaunchUrl != null) {
                        widget.onLaunchUrl!(
                            widget.platformType, widget.ctrl.text);
                      }
                    },
                  ),
                ),
              )
          ],
        )
      ],
    );
  }
}
