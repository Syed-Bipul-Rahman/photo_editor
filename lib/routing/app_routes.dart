import 'package:flutter/material.dart';
import '../camera/view/camera_page.dart';
import '../counter/view/counter_page.dart';
import 'route_config.dart';

class AppRoutes {
  static const String camera = '/camera';
  static const String counter = '/counter';

  static final List<RouteConfig> routes = [
    RouteConfig(
      name: camera,
      path: camera,
      builder: (context) => const CameraPage(),
      transition: RouteTransition.slide,
    ),
    RouteConfig(
      name: counter,
      path: counter,
      builder: (context) => const CounterPage(),
      transition: RouteTransition.fade,
    ),
  ];
}