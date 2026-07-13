import 'package:flutter/widgets.dart';

/// Shared observer so a screen can react to "I've become visible again"
/// after a route pushed above it is popped — used by the dashboard to
/// refresh its stats/calendar no matter how the user got back to it,
/// including cross-navigation via the sidebar from a deep screen (which
/// pops several routes at once rather than one at a time).
final RouteObserver<ModalRoute<void>> appRouteObserver = RouteObserver<ModalRoute<void>>();
