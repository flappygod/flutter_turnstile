import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TurnstileController extends ChangeNotifier {
  /// The connector associated with the controller.
  late WebViewController connector;

  String? _token;

  late String _widgetId;

  /// Get current token
  String? get token => _token;

  /// Sets a new connector.
  void setConnector(newConnector) {
    connector = newConnector;
  }

  /// Sets a new token.
  set newToken(String token) {
    _token = token;
    notifyListeners();
  }

  /// Sets the Turnstile current widget id.
  set widgetId(String id) {
    _widgetId = id;
  }

  /// The function can be called when widget mey become expired and
  /// needs to be refreshed.
  ///
  /// This method can only be called when [widgetId] is not null.
  ///
  /// example:
  /// ```dart
  /// // Initialize controller
  /// TurnstileController controller = TurnstileController();
  ///
  /// await controller.refreshToken();
  /// ```
  Future<void> refreshToken() async {
    await connector.runJavaScript("""turnstile.reset(`$_widgetId`)""");
  }

  /// The function that check if a widget has expired by either
  /// subscription to the [OnTokenExpired] or using isExpired();
  /// function, which returns true if the widget is expired.
  ///
  /// This method can only be called when [widgetId] is not null.
  ///
  ///
  /// example:
  /// ```dart
  /// // Initialize controller
  /// TurnstileController controller = TurnstileController();
  ///
  /// bool isTokenExpired = await controller.isExpired();
  /// print(isTokenExpired);
  /// ```
  Future<bool> isExpired() async {
    final result = await connector
        .runJavaScriptReturningResult("""turnstile.isExpired(`$_widgetId`);""");
    return result == 'true';
  }
}
