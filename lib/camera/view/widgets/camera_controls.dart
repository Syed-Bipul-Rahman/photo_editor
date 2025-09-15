import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_management_app/routing/app_routes.dart';

import '../../../core/core.dart';
import '../../../routing/app_router.dart';

class CameraControls extends StatelessWidget {
  final VoidCallback onCapture;
  final VoidCallback onSwitchCamera;
  final bool canSwitchCamera;
  final Function(double) onZoomChanged;
  final double currentZoom;
  final double minZoom;
  final double maxZoom;
  final VoidCallback? onNavigateAway; // Add this callback

  const CameraControls({
    super.key,
    required this.onCapture,
    required this.onSwitchCamera,
    required this.canSwitchCamera,
    required this.onZoomChanged,
    required this.currentZoom,
    required this.minZoom,
    required this.maxZoom,
    this.onNavigateAway, // Add this parameter
  });

  // Generate zoom levels based on camera capabilities
  List<double> get _availableZoomLevels {
    List<double> zoomLevels = [];

    // Add ultra-wide (0.5x or 0.6x) if camera supports it
    if (minZoom <= 0.6) {
      zoomLevels.add(0.6);
    } else if (minZoom <= 0.5) {
      zoomLevels.add(0.5);
    }

    // Always add 1x if possible
    if (minZoom <= 1.0 && maxZoom >= 1.0) {
      zoomLevels.add(1.0);
    }

    // Add 2x if camera supports it
    if (maxZoom >= 2.0) {
      zoomLevels.add(2.0);
    }

    // Add 3x if camera supports it
    if (maxZoom >= 3.0) {
      zoomLevels.add(3.0);
    }

    // If no standard zoom levels are available, use min and max
    if (zoomLevels.isEmpty) {
      zoomLevels.add(minZoom);
      if (maxZoom > minZoom) {
        zoomLevels.add(maxZoom);
      }
    }

    return zoomLevels;
  }

  // With RouteAware, you don't need manual pause/resume!
  // The camera will automatically pause when navigating away

  void _navigateToAlbum(BuildContext context) {
    // Pause camera before navigation
    if (onNavigateAway != null) {
      onNavigateAway!();
    }
    AppRouter.instance.pushNamed(AppRoutes.album);
  }

  void _navigateToEditor(BuildContext context) {
    // Pause camera before navigation
    if (onNavigateAway != null) {
      onNavigateAway!();
    }
    AppRouter.instance.pushNamed(AppRoutes.editor);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildZoomButtons(),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => _navigateToAlbum(context), // Updated
                  child: Column(
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

  List<Widget> _buildZoomButtons() {
    final zoomLevels = _availableZoomLevels;
    List<Widget> buttons = [];

    for (int i = 0; i < zoomLevels.length; i++) {
      if (i > 0) {
        buttons.add(const SizedBox(width: 20));
      }

      final zoomLevel = zoomLevels[i];
      String label;

      if (zoomLevel < 1.0) {
        label = '${(zoomLevel).toStringAsFixed(1)}x';
      } else if (zoomLevel == 1.0) {
        label = '1x';
      } else {
        label = '${zoomLevel.toInt()}x';
      }

      buttons.add(_buildZoomButton(label, zoomLevel));
    }

    return buttons;
  }

  Widget _buildGalleryButton() {
    return SizedBox(
      width: 60,
      height: 60,
      child: SvgPicture.asset(
        AppIcons.albumsIcon,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: onCapture,
      child: SizedBox(
        width: 80,
        height: 80,
        child: SvgPicture.asset(AppIcons.clickSingleImage, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildZoomButton(String label, double zoomLevel) {
    final isSelected = (currentZoom - zoomLevel).abs() < 0.1;
    return GestureDetector(
      onTap: () => onZoomChanged(zoomLevel),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
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
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Image.asset(
        AppImages.forPreviewDeleteThisLater,
        fit: BoxFit.cover,
      ),
    );
  }
}
