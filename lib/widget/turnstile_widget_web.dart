// ignore_for_file: avoid_web_libraries_in_flutter
import 'package:flutter_turnstile/controller/turnstile_controller_web.dart';
import 'package:flutter_turnstile/options/turnstile_options.dart';
import 'package:flutter_turnstile/data/html_data.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'dart:js' as js;
import 'dart:convert';
import 'dart:async';

/// CloudFlareTurnstile widget
class CloudFlareTurnstile extends StatefulWidget {
  /// Site key for the Turnstile service
  final String siteKey;

  /// Action parameter for the Turnstile service
  final String? action;

  /// Custom payload for the Turnstile service
  final String? cData;

  /// Base URL for the Turnstile service
  final String baseUrl;

  /// Options for configuring the Turnstile widget
  final TurnstileOptions options;

  /// Controller for managing the Turnstile widget
  final TurnstileController? controller;

  /// Callback when a token is received
  final OnTokenReceived? onTokenReceived;

  /// Callback when a token expires
  final OnTokenExpired? onTokenExpired;

  /// Callback when the widget is ready
  final VoidCallback? onWidgetReady;

  /// Callback before the widget becomes interactive
  final VoidCallback? onWidgetBeforeInteractive;

  /// Callback after the widget becomes interactive
  final VoidCallback? onWidgetAfterInteractive;

  /// Callback for errors
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
    //Validate action parameter
    if (action != null) {
      assert(
        action!.length <= 32 && RegExp(r'^[a-zA-Z0-9_-]*$').hasMatch(action!),
        'Action must contain up to 32 characters including _ and -.',
      );
    }

    //Validate cData parameter
    if (cData != null) {
      assert(
        cData!.length <= 255 && RegExp(r'^[a-zA-Z0-9_-]*$').hasMatch(cData!),
        'cData must contain up to 255 characters including _ and -.',
      );
    }
  }

  @override
  State<CloudFlareTurnstile> createState() => _CloudFlareTurnstileState();
}

class _CloudFlareTurnstileState extends State<CloudFlareTurnstile> {
  //IFrame element to display the Turnstile widget
  late html.IFrameElement iframe;

  //Unique view type for the IFrame
  late String iframeViewType;

  //Subscription for IFrame load events
  late StreamSubscription<dynamic> iframeOnLoadSubscription;

  //JavaScript window object for communication
  late js.JsObject jsWindowObject;

  //Flag to check if the widget is interactive
  late bool _isWidgetInteractive;

  //Height of the widget
  late double _widgetHeight = widget.options.size.height;

  //JavaScript to Dart connector function name
  final String _jsToDartConnectorFN = 'connect_js_to_flutter';

  //ID for the Turnstile widget
  String? widgetId;

  //Flag to check if the widget is ready
  bool _isWidgetReady = false;

