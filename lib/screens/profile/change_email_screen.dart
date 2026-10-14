import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instrutor_em_casa/screens/base_screen.dart';
import 'package:instrutor_em_casa/widgets/dialog_services.dart';
import 'package:ionicons/ionicons.dart';

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  bool _loading = false;

  Future<void> _updateEmail() async {
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
      await user.verifyBeforeUpdateEmail(_emailController.text.trim());

      if (mounted) {
        DialogServices().alertDialog(
          context,
          "Um link de verificação foi enviado para seu novo e-mail. Por favor, verifique sua caixa de entrada para concluir a alteração. Após confirmar, você precisará fazer login com o novo e-mail.",
          title: "Verificação Enviada",
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
      String message = "Erro ao atualizar e-mail";
      if (e.code == 'wrong-password') message = "Senha atual incorreta.";
      if (e.code == 'requires-recent-login') message = "Esta operação requer um login recente.";
      if (e.code == 'invalid-email') message = "O e-mail informado é inválido.";
      if (e.code == 'email-already-in-use') message = "Este e-mail já está sendo utilizado por outra conta.";
      
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
        title: const Text("Alterar E-mail"),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              "Por segurança, informe sua senha atual para confirmar a alteração do e-mail.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Senha Atual",
                prefixIcon: Icon(Ionicons.lockClosedOutline),
              ),
              validator: (value) => value!.isEmpty ? "Informe a senha atual" : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Novo E-mail",
                prefixIcon: Icon(Ionicons.mailOutline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return "Informe o novo e-mail";
                if (!value.contains("@")) return "Informe un e-mail válido";
                return null;
              },
            ),
            const SizedBox(height: 40),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _loading ? null : _updateEmail,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Confirmar Alteração de E-mail"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
