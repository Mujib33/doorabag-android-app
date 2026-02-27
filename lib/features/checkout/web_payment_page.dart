// lib/features/checkout/web_payment_page.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebPaymentPage extends StatefulWidget {
  const WebPaymentPage({
    super.key,
    required this.url,
    required this.title,
  });

  final String url;
  final String title;

  @override
  State<WebPaymentPage> createState() => _WebPaymentPageState();
}

class _WebPaymentPageState extends State<WebPaymentPage> {
  late final WebViewController _wc;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _wc = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p),
          onPageFinished: (u) {
            // Yahan aap success/cancel URL detect karke pop kar sakte ho.
            // e.g. if (u.contains('/thank-you') || u.contains('payment=success')) { ... }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          WebViewWidget(controller: _wc),
          if (_progress > 0 && _progress < 100)
            LinearProgressIndicator(value: _progress / 100),
        ],
      ),
    );
  }
}
