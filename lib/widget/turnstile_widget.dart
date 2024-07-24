import 'package:flutter_turnstile/controller/turnstile_controller.dart';
import 'package:flutter_turnstile/data/html_data.dart';
import 'package:flutter_turnstile/options/turnstile_options.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

///app function bridge
const String appFunctionBridge = "BossJobAppBridge";
const String appFunctionPrefix = "BossJobApp";

///CloudFlareTurnstile
class CloudFlareTurnstile extends StatefulWidget {
  /// This [siteKey] is associated with the corresponding widget configuration
  /// and is created upon the widget creation.
  ///
  /// It`s likely generated or obtained from the CloudFlare dashboard.
  final String siteKey;

  /// A customer value that can be used to differentiate widgets under the
  /// same sitekey in analytics and which is returned upon validation.
  ///
  /// This can only contain up to 32 alphanumeric characters including _ and -.
  final String? action;

  /// A customer payload that can be used to attach customer data to the
  /// challenge throughout its issuance and which is returned upon validation.
  ///
  /// This can only contain up to 255 alphanumeric characters including _ and -.
  final String? cData;

  /// A base url of turnstile Site
  final String baseUrl;

  /// A Turnstile widget options
  final TurnstileOptions options;

  /// A controller for an Turnstile widget
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
  final OnTokenRecived? onTokenReceived;

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
  final OnError? onError;

  CloudFlareTurnstile({
    super.key,
    required this.siteKey,
    this.action,
    this.cData,
    this.baseUrl = 'https://www.baidu.com/',
    TurnstileOptions? options,
    this.controller,
    this.onTokenReceived,
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

///CloudFlareTurnstile state
class _CloudFlareTurnstileState extends State<CloudFlareTurnstile> {
  ///the data used to load
  late String data;

  late WebViewController _controller;

  String? widgetId;

  bool _isWidgetReady = false;

  final String _readyJSHandler = "$appFunctionBridge.postMessage(JSON.stringify({\"method\":\"TurnstileReady\"}));";
  final String _tokenReceivedJSHandler = "$appFunctionBridge.postMessage(JSON.stringify({\"method\":\"TurnstileToken\",\"value\":token}));";
  final String _errorJSHandler = "$appFunctionBridge.postMessage(JSON.stringify({\"method\":\"TurnstileError\",\"value\":code}));";
  final String _tokenExpiredJSHandler = "$appFunctionBridge.postMessage(JSON.stringify({\"method\":\"TokenExpired\"}));";
  final String _widgetCreatedJSHandler =
      "$appFunctionBridge.postMessage(JSON.stringify({\"method\":\"TurnstileWidgetId\",\"value\":widgetId}));";

  void _initData() {
    data = htmlData(
      siteKey: widget.siteKey,
      action: widget.action,
      cData: widget.cData,
      options: widget.options,
      onTurnstileReady: _readyJSHandler,
      onTokenReceived: _tokenReceivedJSHandler,
      onTurnstileError: _errorJSHandler,
      onTokenExpired: _tokenExpiredJSHandler,
      onWidgetCreated: _widgetCreatedJSHandler,
    );
  }

  void _initController() {
    _controller = WebViewController()
      ..addJavaScriptChannel(
        appFunctionBridge,
        onMessageReceived: (message) {
          _handleJavaScriptChannel(message.message);
        },
      )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(onPageFinished: (String url) {
        ///_registerJavaScriptChannel();
      }));
    _controller.loadHtmlString(data, baseUrl: widget.baseUrl);
  }

  @override
  void initState() {
    _initData();
    _initController();
    super.initState();
  }

  void _handleJavaScriptChannel(String message) {
    Map data = jsonDecode(message);

    /*switch (data['method']) {
      case "TurnstileToken":
        widget.controller?.newToken = data['value'];
        widget.onTokenReceived?.call(data['value']);
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
    }*/
  }

  void _registerJavaScriptChannel() {
    StringBuffer jsStrBuffer = StringBuffer();

    ///TurnstileToken
    jsStrBuffer.write("$appFunctionPrefix.TurnstileToken = function (){ ");
    jsStrBuffer.write("  $appFunctionBridge.postMessage(JSON.stringify({\"method\":\"TurnstileToken\",\"value\":\"true\"}));");
    jsStrBuffer.write("};");

    ///TurnstileError
    jsStrBuffer.write("$appFunctionPrefix.TurnstileError = function (){ ");
    jsStrBuffer.write("  $appFunctionBridge.postMessage(JSON.stringify({\"method\":\"TurnstileError\"\"value\":\"token\"}));");
    jsStrBuffer.write("};");

    ///TurnstileWidgetId
    jsStrBuffer.write("$appFunctionPrefix.TurnstileWidgetId = function (){ ");
    jsStrBuffer.write("  $appFunctionBridge.postMessage(JSON.stringify({\"method\":\"TurnstileWidgetId\"\"value\":\"code\"}));");
    jsStrBuffer.write("};");

    ///TurnstileReady
    jsStrBuffer.write("$appFunctionPrefix.TurnstileReady = function (){ ");
    jsStrBuffer.write("  $appFunctionBridge.postMessage(JSON.stringify({\"method\":\"TurnstileReady\"}));");
    jsStrBuffer.write("};");

    ///TokenExpired
    jsStrBuffer.write("$appFunctionPrefix.TokenExpired = function (){ ");
    jsStrBuffer.write("  $appFunctionBridge.postMessage(JSON.stringify({\"method\":\"TokenExpired\"\"value\":\"widgetId\"}));");
    jsStrBuffer.write("};");

    _controller.runJavaScript(jsStrBuffer.toString());
  }

  final double _borderWidth = 2.0;

  Widget get _view => WebViewWidget(controller: _controller);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 100,
      child: _view,
    );
    /*return switch (widget.options.mode) {
      TurnstileMode.invisible => SizedBox.shrink(child: _view),
      _ => AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: _isWidgetReady ? widget.options.size.width + _borderWidth : 0,
        height: _isWidgetReady ? widget.options.size.height + _borderWidth : 0,
        child: _view,
      ),
    };*/
  }
}
