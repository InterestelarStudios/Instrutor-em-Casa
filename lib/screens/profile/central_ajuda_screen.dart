import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:url_launcher/url_launcher.dart';

class CentralAjudaScreen extends StatelessWidget {
  const CentralAjudaScreen({super.key});

  final String emailSuporte = "suporte@instrutoremcasa.com.br";
  final String whatsappSuporte = "5592991185307"; // Número atualizado
  final String telefoneSuporte = "92991185307";

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: emailSuporte,
      query: 'subject=Suporte Instrutor em Casa',
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }

  Future<void> _launchWhatsApp() async {
    final String url = "https://wa.me/$whatsappSuporte?text=Olá, preciso de ajuda com o app Instrutor em Casa.";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: telefoneSuporte);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Central de Ajuda"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "Como podemos ajudar você hoje?",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            "Escolha um dos canais abaixo para entrar em contato com nossa equipe de suporte.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              onTap: _launchWhatsApp,
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Ionicons.logo_whatsapp, color: Colors.white),
              ),
              title: const Text("WhatsApp"),
              subtitle: const Text("Fale conosco agora mesmo"),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              onTap: _launchPhone,
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Ionicons.call_outline, color: Colors.white),
              ),
              title: const Text("Ligar agora"),
              subtitle: const Text("(92) 99118-5307"),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              onTap: _launchEmail,
              leading: const CircleAvatar(
                backgroundColor: Colors.grey,
                child: Icon(Ionicons.mail_outline, color: Colors.white),
              ),
              title: const Text("E-mail"),
              subtitle: Text(emailSuporte),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        ],
      ),
    );
  }
}
