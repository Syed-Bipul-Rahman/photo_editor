import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:photo_management_app/editor/crop/src/logic/format_detector/format.dart';
import 'package:photo_management_app/editor/crop/src/logic/format_detector/format_detector.dart';

final FormatDetector imageFormatDetector = (Uint8List data) {
  final format = img.findFormatForData(data);

  return switch (format) {
    img.ImageFormat.png => ImageFormat.png,
    img.ImageFormat.jpg => ImageFormat.jpeg,
    img.ImageFormat.webp => ImageFormat.webp,
    img.ImageFormat.bmp => ImageFormat.bmp,
    img.ImageFormat.ico => ImageFormat.ico,
    _ => ImageFormat.png,
  };
};