  @override
  void initState() {
    super.initState();

    //Determine if the widget is interactive based on the mode
    _isWidgetInteractive = widget.options.mode == TurnstileMode.managed;

    //Set theme based on platform brightness
    if (widget.options.theme == TurnstileTheme.auto) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final brightness = MediaQuery.of(context).platformBrightness;
        widget.options.theme = (brightness == Brightness.dark)
            ? TurnstileTheme.dark
            : TurnstileTheme.light;
      });
    }

    //Create a unique view type and IFrame element
    iframeViewType = _createViewType();
    iframe = _createIFrame();

    //Connect JavaScript to Flutter
    _connectJsToFlutter();
    _registerView(iframeViewType);

    //Update the IFrame source and register load callback
    Future.delayed(Duration.zero, () {
      _updateSource();
      _registerIframeOnLoadCallBack();
    });
  }

  /// Creates a unique view type for the IFrame
  String _createViewType() {
    final iframeId = '_${DateTime.now().microsecondsSinceEpoch}';
    return '_iframe$iframeId';
  }

  /// Creates the IFrame element for the Turnstile widget
  html.IFrameElement _createIFrame() {
    return html.IFrameElement()
      ..id = 'id_$iframeViewType'
      ..name = 'name_$iframeViewType'
      ..style.border = 'none'
      ..width = widget.options.size.width.toString()
      ..height = widget.options.size.height.toString()
      ..style.width = '100%'
      ..style.height = '100%'
      // Title for accessibility
      ..title = 'CloudFlare_Turnstile';
  }

  /// Registers a callback for when the IFrame loads
  void _registerIframeOnLoadCallBack() {
    iframeOnLoadSubscription = iframe.onLoad.listen((event) async {
      Future.delayed(Duration.zero, _detectWidgetMode);
    });
  }

  /// Detects the widget mode and updates the state accordingly
  Future<void> _detectWidgetMode() async {
    if (widget.options.mode == TurnstileMode.auto) {
      final result =
          jsWindowObject.callMethod('eval', ['getWidgetDimensions();']);
      await Future.value(result).then((val) {
        final size = jsonDecode(val as String);
        final height = size['height'] as double;

        setState(() {
          // Check if the widget has visible content
          _isWidgetInteractive = height > 0;
          // Update widget height
          _widgetHeight = height;
          // Mark widget as ready
          _isWidgetReady = true;
        });
      });
    } else {
      // Mark widget as ready if not in auto mode
      setState(() => _isWidgetReady = true);
    }
    // Update controller state
    widget.controller?.isReady = _isWidgetReady;
  }

  /// Connects JavaScript functions to Flutter for communication
  void _connectJsToFlutter() {
    js.context['$_jsToDartConnectorFN$iframeViewType'] = (js.JsObject window) {
      // Store the JavaScript window object
      jsWindowObject = window;

      // Define JavaScript callbacks for various events
      jsWindowObject['TurnstileReady'] = (message) {
        // Call the widget ready callback
        widget.onWidgetReady?.call();
      };

      jsWindowObject['TurnstileBeforeInteractive'] = (message) {
        // Call before interactive callback
        widget.onWidgetBeforeInteractive?.call();
      };

      jsWindowObject['TurnstileAfterInteractive'] = (message) {
        // Call after interactive callback
        widget.onWidgetAfterInteractive?.call();
      };

      jsWindowObject['TurnstileToken'] = (String message) {
        // Update the controller with the new token
        widget.controller?.newToken = message;
        // Call the token received callback
        widget.onTokenReceived?.call(message);
      };

      jsWindowObject['TurnstileError'] = (String message) {
        // Call the error callback
        widget.onError?.call(message);
      };

      jsWindowObject['TokenExpired'] = (message) {
        // Call the token expired callback
        widget.onTokenExpired?.call();
      };

      jsWindowObject['TurnstileWidgetId'] = (String message) {
        // Store the widget ID
        widgetId = message;
        // Update the controller with the widget ID
        widget.controller?.widgetId = message;
      };

      // Set the connector in the controller
      widget.controller?.setConnector(jsWindowObject);
    };
  }

  /// Registers the view type for the IFrame
  void _registerView(String viewType) {
    ui.platformViewRegistry
        .registerViewFactory(viewType, (int viewId) => iframe);
  }

  /// JavaScript handler strings for various events
  final String _onReadyHandler = "TurnstileReady();";
  final String _onBeforeHandler = "TurnstileBeforeInteractive();";
  final String _onAfterHandler = "TurnstileAfterInteractive();";
  final String _onTokenHandler = "TurnstileToken(token);";
  final String _onErrorHandler = "TurnstileError(code);";
  final String _onExpireHandler = "TokenExpired();";
  final String _onCreatedHandler = "TurnstileWidgetId(widgetId);";

  /// Updates the source of the IFrame with the HTML data
  void _updateSource() {
    htmlData(
      siteKey: widget.siteKey,
      action: widget.action,
      cData: widget.cData,
      options: widget.options,
      type: "web",
      onTurnstileReady: _onReadyHandler,
      onBeforeInteractive: _onBeforeHandler,
      onAfterInteractive: _onAfterHandler,
      onTokenReceived: _onTokenHandler,
      onTurnstileError: _onErrorHandler,
      onTokenExpired: _onExpireHandler,
      onWidgetCreated: _onCreatedHandler,
    ).then((data) {
      // Set the IFrame source
      iframe.srcdoc = _embedWebIframeJsConnector(data, iframeViewType);
    });
  }

  ///Embeds the JavaScript connector into the HTML source
  String _embedWebIframeJsConnector(String source, String windowDisambiguator) {
    return _embedJsInHtmlSource(
      source,
      {
        'parent.$_jsToDartConnectorFN$windowDisambiguator && parent.$_jsToDartConnectorFN$windowDisambiguator(window)'
      },
    );
  }

  /// Embeds JavaScript content into the HTML source
  String _embedJsInHtmlSource(String source, Set<String> jsContents) {
    const newLine = '\n';
    const scriptOpenTag = '<script>';
    const scriptCloseTag = '</script>';
    //Join JavaScript contents
    final jsContent = jsContents.join(newLine * 2);

    //Create the script tag with embedded JavaScript
    final whatToEmbed =
        '$newLine$scriptOpenTag$newLine$jsContent$newLine$scriptCloseTag$newLine';
    //Find the end of the head section
    final indexToSplit = source.indexOf('</head>');
    //Get the head section
    final splitSource1 = source.substring(0, indexToSplit);
    //Get the rest of the source
    final splitSource2 = source.substring(indexToSplit);
    //Return the combined source
    return '$splitSource1$whatToEmbed\n$splitSource2';
  }

  //Create the HTML element view for the IFrame
  late final Widget _view = HtmlElementView(
    key: widget.key,
    viewType: iframeViewType,
  );

  @override
  void dispose() {
    //Cancel the load subscription
    iframeOnLoadSubscription.cancel();
    //Remove the IFrame element
    iframe.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //Build the widget based on whether it is interactive
    return _isWidgetInteractive
        ? SizedBox(
            width: widget.options.size.width,
            height: widget.options.size.height,
            child: AbsorbPointer(
              child: RepaintBoundary(
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  maxWidth: widget.options.size.width,
                  maxHeight: _widgetHeight,
                  //Display the IFrame view
                  child: _view,
                ),
              ),
            ),
          )
        : SizedBox(
            //Minimal size if not interactive
            width: 0.01,
            height: 0.01,
            //Still render the IFrame
            child: _view,
          );
  }
}
