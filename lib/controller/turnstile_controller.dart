import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/material.dart';

///自定义控制器
///  1. _connector 是我们的控件State 中设置进来的。
///  2. _token 是html代码执行成功后回调设置进来的，用于缓存，方便使用者随时提取
///  3. _widgetId 也是html代码执行成功后回调设置进来的，当_connector和_widgetId齐全的时候我们就可以通过webViewWidget的控制器_connector执行一段
///  js代码，以达到控制webView中加载的html trunstile 控件的目的
class TurnstileController extends ChangeNotifier {
  ///设置进来的connector，设置了之后才能通过它进行一些列控制
  WebViewController? _connector;

  ///同样的，设置进来的token ,用户保存html界面回调回来的token
  String? _token;

  ///html代码中创建成功后缓存在这里的widgetId，用于后续直接在webView中执行js代码，即下方 refreshToken 和 isExpired;
  String? _widgetId;

  /// Get current token
  String? get token => _token;

  /// Sets a new connector.
  void setConnector(newConnector) {
    _connector = newConnector;
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
    _token = null;
    await _connector?.runJavaScript("""turnstile.reset(`$_widgetId`)""");
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
    final result = await _connector?.runJavaScriptReturningResult(
        """turnstile.isExpired(`$_widgetId`);""");
    return result.toString() == 'true';
  }
}
