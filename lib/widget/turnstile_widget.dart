import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:flutter_turnstile/widget/turnstile_controller.dart';

//app function bridge
const String appFunctionBridge = "BossJobAppBridge";
const String appFunctionPrefix = "BossJobApp";

//options
class TurnstileOptions {
  /// The Turnstile widget mode.
  ///
  ///  The 3 models for turnstile are:
  /// [TurnstileMode.managed] - Cloudflare will use information from the visitor
  /// to decide if an interactive challange should be used. if we show an interaction,
  /// the user will be prmpted to check a box
  ///
  /// [TurnstileMode.nonInteractive] - Users will see a widget with a loading bar
  /// while the browser challanges run. Users will never be required or prompted
  /// to interact with the widget
  ///
  /// [TurnstileMode.invisible] - Users will not see a widget or any indication that
  /// an invisible browser challange is in progress. invisible challanges should take
  /// a few seconds to complete.
  final TurnstileMode mode;

  /// The widget size. Can take the following values: [TurnstileSize.normal], [TurnstileSize.compact].
  /// Default value is [TurnstileSize.normal]
  final TurnstileSize size;

  /// Language to display, must be either: auto (default) to use the
  /// language that the visitor has chosen, or an ISO 639-1 two-letter
  /// language code (e.g. en) or language and country code (e.g. en-US).
  /// Refer to the list of supported languages for more information.
  /// Default value is [auto]
  ///
  /// Refer to [list of supported languages](https://developers.cloudflare.com/turnstile/reference/supported-languages/) for more infrmation.
  final String language;

  final TurnstileTheme theme;

  /// Controls whether the widget should automatically retry to obtain
  /// a token if it did not succeed. The default value is true witch will
  /// retry Autmoatically. This can be set to false to disable retry upon
  /// failure.
  final bool retryAutomatically;

  /// When retry is set to [auto], [retryInterval] controls the time
  /// between retry attempts in milliseconds. Value must be a positive
  /// integer less than 900000, defaults to 8000
  final Duration retryInterval;

  /// Automatically refreshes the token when it expires.
  /// Can take auto, manual or never, defaults to auto.
  final TurnstileRefreshExpired refreshExpired;

  /// Controls whether the widget should automatically refresh upon
  /// entering an interactive challange and observing a timeout.
  /// Can take [auto] (automaticly), [manual] (prompts the visitor to
  /// manualy refresh) or [never] (will show a timeout), defaults to [auto]
  /// Only applies to widgets of mode [managed]
  final TurnstileRefreshTimeout refreshTimeout;

  TurnstileOptions({
    this.mode = TurnstileMode.managed,
    this.size = TurnstileSize.normal,
    this.theme = TurnstileTheme.auto,
    this.language = 'auto',
    this.retryInterval = const Duration(milliseconds: 8000),
    this.retryAutomatically = true,
    this.refreshExpired = TurnstileRefreshExpired.auto,
    this.refreshTimeout = TurnstileRefreshTimeout.auto,
  })  : assert(retryInterval.inMilliseconds > 0 && retryInterval.inMilliseconds <= 900000,
  "Duration must be greater than 0 and less than or equal to 900000 milliseconds."),
        assert(!(mode == TurnstileMode.invisible && refreshExpired == TurnstileRefreshExpired.manual),
        "$refreshExpired is impossible in $mode, consider using TurnstileRefreshExpired.auto or TurnstileRefreshExpired.never"),
        assert(!(mode == TurnstileMode.invisible && refreshTimeout != TurnstileRefreshTimeout.auto),
        "$refreshTimeout has no effect on an $mode widget."),
        assert(!(mode == TurnstileMode.nonInteractive && refreshTimeout != TurnstileRefreshTimeout.auto),
        "$refreshTimeout has no effect on an $mode widget.");
}

enum TurnstileMode { managed, nonInteractive, invisible }

enum TurnstileSize {
  normal(300, 65),
  compact(130, 120);

  final double width;
  final double height;
  const TurnstileSize(this.width, this.height);
}

enum TurnstileTheme { auto, dark, light }

enum TurnstileRefreshExpired { auto, manual, never }

enum TurnstileRefreshTimeout { auto, manual, never }

//function
typedef OnTokenRecived = Function(String token);
typedef OnTokenExpired = Function();
typedef OnError = Function(String error);

class CloudFlareTurnstile extends StatefulWidget {
  /// This [siteKey] is associated with the corresponding widget configuration
  /// and is created upon the widget creation.
  ///
  /// It`s likely generated or obtained from the CloudFlare dashboard.
  @override
  final String siteKey;

  /// A customer value that can be used to differentiate widgets under the
  /// same sitekey in analytics and which is returned upon validation.
  ///
  /// This can only contain up to 32 alphanumeric characters including _ and -.
  @override
  final String? action;

  /// A customer payload that can be used to attach customer data to the
  /// challenge throughout its issuance and which is returned upon validation.
  ///
  /// This can only contain up to 255 alphanumeric characters including _ and -.
  @override
  final String? cData;

  /// A base url of turnstile Site
  @override
  final String baseUrl;

  /// A Turnstile widget options
  @override
  final TurnstileOptions options;

  /// A controller for an Turnstile widget
  @override
  final TurnstileController? controller;

  /// A Callback invoked upon success of the challange.
  /// The callback is passed a [token] that can be validated.
  ///
  /// example:
  /// ```dart
  /// CloudFlareTurnstile(
  ///   siteKey: '0x000000000000000000000',
  ///   onTokenRecived: (String token) {
  ///     print('Token: $token');
  ///   },
  /// ),
  /// ```
  @override
  final OnTokenRecived? onTokenRecived;

