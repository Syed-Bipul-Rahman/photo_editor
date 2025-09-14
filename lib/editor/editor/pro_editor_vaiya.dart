import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_management_app/camera/utils/log_helper.dart';
import 'package:photo_management_app/editor/editor/pro_image_editor.dart';
import 'package:photo_management_app/toast/src/core/position.dart';
import 'package:photo_management_app/toast/src/core/toast.dart';

class ProEditorVaiya extends StatefulWidget {
  const ProEditorVaiya({super.key});

  @override
  State<ProEditorVaiya> createState() => _ProEditorVaiyaState();
}

class _ProEditorVaiyaState extends State<ProEditorVaiya> {
  @override
  Widget build(BuildContext context) {
    return ProImageEditor.asset(
      'assets/images/porimoni.jpg',
      callbacks: ProImageEditorCallbacks(
        onImageEditingComplete: (Uint8List bytes) async {
          showToast(
            "Photo saved",
            duration: Duration(seconds: 3),
            position: ToastPosition.bottom,
          );
          LoggerHelper.info("Image saved to Gallery");
        },
      ),
    );
  }
}
