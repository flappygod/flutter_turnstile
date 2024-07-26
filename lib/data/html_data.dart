import 'package:flutter_turnstile/options/turnstile_options.dart';

///define html
String htmlData({
  required String siteKey,
  String? action,
  String? cData,
  required TurnstileOptions options,
  required String onTurnstileReady,
  required String onTokenReceived,
  required String onTurnstileError,
  required String onTokenExpired,
  required String onWidgetCreated,
}) {
  RegExp exp = RegExp(
      r'<TURNSTILE_(SITE_KEY|ACTION|CDATA|THEME|SIZE|LANGUAGE|RETRY|RETRY_INTERVAL|REFRESH_EXPIRED|REFRESH_TIMEOUT|READY|TOKEN_RECEIVED|ERROR|TOKEN_EXPIRED|CREATED)>');
  String? replacedText = _source.replaceAllMapped(exp, (match) {
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

String _source = """
<!DOCTYPE html>
<html lang="en">

<head>
   <meta charset="UTF-8">
   <meta name="viewport"
      content="width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0">
   <script src="https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit"></script>
</head>

<body>
   <div id="cf-turnstile"></div>
   <script>
   
      function renderWidgets(){
        <TURNSTILE_READY>
         const widgetId = turnstile.render('#cf-turnstile', {
            sitekey: '<TURNSTILE_SITE_KEY>',
            action: '<TURNSTILE_ACTION>',
            cData: '<TURNSTILE_CDATA>',
            theme: '<TURNSTILE_THEME>',
            size: '<TURNSTILE_SIZE>',
            language: '<TURNSTILE_LANGUAGE>',
            retry: '<TURNSTILE_RETRY>',
            'retry-interval': parseInt('<TURNSTILE_RETRY_INTERVAL>'),
            'refresh-expired': '<TURNSTILE_REFRESH_EXPIRED>',
            'refresh-timeout': '<TURNSTILE_REFRESH_TIMEOUT>',
            callback: function (token) {
               <TURNSTILE_TOKEN_RECEIVED>
            },
            'error-callback': function (code) {
               <TURNSTILE_ERROR>
            },
            'expired-callback': function () {
               <TURNSTILE_TOKEN_EXPIRED>
            }
         });
         <TURNSTILE_CREATED>
      };
      
      
      function checkReadyToRender(){
         turnstile.ready(function () {
         if(BossJobAppBridge.postMessage){
           renderWidgets();
         }else{
           setTimeout(() => {
              checkReadyToRender();
              }, 200);
         }
         });
      };
   
   
      checkReadyToRender();
      
   </script>
   <style>
      * {
         overflow: hidden;
         margin: 0;
         padding: 0;
      }
   </style>
</body>

</html>
""";
