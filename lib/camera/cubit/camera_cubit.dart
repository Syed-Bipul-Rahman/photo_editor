import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:photo_management_app/camera/services/camera_state_manager.dart';

// You might want to add these states to your camera states:
abstract class CameraState {}

class CameraInitial extends CameraState {}

class CameraLoading extends CameraState {}

class CameraReady extends CameraState {
  final CameraStateManager cameraStateManager;
  CameraReady(this.cameraStateManager);
}

class CameraPaused extends CameraState {}

class CameraError extends CameraState {
  final String message;
  CameraError(this.message);
}

class CameraCubit extends Cubit<CameraState> {
  late CameraStateManager _cameraStateManager;

  CameraCubit() : super(CameraInitial()) {
    _cameraStateManager = CameraStateManager();
  }

  // Your existing methods...

  /// Pause camera operations (called when navigating away)
  Future<void> pauseCamera() async {
    try {
      debugPrint('CameraCubit: Pausing camera operations');
      await _cameraStateManager.pause();
      emit(CameraPaused()); // You might want to add this state
    } catch (e) {
      debugPrint('CameraCubit: Error pausing camera: $e');
      emit(CameraError(e.toString()));
    }
  }

  /// Resume camera operations (called when returning to camera page)
  Future<void> resumeCamera() async {
    try {
      debugPrint('CameraCubit: Resuming camera operations');
      emit(CameraLoading()); // Show loading while resuming
      await _cameraStateManager.resume();
      emit(CameraReady(_cameraStateManager)); // Or your success state
    } catch (e) {
      debugPrint('CameraCubit: Error resuming camera: $e');
      emit(CameraError(e.toString()));
    }
  }

  /// Get the camera state manager (if needed by UI)
  CameraStateManager get cameraStateManager => _cameraStateManager;

  @override
  Future<void> close() {
    _cameraStateManager.dispose();
    return super.close();
  }
}
