// -----------------------------------------------------------------------------
// FILE: professional_photo_widget.dart
// TYPE: Presentation Layer (UI Component)
// AUTHOR: Senior UI/UX Engineer & System Architect
// DESCRIPTION: ðŸš€ UPGRADED: Fixed Platform crashes on Web. Added unique
//              dynamic Hero Tags. Added Web-safe Blob Image Provider.
// -----------------------------------------------------------------------------

import 'dart:io';
import 'package:flutter/foundation.dart'; // ðŸš€ UPGRADE: For kIsWeb
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:crop_your_image/crop_your_image.dart';

// NOTE: Adjust paths according to your actual folder structure
import '../../../../logic/setting/shop_setup/tabs/basic_info/photo_logic.dart';
import '../../../../theme/settings/shop_setup/tabs/basic_info_tab/basic_info_theme.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';

class ProfessionalPhotoUploadSystem extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String defaultShape;
  final String? initialImagePath;
  final String heroTag;
  final Future<void> Function(File?, String)? onImageSaved;
  final bool isInitiallyLocked;

  const ProfessionalPhotoUploadSystem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.defaultShape,
    this.initialImagePath,
    required this.heroTag,
    this.onImageSaved,
    this.isInitiallyLocked = true,
  });

  @override
  State<ProfessionalPhotoUploadSystem> createState() =>
      _ProfessionalPhotoUploadSystemState();
}

