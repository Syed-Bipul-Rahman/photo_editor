import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class SlideOutMenu extends StatefulWidget {
  final bool isVisible;
  final String selectedAspectRatio;
  final String selectedTimer;
  final AnimationController animationController;
  final VoidCallback onClose;
  final Function(String) onAspectRatioChanged;
  final Function(String) onTimerChanged;

  const SlideOutMenu({
    super.key,
    required this.isVisible,
    required this.selectedAspectRatio,
    required this.selectedTimer,
    required this.animationController,
    required this.onClose,
    required this.onAspectRatioChanged,
    required this.onTimerChanged,
  });

  @override
  State<SlideOutMenu> createState() => _SlideOutMenuState();
}

class _SlideOutMenuState extends State<SlideOutMenu> {
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideAnimation =
        Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: widget.animationController,
            curve: Curves.easeInOut,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return Positioned.fill(
      child: GestureDetector(
        onTap: widget.onClose,
        child: Container(
          color: AppColors.cameraOverlay,
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping on menu
            child: Align(
              alignment: Alignment.centerLeft,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildMenuContent(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuContent(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cameraOverlayDark,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildAspectRatioSelector(),
              const SizedBox(height: 30),
              _buildTimerSelector(),
              const SizedBox(height: 40),
              _buildMenuItems(),
              const SizedBox(height: 40),
              _buildBottomMenuItems(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAspectRatioSelector() {
    final aspectRatios = ['1:1', '3:4', '9:16', 'Full'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.galleryItemBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: aspectRatios.map((ratio) {
          final isSelected = widget.selectedAspectRatio == ratio;
          return GestureDetector(
            onTap: () => widget.onAspectRatioChanged(ratio),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryLight
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                ratio,
                style: TextStyle(
                  color: AppColors.cameraText,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimerSelector() {
    final timers = ['Off', '3S', '5S', '10S'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.galleryItemBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: timers.map((timer) {
          final isSelected = widget.selectedTimer == timer;
          return GestureDetector(
            onTap: () => widget.onTimerChanged(timer),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.galleryItemBackground.withOpacity(0.6)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                timer,
                style: TextStyle(
                  color: AppColors.cameraText,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuItems() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildBottomMenuItem(
          icon: Icons.photo_library_outlined,
          label: 'Albums',
          onTap: () {
            // Navigate to albums
            widget.onClose();
          },
        ),
        const SizedBox(height: 20),
        _buildBottomMenuItem(
          icon: Icons.timeline,
          label: 'Timeline',
          onTap: () {
            // Navigate to timeline
            widget.onClose();
          },
        ),
        const SizedBox(height: 20),
        _buildBottomMenuItem(
          icon: Icons.favorite_border,
          label: 'Favorites',
          onTap: () {
            // Navigate to favorites
            widget.onClose();
          },
        ),
        const SizedBox(height: 20),
        _buildBottomMenuItem(
          icon: Icons.delete_outline,
          label: 'Trash',
          onTap: () {
            // Navigate to trash
            widget.onClose();
          },
        ),
      ],
    );
  }

  Widget _buildBottomMenuItems() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildBottomMenuItem(
          icon: Icons.settings,
          label: 'Setting',
          onTap: () {
            // Navigate to settings
            widget.onClose();
          },
        ),
        _buildBottomMenuItem(
          icon: Icons.message_outlined,
          label: 'Message',
          onTap: () {
            // Navigate to messages
            widget.onClose();
          },
        ),
        _buildBottomMenuItem(
          icon: Icons.person_outline,
          label: 'Profile',
          onTap: () {
            // Navigate to profile
            widget.onClose();
          },
        ),
      ],
    );
  }

  Widget _buildBottomMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.galleryItemBackground.withOpacity(0.3),
            ),
            child: Icon(icon, color: AppColors.cameraText, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.cameraText,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
