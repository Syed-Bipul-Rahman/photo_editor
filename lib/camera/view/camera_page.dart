import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_management_app/camera/camera.dart';
import 'package:photo_management_app/camera/view/camera_screen.dart';

// Import your global routeObserver from main.dart
import 'package:photo_management_app/app/view/app.dart';

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
