import 'package:flutter_turnstile/controller/turnstile_controller.dart';
import 'package:flutter_turnstile/options/turnstile_options.dart';
import 'package:flutter_turnstile/data/html_data.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

///app function bridge
const String appFunctionBridge = "BossJobAppBridge";
const String appFunctionPrefix = "BossJobApp";

///CloudFlareTurnstile
class CloudFlareTurnstile extends StatefulWidget {
  /// siteKey 参数用于传递给html data中的Js代码
  final String siteKey;

  /// action 参数同上，具体含义查询JS Turnstile 文档
  final String? action;

  /// A customer payload that can be used to attach customer data to the
  /// challenge throughout its issuance and which is returned upon validation.
  /// This can only contain up to 255 alphanumeric characters including _ and -.
  /// 同上
  final String? cData;

  /// A base url of turnstile Site，基础URL
  final String baseUrl;

  /// A Turnstile widget options 参数配置类，类中又区分了不少东西
  final TurnstileOptions options;

  /// A controller for an Turnstile widget 控制器用于控制view做操作
  final TurnstileController? controller;

  /// token接收到的回调代码块，外部传入，内部接收到回调后执行此回调通知外部
  final OnTokenReceived? onTokenReceived;

  /// token 过期的回调，同上
  final OnTokenExpired? onTokenExpired;

  ///这里是我们多加的一个回调事件，用户widget ready
  final VoidCallback? onWidgetReady;

  ///这里是我们多加的一个回调事件，BeforeInteractive
  final VoidCallback? onWidgetBeforeInteractive;

  ///这里是我们多加的一个回调事件，AfterInteractive
  final VoidCallback? onWidgetAfterInteractive;

  /// 错误的回调，同上
  final OnError? onError;

  CloudFlareTurnstile({
    super.key,
    required this.siteKey,
    this.action,
    this.cData,
    this.baseUrl = 'http://localhost/',
    TurnstileOptions? options,
    this.controller,
    this.onTokenReceived,
    this.onTokenExpired,
    this.onWidgetReady,
    this.onWidgetBeforeInteractive,
    this.onWidgetAfterInteractive,
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
  ///webView 的控制器，用于控制webView
  late WebViewController _webViewController;

  ///下方是字符串，这个字符串其实是一段js代码，用于和htmlData拼接，最终成为一个完整的html文件以供webView加载
  final String _onReadyHandler = "$appFunctionBridge.postMessage(JSON.stringify({\"method\":\"TurnstileReady\",\"value\":\"true\"}));";
  final String _onBeforeHandler =
      "$appFunctionBridge.postMessage(JSON.stringify({\"method\":\"TurnstileBeforeInteractive\",\"value\":\"true\"}));";
  final String _onAfterHandler =
      "$appFunctionBridge.postMessage(JSON.stringify({\"method\":\"TurnstileAfterInteractive\",\"value\":\"true\"}));";
  final String _onTokenHandler = "$appFunctionBridge.postMessage(JSON.stringify({\"method\":\"TurnstileToken\",\"value\":token}));";
  final String _onErrorHandler = "$appFunctionBridge.postMessage(JSON.stringify({\"method\":\"TurnstileError\",\"value\":code}));";
  final String _onExpireHandler = "$appFunctionBridge.postMessage(JSON.stringify({\"method\":\"TokenExpired\"}));";
  final String _onCreatedHandler = "$appFunctionBridge.postMessage(JSON.stringify({\"method\":\"TurnstileWidgetId\",\"value\":widgetId}));";

  ///首先进行controller的初始化，以便于控制webView
  void _initController() {
    _webViewController = WebViewController()

      ///添加JavaScript交互，官方插件提供的方法，供交互
      ..addJavaScriptChannel(
        appFunctionBridge,
        onMessageReceived: (message) {
          _handleJavaScriptChannel(message.message);
        },
      )

      ///transparent
      ..setBackgroundColor(const Color(0x00000000))

      /// JavaScript execution is not restricted.(开启js,不限制js)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)

      ///设置navigation的代理
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (NavigationRequest request) async {
          ///intent
          if (request.url.contains("www.cloudflare.com") || request.url.contains("www.cloudflare-cn.com")) {
            if (request.url.contains("privacypolicy") || request.url.contains("website-terms") || request.url.contains("products")) {
              launchUrl(Uri.parse(request.url));
              return NavigationDecision.prevent;
            }
          }
          return NavigationDecision.navigate;
        },
      ));

    ///这里还有个点，这里定义的_controller 是用来控制webView的，它是不会向外部暴露的，而我们其实需要通过widget中的TurnstileController来控制webView内部的一些展示，
    ///所以需要将_controller 给到 widget.controller这个TurnstileController类型的控制器
    ///相当于TurnstileController控制器通过一个设置进去的代理控制器控制内部webView的一个动作
    ///但是这样设置之后又存在一些小问题，就是之前提到的，万一哪个傻用户在外部的State中，重新搞了个controller,就会导致这个新的controller中没有设置setConnector
    ///这就需要在didUpdateWidget中做一些处理，这样更符合flutter的规范，如果不处理，正常情况下也不会存在问题，但如果遇到上方的情况，使用者会懵逼
    ///这里有点类似代理模式
    widget.controller?.setConnector(_webViewController);
  }