class _ProfessionalPhotoUploadSystemState
    extends State<ProfessionalPhotoUploadSystem> {
  final PhotoUploadLogic _logic = PhotoUploadLogic();

  File? _selectedImage;
  late String _currentShape;
  late bool _isLocked;
  bool _isProcessing = false;

  // ðŸš€ UPGRADE: Dynamic Hero Tag to prevent collisions
  late String _dynamicHeroTag;

  @override
  void initState() {
    super.initState();
    _currentShape = widget.defaultShape;
    _isLocked = widget.isInitiallyLocked;
    final initialPath = widget.initialImagePath?.trim() ?? '';
    if (!kIsWeb && initialPath.isNotEmpty) {
      final file = File(initialPath);
      if (file.existsSync()) _selectedImage = file;
    }

    // Appending a unique identifier to prevent Hero animation crashes
    _dynamicHeroTag = "${widget.heroTag}_${UniqueKey().toString()}";
  }

  // ðŸš€ UPGRADE: Web-Safe Image Provider
  // XFile returns a blob URL on the web, which FileImage cannot read.
  ImageProvider _getSafeImageProvider(File file) {
    if (kIsWeb) {
      return NetworkImage(file.path);
    }
    return FileImage(file);
  }

  Future<void> _handleImagePick() async {
    setState(() => _isProcessing = true);

    try {
      File? originalFile = await _logic.pickImageFromGallery();

      if (originalFile == null) {
        if (mounted) setState(() => _isProcessing = false);
        return;
      }

      // ðŸš€ UPGRADE: Safe Platform Check
      bool isDesktopOrWeb = kIsWeb ||
          (!kIsWeb &&
              (Platform.isWindows || Platform.isMacOS || Platform.isLinux));

      if (isDesktopOrWeb) {
        // Skip custom desktop crop on Web to prevent byte-saving errors
        if (kIsWeb) {
          if (mounted) {
            setState(() => _isProcessing = false);
            _showShapeSelectionDialog(originalFile,
                onEdit: () => _handleImagePick());
          }
        } else {
          final bytes = await originalFile.readAsBytes();
          if (mounted) {
            setState(() => _isProcessing = false);
            _showDesktopCropDialog(bytes, originalFile);
          }
        }
      } else {
        File? croppedFile = await _logic.cropImageMobile(
            originalFile, BasicInfoColors.goldAccent);
        if (mounted) {
          setState(() => _isProcessing = false);
          if (croppedFile != null) {
            _showShapeSelectionDialog(croppedFile,
                onEdit: () => _handleImagePick());
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        AppFeedback.show(
          context,
          type: AppFeedbackType.error,
          message: e.toString(),
        );
      }
    }
  }

  Future<void> _updateImage(File? newFile) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    try {
      if (widget.onImageSaved != null) {
        await widget.onImageSaved!(newFile, _currentShape);
      }
      _logic.clearImageCache(_selectedImage);
      if (!mounted) return;
      setState(() => _selectedImage = newFile);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showImageOptions() {
    if (_isLocked) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: BasicInfoColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(BasicInfoStyles.rStatusPill)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: BasicInfoStyles.padAll20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 40, height: 4, color: BasicInfoColors.borderGrey300),
                const SizedBox(height: 20),
                Text(BasicInfoStrings.photoOptTitle,
                    style: GoogleFonts.manrope(
                        fontSize: BasicInfoStyles.szHeader18,
                        fontWeight: FontWeight.bold,
                        color: BasicInfoColors.surfaceBlack)),
                const SizedBox(height: 20),
                _buildOptionTile(
                    icon: BasicInfoIcons.uploadFile,
                    label: BasicInfoStrings.photoOptUpload,
                    color: BasicInfoColors.goldAccent,
                    onTap: () {
                      Navigator.pop(context);
                      _handleImagePick();
                    }),
                if (_selectedImage != null)
                  _buildOptionTile(
                      icon: BasicInfoIcons.previewEye,
                      label: BasicInfoStrings.photoOptPreview,
                      color: BasicInfoColors.actionBlue,
                      onTap: () {
                        Navigator.pop(context);
                        _showPreviewDialog();
                      }),
                if (_selectedImage != null)
                  _buildOptionTile(
                      icon: BasicInfoIcons.removeTrash,
                      label: BasicInfoStrings.photoOptRemove,
                      color: BasicInfoColors.btnDanger,
                      onTap: () async {
                        Navigator.pop(context);
                        await _updateImage(null);
                      }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDesktopCropDialog(
      Uint8List originalImageBytes, File originalFileReference) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final CropController localController = CropController();
        bool isLocallyProcessing = false;

        return StatefulBuilder(
          builder: (context, setStateInternal) {
            return Scaffold(
              backgroundColor: BasicInfoColors.surfaceBlack,
              appBar: AppBar(
                backgroundColor: BasicInfoColors.surfaceBlack,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(BasicInfoIcons.closeAction,
                      color: BasicInfoColors.surfaceWhite),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text(BasicInfoStrings.photoAdjustTitle,
                    style: TextStyle(
                        color: BasicInfoColors.surfaceWhite,
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
                              color: BasicInfoColors.goldAccent,
                              strokeWidth: 2),
                        ),
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(BasicInfoIcons.checkAction,
                          color: BasicInfoColors.goldAccent, size: 28),
                      onPressed: () {
                        setStateInternal(() => isLocallyProcessing = true);
                        localController.crop();
                      },
                    )
                ],
              ),
              body: Padding(
                padding: BasicInfoStyles.padAll24,
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
                        _showShapeSelectionDialog(savedFile,
                            onEdit: () => _showDesktopCropDialog(
                                originalImageBytes, originalFileReference));
                      } else {
                        setStateInternal(() => isLocallyProcessing = false);
                      }
                    },
                    aspectRatio: 1,
                    baseColor: BasicInfoColors.surfaceBlack,
                    maskColor: BasicInfoColors.overlayDark,
                    radius: 0,
                    interactive: true,
                    cornerDotBuilder: (size, edgeAlignment) =>
                        const DotControl(color: BasicInfoColors.goldAccent),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showShapeSelectionDialog(File tempImage,
      {required VoidCallback onEdit}) {
    String tempShape = _currentShape;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: BasicInfoColors.surfaceWhite,
              surfaceTintColor: BasicInfoColors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(BasicInfoStyles.rCard)),
              title: Text(BasicInfoStrings.photoFinalizeTitle,
                  style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w800,
                      color: BasicInfoColors.surfaceBlack,
                      fontSize: BasicInfoStyles.szTitle20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: BasicInfoStyles.imgUploadSize,
                    height: BasicInfoStyles.imgUploadSize,
                    decoration: BoxDecoration(
                        shape: tempShape == 'circle'
                            ? BoxShape.circle
                            : BoxShape.rectangle,
                        borderRadius: tempShape == 'square'
                            ? BorderRadius.circular(BasicInfoStyles.rCard)
                            : null,
                        image: DecorationImage(
                            image: _getSafeImageProvider(
                                tempImage), // ðŸš€ UPGRADE: Web-Safe
                            fit: BoxFit.cover),
                        border: Border.all(
                            color: BasicInfoColors.goldAccent, width: 3),
                        boxShadow: [
                          BoxShadow(
                              color: BasicInfoColors.surfaceBlack
                                  .withValues(alpha: 0.15),
                              blurRadius: 15,
                              spreadRadius: 2,
                              offset: const Offset(0, 4))
                        ]),
                  ),
                  const SizedBox(height: 24),
                  Text(BasicInfoStrings.photoShapeLabel,
                      style: GoogleFonts.inter(
                          fontSize: BasicInfoStyles.szFieldLabel,
                          fontWeight: FontWeight.w600,
                          color: BasicInfoColors.textGrey700)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDialogShapeBtn(
                          BasicInfoStrings.photoShapeCircle,
                          "circle",
                          tempShape,
                          (val) => setStateDialog(() => tempShape = val)),
                      const SizedBox(width: 12),
                      _buildDialogShapeBtn(
                          BasicInfoStrings.photoShapeSquare,
                          "square",
                          tempShape,
                          (val) => setStateDialog(() => tempShape = val)),
                    ],
                  )
                ],
              ),
              actionsPadding: BasicInfoStyles.padAll20,
              actions: [
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(BasicInfoStrings.btnCancel,
                          style: TextStyle(
                              color: BasicInfoColors.textGrey600,
                              fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onEdit();
                      },
                      icon: const Icon(BasicInfoIcons.cropAction,
                          size: 16, color: BasicInfoColors.actionBlue),
                      label: const Text(BasicInfoStrings.btnRecrop,
                          style: TextStyle(
                              color: BasicInfoColors.actionBlue,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BasicInfoColors.goldAccent,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(BasicInfoStyles.rBtn)),
                        padding: BasicInfoStyles.padActionBtn,
                        elevation: 2,
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        setState(() {
                          _currentShape = tempShape;
                        });
                        await _updateImage(tempImage);
                      },
                      child: const Text(BasicInfoStrings.btnSavePhoto,
                          style: TextStyle(
                              color: BasicInfoColors.surfaceWhite,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPreviewDialog() {
    if (_selectedImage == null) return;
    showDialog(
      context: context,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Container(
          color: BasicInfoColors.overlayDark,
          child: Center(
            child: Hero(
              tag: _dynamicHeroTag, // ðŸš€ UPGRADE: Dynamic Tag
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                    color: BasicInfoColors.surfaceWhite,
                    shape: _currentShape == 'circle'
                        ? BoxShape.circle
                        : BoxShape.rectangle,
                    borderRadius: _currentShape == 'square'
                        ? BorderRadius.circular(BasicInfoStyles.rCard)
                        : null,
                    image: DecorationImage(
                        image: _getSafeImageProvider(
                            _selectedImage!), // ðŸš€ UPGRADE: Web-Safe
                        fit: BoxFit.cover),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black45,
                          blurRadius: 30,
                          spreadRadius: 5)
                    ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasImage = _selectedImage != null;

    return Container(
      padding: BasicInfoStyles.padAll24,
      decoration: BasicInfoStyles.cardDecoration,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: BasicInfoColors.goldAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon,
                    size: 22, color: BasicInfoColors.goldAccent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: GoogleFonts.manrope(
                            fontSize: BasicInfoStyles.szSectionTitle,
                            fontWeight: FontWeight.w800,
                            color: BasicInfoColors.textDark)),
                    const SizedBox(height: 2),
                    Text(widget.subtitle,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: BasicInfoColors.textGrey600)),
                  ],
                ),
              ),
              InkWell(
                borderRadius:
                    BorderRadius.circular(BasicInfoStyles.rStatusPill),
                onTap: () => setState(() => _isLocked = !_isLocked),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                      color: _isLocked
                          ? BasicInfoColors.bgGrey100
                          : BasicInfoColors.goldAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: _isLocked
                              ? BasicInfoColors.borderGrey300
                              : BasicInfoColors.goldAccent
                                  .withValues(alpha: 0.3))),
                  child: Row(
                    children: [
                      Icon(
                          _isLocked
                              ? BasicInfoIcons.lock
                              : BasicInfoIcons.unlock,
                          size: 16,
                          color: _isLocked
                              ? BasicInfoColors.textGrey600
                              : BasicInfoColors.goldAccent),
                      const SizedBox(width: 6),
                      Text(
                        _isLocked
                            ? BasicInfoStrings.lblLocked
                            : BasicInfoStrings.lblEdit,
                        style: TextStyle(
                            fontSize: BasicInfoStyles.szFieldLabel,
                            fontWeight: FontWeight.bold,
                            color: _isLocked
                                ? BasicInfoColors.textGrey600
                                : BasicInfoColors.goldAccent),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
          const Divider(height: 36, color: BasicInfoColors.borderLight),
          Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: (_isLocked && !hasImage) ? 0.6 : 1.0,
                child: Hero(
                  tag: _dynamicHeroTag, // ðŸš€ UPGRADE: Dynamic Tag
                  child: Container(
                    width: BasicInfoStyles.imgUploadSize,
                    height: BasicInfoStyles.imgUploadSize,
                    decoration: BoxDecoration(
                        color: BasicInfoColors.imgPlaceholderBg,
                        shape: _currentShape == "circle"
                            ? BoxShape.circle
                            : BoxShape.rectangle,
                        borderRadius: _currentShape == "square"
                            ? BorderRadius.circular(BasicInfoStyles.rCard)
                            : null,
                        border: Border.all(
                            color: BasicInfoColors.borderLight, width: 2),
                        image: hasImage
                            ? DecorationImage(
                                image: _getSafeImageProvider(
                                    _selectedImage!), // ðŸš€ UPGRADE: Web-Safe
                                fit: BoxFit.cover)
                            : null,
                        boxShadow: hasImage && !_isLocked
                            ? [
                                BoxShadow(
                                    color: BasicInfoColors.surfaceBlack
                                        .withValues(alpha: 0.08),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5))
                              ]
                            : null),
                    child: !hasImage
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(BasicInfoIcons.placeholderImg,
                                  size: 36, color: BasicInfoColors.textHint),
                              const SizedBox(height: 8),
                              Text(BasicInfoStrings.lblNoPhoto,
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: BasicInfoColors.textHint))
                            ],
                          )
                        : null,
                  ),
                ),
              ),
              if (_isProcessing)
                Container(
                  width: BasicInfoStyles.imgUploadSize,
                  height: BasicInfoStyles.imgUploadSize,
                  decoration: BoxDecoration(
                    color: BasicInfoColors.surfaceWhite.withValues(alpha: 0.5),
                    shape: _currentShape == "circle"
                        ? BoxShape.circle
                        : BoxShape.rectangle,
                    borderRadius: _currentShape == "square"
                        ? BorderRadius.circular(BasicInfoStyles.rCard)
                        : null,
                  ),
                  child: const Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: BasicInfoColors.goldAccent)),
                )
            ],
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
                          onPressed: _isProcessing ? null : _showImageOptions,
                          icon: Icon(
                              hasImage
                                  ? BasicInfoIcons.edit
                                  : BasicInfoIcons.addPhoto,
                              size: 18,
                              color: BasicInfoColors.surfaceWhite),
                          label: Text(
                              hasImage
                                  ? BasicInfoStrings.btnManagePhoto
                                  : BasicInfoStrings.btnUploadPhoto,
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: BasicInfoStyles.szFieldText)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BasicInfoColors.goldAccent,
                            foregroundColor: BasicInfoColors.surfaceWhite,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    BasicInfoStyles.rInputRadius)),
                            elevation: 2,
                            shadowColor: BasicInfoColors.goldAccent
                                .withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
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
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(label,
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: BasicInfoColors.textBlack87,
              fontSize: BasicInfoStyles.szFieldText)),
      trailing: const Icon(BasicInfoIcons.arrowForwardIos,
          size: 16, color: BasicInfoColors.textGrey500),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildDialogShapeBtn(String label, String value,
      String currentGroupValue, Function(String) onShapeChanged) {
    bool isSelected = currentGroupValue == value;
    return InkWell(
      onTap: () => onShapeChanged(value),
      borderRadius: BorderRadius.circular(BasicInfoStyles.rBtn),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: BasicInfoStyles.padDialogOption,
        decoration: BoxDecoration(
          color: isSelected
              ? BasicInfoColors.goldAccent.withValues(alpha: 0.1)
              : BasicInfoColors.bgGrey50,
          border: Border.all(
              color: isSelected
                  ? BasicInfoColors.goldAccent
                  : BasicInfoColors.borderGrey300,
              width: isSelected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(BasicInfoStyles.rBtn),
        ),
        child: Row(
          children: [
            Icon(
                isSelected
                    ? BasicInfoIcons.radioChecked
                    : BasicInfoIcons.radioUnchecked,
                size: 18,
                color: isSelected
                    ? BasicInfoColors.goldAccent
                    : BasicInfoColors.textGrey500),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: BasicInfoStyles.szFieldLabel,
                    color: isSelected
                        ? BasicInfoColors.textDark
                        : BasicInfoColors.textGrey600)),
          ],
        ),
      ),
    );
  }
}
