// -----------------------------------------------------------------------------
// FILE: address_card_tab.dart
// TYPE: Presentation Layer (UI)
// AUTHOR: Senior UI/UX Engineer & Enterprise Architect
// DESCRIPTION: ðŸš€ UPGRADED: 100% Theme-Driven, Zero-Lag UI.
//              Controllers and Map elements moved to UI State safely.
//              Strictly uses ListenableBuilder with decoupled Logic.
//              [FINAL UPGRADE: Auto-Fill for Text, Map Coordinates & Chips]
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../theme/settings/shop_setup/tabs/address/address_theme.dart';
import '../../../../logic/setting/shop_setup/tabs/address/address_logic.dart';
import '../../../../logic/setting/shop_setup/tabs/address/address_map_logic.dart';

class AddressTab extends StatefulWidget {
  // ðŸš€ NEW: Receive initial data from parent
  final Map<String, dynamic>? initialData;

  const AddressTab({super.key, this.initialData});

  @override
  State<AddressTab> createState() => AddressTabState();
}

class AddressTabState extends State<AddressTab> {
  // ðŸš€ UPGRADE: Logic Engines
  late final AddressFormLogic formLogic;
  late final AddressMapLogic mapLogic;

  // ðŸš€ UPGRADE: Controllers safely moved to UI State
  final TextEditingController addr1Ctrl = TextEditingController();
  final TextEditingController addr2Ctrl = TextEditingController();
  final TextEditingController cityCtrl = TextEditingController();
  final TextEditingController stateCtrl = TextEditingController();
  final TextEditingController pinCtrl = TextEditingController();
  final TextEditingController countryCtrl =
      TextEditingController(text: "India");

  // ðŸš€ UPGRADE: Focus Nodes strictly in UI Layer
  final FocusNode addr1Focus = FocusNode();
  final FocusNode addr2Focus = FocusNode();
  final FocusNode cityFocus = FocusNode();
  final FocusNode stateFocus = FocusNode();
  final FocusNode pinFocus = FocusNode();
  final FocusNode countryFocus = FocusNode();

  final FocusNode headOfficeFocus = FocusNode();
  final FocusNode branchOfficeFocus = FocusNode();
  final FocusNode warehouseFocus = FocusNode();

  // ðŸš€ UPGRADE: Map Visual Elements in UI Layer
  final MapController mapController = MapController();
  List<Marker> mapMarkers = [];

