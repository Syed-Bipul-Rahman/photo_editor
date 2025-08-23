import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_management_app/camera/view/widgets/camera_controls.dart';
import 'package:photo_management_app/camera/view/widgets/grid_overlay.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isFlashOn = false;
  int _selectedCameraIndex = 0;
  double _currentZoom = 1;
  double _minZoom = 1;
  double _maxZoom = 1;
  bool _showGrid = true;
  bool _showMoreControls = false;
  Offset? _focusPoint;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setFullScreen();
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _restoreSystemUI();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  void _setFullScreen() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }

  void _restoreSystemUI() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  Future<void> _initializeCamera() async {
    final permission = await Permission.camera.request();
    if (!permission.isGranted) {
      _showPermissionDeniedDialog();
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _showNoCameraDialog();
        return;
      }

      await _initializeCameraController();
    } catch (e) {
      _showErrorDialog('Failed to initialize camera: $e');
    }
  }

  Future<void> _initializeCameraController() async {
    if (_selectedCameraIndex >= _cameras.length) {
      _selectedCameraIndex = 0;
    }

    _controller = CameraController(
      _cameras[_selectedCameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      _minZoom = await _controller!.getMinZoomLevel();
      _maxZoom = await _controller!.getMaxZoomLevel();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _currentZoom = _minZoom;
        });
      }
    } catch (e) {
      _showErrorDialog('Failed to initialize camera controller: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      final directory = await getTemporaryDirectory();
      final imagePath = path.join(
        directory.path,
        '${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final image = await _controller!.takePicture();
      await File(image.path).copy(imagePath);

      if (mounted) {
        _showImageTakenSnackBar(imagePath);
      }
    } catch (e) {
      _showErrorDialog('Failed to take picture: $e');
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      final newFlashMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
      await _controller!.setFlashMode(newFlashMode);

      if (mounted) {
        setState(() {
          _isFlashOn = !_isFlashOn;
        });
      }
    } catch (e) {
      _showErrorDialog('Failed to toggle flash: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;

    if (mounted) {
      setState(() {
        _isInitialized = false;
      });
    }

    await _controller?.dispose();
    await _initializeCameraController();
  }

  void _onZoomChanged(double zoom) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    final clampedZoom = zoom.clamp(_minZoom, _maxZoom);
    _controller!.setZoomLevel(clampedZoom);

    if (mounted) {
      setState(() {
        _currentZoom = clampedZoom;
      });
    }
  }

  void _onFocusTap(Offset point) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    final renderBox = context.findRenderObject()! as RenderBox;
    final localPoint = renderBox.globalToLocal(point);
    final size = renderBox.size;

    final focusPoint = Offset(
      localPoint.dx / size.width,
      localPoint.dy / size.height,
    );

    _controller!.setFocusPoint(focusPoint);
    _controller!.setExposurePoint(focusPoint);

    setState(() {
      _focusPoint = localPoint;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _focusPoint = null;
        });
      }
    });
  }

  void _toggleGrid() {
    setState(() {
      _showGrid = !_showGrid;
    });
  }

  void _toggleMoreControls() {
    setState(() {
      _showMoreControls = !_showMoreControls;
    });
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
          'This app needs camera permission to function properly.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  void _showNoCameraDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Camera Found'),
        content: const Text('No camera is available on this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showImageTakenSnackBar(String imagePath) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Image saved to: $imagePath'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildRightSideControl({
    required String iconPath,
    required String label,
    VoidCallback? onTap,
    bool showLabel = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLabel && label.isNotEmpty) ...[
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SvgPicture.asset(
                iconPath,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isInitialized && _controller != null
          ? Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTapUp: (details) => _onFocusTap(details.globalPosition),
                    onScaleUpdate: (details) {
                      _onZoomChanged(_currentZoom * details.scale);
                    },
                    child: CameraPreview(_controller!),
                  ),
                ),
                if (_showGrid)
                  const Positioned.fill(
                    child: GridOverlay(),
                  ),
                if (_focusPoint != null)
                  Positioned(
                    left: _focusPoint!.dx - 50,
                    top: _focusPoint!.dy - 50,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.yellow, width: 2),
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                Positioned(
                  top: 50,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: SvgPicture.asset(
                            'assets/icons/burger.svg',
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: SvgPicture.asset(
                                'assets/icons/person.svg',
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          GestureDetector(
                            onTap: _switchCamera,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Image.asset(
                                  'assets/icons/switch_camera.png',
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 120,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildRightSideControl(
                        onTap: _toggleFlash,
                        iconPath: _isFlashOn
                            ? 'assets/icons/flash_on.svg'
                            : 'assets/icons/flash_off.svg',
                        label: 'Flash',
                      ),
                      const SizedBox(height: 30),
                      if (_showMoreControls)
                        Column(
                          children: [
                            _buildRightSideControl(
                              iconPath:
                                  'assets/icons/copy_icon_that_represent_multi_click.svg',
                              label: 'Multi Click',
                            ),
                            const SizedBox(height: 30),
                          ],
                        )
                      else
                        SizedBox.shrink(),

                      if (_showMoreControls)
                        Column(
                          children: [
                            _buildRightSideControl(
                              iconPath: 'assets/icons/timer_off.svg',
                              label: 'Timer',
                            ),
                            const SizedBox(height: 30),
                          ],
                        )
                      else
                        SizedBox.shrink(),

                      GestureDetector(
                        onTap: _toggleMoreControls,
                        child: _buildRightSideControl(
                          iconPath: _showMoreControls
                              ? 'assets/icons/show_less_items.svg'
                              : 'assets/icons/show_more_item.svg',
                          label: '',
                          showLabel: false,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: CameraControls(
                    onCapture: _takePicture,
                    onSwitchCamera: _switchCamera,
                    canSwitchCamera: _cameras.length > 1,
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
    );
  }
}
