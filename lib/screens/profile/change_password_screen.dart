import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instrutor_em_casa/screens/base_screen.dart';
import 'package:instrutor_em_casa/widgets/dialog_services.dart';
import 'package:ionicons/ionicons.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  bool _loading = false;

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Reautenticação obrigatória para operações sensíveis
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_passwordController.text.trim());

      if (mounted) {
        DialogServices().alertDialog(
          context,
          "Sua senha foi atualizada. Por segurança, você precisa fazer login novamente.",
          title: "Sucesso!",
          onTap1: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const BaseScreen()),
              (route) => false,
            );
          },
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = "Erro ao atualizar senha";
      if (e.code == 'wrong-password') message = "Senha atual incorreta.";
      if (e.code == 'requires-recent-login') message = "Esta operação requer um login recente.";
      if (e.code == 'weak-password') message = "A nova senha é muito fraca.";
      
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
        title: const Text("Alterar Senha"),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              "Por segurança, informe sua senha atual para confirmar a alteração da senha.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Senha Atual",
                prefixIcon: Icon(Ionicons.lock_closed_outline),
              ),
              validator: (value) => value!.isEmpty ? "Informe a senha atual" : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Nova Senha",
                prefixIcon: Icon(Ionicons.key_outline),
              ),
              validator: (value) => value!.length < 6 ? "A senha deve ter pelo menos 6 caracteres" : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Confirmar Nova Senha",
                prefixIcon: Icon(Ionicons.key_outline),
              ),
              validator: (value) {
                if (value != _passwordController.text) return "As senhas não coincidem";
                return null;
              },
            ),
            const SizedBox(height: 40),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _loading ? null : _updatePassword,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Confirmar Alteração de Senha"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
