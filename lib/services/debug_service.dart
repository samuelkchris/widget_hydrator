import 'package:flutter/foundation.dart';

class DebugService {
  static final DebugService _instance = DebugService._internal();
  factory DebugService() => _instance;
  DebugService._internal();

  bool enableLogging = kDebugMode;

  void log(String message) {
    if (enableLogging) {
      if (kDebugMode) {
        print('WidgetHydrator: $message 😊');
      }
    }
  }

  void logError(String message) {
    if (enableLogging) {
      if (kDebugMode) {
        print('WidgetHydrator Error: $message ❌');
      }
    }
  }

  void logWarning(String message) {
    if (enableLogging) {
      if (kDebugMode) {
        print('WidgetHydrator Warning: $message ⚠️');
      }
    }
  }
}