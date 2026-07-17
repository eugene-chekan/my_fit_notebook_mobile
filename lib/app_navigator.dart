import 'package:flutter/widgets.dart';

/// App-wide navigator key, so non-widget code (e.g. a tapped reminder) can push
/// routes without a BuildContext.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