  @override
  void initState() {
    super.initState();
    formLogic = AddressFormLogic();
    mapLogic = AddressMapLogic();

    // ðŸš€ NEW: AUTO-FILL LOGIC FOR ADDRESS & MAP
    if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      addr1Ctrl.text = widget.initialData!['addr1']?.toString() ?? '';
      addr2Ctrl.text = widget.initialData!['addr2']?.toString() ?? '';
      cityCtrl.text = widget.initialData!['city']?.toString() ?? '';
      stateCtrl.text = widget.initialData!['state']?.toString() ?? '';
      pinCtrl.text = widget.initialData!['pincode']?.toString() ?? '';

      if (widget.initialData!['country'] != null &&
          widget.initialData!['country'].toString().isNotEmpty) {
        countryCtrl.text = widget.initialData!['country'].toString();
      }

      if (widget.initialData!['type'] != null) {
        formLogic.updateAddressType(widget.initialData!['type'].toString());
      }

      // Auto-Locate Map to saved coordinates
      if (widget.initialData!['latitude'] != null &&
          widget.initialData!['longitude'] != null) {
        try {
          final double lat =
              double.parse(widget.initialData!['latitude'].toString());
          final double lng =
              double.parse(widget.initialData!['longitude'].toString());
          final LatLng savedLoc = LatLng(lat, lng);

          mapLogic.selectedLocation.value = savedLoc;
          mapMarkers = [
            Marker(
              point: savedLoc,
              width: 40,
              height: 40,
              alignment: Alignment.topCenter,
              child: const Icon(Icons.location_on,
                  color: AddressColors.goldAccent, size: 40),
            )
          ];

          // Move map controller safely after UI layout is built
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              mapController.move(savedLoc, 16.0);
            } catch (_) {}
          });
        } catch (e) {
          debugPrint("Map Coordinate Auto-Fill Error: $e");
        }
      }
    }
  }

  @override
  void dispose() {
    formLogic.dispose();
    mapLogic.dispose();

    // Memory Leak Prevention: Dispose all UI controllers
    addr1Ctrl.dispose();
    addr2Ctrl.dispose();
    cityCtrl.dispose();
    stateCtrl.dispose();
    pinCtrl.dispose();
    countryCtrl.dispose();

    addr1Focus.dispose();
    addr2Focus.dispose();
    cityFocus.dispose();
    stateFocus.dispose();
    pinFocus.dispose();
    countryFocus.dispose();
    headOfficeFocus.dispose();
    branchOfficeFocus.dispose();
    warehouseFocus.dispose();

    mapController.dispose();
    super.dispose();
  }

  // --- SMART TOGGLE HANDLING FOR FORM ---
  void _handleAddressToggle() async {
    if (formLogic.isSaving.value) return;

    if (formLogic.isAddressLocked.value) {
      formLogic.unlockAddress();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) FocusScope.of(context).requestFocus(addr1Focus);
      });
    } else {
      // ðŸš€ UPGRADE: Pure Validation Workflow
      List<String> errors = formLogic.validateAddress(
        addr1: addr1Ctrl.text,
        addr2: addr2Ctrl.text,
        city: cityCtrl.text,
        state: stateCtrl.text,
        pin: pinCtrl.text,
      );

      if (errors.isNotEmpty) {
        _routeFocusToError(errors.first);
        return;
      }

      await formLogic.saveAddress(errors);
    }
  }

  void _routeFocusToError(String errorKey) {
    if (errorKey == 'keyAddr1') {
      addr1Focus.requestFocus();
    } else if (errorKey == 'keyAddr2')
      addr2Focus.requestFocus();
    else if (errorKey == 'keyCity')
      cityFocus.requestFocus();
    else if (errorKey == 'keyState')
      stateFocus.requestFocus();
    else if (errorKey == 'keyPin') pinFocus.requestFocus();
  }

  // --- SMART MAP HANDLING ---
  void _handleMapTap(LatLng latLng) {
    if (mapLogic.isMapLocked.value) {
      _showMapSnack(AddressStrings.msgUnlockMap, isError: true);
    } else {
      mapLogic.onMapTap(latLng);
      _updateMapMarker(latLng);
    }
  }

  Future<void> _handleGpsDetect() async {
    try {
      LatLng newLoc = await mapLogic.detectCurrentLocation();
      _updateMapMarker(newLoc);
      mapController.move(newLoc, 16.0);
      _showMapSnack("Location Detected Successfully", isError: false);
    } catch (e) {
      _showMapSnack(e.toString().replaceAll("Exception: ", ""), isError: true);
    }
  }

  void _updateMapMarker(LatLng latLng) {
    setState(() {
      mapMarkers = [
        Marker(
          point: latLng,
          width: 40,
          height: 40,
          alignment: Alignment.topCenter,
          child: const Icon(Icons.location_on,
              color: AddressColors.goldAccent, size: 40),
        )
      ];
    });
  }

  void _showMapSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? AddressIcons.errorOutline : AddressIcons.checkCircle,
            color: AddressColors.surfaceWhite, size: 20),
        const SizedBox(width: 8),
        Expanded(
            child: Text(msg,
                style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis))
      ]),
      backgroundColor:
          isError ? AddressColors.btnDanger : AddressColors.saveBtn,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  void _handleChipSelect(String type) {
    if (formLogic.isAddressLocked.value) return;
    formLogic.updateAddressType(type);
    _handleAddressToggle();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: LayoutBuilder(builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PageHeader(),
              const SizedBox(height: 30),
              isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 65, child: _buildAddressCard()),
        const SizedBox(width: 24),
        Expanded(flex: 35, child: _buildMapSection()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildAddressCard(),
        const SizedBox(height: 24),
        _buildMapSection(),
      ],
    );
  }

  Widget _buildAddressCard() {
    return ListenableBuilder(
        listenable: Listenable.merge([
          formLogic.isAddressLocked,
          formLogic.isSaving,
          formLogic.selectedAddressType
        ]),
        builder: (context, _) {
          bool isLocked = formLogic.isAddressLocked.value;
          return Container(
            padding: AddressStyles.padCardInternal,
            decoration: AddressStyles.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                    title: AddressStrings.secAddress,
                    icon: AddressIcons.sectionAddress,
                    isLocked: isLocked,
                    isSaving: formLogic.isSaving.value,
                    onToggle: _handleAddressToggle),
                const Divider(
                    height: 40, thickness: 1, color: AddressColors.borderLight),
                _buildSectionLabel(AddressStrings.subLocation),
                const SizedBox(height: 16),
                SmartInput(
                  label: AddressStrings.lblAddr1,
                  hint: AddressStrings.hintAddr1,
                  icon: AddressIcons.addrHome,
                  brandColor: AddressColors.brandLocation,
                  ctrl: addr1Ctrl,
                  focusNode: addr1Focus,
                  nextFocus: addr2Focus,
                  isLocked: isLocked,
                  isRequired: true,
                ),
                const SizedBox(height: 16),
                SmartInput(
                  label: AddressStrings.lblAddr2,
                  hint: AddressStrings.hintAddr2,
                  icon: AddressIcons.addrRoad,
                  brandColor: AddressColors.brandStreet,
                  ctrl: addr2Ctrl,
                  focusNode: addr2Focus,
                  nextFocus: cityFocus,
                  isLocked: isLocked,
                  isRequired: true,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: SmartInput(
                      label: AddressStrings.lblCity,
                      hint: AddressStrings.hintCity,
                      icon: AddressIcons.city,
                      brandColor: AddressColors.brandCity,
                      ctrl: cityCtrl,
                      focusNode: cityFocus,
                      nextFocus: stateFocus,
                      isLocked: isLocked,
                      isRequired: true,
                    )),
                    const SizedBox(width: 20),
                    Expanded(
                        child: SmartInput(
                      label: AddressStrings.lblState,
                      hint: AddressStrings.hintState,
                      icon: AddressIcons.state,
                      brandColor: AddressColors.brandState,
                      ctrl: stateCtrl,
                      focusNode: stateFocus,
                      nextFocus: pinFocus,
                      isLocked: isLocked,
                      isRequired: true,
                    )),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: SmartInput(
                      label: AddressStrings.lblPin,
                      hint: AddressStrings.hintPin,
                      icon: AddressIcons.pincode,
                      brandColor: AddressColors.brandPin,
                      ctrl: pinCtrl,
                      focusNode: pinFocus,
                      nextFocus: countryFocus,
                      isLocked: isLocked,
                      inputType: TextInputType.number,
                      maxLength: 6,
                      isDigitsOnly: true,
                      isRequired: true,
                    )),
                    const SizedBox(width: 20),
                    Expanded(
                        child: SmartInput(
                      label: AddressStrings.lblCountry,
                      hint: AddressStrings.hintCountry,
                      icon: AddressIcons.country,
                      brandColor: AddressColors.brandCountry,
                      ctrl: countryCtrl,
                      focusNode: countryFocus,
                      nextFocus: headOfficeFocus,
                      isLocked: isLocked,
                      inputType: TextInputType.name,
                    )),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionLabel(AddressStrings.subFacility),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _KeyboardChip(
                      label: AddressStrings.typeHeadOffice,
                      isSelected: formLogic.selectedAddressType.value ==
                          AddressStrings.typeHeadOffice,
                      isDisabled: isLocked,
                      focusNode: headOfficeFocus,
                      nextFocus: branchOfficeFocus,
                      prevFocus: countryFocus,
                      onSelect: () =>
                          _handleChipSelect(AddressStrings.typeHeadOffice),
                    )),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _KeyboardChip(
                      label: AddressStrings.typeBranchOffice,
                      isSelected: formLogic.selectedAddressType.value ==
                          AddressStrings.typeBranchOffice,
                      isDisabled: isLocked,
                      focusNode: branchOfficeFocus,
                      nextFocus: warehouseFocus,
                      prevFocus: headOfficeFocus,
                      onSelect: () =>
                          _handleChipSelect(AddressStrings.typeBranchOffice),
                    )),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _KeyboardChip(
                      label: AddressStrings.typeWarehouse,
                      isSelected: formLogic.selectedAddressType.value ==
                          AddressStrings.typeWarehouse,
                      isDisabled: isLocked,
                      focusNode: warehouseFocus,
                      nextFocus: null,
                      prevFocus: branchOfficeFocus,
                      onSelect: () =>
                          _handleChipSelect(AddressStrings.typeWarehouse),
                    )),
                  ],
                ),
              ],
            ),
          );
        });
  }

  Widget _buildMapSection() {
    return ListenableBuilder(
        listenable:
            Listenable.merge([mapLogic.isMapLocked, mapLogic.isLocating]),
        builder: (context, _) {
          bool isLocked = mapLogic.isMapLocked.value;
          return Container(
            padding: AddressStyles.padCardInternal,
            decoration: AddressStyles.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  title: AddressStrings.secMap,
                  icon: AddressIcons.sectionMap,
                  isLocked: isLocked,
                  isSaving: false,
                  onToggle: () => _showMapSnack(mapLogic.toggleLock()),
                ),
                const Divider(
                    height: 40, thickness: 1, color: AddressColors.borderLight),
                Container(
                  height: 280,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: AddressColors.mapPlaceholderBg,
                      borderRadius:
                          BorderRadius.circular(AddressStyles.rMapContainer),
                      border: Border.all(
                          color: isLocked
                              ? AddressColors.borderLight
                              : AddressColors.goldAccent,
                          width: isLocked ? 1 : 2),
                      boxShadow: isLocked
                          ? []
                          : const [
                              BoxShadow(
                                  color: AddressColors.goldAccent20,
                                  blurRadius: 10,
                                  offset: Offset(0, 4))
                            ]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AddressStyles.rMapClip),
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: mapController,
                          options: MapOptions(
                            initialCenter: mapLogic.selectedLocation.value ??
                                AddressMapLogic.defaultLocation,
                            initialZoom: mapLogic.selectedLocation.value != null
                                ? 16.0
                                : 4.8,
                            onTap: (tapPos, latLng) => _handleMapTap(latLng),
                            interactionOptions: InteractionOptions(
                              flags: isLocked
                                  ? InteractiveFlag.none
                                  : (InteractiveFlag.all &
                                      ~InteractiveFlag.doubleTapZoom),
                            ),
                          ),
                          children: [
                            TileLayer(
                                urlTemplate: AddressStrings.mapTileUrl,
                                userAgentPackageName:
                                    AddressStrings.mapUserAgent),
                            MarkerLayer(markers: mapMarkers),
                          ],
                        ),
                        if (isLocked)
                          Container(color: AddressColors.mapOverlayLocked),
                        if (mapLogic.isLocating.value)
                          Container(
                            color: AddressColors.mapOverlayLoading,
                            child: const Center(
                                child: CircularProgressIndicator(
                                    color: AddressColors.goldAccent)),
                          )
                      ],
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  child: isLocked
                      ? const SizedBox.shrink()
                      : Column(
                          children: [
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                    child: InkWell(
                                  onTap: mapLogic.isLocating.value
                                      ? null
                                      : _handleGpsDetect,
                                  borderRadius: BorderRadius.circular(
                                      AddressStyles.rButton),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: BoxDecoration(
                                      color: AddressColors.goldAccent10,
                                      border: Border.all(
                                          color: AddressColors.goldAccent),
                                      borderRadius: BorderRadius.circular(
                                          AddressStyles.rButton),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        mapLogic.isLocating.value
                                            ? const SizedBox(
                                                height: 16,
                                                width: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: AddressColors
                                                            .goldAccent))
                                            : const Icon(AddressIcons.detectLoc,
                                                size: 16,
                                                color:
                                                    AddressColors.goldAccent),
                                        const SizedBox(width: 8),
                                        Text(
                                            mapLogic.isLocating.value
                                                ? AddressStrings.btnLocating
                                                : AddressStrings.btnDetectGps,
                                            style: GoogleFonts.inter(
                                                fontSize:
                                                    AddressStyles.szButtonText,
                                                fontWeight: FontWeight.w600,
                                                color: AddressColors.textDark)),
                                      ],
                                    ),
                                  ),
                                )),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                          color: AddressColors.borderLight),
                                      borderRadius: BorderRadius.circular(
                                          AddressStyles.rButton)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(AddressIcons.mouse,
                                          size: 16,
                                          color: AddressColors.textMuted),
                                      const SizedBox(width: 8),
                                      Text(AddressStrings.lblMapInstruction,
                                          style: GoogleFonts.inter(
                                              fontSize:
                                                  AddressStyles.szButtonText,
                                              fontWeight: FontWeight.w600,
                                              color: AddressColors.textBody)),
                                    ],
                                  ),
                                )),
                              ],
                            ),
                          ],
                        ),
                )
              ],
            ),
          );
        });
  }

  Widget _buildSectionLabel(String text) {
    return Text(text,
        style: GoogleFonts.inter(
            fontSize: AddressStyles.szSectionSub,
            fontWeight: FontWeight.w800,
            color: AddressColors.textMuted,
            letterSpacing: 1.2));
  }
}

