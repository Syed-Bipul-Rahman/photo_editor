import 'package:flutter/material.dart';
import '../album/view/album_page.dart';
import '../camera/view/camera_page.dart';
import '../editor/editor/pro_editor_vaiya.dart';
import '../editor/view/editor_screen.dart';
import 'route_config.dart';

class AppRoutes {
  static const String camera = '/camera';
  static const String album = '/album';
  static const String editor = '/editor';

  static final List<RouteConfig> routes = [
    RouteConfig(
      name: camera,
      path: camera,
      builder: (context) => const CameraPage(),
      transition: RouteTransition.slide,
    ),
    RouteConfig(
      name: album,
      path: album,
      builder: (context) => const AlbumPage(),
      transition: RouteTransition.fade,
    ),
    RouteConfig(
      name: editor,
      path: editor,
      builder: (context) => const ProEditorVaiya(),
      transition: RouteTransition.fade,
    ),
  ];
}
