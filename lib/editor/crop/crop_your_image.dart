import 'package:photo_management_app/editor/crop/src/logic/cropper/image_image_cropper.dart';
import 'package:photo_management_app/editor/crop/src/logic/cropper/legacy_image_image_cropper.dart';
import 'package:photo_management_app/editor/crop/src/logic/format_detector/default_format_detector.dart';
import 'package:photo_management_app/editor/crop/src/logic/parser/image_image_parser.dart';

export 'src/widget/widget.dart';
export 'src/logic/logic.dart';

final defaultImageParser = imageImageParser;
final defaultFormatDetector = imageFormatDetector;
const defaultImageCropper = ImageImageCropper();
const legacyImageCropper = LegacyImageImageCropper();
