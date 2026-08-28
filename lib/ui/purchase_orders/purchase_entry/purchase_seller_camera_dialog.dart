import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../theme/purchase/purchase_entry/purchase_entry_theme.dart';

class PurchaseSellerCameraDialog extends StatefulWidget {
  const PurchaseSellerCameraDialog({super.key});

  @override
  State<PurchaseSellerCameraDialog> createState() =>
      _PurchaseSellerCameraDialogState();
}

class _PurchaseSellerCameraDialogState
    extends State<PurchaseSellerCameraDialog> {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  CameraDescription? _selectedCamera;
  String? _errorMessage;
  bool _loading = true;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadCameras());
  }

  Future<void> _loadCameras() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final cameras = await availableCameras();
      if (!mounted) return;
      if (cameras.isEmpty) {
        setState(() {
          _cameras = const [];
          _selectedCamera = null;
          _loading = false;
          _errorMessage = 'No camera was found on this device.';
        });
        return;
      }

      _cameras = cameras;
      _selectedCamera = cameras.first;
      await _startCamera(cameras.first);
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = _cameraMessage(error);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Camera could not be started.';
      });
    }
  }

  Future<void> _startCamera(CameraDescription camera) async {
    final oldController = _controller;
    _controller = null;
    await oldController?.dispose();

    if (mounted) {
      setState(() {
        _selectedCamera = camera;
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = _cameraMessage(error);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Camera could not be started.';
      });
    }
  }

  Future<void> _takePhoto() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture ||
        _capturing) {
      return;
    }

    setState(() => _capturing = true);
    try {
      final photo = await controller.takePicture();
      if (!mounted) return;
      Navigator.pop(context, photo.path);
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _capturing = false;
        _errorMessage = _cameraMessage(error);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _capturing = false;
        _errorMessage = 'Photo could not be captured.';
      });
    }
  }

  String _cameraMessage(CameraException error) {
    return switch (error.code) {
      'CameraAccessDenied' =>
        'Camera permission was denied. Allow camera access in Windows Settings.',
      'CameraAccessDeniedWithoutPrompt' =>
        'Camera access is blocked. Enable it in system privacy settings.',
      'NoCameraAvailable' => 'No camera was found on this device.',
      _ => error.description ?? 'Camera could not be started.',
    };
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller?.value.isInitialized ?? false;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 690),
        decoration: BoxDecoration(
          color: PurchaseEntryColors.bodyPanel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: PurchaseEntryColors.bodyBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const Divider(height: 1, color: PurchaseEntryColors.bodyBorder),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _errorMessage != null
                    ? _CameraErrorState(
                        message: _errorMessage!,
                        onRetry: _loadCameras,
                      )
                    : ready
                        ? _buildPreview(controller!)
                        : const SizedBox(
                            height: 360,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: PurchaseEntryColors.purchaseAccent,
                              ),
                            ),
                          ),
              ),
            ),
            const Divider(height: 1, color: PurchaseEntryColors.bodyBorder),
            _buildFooter(ready),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 13, 10, 11),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.photo_camera_outlined,
              color: PurchaseEntryColors.purchaseAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Capture Seller Photo',
                  style: PurchaseEntryStyles.inputText.copyWith(fontSize: 16),
                ),
                Text(
                  'Internal and external cameras are supported.',
                  style: PurchaseEntryStyles.subTitleMuted,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: _capturing ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(CameraController controller) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final aspectRatio = controller.value.aspectRatio;
          return ColoredBox(
            color: Colors.black,
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxWidth / aspectRatio,
                  child: CameraPreview(controller),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _loading || _capturing) {
      return;
    }

    final current = _selectedCamera;
    final targetDirection = switch (current?.lensDirection) {
      CameraLensDirection.front => CameraLensDirection.back,
      CameraLensDirection.back => CameraLensDirection.front,
      _ => null,
    };
    final directedCamera =
        targetDirection == null ? null : _firstCameraFacing(targetDirection);
    if (directedCamera != null) {
      await _startCamera(directedCamera);
      return;
    }

    final currentIndex = current == null ? -1 : _cameras.indexOf(current);
    final nextIndex = (currentIndex + 1) % _cameras.length;
    await _startCamera(_cameras[nextIndex]);
  }

  CameraDescription? _firstCameraFacing(CameraLensDirection direction) {
    for (final camera in _cameras) {
      if (camera.lensDirection == direction) {
        return camera;
      }
    }
    return null;
  }

  Widget _buildFlipButton() {
    final canSwitch = _cameras.length > 1 && !_loading && !_capturing;
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: canSwitch ? () => unawaited(_switchCamera()) : null,
        style: _CameraButtonStyles.outlined(),
        icon: const Icon(Icons.cameraswitch_rounded, size: 18),
        label: const Text('Flip Camera'),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: _loading || _capturing ? null : _loadCameras,
        style: _CameraButtonStyles.outlined(),
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('Refresh'),
      ),
    );
  }

  Widget _buildCaptureButton(bool ready) {
    return SizedBox(
      height: 46,
      child: FilledButton.icon(
        onPressed: ready && !_capturing ? _takePhoto : null,
        style: FilledButton.styleFrom(
          backgroundColor: PurchaseEntryColors.purchaseAccent,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              PurchaseEntryColors.bodyBorder.withValues(alpha: 0.85),
          disabledForegroundColor:
              PurchaseEntryColors.textDark.withValues(alpha: 0.62),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: _capturing
            ? const SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.camera_alt_rounded, size: 19),
        label: Text(
          _capturing ? 'Capturing...' : 'Take Photo',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _buildFooter(bool ready) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: _CameraSelector(
              cameras: _cameras,
              selectedCamera: _selectedCamera,
              loading: _loading || _capturing,
              onChanged: (camera) => unawaited(_startCamera(camera)),
            ),
          ),
          const SizedBox(width: 10),
          _buildFlipButton(),
          const SizedBox(width: 10),
          _buildRefreshButton(),
          const SizedBox(width: 10),
          _buildCaptureButton(ready),
        ],
      ),
    );
  }
}

