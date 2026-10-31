import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class LiveCameraSession extends ChangeNotifier {
  List<CameraDescription> cameras = const [];
  CameraDescription? selectedCamera;
  CameraController? controller;
  String? errorMessage;
  bool loading = true;
  bool capturing = false;
  bool _disposed = false;

  bool get ready => controller?.value.isInitialized ?? false;
  bool get canSwitch => cameras.length > 1 && !loading && !capturing;

  Future<void> loadCameras() async {
    if (_disposed || capturing) return;
    loading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final devices = await availableCameras();
      if (_disposed) return;
      cameras = devices;
      if (devices.isEmpty) {
        selectedCamera = null;
        await _releaseCamera();
        errorMessage =
            'No camera was found. Connect a camera and select Refresh.';
        loading = false;
        notifyListeners();
        return;
      }
      final previous = selectedCamera;
      final preferred = devices.contains(previous) ? previous! : devices.first;
      await _startCamera(preferred);
    } on CameraException catch (error) {
      _showError(_messageFor(error));
    } catch (_) {
      _showError(
          'Camera could not be started. Check the connection and retry.');
    }
  }

  Future<void> selectCamera(CameraDescription camera) async {
    if (_disposed || loading || capturing || selectedCamera == camera) return;
    await _startCamera(camera);
  }

  Future<void> flipCamera() async {
    if (!canSwitch) return;
    final current = selectedCamera;
    final opposite = switch (current?.lensDirection) {
      CameraLensDirection.front => CameraLensDirection.back,
      CameraLensDirection.back => CameraLensDirection.front,
      _ => null,
    };
    CameraDescription? next;
    if (opposite != null) {
      for (final camera in cameras) {
        if (camera.lensDirection == opposite) {
          next = camera;
          break;
        }
      }
    }
    final currentIndex = current == null ? -1 : cameras.indexOf(current);
    next ??= cameras[(currentIndex + 1) % cameras.length];
    await _startCamera(next);
  }

  Future<String?> takePhoto() async {
    final active = controller;
    if (_disposed ||
        !ready ||
        loading ||
        capturing ||
        active == null ||
        active.value.isTakingPicture) {
      return null;
    }
    capturing = true;
    notifyListeners();
    try {
      final photo = await active.takePicture();
      return _disposed ? null : photo.path;
    } on CameraException catch (error) {
      _showError(_messageFor(error));
      return null;
    } catch (_) {
      _showError('Photo could not be captured. Please try again.');
      return null;
    } finally {
      if (!_disposed) {
        capturing = false;
        notifyListeners();
      }
    }
  }

  Future<void> _startCamera(CameraDescription camera) async {
    loading = true;
    errorMessage = null;
    selectedCamera = camera;
    notifyListeners();
    CameraController? opening;
    try {
      await _releaseCamera();
      if (_disposed) return;
      opening = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await opening.initialize();
      if (_disposed) {
        await opening.dispose();
        return;
      }
      controller = opening;
      loading = false;
      notifyListeners();
    } on CameraException catch (error) {
      await opening?.dispose();
      _showError(_messageFor(error));
    } catch (_) {
      await opening?.dispose();
      _showError(
          'Camera could not be started. Check the connection and retry.');
    }
  }

  Future<void> _releaseCamera() async {
    final previous = controller;
    controller = null;
    if (previous != null) await previous.dispose();
  }

  void _showError(String message) {
    if (_disposed) return;
    errorMessage = message;
    loading = false;
    notifyListeners();
  }

  String _messageFor(CameraException error) => switch (error.code) {
        'CameraAccessDenied' =>
          'Camera permission was denied. Allow camera access in Windows Settings.',
        'CameraAccessDeniedWithoutPrompt' =>
          'Camera access is blocked. Enable it in system privacy settings.',
        _ => error.description ?? 'Camera could not be started.',
      };

  @override
  void dispose() {
    _disposed = true;
    final previous = controller;
    controller = null;
    if (previous != null) unawaited(previous.dispose());
    super.dispose();
  }
}
