# Comprehensive Flutter Router

A powerful, zero-dependency routing solution for Flutter with built-in data sharing capabilities.

## Features

- 🚀 **Zero Dependencies**: No external packages required
- 📊 **Data Sharing**: Pass data between screens without constructor parameters
- 🎯 **Type Safety**: Full type safety for routes and data
- 🎨 **Custom Transitions**: Multiple built-in transition animations
- 🔒 **Route Guards**: Protect routes with authentication checks
- 📱 **Navigation History**: Track and manage navigation history
- 🎭 **Multiple Environments**: Support for different app flavors
- ⚡ **Performance**: Optimized for large applications

## Quick Start

### 1. Basic Navigation

```dart
// Navigate to a route
AppRouter.instance.pushNamed('/counter');

// Navigate with data
AppRouter.instance.pushNamed(
  '/counter',
  data: {'title': 'My Counter', 'initialValue': 5},
);

// Replace current route
AppRouter.instance.pushReplacementNamed('/camera');

// Navigate and clear stack
AppRouter.instance.pushNamedAndClearStack('/home');
```

### 2. Data Sharing Between Screens

#### Setting Data (from source screen):
```dart
// In your source screen (e.g., CameraPage)
class CameraPage extends StatelessWidget {
  void _navigateToPreview(String imagePath) {
    // Set data before navigation
    RouteData.instance.set('imagePath', imagePath);
    RouteData.instance.set('timestamp', DateTime.now());
    
    AppRouter.instance.pushNamed('/preview');
  }
}
```

#### Getting Data (in destination screen):
```dart
// In your destination screen (e.g., PreviewPage)
class PreviewPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Get data without parameters
    final imagePath = RouteData.instance.get<String>('imagePath');
    final timestamp = RouteData.instance.get<DateTime>('timestamp');
    
    return Scaffold(
      body: Image.file(File(imagePath ?? '')),
    );
  }
}
```

#### Reactive Data Watching:
```dart
class PreviewPage extends StatefulWidget {
  @override
  _PreviewPageState createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: RouteData.instance.watch<String>('imagePath'),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.file(File(snapshot.data!));
        }
        return CircularProgressIndicator();
      },
    );
  }
}
```

### 3. Route Configuration

```dart
// Define your routes
class AppRoutes {
  static const String home = '/home';
  static const String camera = '/camera';
  static const String preview = '/preview';
  
  static final List<RouteConfig> routes = [
    RouteConfig(
      name: home,
      path: home,
      builder: (context) => const HomePage(),
      transition: RouteTransition.fade,
    ),
    RouteConfig(
      name: camera,
      path: camera,
      builder: (context) => const CameraPage(),
      transition: RouteTransition.slideFromRight,
      transitionDuration: Duration(milliseconds: 500),
    ),
    RouteConfig(
      name: preview,
      path: preview,
      builder: (context) => const PreviewPage(),
      transition: RouteTransition.scale,
      fullScreenDialog: true,
    ),
  ];
}
```

### 4. Route Guards

```dart
// Add authentication guard
AppRouter.instance.addGuard(
  '/profile',
  RouteGuard(
    canActivate: () => AuthService.instance.isLoggedIn,
    redirectTo: '/login',
    onBlock: () => showDialog(/* login required dialog */),
  ),
);
```

### 5. Advanced Data Management

```dart
// Set temporary data with auto-cleanup
RouteData.instance.setTemporary(
  'tempData', 
  'value',
  expiration: Duration(minutes: 5),
);

// Set multiple values at once
RouteData.instance.setMultiple({
  'userId': 123,
  'userName': 'john_doe',
  'preferences': UserPreferences(),
});

// Check if data exists
if (RouteData.instance.has('imagePath')) {
  // Process image
}

// Get with default value
final theme = RouteData.instance.getOrDefault('theme', 'light');

// Clear specific data
RouteData.instance.remove('tempData');

// Clear all data
RouteData.instance.clear();
```

## Available Transitions

- `RouteTransition.slide` - Default Material slide
- `RouteTransition.fade` - Fade in/out
- `RouteTransition.scale` - Scale up/down
- `RouteTransition.slideFromTop` - Slide from top
- `RouteTransition.slideFromBottom` - Slide from bottom
- `RouteTransition.slideFromLeft` - Slide from left
- `RouteTransition.slideFromRight` - Slide from right
- `RouteTransition.rotation` - Rotate transition
- `RouteTransition.size` - Size transition
- `RouteTransition.none` - No animation

## Navigation Methods

```dart
final router = AppRouter.instance;

// Basic navigation
router.pushNamed('/route');
router.pushReplacementNamed('/route');
router.pushNamedAndClearStack('/route');

// Navigation with data
router.pushNamed('/route', data: {'key': 'value'});

// Pop operations
router.pop(); // Pop current route
router.popUntil('/home'); // Pop until specific route
router.popToRoot(); // Pop to first route
router.maybePop(); // Pop if possible

// Route information
String? current = router.currentRoute;
String? previous = router.previousRoute;
bool isCurrentRoute = router.isCurrentRoute('/home');
List<String> history = router.routeHistory;
```

## Best Practices

1. **Data Lifecycle**: Always clear sensitive data after use
2. **Type Safety**: Use generic types when getting/setting data
3. **Error Handling**: Check for null values when retrieving data
4. **Memory Management**: Use temporary data for short-lived values
5. **Route Guards**: Implement proper authentication checks

## Integration with BLoC

```dart
// In your BLoC
class CameraCubit extends Cubit<CameraState> {
  void capturePhoto(String imagePath) {
    // Save to RouteData instead of passing as parameter
    RouteData.instance.set('capturedImage', imagePath);
    
    // Navigate
    AppRouter.instance.pushNamed('/preview');
  }
}

// In your destination widget
class PreviewPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreviewCubit, PreviewState>(
      builder: (context, state) {
        // Get data from RouteData service
        final imagePath = RouteData.instance.get<String>('capturedImage');
        
        if (imagePath == null) {
          return ErrorWidget('No image provided');
        }
        
        return Image.file(File(imagePath));
      },
    );
  }
}
```

This routing solution provides a clean, maintainable way to handle navigation and data sharing in your Flutter application without cluttering constructors or route parameters.