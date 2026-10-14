import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/screens/base_screen.dart';
import 'package:instrutor_em_casa/widgets/dialog_services.dart';
import 'package:ionicons/ionicons.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key, required this.usuario});
  final Usuario usuario;

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _deleteAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. Reautenticação (obrigatória para deletar conta)
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _passwordController.text,
      );
      await user.reauthenticateWithCredential(credential);

      // 2. Apagar foto do Storage (se houver)
      if (widget.usuario.image != null && widget.usuario.image!.contains("firebase")) {
        try {
          await FirebaseStorage.instance.ref("profile_pics/${widget.usuario.id}").delete();
        } catch (e) {
          debugPrint("Erro ao deletar imagem: $e");
        }
      }

      // 3. Apagar dados do Firestore
      await FirebaseFirestore.instance.collection("users").doc(widget.usuario.id).delete();

      // 4. Apagar conta do Auth
      await user.delete();

      if (mounted) {
        DialogServices().alertDialog(
          context,
          "Sua conta e todos os seus dados foram removidos permanentemente.",
          title: "Conta Excluída",
          onTap1: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const BaseScreen()),
              (route) => false,
            );
          },
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = "Erro ao excluir conta";
      if (e.code == 'wrong-password') message = "Senha incorreta.";
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Excluir Conta"),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Ionicons.warningOutline, size: 80, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              "Esta ação é irreversível!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 20),
            const Text(
              "Ao excluir sua conta, todos os seus dados, histórico de aulas e fotos serão removidos permanentemente de nossos servidores.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Confirme sua senha para continuar",
                prefixIcon: Icon(Ionicons.lockClosedOutline),
              ),
              validator: (value) => value!.isEmpty ? "Informe sua senha" : null,
            ),
            const SizedBox(height: 40),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _deleteAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("EXCLUIR MINHA CONTA AGORA"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
