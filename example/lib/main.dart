import 'package:flutter/material.dart';
import 'package:selfsign_webview_flutter/selfsign_webview_flutter.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  final TextEditingController _urlController = TextEditingController(
    text: 'https://example.com/sign',
  );
  final List<String> _events = <String>[];

  @override
  void initState() {
    super.initState();
    SelfsignWebView.onJsBridgeCall.listen((event) {
      setState(() {
        _events.insert(
          0,
          '[${DateTime.now().toIso8601String()}] '
          '${event.method}: ${event.payload}',
        );
        if (_events.length > 50) _events.removeLast();
      });
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _openFullscreen() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    await SelfsignWebView.open(
      url: url,
      appType: 'PatientAPP02',
      title: '簽署',
      confirmBeforeBack: true,
    );
  }

  void _openEmbedded() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Embedded WebView')),
        body: SelfsignWebViewWidget(
          url: url,
          appType: 'PatientAPP02',
          onJsBridgeCall: (event) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('JS bridge: ${event.method}')),
            );
          },
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'selfsign_webview_flutter example',
      home: Scaffold(
        appBar: AppBar(title: const Text('selfsign_webview_flutter')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Sign page URL',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _openFullscreen,
                child: const Text('Open full-screen WebView'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _openEmbedded,
                child: const Text('Open embedded (PlatformView) WebView'),
              ),
              const SizedBox(height: 16),
              const Text('JS bridge events:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: _events.length,
                  itemBuilder: (_, i) => Text(_events[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
