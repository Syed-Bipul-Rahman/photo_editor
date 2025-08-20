import 'package:flutter/material.dart';

class CameraControls extends StatelessWidget {
  final VoidCallback onCapture;
  final VoidCallback onSwitchCamera;
  final bool canSwitchCamera;

  const CameraControls({
    super.key,
    required this.onCapture,
    required this.onSwitchCamera,
    required this.canSwitchCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildGalleryButton(),
            _buildCaptureButton(),
            _buildSwitchCameraButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryButton() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
      ),
      child: Icon(
        Icons.photo_library,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: onCapture,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300, width: 4),
        ),
        child: Container(
          margin: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchCameraButton() {
    return GestureDetector(
      onTap: canSwitchCamera ? onSwitchCamera : null,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: canSwitchCamera 
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: canSwitchCamera 
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.flip_camera_ios,
          color: canSwitchCamera ? Colors.white : Colors.grey,
          size: 28,
        ),
      ),
    );
  }
}