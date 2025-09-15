// CameraController needed for UI components
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_management_app/camera/controllers/focus_zoom_controller.dart';
import 'package:photo_management_app/camera/models/photo_model.dart';
import 'package:photo_management_app/camera/services/camera_state_manager.dart'
    as camera_service;
import 'package:photo_management_app/camera/services/system_ui_manager.dart';
import 'package:photo_management_app/camera/utils/camera_dialogs.dart';
import 'package:photo_management_app/camera/utils/db_helper.dart';
import 'package:photo_management_app/camera/view/widgets/camera_controls.dart';
import 'package:photo_management_app/camera/view/widgets/grid_overlay.dart';
import 'package:photo_management_app/camera/widgets/camera_ui_components.dart';
import 'package:photo_management_app/camera/widgets/slide_out_menu.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late camera_service.CameraStateManager _cameraStateManager;
  late FocusZoomController _focusZoomController;
  late DatabaseHelper _databaseHelper;

  bool _showGrid = true;
  bool _showMoreControls = false;
  bool _showMenu = false;
  String _selectedAspectRatio = '3:4';
  String _selectedTimer = 'Off';

  late AnimationController _menuAnimationController;
  late AnimationController _flashAnimationController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _cameraStateManager = camera_service.CameraStateManager();
    _focusZoomController = FocusZoomController(_cameraStateManager);
    _databaseHelper = DatabaseHelper(dbName: 'photo_management.db');

    _focusZoomController.initializeFocusAnimation(this);

    _menuAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _flashAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    SystemUIManager.setFullScreen();
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusZoomController.dispose();
    _menuAnimationController.dispose();
    _flashAnimationController.dispose();
    SystemUIManager.restoreSystemUI();
    _cameraStateManager.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _cameraStateManager.handleAppLifecycleChange(state);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Handle returning from navigation
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent && _cameraStateManager.isPaused) {
      // Resume camera when returning to this screen
      _cameraStateManager.resume();
    }
  }

  // Handle navigation away from camera screen
  void _onNavigateAway() {
    if (!_cameraStateManager.isPaused && _cameraStateManager.isInitialized) {
      _cameraStateManager.pause();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      await _cameraStateManager.initialize();
      _focusZoomController.updateZoomLevels();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (e is camera_service.CameraException) {
        if (e.code == 'permission_denied') {
          CameraDialogs.showPermissionDeniedDialog(context);
        } else if (e.code == 'no_camera') {
          CameraDialogs.showNoCameraDialog(context);
        } else {
          CameraDialogs.showErrorDialog(context, e.toString());
        }
      } else {
        CameraDialogs.showErrorDialog(
          context,
          'Failed to initialize camera: $e',
        );
      }
    }
  }

  void _toggleMenu() {
    setState(() {
      _showMenu = !_showMenu;
    });

    if (_showMenu) {
      _menuAnimationController.forward();
    } else {
      _menuAnimationController.reverse();
    }
  }

  Future<void> _takePicture() async {
    try {
      // Trigger flash animation and sound
      if (mounted) {
        _flashAnimationController.forward().then((_) {
          _flashAnimationController.reverse();
        });
        CameraDialogs.playClickSound();
      }

      final imagePath = await _cameraStateManager.takePicture();

      await _savePictureToDatabase(imagePath);
    } catch (e) {
      if (mounted) {
        CameraDialogs.showErrorDialog(context, 'Failed to take picture: $e');
      }
    }
  }

  Future<void> _savePictureToDatabase(String imagePath) async {
    try {
      final file = File(imagePath);
      final fileStats = await file.stat();

      final photo = Photo(
        path: imagePath,
        takenDate: DateTime.now(),
        fileSize: fileStats.size,
      );

      await _databaseHelper.insertModel(photo);
    } catch (e) {
      print('Failed to save picture to database: $e');
    }
  }

  Future<void> _toggleFlash() async {
    try {
      await _cameraStateManager.toggleFlash();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        CameraDialogs.showErrorDialog(context, 'Failed to toggle flash: $e');
      }
    }
  }

  Future<void> _switchCamera() async {
    try {
      await _cameraStateManager.switchCamera();
      _focusZoomController.updateZoomLevels();
      _focusZoomController.reset();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        CameraDialogs.showErrorDialog(context, 'Failed to switch camera: $e');
      }
    }
  }

  void _onZoomChanged(double zoom) {
    _focusZoomController.onZoomChanged(zoom);
    if (mounted) {
      setState(() {});
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _focusZoomController.handleScaleStart(details);
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    _focusZoomController.handleScaleUpdate(details);
    if (mounted) {
      setState(() {});
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _focusZoomController.handleScaleEnd(details);
  }

  Future<void> _onFocusTap(TapUpDetails details) async {
    if (_showMenu) return;

    try {
      await _focusZoomController.onFocusTap(details, context);
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        CameraDialogs.showErrorDialog(context, 'Failed to focus: $e');
      }
    }
  }


  void _toggleMoreControls() {
    setState(() {
      _showMoreControls = !_showMoreControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body:
          _cameraStateManager.isInitialized &&
              _cameraStateManager.controller != null
          ? ListenableBuilder(
              listenable: Listenable.merge([
                _cameraStateManager,
                _focusZoomController,
              ]),
              builder: (context, _) {
                return Stack(
                  children: [
                    // Camera preview with gesture detection for zoom and focus
                    if (_cameraStateManager.controller != null && _cameraStateManager.isInitialized)
                      GestureDetector(
                        onTapUp: _onFocusTap,
                        onScaleStart: _handleScaleStart,
                        onScaleUpdate: _handleScaleUpdate,
                        onScaleEnd: _handleScaleEnd,
                        child: CameraUIComponents.buildCameraPreview(
                          controller: _cameraStateManager.controller!,
                        ),
                      )
                    else
                      // Show loading indicator while camera is initializing/resuming
                      const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),

                    // Grid overlay
                    if (_showGrid && !_showMenu)
                      const Positioned.fill(child: GridOverlay()),

                    // Focus indicator
                    if (_focusZoomController.focusAnimation != null)
                      CameraUIComponents.buildFocusIndicator(
                        focusPoint: _focusZoomController.focusPoint,
                        isFocusing: _focusZoomController.isFocusing,
                        showMenu: _showMenu,
                        focusAnimation: _focusZoomController.focusAnimation!,
                      ),

                    // Zoom indicator
                    CameraUIComponents.buildZoomIndicator(
                      currentZoom: _focusZoomController.currentZoom,
                      minZoom: _focusZoomController.minZoom,
                      showMenu: _showMenu,
                    ),

                    // Top controls
                    CameraUIComponents.buildTopControls(
                      showMenu: _showMenu,
                      onMenuToggle: _toggleMenu,
                      onSwitchCamera: _switchCamera,
                    ),

                    // Right side controls
                    CameraUIComponents.buildRightSideControls(
                      showMenu: _showMenu,
                      isFlashOn: _cameraStateManager.isFlashOn,
                      showMoreControls: _showMoreControls,
                      onToggleFlash: _toggleFlash,
                      onToggleMoreControls: _toggleMoreControls,
                    ),

                    // Bottom controls
                    if (!_showMenu)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: CameraControls(
                          onCapture: _takePicture,
                          onSwitchCamera: _switchCamera,
                          canSwitchCamera: _cameraStateManager.canSwitchCamera,
                          onZoomChanged: _onZoomChanged,
                          currentZoom: _focusZoomController.currentZoom,
                          minZoom: _focusZoomController.minZoom,
                          maxZoom: _focusZoomController.maxZoom,
                          // Add the onNavigateAway callback:
                          onNavigateAway: _onNavigateAway,
                        ),
                      ),

                    // Slide-out menu
                    SlideOutMenu(
                      isVisible: _showMenu,
                      selectedAspectRatio: _selectedAspectRatio,
                      selectedTimer: _selectedTimer,
                      animationController: _menuAnimationController,
                      onClose: _toggleMenu,
                      onAspectRatioChanged: (ratio) {
                        setState(() {
                          _selectedAspectRatio = ratio;
                        });
                      },
                      onTimerChanged: (timer) {
                        setState(() {
                          _selectedTimer = timer;
                        });
                      },
                    ),

                    // Flash overlay
                    AnimatedBuilder(
                      animation: _flashAnimationController,
                      builder: (context, child) {
                        return _flashAnimationController.value > 0
                            ? Positioned.fill(
                                child: Container(
                                  color: Colors.black.withValues(
                                    alpha: _flashAnimationController.value,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink();
                      },
                    ),
                  ],
                );
              },
            )
          : const Center(
              child: CupertinoActivityIndicator(color: Colors.white),
            ),
    );
  }
}
