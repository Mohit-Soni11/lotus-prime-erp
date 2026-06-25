part of '../new_girvi_screen.dart';

class _KycCameraDialog extends StatefulWidget {
  const _KycCameraDialog();

  @override
  State<_KycCameraDialog> createState() => _KycCameraDialogState();
}

class _KycCameraDialogState extends State<_KycCameraDialog> {
  CameraController? _controller;
  String? _errorMessage;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException(
          'NoCameraAvailable',
          'No camera was found on this device.',
        );
      }

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      _controller = controller;
      await controller.initialize();

      if (!mounted) return;
      setState(() {});
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = switch (e.code) {
          'CameraAccessDenied' =>
            'Camera permission was denied. Allow camera access in Windows Settings.',
          'CameraAccessDeniedWithoutPrompt' =>
            'Camera access is blocked. Enable it in system privacy settings.',
          'NoCameraAvailable' => 'No camera was found on this device.',
          _ => e.description ?? 'Camera could not be started.',
        };
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Camera could not be started.');
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
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _capturing = false;
        _errorMessage = e.description ?? 'Photo could not be captured.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _capturing = false;
        _errorMessage = 'Photo could not be captured.';
      });
    }
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
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 680),
        decoration: BoxDecoration(
          color: GirviColors.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: GirviColors.cardBorder),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 13, 10, 11),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: GirviColors.brandGoldLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.document_scanner_outlined,
                      color: GirviColors.brandGold,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Capture KYC Document',
                          style: GoogleFonts.manrope(
                            color: GirviColors.textDark,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Keep the full card visible and text readable.',
                          style: GirviStyles.caption.copyWith(fontSize: 12.5),
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
            ),
            const Divider(height: 1, color: GirviColors.divider),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _errorMessage != null
                    ? _CameraErrorState(
                        message: _errorMessage!,
                        onRetry: () {
                          setState(() => _errorMessage = null);
                          _controller?.dispose();
                          _controller = null;
                          _initializeCamera();
                        },
                      )
                    : ready
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: ColoredBox(
                              color: Colors.black,
                              child: AspectRatio(
                                aspectRatio: controller!.value.aspectRatio,
                                child: CameraPreview(controller),
                              ),
                            ),
                          )
                        : const SizedBox(
                            height: 360,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: GirviColors.brandGold,
                              ),
                            ),
                          ),
              ),
            ),
            const Divider(height: 1, color: GirviColors.divider),
            Padding(
              padding: const EdgeInsets.all(14),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton.icon(
                  onPressed: ready && !_capturing ? _takePhoto : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: GirviColors.brandGold,
                    foregroundColor: GirviColors.shellBg,
                    disabledBackgroundColor: GirviColors.inputBgLocked,
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
                            color: GirviColors.shellBg,
                          ),
                        )
                      : const Icon(Icons.camera_alt_rounded, size: 19),
                  label: Text(
                    _capturing ? 'Capturing...' : 'Take Photo',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ),
          ],
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
                color: GirviColors.danger,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: GirviColors.textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
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
