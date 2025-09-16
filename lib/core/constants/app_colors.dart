import 'package:flutter/material.dart';

abstract class AppColors {
  AppColors._();

  // Primary colors
  static const Color primary = Color(0xFF004C9E);
  static const Color primaryLight = Color(0xFF7CC3ED);
  static const Color primaryDark = Color(0xFF3BA6E4);
  
  // Text colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFFE1E1E1);
  static const Color textLight = Color(0xFFFEFEFE);
  static const Color textDark = Color(0xFF000000);
  
  // Background colors
  static const Color background = Color(0xFF161616);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF000000);
  static const Color backgroundGrey = Color(0xFF333333);
  
  // UI element colors
  static const Color appBarBackground = Color(0xFF000000);
  static const Color appBarText = Color(0xFFFFFFFF);
  static const Color bottomBarBackground = Color(0xFF000000);
  static const Color bottomBarText = Color(0xFFFFFFFF);
  static const Color statusBar = Color(0x42000000);
  static const Color systemNavigationBar = Color(0xFF000000);
  
  // Button colors
  static const Color buttonPrimary = Color(0xFF333333);
  static const Color buttonText = Color(0xFFFEFEFE);
  
  // Indicator colors
  static const Color indicatorActive = Color(0xFF3BA6E4);
  static const Color indicatorInactive = Color(0xFFD2D2D2);
  
  // Gallery/Album colors
  static const MaterialColor galleryBackground = Colors.grey;
  static const MaterialColor galleryItemBackground = Colors.grey;
  static const MaterialColor galleryItemError = Colors.grey;
  
  // Camera colors
  static const Color cameraText = Color(0xFFFFFFFF);
  static const Color cameraControlBackground = Color(0xFF000000);
  static const Color cameraControlBackgroundTransparent = Color(0x4D000000); // 30% opacity
  static const Color cameraOverlay = Color(0x99000000); // 60% opacity
  static const Color cameraOverlayDark = Color(0xCC000000); // 80% opacity
  static const MaterialColor focusIndicatorActive = Colors.yellow;
  static const MaterialColor focusIndicatorInactive = Colors.green;
  
  // Editor colors
  static const Color editorBackground = Color(0xFF161616);
  static const Color editorText = Color(0xFFE1E1E1);
  static const Color editorError = Color(0xFFF44336);
  static const Color jpegBackground = Color(0xFFFFFFFF);
  
  // Cupertino colors
  static const Color cupertinoPrimaryLight = Color(0xFF000000);
  static const Color cupertinoPrimaryDark = Color(0xFFFFFFFF);
}