class _CameraSelector extends StatelessWidget {
  final List<CameraDescription> cameras;
  final CameraDescription? selectedCamera;
  final bool loading;
  final ValueChanged<CameraDescription> onChanged;

  const _CameraSelector({
    required this.cameras,
    required this.selectedCamera,
    required this.loading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: loading
            ? PurchaseEntryColors.bodyBorder.withValues(alpha: 0.35)
            : PurchaseEntryColors.formInputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: PurchaseEntryColors.textDark.withValues(alpha: 0.18),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CameraDescription>(
          value: selectedCamera,
          isExpanded: true,
          iconEnabledColor: PurchaseEntryColors.textDark,
          iconDisabledColor:
              PurchaseEntryColors.textDark.withValues(alpha: 0.50),
          style: PurchaseEntryStyles.inputText.copyWith(fontSize: 13),
          hint: Text(
            'Select Camera',
            style: PurchaseEntryStyles.inputText.copyWith(
              color: PurchaseEntryColors.textDark.withValues(alpha: 0.72),
              fontSize: 13,
            ),
          ),
          disabledHint: Text(
            cameras.isEmpty ? 'No camera selected' : 'Camera loading...',
            style: PurchaseEntryStyles.inputText.copyWith(
              color: PurchaseEntryColors.textDark.withValues(alpha: 0.68),
              fontSize: 13,
            ),
          ),
          items: cameras
              .map(
                (camera) => DropdownMenuItem(
                  value: camera,
                  child: Text(
                    camera.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: loading
              ? null
              : (camera) => camera == null ? null : onChanged(camera),
        ),
      ),
    );
  }
}

class _CameraErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _CameraErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                color: PurchaseEntryColors.danger,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: PurchaseEntryStyles.inputText.copyWith(
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                style: _CameraButtonStyles.outlined(),
                icon: const Icon(Icons.refresh_rounded, size: 17),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraButtonStyles {
  _CameraButtonStyles._();

  static ButtonStyle outlined({bool active = false}) {
    return OutlinedButton.styleFrom(
      backgroundColor: active
          ? PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.12)
          : null,
      foregroundColor: active
          ? PurchaseEntryColors.purchaseAccent
          : PurchaseEntryColors.purchaseAccentMid,
      disabledForegroundColor: PurchaseEntryColors.textDark.withValues(
        alpha: 0.55,
      ),
      side: BorderSide(
        color: PurchaseEntryColors.purchaseAccent.withValues(
          alpha: active ? 0.90 : 0.55,
        ),
      ),
      textStyle: const TextStyle(fontWeight: FontWeight.w900),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
