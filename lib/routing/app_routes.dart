import 'package:flutter/material.dart';
import '../album/view/album_page.dart';
import '../camera/view/camera_page.dart';
import 'route_config.dart';

class AppRoutes {
  static const String camera = '/camera';
  static const String album = '/album';

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
  ];
}