  ///初始化html数据，因为我们改为了异步加载，所以需要在文件读取完成之后
  void _initHtmlData() {
    htmlData(
      siteKey: widget.siteKey,
      action: widget.action,
      cData: widget.cData,
      options: widget.options,
      onTurnstileReady: _onReadyHandler,
      onBeforeInteractive: _onBeforeHandler,
      onAfterInteractive: _onAfterHandler,
      onTokenReceived: _onTokenHandler,
      onTurnstileError: _onErrorHandler,
      onTokenExpired: _onExpireHandler,
      onWidgetCreated: _onCreatedHandler,
    ).then((data) {
      ///then中返回的就是htmlData这个方法中耗时操作完成后得到的拼接字符串
      if (mounted) {
        _webViewController.loadHtmlString(data, baseUrl: widget.baseUrl);
      }
    });
  }

  @override
  void didUpdateWidget(CloudFlareTurnstile oldWidget) {
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.setConnector(null);
      widget.controller?.setConnector(_webViewController);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _webViewController.loadRequest(Uri.parse('about:blank'));
    _webViewController.removeJavaScriptChannel(appFunctionBridge);
    widget.controller?.setConnector(null);
    super.dispose();
  }

  @override
  void initState() {
    _initController();
    _initHtmlData();
    super.initState();
  }

  ///handle function
  void _handleJavaScriptChannel(String message) {
    ///disposed
    if (!mounted) {
      return;
    }

    ///解析我们传过来的json字符串为map
    Map data = jsonDecode(message);

    switch (data['method']) {
      case "TurnstileToken":

        ///获取到token，data['value'],为了防止极小可能出现的类型问题，这里加上一个toString
        String token = data['value'].toString();

        ///将获取到的token传给controller保存起来
        widget.controller?.newToken = token;

        ///执行回调,告诉外部token获取到了
        widget.onTokenReceived?.call(token);
        break;
      case "TurnstileError":

        ///错误的回调，通知外部有异常
        widget.onError?.call(data['value'].toString());
        break;
      case "TurnstileWidgetId":

        ///获取到widget ID,当前state拿它没什么用，就直接删掉了，但是控制器中需要保存一下，这个widgetId是html的js代码中turnstile.render这个方法回传的id
        ///后续会使用它控制webView加载的html中的控件，所以我们直接保存在控制器中
        widget.controller?.widgetId = data['value'];
        break;
      case "TurnstileReady":

        ///Turnstile ready的回调，我们没用同样直接通知到外部，之前的_isWidgetReady代码是之前用来在当前界面做动画的我们暂时没有用到就先删了
        widget.onWidgetReady?.call();
        break;
      case "TurnstileBeforeInteractive":

        ///before interactive回调
        widget.onWidgetBeforeInteractive?.call();
        break;
      case "TurnstileAfterInteractive":

        ///after interactive回调
        widget.onWidgetAfterInteractive?.call();
        break;
      case "TokenExpired":

        ///token过期的回调
        widget.onTokenExpired?.call();
        break;
    }
  }

  ///get view
  Widget get _view => WebViewWidget(controller: _webViewController);

  @override
  Widget build(BuildContext context) {
    ///这里是主要的buildView ，分析trunstile.html 中的TURNSTILE_SIZE 及之前传递的 options.size.name 我们可以认为目前这html就只支持两种大小，
    ///normal和compact，所以我们这里暂时只能使用它的大小。
    return SizedBox(
      width: widget.options.size.width,
      height: widget.options.size.height,
      child: _view,
    );
  }
}
