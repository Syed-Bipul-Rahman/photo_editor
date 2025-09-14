I'll show you how to implement the RouteAware method step by step for automatic camera handling:
Step 1: Set up RouteObserver in your main app


// In your main.dart or where you define your MaterialApp
import 'package:flutter/material.dart';

// Create a global RouteObserver instance
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() {
runApp(MyApp());
}

class MyApp extends StatelessWidget {
@override
Widget build(BuildContext context) {
return MaterialApp(
title: 'Photo Management App',

      // Add the RouteObserver to navigatorObservers
      navigatorObservers: [routeObserver],
      
      // Your existing app configuration
      home: YourHomeWidget(),
      routes: {
        // Your routes
      },
      
      // Or if you're using GoRouter/AutoRoute, add it there:
      // routerConfig: AppRouter.router,
    );
}
}


Step 2: Update your CameraStateManager with pause/resume methods
// Add these methods to your existing CameraStateManager class
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraStateManager extends ChangeNotifier {
CameraController? _controller;
bool _isInitialized = false;
bool _isPaused = false;
bool _isDisposed = false;

// Store the last camera description for resuming
CameraDescription? _lastCameraDescription;

// Your existing getters
CameraController? get controller => _controller;
bool get isInitialized => _isInitialized && !_isPaused;
bool get isPaused => _isPaused;

// Your existing methods (initialize, switchCamera, etc.)...

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
ResolutionPreset.high,
enableAudio: false,
imageFormatGroup: ImageFormatGroup.jpeg,
);

      await _controller!.initialize();
      
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

@override
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

Step 3: Update your CameraPage with RouteAware


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_management_app/camera/camera.dart';
import 'package:photo_management_app/camera/view/camera_screen.dart';

// Import your global routeObserver from main.dart
import 'package:photo_management_app/main.dart'; // Adjust import path

class CameraPage extends StatefulWidget {
const CameraPage({super.key});

@override
State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with RouteAware {
late CameraCubit _cameraCubit;

@override
void initState() {
super.initState();
_cameraCubit = CameraCubit();
debugPrint('CameraPage: initState');
}

@override
void didChangeDependencies() {
super.didChangeDependencies();

    // Subscribe to route changes
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
      debugPrint('CameraPage: Subscribed to route observer');
    }
}

@override
void dispose() {
debugPrint('CameraPage: dispose');

    // Unsubscribe from route observer
    routeObserver.unsubscribe(this);
    
    // Dispose the cubit
    _cameraCubit.close();
    
    super.dispose();
}

// RouteAware callbacks - these are called automatically!

@override
void didPush() {
// Called when this route is first pushed onto the navigator
debugPrint('CameraPage: didPush - Camera page opened');
// Camera will be initialized through normal flow
}

@override
void didPopNext() {
// Called when returning to this route from another route
debugPrint('CameraPage: didPopNext - Returned to camera page');

    // Resume camera when coming back to this page
    _resumeCamera();
}

@override
void didPushNext() {
// Called when another route is pushed on top of this one
debugPrint('CameraPage: didPushNext - Navigated away from camera page');

    // Pause camera when navigating to another page
    _pauseCamera();
}

@override
void didPop() {
// Called when this route is popped from the navigator
debugPrint('CameraPage: didPop - Camera page closed');

    // Camera will be disposed through normal disposal flow
}

void _pauseCamera() {
debugPrint('CameraPage: Pausing camera...');
// Access the camera state manager through your cubit or directly
// Adjust this based on how you access your CameraStateManager
_cameraCubit.pauseCamera(); // You'll need to add this method to your cubit
}

void _resumeCamera() {
debugPrint('CameraPage: Resuming camera...');
// Resume camera operations
_cameraCubit.resumeCamera(); // You'll need to add this method to your cubit
}

@override
Widget build(BuildContext context) {
return BlocProvider.value(
value: _cameraCubit,
child: const CameraScreen(),
);
}
}


Step 4: Update your CameraCubit to support pause/resume

// Add these methods to your existing CameraCubit class
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_management_app/camera/services/camera_state_manager.dart';

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


Step 5: Clean up your CameraControls (remove manual navigation handling)



// Update your CameraControls widget to pause camera before navigation

class CameraControls extends StatelessWidget {
// ... existing properties ...
final VoidCallback? onNavigateAway; // Add this callback

const CameraControls({
// ... existing parameters ...
this.onNavigateAway, // Add this parameter
});

// With RouteAware, you don't need manual pause/resume!
// The camera will automatically pause when navigating away

void _navigateToAlbum() {
AppRouter.instance.pushNamed(AppRoutes.album);
}

void _navigateToEditor() {
AppRouter.instance.pushNamed(AppRoutes.editor);
}

@override
Widget build(BuildContext context) {
return Container(
// ... existing container code ...
child: Padding(
// ... existing padding and column code ...
child: Column(
children: [
// ... existing zoom buttons ...
Row(
mainAxisAlignment: MainAxisAlignment.spaceAround,
crossAxisAlignment: CrossAxisAlignment.center,
children: [
GestureDetector(
onTap: () => _navigateToAlbum(context), // Updated
child: Column(
// ... existing album button code ...
),
),
_buildCaptureButton(),
GestureDetector(
onTap: () => _navigateToEditor(context), // Updated
child: _buildRecentClicks(),
),
],
),
],
),
),
);
}
}

// Then in your CameraScreen, pass the callback:
// In the CameraControls widget call:
CameraControls(
// ... other parameters ...
onNavigateAway: () {
_cameraStateManager.pause(); // Pause camera before navigation
},
)

