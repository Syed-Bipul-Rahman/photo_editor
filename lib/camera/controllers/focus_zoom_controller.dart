import 'package:flutter/material.dart';
import '../services/camera_state_manager.dart';

class FocusZoomController extends ChangeNotifier {
  final CameraStateManager _cameraStateManager;
  
  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _baseZoom = 1.0;
  bool _isZooming = false;
  
  Offset? _focusPoint;
  bool _isFocusing = false;
  
  // Animation controllers
  AnimationController? _focusAnimationController;
  Animation<double>? _focusAnimation;

  FocusZoomController(this._cameraStateManager) {
    _initializeZoomLevels();
  }

  // Getters
  double get currentZoom => _currentZoom;
  double get minZoom => _minZoom;
  double get maxZoom => _maxZoom;
  Offset? get focusPoint => _focusPoint;
  bool get isFocusing => _isFocusing;
  Animation<double>? get focusAnimation => _focusAnimation;

  Future<void> _initializeZoomLevels() async {
    if (_cameraStateManager.isInitialized) {
      _minZoom = await _cameraStateManager.getMinZoomLevel();
      _maxZoom = await _cameraStateManager.getMaxZoomLevel();
      _currentZoom = _minZoom;
      _baseZoom = _minZoom;
      notifyListeners();
    }
  }

  void initializeFocusAnimation(TickerProvider vsync) {
    _focusAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: vsync,
    );
    
    _focusAnimation = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _focusAnimationController!,
        curve: Curves.easeInOut,
      ),
    );
  }

  void onZoomChanged(double zoom) {
    if (!_cameraStateManager.isInitialized) return;

    final clampedZoom = zoom.clamp(_minZoom, _maxZoom);
    _cameraStateManager.setZoomLevel(clampedZoom);
    
    _currentZoom = clampedZoom;
    notifyListeners();
  }

  void handleScaleStart(ScaleStartDetails details) {
    _baseZoom = _currentZoom;
    _isZooming = true;
  }

  void handleScaleUpdate(ScaleUpdateDetails details) {
    if (!_isZooming || !_cameraStateManager.isInitialized) return;

    final newZoom = _baseZoom * details.scale;
    onZoomChanged(newZoom);
  }

  void handleScaleEnd(ScaleEndDetails details) {
    _isZooming = false;
  }

  Future<void> onFocusTap(TapUpDetails details, BuildContext context) async {
    if (!_cameraStateManager.isInitialized) return;

    _isFocusing = true;
    notifyListeners();

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset localPoint = renderBox.globalToLocal(details.globalPosition);
    final Size size = renderBox.size;

    // Convert tap coordinates to camera coordinates (0.0 - 1.0)
    final double x = localPoint.dx / size.width;
    final double y = localPoint.dy / size.height;

    final Offset focusPoint = Offset(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0));

    try {
      await _cameraStateManager.setFocusAndExposurePoint(focusPoint);

      _focusPoint = localPoint;
      notifyListeners();

      // Start focus animation
      if (_focusAnimationController != null) {
        await _focusAnimationController!.forward().then((_) {
          _focusAnimationController!.reverse();
        });
      }

      // Hide focus indicator after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        _focusPoint = null;
        _isFocusing = false;
        notifyListeners();
      });
    } catch (e) {
      _isFocusing = false;
      notifyListeners();
      rethrow;
    }
  }

  void reset() {
    _focusPoint = null;
    _isFocusing = false;
    _isZooming = false;
    notifyListeners();
  }

  void updateZoomLevels() {
    _initializeZoomLevels();
  }

  @override
  void dispose() {
    _focusAnimationController?.dispose();
    super.dispose();
  }
}