import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraStateManager extends ChangeNotifier {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isFlashOn = false;
  int _selectedCameraIndex = 0;
  bool _isDisposed = false;

  // Getters
  CameraController? get controller => _controller;
  List<CameraDescription> get cameras => _cameras;
  bool get isInitialized => _isInitialized;
  bool get isFlashOn => _isFlashOn;
  int get selectedCameraIndex => _selectedCameraIndex;
  bool get canSwitchCamera => _cameras.length > 1;

  Future<void> initialize() async {
    final permission = await Permission.camera.request();
    if (!permission.isGranted) {
      throw CameraException('permission_denied', 'Camera permission denied');
    }

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw CameraException('no_camera', 'No camera found on device');
      }

      await _initializeCameraController();
    } catch (e) {
      throw CameraException('initialization_failed', 'Failed to initialize camera: $e');
    }
  }

  Future<void> _initializeCameraController() async {
    if (_selectedCameraIndex >= _cameras.length) {
      _selectedCameraIndex = 0;
    }

    _controller = CameraController(
      _cameras[_selectedCameraIndex],
      ResolutionPreset.veryHigh,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _controller!.initialize();
      await _controller!.setFocusMode(FocusMode.auto);
      await _controller!.setExposureMode(ExposureMode.auto);

      _isInitialized = true;
      if (!_isDisposed) {
        notifyListeners();
      }
    } catch (e) {
      throw CameraException('controller_init_failed', 'Failed to initialize camera controller: $e');
    }
  }

  Future<String> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw CameraException('not_initialized', 'Camera not initialized');
    }

    try {
      await _controller!.setFocusMode(FocusMode.auto);

      final directory = await getTemporaryDirectory();
      final imagePath = path.join(
        directory.path,
        '${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final image = await _controller!.takePicture();
      await File(image.path).copy(imagePath);

      return imagePath;
    } catch (e) {
      throw CameraException('capture_failed', 'Failed to take picture: $e');
    }
  }

  Future<void> toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      final newFlashMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
      await _controller!.setFlashMode(newFlashMode);
      _isFlashOn = !_isFlashOn;
      
      if (!_isDisposed) {
        notifyListeners();
      }
    } catch (e) {
      throw CameraException('flash_failed', 'Failed to toggle flash: $e');
    }
  }

  Future<void> switchCamera() async {
    if (_cameras.length < 2) return;

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    _isInitialized = false;
    
    if (!_isDisposed) {
      notifyListeners();
    }

    await _controller?.dispose();
    await _initializeCameraController();
  }

  Future<void> setFocusAndExposurePoint(Offset point) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      await _controller!.setFocusPoint(point);
      await _controller!.setExposurePoint(point);
      await _controller!.setFocusMode(FocusMode.auto);
    } catch (e) {
      throw CameraException('focus_failed', 'Failed to set focus point: $e');
    }
  }

  Future<double> getMinZoomLevel() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return 1.0;
    }
    return await _controller!.getMinZoomLevel();
  }

  Future<double> getMaxZoomLevel() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return 1.0;
    }
    return await _controller!.getMaxZoomLevel();
  }

  Future<void> setZoomLevel(double zoom) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }
    await _controller!.setZoomLevel(zoom);
  }

  void handleAppLifecycleChange(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      initialize();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller?.dispose();
    super.dispose();
  }
}

class CameraException implements Exception {
  final String code;
  final String message;

  CameraException(this.code, this.message);

  @override
  String toString() => 'CameraException($code): $message';
}