// ==========================================
// --- EXTRACTED WIDGETS ---
// ==========================================

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AddressStrings.pageTitle,
                  style: GoogleFonts.manrope(
                      fontSize: AddressStyles.szPageTitle,
                      fontWeight: FontWeight.w800,
                      color: AddressColors.surfaceWhite,
                      letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text(AddressStrings.pageSub,
                  style: GoogleFonts.inter(
                      fontSize: AddressStyles.szPageSub,
                      color: AddressColors.textWhite70)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
              color: AddressColors.statusActiveBg,
              borderRadius: BorderRadius.circular(AddressStyles.rStatusPill),
              border: Border.all(color: AddressColors.statusActiveText30)),
          child: Row(
            children: [
              const Icon(AddressIcons.mapPin,
                  size: 16, color: AddressColors.statusActiveText),
              const SizedBox(width: 8),
              Text(AddressStrings.statusActive,
                  style: GoogleFonts.inter(
                      color: AddressColors.statusActiveText,
                      fontWeight: FontWeight.w700,
                      fontSize: 11)),
            ],
          ),
        )
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isLocked;
  final bool isSaving;
  final VoidCallback onToggle;

  const _SectionHeader(
      {required this.title,
      required this.icon,
      required this.isLocked,
      required this.isSaving,
      required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: AddressColors.goldAccent10,
                    borderRadius:
                        BorderRadius.circular(AddressStyles.rHeaderIcon)),
                child: Icon(icon, color: AddressColors.goldAccent, size: 22)),
            const SizedBox(width: 12),
            Text(title,
                style: GoogleFonts.manrope(
                    fontSize: AddressStyles.szSectionTitle,
                    fontWeight: FontWeight.w700,
                    color: AddressColors.textDark)),
          ],
        ),
        Material(
          color: AddressColors.transparent,
          child: InkWell(
            onTap: isSaving ? null : onToggle,
            borderRadius: BorderRadius.circular(AddressStyles.rStatusPill),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                  color: isLocked
                      ? AddressColors.inputBgLocked
                      : AddressColors.statusActiveBg,
                  borderRadius:
                      BorderRadius.circular(AddressStyles.rStatusPill),
                  border: Border.all(
                      color: isLocked
                          ? AddressColors.textHint30
                          : AddressColors.statusActiveText30)),
              child: Row(
                children: [
                  if (isSaving)
                    const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AddressColors.statusActiveText))
                  else
                    Icon(
                        isLocked
                            ? AddressIcons.lockOutline
                            : AddressIcons.checkCircleOutline,
                        size: 16,
                        color: isLocked
                            ? AddressColors.textMuted
                            : AddressColors.statusActiveText),
                  const SizedBox(width: 6),
                  Text(
                      isSaving
                          ? AddressStrings.lblSaving
                          : (isLocked
                              ? AddressStrings.lblLocked
                              : AddressStrings.lblSave),
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isLocked
                              ? AddressColors.textMuted
                              : AddressColors.statusActiveText)),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}

