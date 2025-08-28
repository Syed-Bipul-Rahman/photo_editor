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
    with WidgetsBindingObserver, TickerProviderStateMixin {
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
  bool _isFocusing = false;

  // Animation controllers for focus indicator
  late AnimationController _focusAnimationController;
  late Animation<double> _focusAnimation;

  // Zoom gesture tracking
  double _baseZoom = 1;
  bool _isZooming = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize focus animation
    _focusAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _focusAnimation = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _focusAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _setFullScreen();
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusAnimationController.dispose();
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
      ResolutionPreset.veryHigh,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _controller!.initialize();
      _minZoom = await _controller!.getMinZoomLevel();
      _maxZoom = await _controller!.getMaxZoomLevel();

      await _controller!.setFocusMode(FocusMode.auto);
      await _controller!.setExposureMode(ExposureMode.auto);

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _currentZoom = _minZoom;
          _baseZoom = _minZoom;
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
      // Ensure autofocus before taking picture
      if (!_isFocusing) {
        await _controller!.setFocusMode(FocusMode.auto);
      }

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

  // Enhanced zoom handling for gesture detection
  void _handleScaleStart(ScaleStartDetails details) {
    _baseZoom = _currentZoom;
    _isZooming = true;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (!_isZooming ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return;
    }

    final newZoom = _baseZoom * details.scale;
    _onZoomChanged(newZoom);
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _isZooming = false;
  }

  // Enhanced autofocus with tap-to-focus
  Future<void> _onFocusTap(TapUpDetails details) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    setState(() {
      _isFocusing = true;
    });

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset localPoint = renderBox.globalToLocal(details.globalPosition);
    final Size size = renderBox.size;

    // Convert tap coordinates to camera coordinates (0.0 - 1.0)
    final double x = localPoint.dx / size.width;
    final double y = localPoint.dy / size.height;

    final Offset focusPoint = Offset(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0));

    try {
      // Set focus and exposure point
      await _controller!.setFocusPoint(focusPoint);
      await _controller!.setExposurePoint(focusPoint);

      // Set focus mode to auto for better focusing
      await _controller!.setFocusMode(FocusMode.auto);

      // Update UI with focus indicator
      setState(() {
        _focusPoint = localPoint;
      });

      // Start focus animation
      await _focusAnimationController.forward().then((_) {
        _focusAnimationController.reverse();
      });

      // Hide focus indicator after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _focusPoint = null;
            _isFocusing = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isFocusing = false;
      });
      _showErrorDialog('Failed to focus: $e');
    }
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

  // Enhanced focus indicator widget
  Widget _buildFocusIndicator() {
    if (_focusPoint == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _focusAnimation,
      builder: (context, child) {
        return Positioned(
          left: _focusPoint!.dx - 50,
          top: _focusPoint!.dy - 50,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(
                color: _isFocusing ? Colors.yellow : Colors.green,
                width: 2,
              ),
              color: Colors.transparent,
            ),
            child: _isFocusing
                ? Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.yellow.withOpacity(_focusAnimation.value),
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  // Zoom indicator widget
  Widget _buildZoomIndicator() {
    if (_currentZoom <= _minZoom + 0.1) return const SizedBox.shrink();

    return Positioned(
      bottom: 150,
      left: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '${_currentZoom.toStringAsFixed(1)}x',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
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
                // Camera preview with gesture detection for zoom and focus
                GestureDetector(
                  onTapUp: _onFocusTap,
                  onScaleStart: _handleScaleStart,
                  onScaleUpdate: _handleScaleUpdate,
                  onScaleEnd: _handleScaleEnd,
                  child: _buildCameraPreviewExpanded(),
                ),

                // Grid overlay
                if (_showGrid)
                  const Positioned.fill(
                    child: GridOverlay(),
                  ),

                // Focus indicator
                _buildFocusIndicator(),

                // Zoom indicator
                _buildZoomIndicator(),

                // Top controls
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
                          const SizedBox(width: 8),
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

                // Right side controls
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
                        const SizedBox.shrink(),
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
                        const SizedBox.shrink(),
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

                // Bottom camera controls
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

  Widget _buildCameraPreviewExpanded() {
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.previewSize?.height ?? 1,
          height: _controller!.value.previewSize?.width ?? 1,
          child: CameraPreview(_controller!),
        ),
      ),
    );
  }
}
