import 'package:flutter/material.dart';
import 'route_config.dart';
import 'route_data.dart';

class AppRouter {
  AppRouter._internal();
  static final AppRouter _instance = AppRouter._internal();
  static AppRouter get instance => _instance;

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final List<String> _routeHistory = [];
  final Map<String, RouteConfig> _routes = {};
  final Map<String, RouteGuard> _guards = {};
  final List<NavigatorObserver> _observers = [];

  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;
  BuildContext? get context => _navigatorKey.currentContext;
  List<String> get routeHistory => List.unmodifiable(_routeHistory);

  void addRoute(RouteConfig route) {
    _routes[route.name] = route;
  }

  void addRoutes(List<RouteConfig> routes) {
    for (final route in routes) {
      addRoute(route);
    }
  }

  void addGuard(String routeName, RouteGuard guard) {
    _guards[routeName] = guard;
  }

  void addObserver(NavigatorObserver observer) {
    _observers.add(observer);
  }

  Future<T?> pushNamed<T extends Object?>(
    String routeName, {
    Map<String, dynamic>? data,
    bool clearData = false,
  }) async {
    if (clearData) {
      RouteData.instance.clear();
    }
    
    if (data != null) {
      RouteData.instance.setMultiple(data);
    }

    if (!_canNavigate(routeName)) {
      return null;
    }

    final route = _routes[routeName];
    if (route == null) {
      throw ArgumentError('Route "$routeName" not found');
    }

    _routeHistory.add(routeName);

    return _navigatorKey.currentState?.push<T>(
      _buildPageRoute<T>(route),
    );
  }

  Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    Map<String, dynamic>? data,
    TO? result,
    bool clearData = false,
  }) async {
    if (clearData) {
      RouteData.instance.clear();
    }
    
    if (data != null) {
      RouteData.instance.setMultiple(data);
    }

    if (!_canNavigate(routeName)) {
      return null;
    }

    final route = _routes[routeName];
    if (route == null) {
      throw ArgumentError('Route "$routeName" not found');
    }

    if (_routeHistory.isNotEmpty) {
      _routeHistory.removeLast();
    }
    _routeHistory.add(routeName);

    return _navigatorKey.currentState?.pushReplacement<T, TO>(
      _buildPageRoute<T>(route),
      result: result,
    );
  }

  Future<T?> pushNamedAndClearStack<T extends Object?>(
    String routeName, {
    Map<String, dynamic>? data,
    bool clearData = true,
  }) async {
    if (clearData) {
      RouteData.instance.clear();
    }
    
    if (data != null) {
      RouteData.instance.setMultiple(data);
    }

    if (!_canNavigate(routeName)) {
      return null;
    }

    final route = _routes[routeName];
    if (route == null) {
      throw ArgumentError('Route "$routeName" not found');
    }

    _routeHistory.clear();
    _routeHistory.add(routeName);

    return _navigatorKey.currentState?.pushNamedAndRemoveUntil<T>(
      routeName,
      (route) => false,
    );
  }

  void pop<T extends Object?>([T? result]) {
    if (_routeHistory.isNotEmpty) {
      _routeHistory.removeLast();
    }
    _navigatorKey.currentState?.pop<T>(result);
  }

  void popUntil(String routeName) {
    _navigatorKey.currentState?.popUntil(
      (route) => route.settings.name == routeName,
    );
    
    final index = _routeHistory.lastIndexOf(routeName);
    if (index != -1) {
      _routeHistory.removeRange(index + 1, _routeHistory.length);
    }
  }

  void popToRoot() {
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    if (_routeHistory.isNotEmpty) {
      final firstRoute = _routeHistory.first;
      _routeHistory.clear();
      _routeHistory.add(firstRoute);
    }
  }

  bool canPop() {
    return _navigatorKey.currentState?.canPop() ?? false;
  }

  Future<bool> maybePop<T extends Object?>([T? result]) async {
    if (_routeHistory.isNotEmpty) {
      _routeHistory.removeLast();
    }
    return _navigatorKey.currentState?.maybePop<T>(result) ?? false;
  }

  String? get currentRoute {
    return _routeHistory.isNotEmpty ? _routeHistory.last : null;
  }

  String? get previousRoute {
    return _routeHistory.length > 1 ? _routeHistory[_routeHistory.length - 2] : null;
  }

  bool isCurrentRoute(String routeName) {
    return currentRoute == routeName;
  }

  void clearHistory() {
    _routeHistory.clear();
  }

  Route<T> generateRoute<T extends Object?>(RouteSettings settings) {
    final routeName = settings.name;
    if (routeName == null) {
      return _buildNotFoundRoute<T>();
    }

    final route = _routes[routeName];
    if (route == null) {
      return _buildNotFoundRoute<T>();
    }

    if (!_canNavigate(routeName)) {
      final guard = _guards[routeName];
      if (guard?.redirectTo != null) {
        final redirectRoute = _routes[guard!.redirectTo!];
        if (redirectRoute != null) {
          return _buildPageRoute<T>(redirectRoute);
        }
      }
      return _buildNotFoundRoute<T>();
    }

    _routeHistory.add(routeName);
    return _buildPageRoute<T>(route);
  }

  List<NavigatorObserver> get observers => _observers;

  PageRoute<T> _buildPageRoute<T>(RouteConfig config) {
    switch (config.transition) {
      case RouteTransition.fade:
        return PageRouteBuilder<T>(
          settings: RouteSettings(name: config.name),
          pageBuilder: (context, animation, _) => config.builder(context),
          transitionDuration: config.transitionDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          fullscreenDialog: config.fullScreenDialog,
          maintainState: config.maintainState,
          barrierDismissible: config.barrierDismissible,
          barrierColor: config.barrierColor,
          barrierLabel: config.barrierLabel,
          opaque: config.opaque,
        );

      case RouteTransition.scale:
        return PageRouteBuilder<T>(
          settings: RouteSettings(name: config.name),
          pageBuilder: (context, animation, _) => config.builder(context),
          transitionDuration: config.transitionDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(
              scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.fastOutSlowIn),
              ),
              child: child,
            );
          },
          fullscreenDialog: config.fullScreenDialog,
          maintainState: config.maintainState,
          barrierDismissible: config.barrierDismissible,
          barrierColor: config.barrierColor,
          barrierLabel: config.barrierLabel,
          opaque: config.opaque,
        );

      case RouteTransition.slideFromTop:
        return PageRouteBuilder<T>(
          settings: RouteSettings(name: config.name),
          pageBuilder: (context, animation, _) => config.builder(context),
          transitionDuration: config.transitionDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, -1.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
          fullscreenDialog: config.fullScreenDialog,
          maintainState: config.maintainState,
          barrierDismissible: config.barrierDismissible,
          barrierColor: config.barrierColor,
          barrierLabel: config.barrierLabel,
          opaque: config.opaque,
        );

      case RouteTransition.slideFromBottom:
        return PageRouteBuilder<T>(
          settings: RouteSettings(name: config.name),
          pageBuilder: (context, animation, _) => config.builder(context),
          transitionDuration: config.transitionDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
          fullscreenDialog: config.fullScreenDialog,
          maintainState: config.maintainState,
          barrierDismissible: config.barrierDismissible,
          barrierColor: config.barrierColor,
          barrierLabel: config.barrierLabel,
          opaque: config.opaque,
        );

      case RouteTransition.slideFromLeft:
        return PageRouteBuilder<T>(
          settings: RouteSettings(name: config.name),
          pageBuilder: (context, animation, _) => config.builder(context),
          transitionDuration: config.transitionDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
          fullscreenDialog: config.fullScreenDialog,
          maintainState: config.maintainState,
          barrierDismissible: config.barrierDismissible,
          barrierColor: config.barrierColor,
          barrierLabel: config.barrierLabel,
          opaque: config.opaque,
        );

      case RouteTransition.slideFromRight:
        return PageRouteBuilder<T>(
          settings: RouteSettings(name: config.name),
          pageBuilder: (context, animation, _) => config.builder(context),
          transitionDuration: config.transitionDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
          fullscreenDialog: config.fullScreenDialog,
          maintainState: config.maintainState,
          barrierDismissible: config.barrierDismissible,
          barrierColor: config.barrierColor,
          barrierLabel: config.barrierLabel,
          opaque: config.opaque,
        );

      case RouteTransition.rotation:
        return PageRouteBuilder<T>(
          settings: RouteSettings(name: config.name),
          pageBuilder: (context, animation, _) => config.builder(context),
          transitionDuration: config.transitionDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return RotationTransition(
              turns: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.linear),
              ),
              child: child,
            );
          },
          fullscreenDialog: config.fullScreenDialog,
          maintainState: config.maintainState,
          barrierDismissible: config.barrierDismissible,
          barrierColor: config.barrierColor,
          barrierLabel: config.barrierLabel,
          opaque: config.opaque,
        );

      case RouteTransition.size:
        return PageRouteBuilder<T>(
          settings: RouteSettings(name: config.name),
          pageBuilder: (context, animation, _) => config.builder(context),
          transitionDuration: config.transitionDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return Align(
              child: SizeTransition(
                sizeFactor: animation,
                child: child,
              ),
            );
          },
          fullscreenDialog: config.fullScreenDialog,
          maintainState: config.maintainState,
          barrierDismissible: config.barrierDismissible,
          barrierColor: config.barrierColor,
          barrierLabel: config.barrierLabel,
          opaque: config.opaque,
        );

      case RouteTransition.none:
        return PageRouteBuilder<T>(
          settings: RouteSettings(name: config.name),
          pageBuilder: (context, animation, _) => config.builder(context),
          transitionDuration: Duration.zero,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;
          },
          fullscreenDialog: config.fullScreenDialog,
          maintainState: config.maintainState,
          barrierDismissible: config.barrierDismissible,
          barrierColor: config.barrierColor,
          barrierLabel: config.barrierLabel,
          opaque: config.opaque,
        );

      case RouteTransition.slide:
      default:
        return MaterialPageRoute<T>(
          settings: RouteSettings(name: config.name),
          builder: config.builder,
          fullscreenDialog: config.fullScreenDialog,
          maintainState: config.maintainState,
        );
    }
  }

  Route<T> _buildNotFoundRoute<T>() {
    return MaterialPageRoute<T>(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Page Not Found')),
        body: const Center(
          child: Text(
            '404 - Page Not Found',
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }

  bool _canNavigate(String routeName) {
    final guard = _guards[routeName];
    if (guard == null) return true;

    if (!guard.canActivate()) {
      guard.onBlock?.call();
      return false;
    }

    return true;
  }

  void dispose() {
    _routeHistory.clear();
    _routes.clear();
    _guards.clear();
    _observers.clear();
    RouteData.instance.dispose();
  }
}