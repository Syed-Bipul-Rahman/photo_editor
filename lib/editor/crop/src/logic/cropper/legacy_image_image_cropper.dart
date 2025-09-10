import 'dart:ui';

import 'package:image/image.dart' hide ImageFormat;
import 'package:photo_management_app/editor/crop/src/logic/cropper/default_rect_validator.dart';
import 'package:photo_management_app/editor/crop/src/logic/cropper/image_cropper.dart';
import 'package:photo_management_app/editor/crop/src/logic/format_detector/format.dart';

/// an implementation of [ImageCropper] using image package
/// this implementation is legacy that behaves the same as the version 1.1.0 or earlier
/// meaning that it doesn't respect the outputFormat and always encode result as png
class LegacyImageImageCropper extends ImageCropper<Image> {
  const LegacyImageImageCropper();

  @override
  RectCropper<Image> get rectCropper => legacyRectCropper;

  @override
  CircleCropper<Image> get circleCropper => legacyCircleCropper;

  @override
  RectValidator<Image> get rectValidator => defaultRectValidator;
}

/// process cropping image.
/// this method is supposed to be called only via compute()
final RectCropper<Image> legacyRectCropper =
    (
      Image original, {
      required Offset topLeft,
      required Size size,
      required ImageFormat? outputFormat,
    }) {
      return encodePng(
        copyCrop(
          original,
          x: topLeft.dx.toInt(),
          y: topLeft.dy.toInt(),
          width: size.width.toInt(),
          height: size.height.toInt(),
        ),
      );
    };

/// process cropping image with circle shape.
/// this method is supposed to be called only via compute()
final CircleCropper<Image> legacyCircleCropper =
    (
      Image original, {
      required Offset center,
      required double radius,
      required ImageFormat? outputFormat,
    }) {
      // convert to rgba if necessary
      final target = original.numChannels == 4
          ? original
          : original.convert(numChannels: 4);

      return encodePng(
        copyCropCircle(
          target,
          centerX: center.dx.toInt(),
          centerY: center.dy.toInt(),
          radius: radius.toInt(),
        ),
      );
    };
