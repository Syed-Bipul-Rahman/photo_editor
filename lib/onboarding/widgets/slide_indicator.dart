import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class SlideIndicator extends StatefulWidget {
  int length;
  int indicatorIndex;

  SlideIndicator({super.key, this.length = 0, this.indicatorIndex = 0});

  @override
  State<SlideIndicator> createState() => _SlideIndicatorState();
}

class _SlideIndicatorState extends State<SlideIndicator> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.length,
        (dotIndex) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.indicatorIndex == dotIndex
                ? AppColors.indicatorActive
                : AppColors.indicatorInactive,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
