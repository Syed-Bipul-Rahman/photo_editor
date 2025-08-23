import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

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
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  children: [
                    _buildGalleryButton(),
                    const SizedBox(height: 8),
                    Text(
                      'Albums',
                      style: GoogleFonts.publicSans(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: const Color(0xFFFFFFFF),
                      ),
                    ),
                  ],
                ),
                _buildCaptureButton(),
                _buildRecentClicks(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryButton() {
    return SizedBox(
      width: 60,
      height: 60,
      // decoration: BoxDecoration(
      //   color: Colors.white.withValues(alpha: 0.2),
      //   borderRadius: BorderRadius.circular(8),
      //   border: Border.all(
      //     color: Colors.white.withValues(alpha: 0.3),
      //     width: 1,
      //   ),
      // ),
      child: SvgPicture.asset(
        'assets/icons/albums_icon.svg',
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: onCapture,
      child: Container(
        width: 80,
        height: 80,
        child: SvgPicture.asset(
          'assets/icons/click_single_image.svg',
          fit: BoxFit.cover,
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

  Widget _buildRecentClicks() {
    return Container(
      clipBehavior: Clip.antiAlias,
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Image.asset(
        'assets/images/for_preview_delete_this_later.png',
        fit: BoxFit.cover,
      ),
    );
  }
}
