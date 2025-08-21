import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
      height: 200,
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildZoomButton('0.6'),
                const SizedBox(width: 20),
                _buildZoomButton('1X', isSelected: true),
                const SizedBox(width: 20),
                _buildZoomButton('2'),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  children: [
                    _buildGalleryButton(),
                    const SizedBox(height: 8),
                    const Text(
                      'album',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                _buildCaptureButton(),
                Column(
                  children: [
                    _buildMultiClickButton(),
                    const SizedBox(height: 8),
                    const Text(
                      'click/multi click',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // _buildRecentImagesRow(),
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
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SvgPicture.asset(
          'assets/icons/albums_icon.svg',
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
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

  Widget _buildZoomButton(String label, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.white.withValues(alpha: 0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildMultiClickButton() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SvgPicture.asset(
          'assets/icons/multi_click_image.svg',
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
      ),
    );
  }

  Widget _buildRecentImagesRow() {
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: List.generate(6, (index) {
          return Container(
            width: 60,
            height: 60,
            margin: EdgeInsets.only(right: index < 5 ? 8 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.withValues(alpha: 0.3),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                color: Colors.grey.withValues(alpha: 0.5),
                child: const Icon(
                  Icons.image,
                  color: Colors.white54,
                  size: 24,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
