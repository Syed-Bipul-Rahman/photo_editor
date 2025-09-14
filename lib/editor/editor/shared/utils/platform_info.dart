// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:photo_management_app/editor/editor/core/enums/design_mode.dart';
import 'package:photo_management_app/editor/editor/core/platform/io/io_helper.dart';

/// Checks if the app is running on a desktop platform.
final isDesktop = !isWebMobile &&
    (kIsWeb || Platform.isMacOS || Platform.isWindows || Platform.isLinux);

/// Checks if the current platform is a web mobile device.
final isWebMobile = kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android);

/// Determines if the platform uses Material Design.
final platformIsMaterialDesign = kIsWeb ||
    (defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.macOS);

/// Sets the design mode for the image editor based on the platform.
/// Uses Material Design for non-iOS/macOS platforms and Cupertino for iOS/macOS.
final ImageEditorDesignMode platformDesignMode = platformIsMaterialDesign
    ? ImageEditorDesignMode.material
    : ImageEditorDesignMode.cupertino;
