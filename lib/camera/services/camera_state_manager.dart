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
  bool _isPaused = false;

  // Store the last camera description for resuming
  CameraDescription? _lastCameraDescription;

  // Getters
  CameraController? get controller => _controller;
  List<CameraDescription> get cameras => _cameras;
  bool get isInitialized => _isInitialized && !_isPaused;
  bool get isFlashOn => _isFlashOn;
  int get selectedCameraIndex => _selectedCameraIndex;
  bool get canSwitchCamera => _cameras.length > 1;
  bool get isPaused => _isPaused;

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
      // Store the last camera description for resuming
      if (_controller != null) {
        _lastCameraDescription = _controller!.description;
      }
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

  /// Pause camera operations - stops preview and releases camera resources
  Future<void> pause() async {
    if (_isPaused || !_isInitialized || _controller == null || _isDisposed) {
      return;
    }

    try {
      debugPrint('CameraStateManager: Pausing camera...');
      _isPaused = true;
      
      // Store current camera for resume
      if (_controller != null) {
        _lastCameraDescription = _controller!.description;
      }
      
      // Stop the camera preview and dispose controller
      await _controller?.dispose();
      _controller = null;
      
      notifyListeners();
      debugPrint('CameraStateManager: Camera paused successfully');
    } catch (e) {
      debugPrint('CameraStateManager: Error pausing camera: $e');
    }
  }

  /// Resume camera operations - reinitializes camera with last settings
  Future<void> resume() async {
    if (!_isPaused || _isDisposed) {
      return;
    }

    try {
      debugPrint('CameraStateManager: Resuming camera...');
      _isPaused = false;
      
      // Re-initialize camera with the last camera description if available
      if (_lastCameraDescription != null) {
        await _initializeWithCamera(_lastCameraDescription!);
      } else {
        // Fallback to default initialization
        await initialize();
      }
      
      debugPrint('CameraStateManager: Camera resumed successfully');
    } catch (e) {
      debugPrint('CameraStateManager: Error resuming camera: $e');
      _isPaused = true; // Reset pause state if resume failed
      notifyListeners();
    }
  }

  /// Helper method to initialize with specific camera
  Future<void> _initializeWithCamera(CameraDescription cameraDescription) async {
    try {
      _controller = CameraController(
        cameraDescription,
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      await _controller!.setFocusMode(FocusMode.auto);
      await _controller!.setExposureMode(ExposureMode.auto);

      if (!_isDisposed) {
        _isInitialized = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('CameraStateManager: Failed to initialize camera: $e');
      _controller?.dispose();
      _controller = null;
      rethrow;
    }
  }

  void handleAppLifecycleChange(AppLifecycleState state) {
    if (_isDisposed) return;

    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('CameraStateManager: App resumed');
        if (_isPaused && !_isDisposed) {
          resume();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        debugPrint('CameraStateManager: App paused/inactive/detached');
        if (!_isPaused && _isInitialized) {
          pause();
        }
        break;
      case AppLifecycleState.hidden:
        debugPrint('CameraStateManager: App hidden');
        // Handle if needed
        break;
    }
  }

  @override
  void dispose() {
    debugPrint('CameraStateManager: Disposing...');
    _isDisposed = true;

    if (!_isPaused) {
      _controller?.dispose();
    }
    
    _controller = null;
    _lastCameraDescription = null;
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