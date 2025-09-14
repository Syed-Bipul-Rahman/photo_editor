import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_management_app/camera/utils/log_helper.dart';
import 'package:photo_management_app/editor/editor/pro_image_editor.dart';
import 'package:photo_management_app/routing/route_data.dart';
import 'package:photo_management_app/toast/src/core/position.dart';
import 'package:photo_management_app/toast/src/core/toast.dart';

class ProEditorVaiya extends StatefulWidget {
  const ProEditorVaiya({super.key});

  @override
  State<ProEditorVaiya> createState() => _ProEditorVaiyaState();
}

class _ProEditorVaiyaState extends State<ProEditorVaiya> {
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await Permission.storage.status;
      if (androidInfo == PermissionStatus.granted) {
        return true;
      }

      final result = await Permission.storage.request();
      return result == PermissionStatus.granted;
    }
    return true; // iOS doesn't need explicit permission for this
  }

  Future<String> _getPublicPicturesPath() async {
    if (Platform.isAndroid) {
      // Use Android's public Pictures directory
      return '/storage/emulated/0/Pictures';
    } else {
      // Fallback for iOS
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get image path from route data, fallback to default asset if not provided
    final imagePath = RouteData.instance.get<String>('imagePath');
    
    if (imagePath != null && File(imagePath).existsSync()) {
      // Use file constructor if we have a valid file path
      return ProImageEditor.file(
        File(imagePath),
        callbacks: ProImageEditorCallbacks(
          onImageEditingComplete: (Uint8List bytes) async {
            try {
              // Request storage permission
              bool hasPermission = await _requestStoragePermission();
              if (!hasPermission) {
                showToast(
                  "Storage permission required to save photo",
                  duration: Duration(seconds: 3),
                  position: ToastPosition.bottom,
                );
                LoggerHelper.error("Storage permission denied");
                return;
              }

              // Get public Pictures directory
              final picturesPath = await _getPublicPicturesPath();
              final picturesDir = Directory(picturesPath);

              // Ensure the directory exists
              if (!await picturesDir.exists()) {
                await picturesDir.create(recursive: true);
              }

              final fileName = "pro_editor_${DateTime.now().millisecondsSinceEpoch}.jpg";
              final file = File('$picturesPath/$fileName');

              await file.writeAsBytes(bytes);

              showToast(
                "Photo saved to Pictures folder",
                duration: Duration(seconds: 3),
                position: ToastPosition.bottom,
              );
              LoggerHelper.info("Image saved to public Pictures: ${file.path}");
            } catch (e) {
              showToast(
                "Error saving photo",
                duration: Duration(seconds: 3),
                position: ToastPosition.bottom,
              );
              LoggerHelper.error("Error saving image to Pictures folder: $e");
            }
          },
        ),
      );
    } else {
      // Fallback to default asset if no valid path provided
      return ProImageEditor.asset(
        'assets/images/porimoni.jpg',
        callbacks: ProImageEditorCallbacks(
          onImageEditingComplete: (Uint8List bytes) async {
            try {
              // Request storage permission
              bool hasPermission = await _requestStoragePermission();
              if (!hasPermission) {
                showToast(
                  "Storage permission required to save photo",
                  duration: Duration(seconds: 3),
                  position: ToastPosition.bottom,
                );
                LoggerHelper.error("Storage permission denied");
                return;
              }

              // Get public Pictures directory
              final picturesPath = await _getPublicPicturesPath();
              final picturesDir = Directory(picturesPath);

              // Ensure the directory exists
              if (!await picturesDir.exists()) {
                await picturesDir.create(recursive: true);
              }

              final fileName = "pro_editor_${DateTime.now().millisecondsSinceEpoch}.jpg";
              final file = File('$picturesPath/$fileName');

              await file.writeAsBytes(bytes);

              showToast(
                "Photo saved to Pictures folder",
                duration: Duration(seconds: 3),
                position: ToastPosition.bottom,
              );
              LoggerHelper.info("Image saved to public Pictures: ${file.path}");
            } catch (e) {
              showToast(
                "Error saving photo",
                duration: Duration(seconds: 3),
                position: ToastPosition.bottom,
              );
              LoggerHelper.error("Error saving image to Pictures folder: $e");
            }
          },
        ),
      );
    }
  }
}
