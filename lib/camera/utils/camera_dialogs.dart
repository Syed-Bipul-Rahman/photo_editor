import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../core/constants/app_strings.dart';

class CameraDialogs {
  static void showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.cameraPermissionRequired),
        content: const Text(
          AppStrings.cameraPermissionExplanation,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text(AppStrings.settings),
          ),
        ],
      ),
    );
  }

  static void showNoCameraDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.noCameraFound),
        content: const Text(AppStrings.noCameraAvailable),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.ok),
          ),
        ],
      ),
    );
  }

  static void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
                title: const Text(AppStrings.error),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.ok),
          ),
        ],
      ),
    );
  }

  static Future<void> playClickSound() async {
    try {
      final player = AudioPlayer();
      await player.play(AssetSource('sound/click_one.wav'));
    } catch (e) {
      // Silently handle audio playback errors
    }
  }
}