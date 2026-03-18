import 'package:flutter/widgets.dart';

class PintapObserver extends NavigatorObserver {
  // A global callback that Pintap can listen to
  static void Function(String routeName)? onRouteChanged;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _notifyRouteChange(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _notifyRouteChange(previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _notifyRouteChange(newRoute);
    }
  }

  void _notifyRouteChange(Route<dynamic> route) {
    final name = route.settings.name;
    if (name != null && onRouteChanged != null) {
      onRouteChanged!(name);
    }
  }
}
