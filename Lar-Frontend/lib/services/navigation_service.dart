import 'package:flutter/material.dart';

// A global navigator key that can be used by services to navigate from outside widget context.
final GlobalKey<NavigatorState> navigationKey = GlobalKey<NavigatorState>();

// Helper to navigate with optional arguments
Future<T?> navigateTo<T extends Object?>(String routeName, {Object? arguments}) {
  return navigationKey.currentState!.pushNamed<T>(routeName, arguments: arguments);
}
