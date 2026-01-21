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

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            _callSnap();
          },
          onNavigationRequest: (request) {
            // Tangkap redirect status
            if (request.url.contains('success')) {
              Get.back(result: 'success');
            }
            if (request.url.contains('pending')) {
              Get.back(result: 'pending');
            }
            if (request.url.contains('error')) {
              Get.back(result: 'failed');
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(_htmlSnap(widget.snapToken));
  }

  void _callSnap() {
    _controller.runJavaScript("""
      snap.pay('${widget.snapToken}', {
        onSuccess: function(result){
          window.location.href = 'success';
        },
        onPending: function(result){
          window.location.href = 'pending';
        },
        onError: function(result){
          window.location.href = 'error';
        },
        onClose: function(){
          window.location.href = 'closed';
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
