import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:get/get.dart';

class SnapPaymentPage extends StatefulWidget {
  final String snapToken;

  const SnapPaymentPage({super.key, required this.snapToken});

  @override
  State<SnapPaymentPage> createState() => _SnapPaymentPageState();
}

class _SnapPaymentPageState extends State<SnapPaymentPage> {
  late final WebViewController _controller;
  bool _snapCalled = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'SnapChannel',
        onMessageReceived: (message) {
          final status = message.message;
          Get.back(result: status);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            if (!_snapCalled) {
              _snapCalled = true;
              _callSnap();
            }
          },
        ),
      )
      ..loadHtmlString(_htmlSnap(widget.snapToken));
  }

  void _callSnap() {
    _controller.runJavaScript("""
      snap.pay('${widget.snapToken}', {
        onSuccess: function(result){
          SnapChannel.postMessage('success');
        },
        onPending: function(result){
          SnapChannel.postMessage('pending');
        },
        onError: function(result){
          SnapChannel.postMessage('failed');
        },
        onClose: function(){
          SnapChannel.postMessage('closed');
        }
      });
    """);
  }

  String _htmlSnap(String token) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <script src="https://app.sandbox.midtrans.com/snap/snap.js"
          data-client-key="Mid-client-mEFo-UlRTyeILwaG"></script>
</head>
<body>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: WebViewWidget(controller: _controller),
    );
  }
}
