import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'camera/live_camera_controls.dart';
import 'camera/live_camera_session.dart';

class LiveCameraDialog extends StatefulWidget {
  final String title;
  final String guidance;
  final Color accentColor;

  const LiveCameraDialog({
    super.key,
    required this.title,
    required this.guidance,
    this.accentColor = const Color(0xFFD4AF37),
  });

  @override
  State<LiveCameraDialog> createState() => _LiveCameraDialogState();
}

class _LiveCameraDialogState extends State<LiveCameraDialog> {
  final LiveCameraSession _session = LiveCameraSession();

  @override
  void initState() {
    super.initState();
    _session.addListener(_refresh);
    unawaited(_session.loadCameras());
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _capture() async {
    final path = await _session.takePhoto();
    if (mounted && path != null) Navigator.pop(context, path);
  }

  @override
  void dispose() {
    _session.removeListener(_refresh);
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = math.min(720.0, MediaQuery.sizeOf(context).height - 32);
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFD9C99F)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 860, maxHeight: height),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _header(),
          const Divider(height: 1, color: Color(0xFFE7E0D4)),
          Flexible(
              child: Padding(
            padding: const EdgeInsets.all(16),
            child: _preview(),
          )),
          const Divider(height: 1, color: Color(0xFFE7E0D4)),
          LiveCameraControls(
            session: _session,
            accentColor: widget.accentColor,
            onCancel: () => Navigator.pop(context),
            onCapture: () => unawaited(_capture()),
          ),
        ]),
      ),
    );
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1C8),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.photo_camera_rounded,
                color: Color(0xFF8A5D00), size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(widget.title,
                    style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black)),
                const SizedBox(height: 2),
                Text(widget.guidance,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87)),
              ])),
          IconButton.filledTonal(
            tooltip: 'Close camera',
            onPressed: _session.capturing ? null : () => Navigator.pop(context),
            style: IconButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: const Color(0xFFF3EEE4),
            ),
            icon: const Icon(Icons.close_rounded),
          ),
        ]),
      );

  Widget _preview() {
    final error = _session.errorMessage;
    final controller = _session.controller;
    if (error != null) {
      return _CameraStatus(
        icon: Icons.no_photography_rounded,
        message: error,
        actionLabel: 'Try Again',
        onAction: () => unawaited(_session.loadCameras()),
      );
    }
    if (controller == null || !controller.value.isInitialized) {
      return const _CameraStatus(
        icon: Icons.videocam_rounded,
        message: 'Connecting to camera...',
        loading: true,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: Colors.black,
        child: Stack(children: [
          Center(
              child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller),
          )),
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                'Camera ${_session.cameras.indexOf(_session.selectedCamera!) + 1} of ${_session.cameras.length}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _CameraStatus extends StatelessWidget {
  final IconData icon;
  final String message;
  final bool loading;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _CameraStatus({
    required this.icon,
    required this.message,
    this.loading = false,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
    constraints: const BoxConstraints(minHeight: 160),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F7F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE7E0D4)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (loading)
            const CircularProgressIndicator(color: Color(0xFF9C6D00))
          else
            Icon(icon, size: 42, color: const Color(0xFF9C6D00)),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.black)),
          ),
          if (onAction != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel ?? 'Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ]),
      );
}
