// CameraController needed for UI components
import 'dart:io';
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

    SystemUIManager.setFullScreen();
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusZoomController.dispose();
    _menuAnimationController.dispose();
    SystemUIManager.restoreSystemUI();
    _cameraStateManager.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _cameraStateManager.handleAppLifecycleChange(state);
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
      final imagePath = await _cameraStateManager.takePicture();
      
      await _savePictureToDatabase(imagePath);
      
      if (mounted) {
        CameraDialogs.showImageTakenSnackBar(context, imagePath);
      }
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
                    GestureDetector(
                      onTapUp: _onFocusTap,
                      onScaleStart: _handleScaleStart,
                      onScaleUpdate: _handleScaleUpdate,
                      onScaleEnd: _handleScaleEnd,
                      child: CameraUIComponents.buildCameraPreview(
                        controller: _cameraStateManager.controller!,
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
                  ],
                );
              },
            )
          : const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}