  /// A Callback invoke when the token expires and does not
  /// reset the widget.
  ///
  /// example:
  /// ```dart
  /// CloudFlareTurnstile(
  ///   siteKey: '0x000000000000000000000',
  ///   onTokenExpired: () {
  ///     print('Token Expired');
  ///   },
  /// ),
  /// ```
  @override
  final OnTokenExpired? onTokenExpired;

  /// A Callback invoke when there is an error
  /// (e.g network error or challange failed).
  ///
  /// example:
  /// ```dart
  /// CloudFlareTurnstile(
  ///   siteKey: '0x000000000000000000000',
  ///   onError: (String error) {
  ///     print('Error: $error');
  ///   },
  /// ),
  /// ```
  ///
  /// Refer to [Client-side errors](https://developers.cloudflare.com/turnstile/troubleshooting/client-side-errors/).
  @override
  final OnError? onError;

  CloudFlareTurnstile({
    super.key,
    required this.siteKey,
    this.action,
    this.cData,
    this.baseUrl = 'http://localhost/',
    TurnstileOptions? options,
    this.controller,
    this.onTokenRecived,
    this.onTokenExpired,
    this.onError,
  }) : options = options ?? TurnstileOptions() {
    if (action != null) {
      assert(
      action!.length <= 32 && RegExp(r'^[a-zA-Z0-9_-]*$').hasMatch(action!),
      'action must be contain up to 32 characters including _ and -.',
      );
    }

    if (cData != null) {
      assert(
      cData!.length <= 32 && RegExp(r'^[a-zA-Z0-9_-]*$').hasMatch(cData!),
      'action must be contain up to 32 characters including _ and -.',
      );
    }
  }

  @override
  State<CloudFlareTurnstile> createState() => _CloudFlareTurnstileState();
}

class _CloudFlareTurnstileState extends State<CloudFlareTurnstile> {
  late String data;

  late WebViewController _controller;

  String? widgetId;

  bool _isWidgetReady = false;

  void _initController() {
    _controller = WebViewController()
        ..addJavaScriptChannel(appFunctionBridge,
            onMessageReceived: (message) {
              _handleJavaScriptChannel(message.message);
            },
        )
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(
          onPageFinished: (String url) {
            _registerJavaScriptChannel();
          }
        ))
        ..loadRequest(Uri.parse(widget.baseUrl));
  }

  @override
  void initState() {
    _initController();
    super.initState();
  }

  void _handleJavaScriptChannel(String message) {
    Map data = jsonDecode(message);

    switch (data['method']) {
      case "TurnstileToken":
        widget.controller?.newToken = data['value'];
        widget.onTokenRecived?.call(data['value']);
        break;
      case "TurnstileError":
        widget.onError?.call(data['value']);
        break;
      case "TurnstileWidgetId":
        widgetId = data['value'];
        widget.controller?.widgetId = data['value'];
        break;
      case "TurnstileReady":
        setState(() {
          _isWidgetReady = data['value'];
        });
        break;
      case "TokenExpired":
        widget.onTokenExpired?.call();
        break;
    }
  }

  void _registerJavaScriptChannel() {
    StringBuffer jsStrBuffer = StringBuffer();

    ///TurnstileToken
    jsStrBuffer.write("$appFunctionPrefix.TurnstileToken = function (){ ");
    jsStrBuffer.write(
        "  $appFunctionBridge.postMessage(JSON.stringify({\"method\":\"TurnstileToken\"\"value\":\"true\"}));");
    jsStrBuffer.write("};");

    ///TurnstileError
    jsStrBuffer.write("$appFunctionPrefix.TurnstileError = function (){ ");
    jsStrBuffer.write(
        "  $appFunctionBridge.postMessage(JSON.stringify({\"method\":\"TurnstileError\"\"value\":\"token\"}));");
    jsStrBuffer.write("};");

    ///TurnstileWidgetId
    jsStrBuffer.write("$appFunctionPrefix.TurnstileWidgetId = function (){ ");
    jsStrBuffer.write(
        "  $appFunctionBridge.postMessage(JSON.stringify({\"method\":\"TurnstileWidgetId\"\"value\":\"code\"}));");
    jsStrBuffer.write("};");

    ///TurnstileReady
    jsStrBuffer.write("$appFunctionPrefix.TurnstileReady = function (){ ");
    jsStrBuffer.write(
        "  $appFunctionBridge.postMessage(JSON.stringify({\"method\":\"TurnstileReady\"}));");
    jsStrBuffer.write("};");

    ///TokenExpired
    jsStrBuffer.write("$appFunctionPrefix.TokenExpired = function (){ ");
    jsStrBuffer.write(
        "  $appFunctionBridge.postMessage(JSON.stringify({\"method\":\"TokenExpired\"\"value\":\"widgetId\"}));");
    jsStrBuffer.write("};");

    _controller.runJavaScript(jsStrBuffer.toString());
  }

  final double _borderWidth = 2.0;

  Widget get _view => WebViewWidget(controller: _controller);

  @override
  Widget build(BuildContext context) {
    return switch (widget.options.mode) {
      TurnstileMode.invisible => SizedBox.shrink(child: _view),
      _ => AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: _isWidgetReady ? widget.options.size.width + _borderWidth : 0,
        height: _isWidgetReady ? widget.options.size.height + _borderWidth : 0,
        child: _view,
      ),
    };
  }
}