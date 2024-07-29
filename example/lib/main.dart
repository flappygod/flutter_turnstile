import 'package:flutter/material.dart';
import 'package:flutter_turnstile/flutter_turnstile.dart';

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
    mode: TurnstileMode.managed,
    size: TurnstileSize.normal,
    theme: TurnstileTheme.light,
    language: 'zh',
    retryAutomatically: true,
    refreshTimeout: TurnstileRefreshTimeout.manual,
  );


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
              //siteKey: '3x00000000000000000000FF',
              //baseUrl: "https://www.baidu.com",
              siteKey: '0x4AAAAAAAJDRnSb5DfsUd2S',
              baseUrl: "https://dev.api.bossjob.com",
              options: _options,
              controller: _controller,
              onTokenReceived: (token) {

              },
              onWidgetReady: (){
                print("onWidgetReady");
              },
              onWidgetBeforeInteractive: (){
                print("AAAAAA");
              },
              onWidgetAfterInteractive: (){
                print("BBBBBB");
              },
              onTokenExpired: () {},
              onError: (error) {
                /*ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error)),
                );*/
              },
            ),
          )),
        ),
      ),
    );
  }
}
