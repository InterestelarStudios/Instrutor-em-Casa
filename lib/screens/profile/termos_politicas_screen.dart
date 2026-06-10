import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TermosPoliticasScreen extends StatefulWidget {
  const TermosPoliticasScreen({super.key});

  @override
  State<TermosPoliticasScreen> createState() => _TermosPoliticasScreenState();
}

class _TermosPoliticasScreenState extends State<TermosPoliticasScreen> {
  late final WebViewController controller;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    // Exemplo de URL de PDF hospedado. Substituir pelo link real dos termos.
    // O Google Docs Viewer é uma forma comum de exibir PDFs em WebView.
    const String pdfUrl = "https://www.adobe.com/support/products/enterprise/knowledgecenter/pdfs/oat_install_guide.pdf";
    const String viewerUrl = "https://docs.google.com/gview?embedded=true&url=$pdfUrl";

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() => loading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(viewerUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Termos e Políticas"),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (loading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
