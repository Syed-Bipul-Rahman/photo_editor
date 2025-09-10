import 'dart:typed_data';

import 'package:photo_management_app/editor/crop/src/logic/format_detector/format.dart';
import 'package:photo_management_app/editor/crop/src/logic/parser/image_detail.dart';

/// Interface for parsing image and build [ImageDetail] from given [data].
typedef ImageParser<T> =
    ImageDetail<T> Function(Uint8List data, {ImageFormat? inputFormat});