class SmartInput extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final Color? brandColor;
  final TextEditingController ctrl;
  final bool isLocked;
  final bool isRequired;
  final bool isDigitsOnly;
  final TextInputType inputType;
  final int? maxLength;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;

  const SmartInput({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.brandColor,
    required this.ctrl,
    required this.isLocked,
    this.isRequired = false,
    this.isDigitsOnly = false,
    this.inputType = TextInputType.text,
    this.maxLength,
    this.focusNode,
    this.nextFocus,
  });

  @override
  Widget build(BuildContext context) {
    final formatters = <TextInputFormatter>[
      if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
      if (isDigitsOnly) FilteringTextInputFormatter.digitsOnly,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: GoogleFonts.manrope(
                    fontSize: AddressStyles.szFieldLabel,
                    fontWeight: FontWeight.w700,
                    color: AddressColors.textBody)),
            if (isRequired)
              const Text(" *",
                  style: TextStyle(
                      color: AddressColors.mandatoryStar,
                      fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ListenableBuilder(
            listenable: Listenable.merge([focusNode ?? ChangeNotifier(), ctrl]),
            builder: (context, _) {
              final hasFocus = focusNode?.hasFocus ?? false;
              BoxDecoration boxDecoration = (!isLocked && hasFocus)
                  ? AddressStyles.activeInputDecoration
                  : AddressStyles.inputDecoration(isLocked);
              Color iconColor = hasFocus
                  ? AddressColors.goldAccent
                  : (ctrl.text.isNotEmpty
                      ? (brandColor ?? AddressColors.iconSuccessDefault)
                      : AddressColors.textHint);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: AddressStyles.hInputField,
                decoration: boxDecoration,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Icon(icon,
                            key: ValueKey(iconColor),
                            size: 20,
                            color: iconColor)),
                    const SizedBox(width: 12),
                    Container(
                        width: 1, height: 24, color: AddressColors.borderLight),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: ctrl,
                        focusNode: focusNode,
                        readOnly: isLocked,
                        keyboardType: inputType,
                        inputFormatters: formatters,
                        style: GoogleFonts.manrope(
                            fontSize: AddressStyles.szFieldText,
                            fontWeight: FontWeight.w700,
                            color: AddressColors.textDark),
                        textInputAction: nextFocus != null
                            ? TextInputAction.next
                            : TextInputAction.done,
                        onFieldSubmitted: (_) {
                          if (nextFocus != null) {
                            FocusScope.of(context).requestFocus(nextFocus);
                          }
                        },
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            counterText: "",
                            hintText: hint,
                            hintStyle: GoogleFonts.inter(
                                color: AddressColors.textHint,
                                fontSize: AddressStyles.szFieldHint),
                            contentPadding: const EdgeInsets.only(bottom: 2)),
                      ),
                    )
                  ],
                ),
              );
            }),
      ],
    );
  }
}

