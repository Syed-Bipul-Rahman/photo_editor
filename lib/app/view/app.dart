import 'package:flutter/material.dart';
import 'package:photo_management_app/l10n/l10n.dart';
import 'package:photo_management_app/routing/routing.dart';
import 'package:photo_management_app/routing/app_routes.dart';

// Create a global RouteObserver instance
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final router = AppRouter.instance;
    router.addRoutes(AppRoutes.routes);

    return MaterialApp(
      navigatorKey: router.navigatorKey,
      // Add the RouteObserver to navigatorObservers
      navigatorObservers: [routeObserver, ...router.observers],
      onGenerateRoute: router.generateRoute,
      initialRoute: AppRoutes.camera,
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
