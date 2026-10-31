import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'live_camera_session.dart';

class LiveCameraControls extends StatelessWidget {
  final LiveCameraSession session;
  final Color accentColor;
  final VoidCallback onCancel;
  final VoidCallback onCapture;

  const LiveCameraControls({
    super.key,
    required this.session,
    required this.accentColor,
    required this.onCancel,
    required this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        LayoutBuilder(builder: (context, constraints) {
          final selector = _CameraSelector(session: session);
          final actions = Row(mainAxisSize: MainAxisSize.min, children: [
            _toolButton(
              icon: Icons.cameraswitch_rounded,
              label: 'Flip Camera',
              onPressed: session.canSwitch
                  ? () => unawaited(session.flipCamera())
                  : null,
            ),
            const SizedBox(width: 8),
            _toolButton(
              icon: Icons.refresh_rounded,
              label: 'Refresh',
              onPressed: session.loading || session.capturing
                  ? null
                  : () => unawaited(session.loadCameras()),
            ),
          ]);
          if (constraints.maxWidth < 630) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  selector,
                  const SizedBox(height: 10),
                  actions,
                ]);
          }
          return Row(children: [
            Expanded(child: selector),
            const SizedBox(width: 10),
            actions,
          ]);
        }),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: session.capturing ? null : onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Color(0xFF4B5563), width: 1.3),
                  textStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800),
                ),
                icon: const Icon(Icons.close_rounded, size: 19),
                label: const Text('Cancel'),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed:
                    session.ready && !session.loading && !session.capturing
                        ? onCapture
                        : null,
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: const Color(0xFFFFE9A3),
                  disabledForegroundColor: Colors.black87,
                  textStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w900),
                ),
                icon: session.capturing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.camera_alt_rounded, size: 19),
                label:
                    Text(session.capturing ? 'Capturing...' : 'Capture Photo'),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _toolButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) =>
      SizedBox(
        height: 44,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black,
            disabledForegroundColor: Colors.black87,
            side: const BorderSide(color: Color(0xFF9CA3AF)),
            textStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          icon: Icon(icon, size: 18),
          label: Text(label),
        ),
      );
}

class _CameraSelector extends StatelessWidget {
  final LiveCameraSession session;

  const _CameraSelector({required this.session});

  @override
  Widget build(BuildContext context) {
    final disabled = session.loading || session.capturing;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFF9CA3AF), width: 1.2),
      ),
      child: Row(children: [
        const Icon(Icons.videocam_rounded, color: Colors.black, size: 19),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<CameraDescription>(
              value: session.selectedCamera,
              isExpanded: true,
              borderRadius: BorderRadius.circular(12),
              menuMaxHeight: 300,
              dropdownColor: Colors.white,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
              hint: const Text('Select Camera'),
              disabledHint: Text(session.cameras.isEmpty
                  ? 'No camera available'
                  : 'Camera loading...'),
              items: session.cameras
                  .map((camera) => DropdownMenuItem(
                        value: camera,
                        child: Text(
                          camera.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(growable: false),
              onChanged: disabled
                  ? null
                  : (camera) {
                      if (camera != null) {
                        unawaited(session.selectCamera(camera));
                      }
                    },
            ),
          ),
        ),
      ]),
    );
  }
}
