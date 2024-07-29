import 'package:flutter_turnstile/options/turnstile_options.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

///define html
Future<String> htmlData({
  required String siteKey,
  String? action,
  String? cData,
  required TurnstileOptions options,
  required String onTurnstileReady,
  required String onBeforeInteractive,
  required String onAfterInteractive,
  required String onTokenReceived,
  required String onTurnstileError,
  required String onTokenExpired,
  required String onWidgetCreated,
}) async {
  ///正则匹配TURNSTILE_*类型的文本，分case进行替换
  RegExp exp = RegExp(
      r'<TURNSTILE_(SITE_KEY|ACTION|CDATA|THEME|SIZE|LANGUAGE|RETRY|RETRY_INTERVAL|REFRESH_EXPIRED|REFRESH_TIMEOUT|READY|BEFORE_INTERACTIVE|AFTER_INTERACTIVE|TOKEN_RECEIVED|ERROR|TOKEN_EXPIRED|CREATED)>');

  ///为了更直观，我们直接将source提出去到trunstile.html文件中去，然后在代码中把它加载进来，当然你得知道其路径。,因为这里是耗时操作，所以我们使用了 async ,返回也是Future<String>
  ByteData bytes =
      await rootBundle.load("packages/flutter_turnstile/data/trunstile.html");

  // 将 ByteData 转换为 Uint8List
  Uint8List uint8list = bytes.buffer.asUint8List();

  ///替换之后的text
  String? replacedText = utf8.decode(uint8list).replaceAllMapped(exp, (match) {
    switch (match.group(1)) {
      case 'SITE_KEY':
        return siteKey;
      case 'ACTION':
        return action ?? '';
      case 'CDATA':
        return cData ?? '';
      case 'THEME':
        return options.theme.name;
      case 'SIZE':
        return options.size.name;
      case 'LANGUAGE':
        return options.language;
      case 'RETRY':
        return options.retryAutomatically ? 'auto' : 'never';
      case 'RETRY_INTERVAL':
        return options.retryInterval.inMilliseconds.toString();
      case 'REFRESH_EXPIRED':
        return options.refreshExpired.name;
      case 'REFRESH_TIMEOUT':
        return options.refreshTimeout.name;
      case 'READY':
        return onTurnstileReady;
      case 'BEFORE_INTERACTIVE':
        return onBeforeInteractive;
      case 'AFTER_INTERACTIVE':
        return onAfterInteractive;
      case 'TOKEN_RECEIVED':
        return onTokenReceived;
      case 'ERROR':
        return onTurnstileError;
      case 'TOKEN_EXPIRED':
        return onTokenExpired;
      case 'CREATED':
        return onWidgetCreated;
      default:
        return match.group(0) ?? "";
    }
  });

  return replacedText;
}
