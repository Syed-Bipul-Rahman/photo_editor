import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_management_app/editor/editor/pro_image_editor.dart';

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
          /*
          Your code to process the edited image, such as uploading it to your server.

          You can choose to use await to keep the loading dialog visible until
          your code completes, or run it without async to close the loading dialog immediately.

          By default, the image bytes are in JPG format.
        */
          Navigator.pop(context);
        },
        /*
        Optional: If you want haptic feedback when a line is hit, similar to WhatsApp,
        you can use the code below along with the vibration package.

        mainEditorCallbacks: MainEditorCallbacks(
          helperLines: HelperLinesCallbacks(
            onLineHit: () {
              Vibration.vibrate(duration: 3);
            },
          ),
        ),
        */
      ),
    );
  }
}
