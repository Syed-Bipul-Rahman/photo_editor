import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/core.dart';

class CameraUIComponents {
  static Widget buildRightSideControl({
    required String iconPath,
    required String label,
    VoidCallback? onTap,
    bool showLabel = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLabel && label.isNotEmpty) ...[
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SvgPicture.asset(
                iconPath,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildFocusIndicator({
    required Offset? focusPoint,
    required bool isFocusing,
    required bool showMenu,
    required Animation<double> focusAnimation,
  }) {
    if (focusPoint == null || showMenu) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: focusAnimation,
      builder: (context, child) {
        return Positioned(
          left: focusPoint.dx - 50,
          top: focusPoint.dy - 50,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(
                color: isFocusing ? Colors.yellow : Colors.green,
                width: 2,
              ),
              color: Colors.transparent,
            ),
            child: isFocusing
                ? Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.yellow.withOpacity(focusAnimation.value),
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  static Widget buildZoomIndicator({
    required double currentZoom,
    required double minZoom,
    required bool showMenu,
  }) {
    if (currentZoom <= minZoom + 0.1 || showMenu) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 150,
      left: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '${currentZoom.toStringAsFixed(1)}x',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  static Widget buildTopControls({
    required bool showMenu,
    required VoidCallback onMenuToggle,
    required VoidCallback onSwitchCamera,
  }) {
    if (showMenu) return const SizedBox.shrink();

    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onMenuToggle,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SvgPicture.asset(
                  AppIcons.burger,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SvgPicture.asset(
                    AppIcons.person,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onSwitchCamera,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      AppIcons.switchCamera,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget buildRightSideControls({
    required bool showMenu,
    required bool isFlashOn,
    required bool showMoreControls,
    required VoidCallback onToggleFlash,
    required VoidCallback onToggleMoreControls,
  }) {
    if (showMenu) return const SizedBox.shrink();

    return Positioned(
      top: 120,
      right: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          buildRightSideControl(
            onTap: onToggleFlash,
            iconPath: isFlashOn ? AppIcons.flashOn : AppIcons.flashOff,
            label: 'Flash',
          ),
          const SizedBox(height: 30),
          if (showMoreControls) ...[
            buildRightSideControl(
              iconPath: AppIcons.copyIconThatRepresentMultiClick,
              label: 'Multi Click',
            ),
            const SizedBox(height: 30),
            buildRightSideControl(
              iconPath: AppIcons.timerOff,
              label: 'Timer',
            ),
            const SizedBox(height: 30),
          ],
          GestureDetector(
            onTap: onToggleMoreControls,
            child: buildRightSideControl(
              iconPath: showMoreControls
                  ? AppIcons.showLessItems
                  : AppIcons.showMoreItem,
              label: '',
              showLabel: false,
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildCameraPreview({
    required CameraController controller,
  }) {
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.previewSize?.height ?? 1,
          height: controller.value.previewSize?.width ?? 1,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}