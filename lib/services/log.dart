import 'dart:developer' as developer;

/// The one logging seam: visible in `flutter logs`/DevTools without leaking
/// into release stdout the way `print` does.
void logInfo(String message, {String name = 'app'}) =>
    developer.log(message, name: name);

void logError(String message,
        {Object? error, StackTrace? stackTrace, String name = 'app'}) =>
    developer.log(message,
        name: name, error: error, stackTrace: stackTrace, level: 1000);