class _KeyboardChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDisabled;
  final FocusNode focusNode;
  final FocusNode? nextFocus;
  final FocusNode? prevFocus;
  final VoidCallback onSelect;

  const _KeyboardChip(
      {required this.label,
      required this.isSelected,
      required this.isDisabled,
      required this.focusNode,
      this.nextFocus,
      this.prevFocus,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (label) {
      AddressStrings.typeHeadOffice => (
          AddressIcons.typeHead,
          AddressColors.brandCity
        ),
      AddressStrings.typeBranchOffice => (
          AddressIcons.typeBranch,
          AddressColors.brandLocation
        ),
      _ => (AddressIcons.typeWarehouse, AddressColors.brandState),
    };

    return Focus(
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            if (nextFocus != null) nextFocus!.requestFocus();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            if (prevFocus != null) prevFocus!.requestFocus();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space) {
            onSelect();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: isDisabled
            ? null
            : () {
                focusNode.requestFocus();
                onSelect();
              },
        child: ListenableBuilder(
            listenable: focusNode,
            builder: (context, _) {
              final isFocused = focusNode.hasFocus;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.1)
                      : AddressColors.inputBg,
                  border: Border.all(
                      color: isFocused
                          ? AddressColors.goldAccent
                          : (isSelected ? color : AddressColors.borderLight),
                      width: isFocused ? 2 : (isSelected ? 1.5 : 1)),
                  borderRadius: BorderRadius.circular(AddressStyles.rChip),
                  boxShadow: isFocused
                      ? const [
                          BoxShadow(
                              color: AddressColors.goldAccent20,
                              blurRadius: 8,
                              offset: Offset(0, 2))
                        ]
                      : [],
                ),
                child: Opacity(
                  opacity: isDisabled ? 0.6 : 1.0,
                  child: Column(
                    children: [
                      Icon(icon,
                          size: 18,
                          color: isSelected ? color : AddressColors.textMuted),
                      const SizedBox(height: 4),
                      Text(label,
                          style: GoogleFonts.inter(
                              fontSize: AddressStyles.szChipText,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AddressColors.textDark
                                  : AddressColors.textBody),
                          textAlign: TextAlign.center)
                    ],
                  ),
                ),
              );
            }),
      ),
    );
  }
}
