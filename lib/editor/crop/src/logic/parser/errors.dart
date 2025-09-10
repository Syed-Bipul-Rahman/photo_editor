import 'package:photo_management_app/editor/crop/src/logic/format_detector/format.dart';

class InvalidInputFormatException implements Exception {
  final ImageFormat? inputFormat;

  InvalidInputFormatException(this.inputFormat);
}
