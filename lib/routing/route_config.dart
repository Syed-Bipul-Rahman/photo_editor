import 'package:flutter/material.dart';

enum RouteTransition {
  slide,
  fade,
  scale,
  slideFromTop,
  slideFromBottom,
  slideFromLeft,
  slideFromRight,
  rotation,
  size,
  none,
}

class RouteConfig {
  const RouteConfig({
    required this.name,
    required this.path,
    required this.builder,
    this.transition = RouteTransition.slide,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.fullScreenDialog = false,
    this.maintainState = true,
    this.barrierDismissible = false,
    this.barrierColor,
    this.barrierLabel,
    this.opaque = true,
  });

  final String name;
  final String path;
  final Widget Function(BuildContext context) builder;
  final RouteTransition transition;
  final Duration transitionDuration;
  final bool fullScreenDialog;
  final bool maintainState;
  final bool barrierDismissible;
  final Color? barrierColor;
  final String? barrierLabel;
  final bool opaque;
}

class NestedRouteConfig {
  const NestedRouteConfig({
    required this.name,
    required this.path,
    required this.builder,
    this.children = const [],
    this.redirect,
    this.transition = RouteTransition.slide,
    this.transitionDuration = const Duration(milliseconds: 300),
  });

  final String name;
  final String path;
  final Widget Function(BuildContext context) builder;
  final List<NestedRouteConfig> children;
  final String? redirect;
  final RouteTransition transition;
  final Duration transitionDuration;
}

class RouteGuard {
  const RouteGuard({
    required this.canActivate,
    this.redirectTo,
    this.onBlock,
  });

  final bool Function() canActivate;
  final String? redirectTo;
  final VoidCallback? onBlock;
}