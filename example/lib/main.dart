import 'package:flutter/material.dart';
import 'package:flutter_turnstile/widget/turnstile_widget.dart';
import 'package:flutter_turnstile/controller/turnstile_controller.dart';
import 'package:flutter_turnstile/options/turnstile_options.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TurnstileController _controller = TurnstileController();
  final TurnstileOptions _options = TurnstileOptions(
    size: TurnstileSize.normal,
    theme: TurnstileTheme.light,
    refreshExpired: TurnstileRefreshExpired.manual,
    language: 'zh',
    retryAutomatically: false,
  );

  String? _token;

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(

              ///自动撑开
              child: Container(
            color: Colors.red,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: CloudFlareTurnstile(
              siteKey: '3x00000000000000000000FF',
              // baseUrl: "https://dev.api.bossjob.com",
              baseUrl: "https://www.baidu.com",
              options: _options,
              controller: _controller,
              onTokenReceived: (token) {
                setState(() {
                  _token = token;
                });
              },
              onWidgetBeforeInteractive: (){
                print("AAAAAA");
              },
              onWidgetAfterInteractive: (){
                print("BBBBBB");
              },
              onTokenExpired: () {},
              onError: (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error)),
                );
              },
            ),
          )),
        ),
      ),
    );
  }
}
