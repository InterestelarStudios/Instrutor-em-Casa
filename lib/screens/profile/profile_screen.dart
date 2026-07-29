import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/screens/base_screen.dart';
import 'package:instrutor_em_casa/screens/profile/central_ajuda_screen.dart';
import 'package:instrutor_em_casa/screens/profile/change_email_screen.dart';
import 'package:instrutor_em_casa/screens/profile/change_password_screen.dart';
import 'package:instrutor_em_casa/screens/profile/delete_account_screen.dart';
import 'package:instrutor_em_casa/screens/profile/edit_profile_screen.dart';
import 'package:instrutor_em_casa/screens/profile/favoritos_screen.dart';
import 'package:instrutor_em_casa/screens/profile/my_documents_screen.dart';
import 'package:instrutor_em_casa/screens/profile/historico_cobrancas_screen.dart';
import 'package:instrutor_em_casa/screens/profile/horas_direcao_screen.dart';
import 'package:instrutor_em_casa/screens/profile/termos_politicas_screen.dart';
import 'package:instrutor_em_casa/widgets/avatar.dart';
import 'package:instrutor_em_casa/widgets/dialog_services.dart';
import 'package:instrutor_em_casa/widgets/stars.dart';
import 'package:instrutor_em_casa/widgets/theme.dart';
import 'package:ionicons/ionicons.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.usuario});
  final Usuario usuario;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final bool isAluno = widget.usuario.type == UserType.aluno;

    return ListView(
      children: [
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Padding(
            padding: const EdgeInsetsGeometry.all(20),
            child: Row(
              children: [
                UserAvatar(user: widget.usuario.toDetails()),
                Expanded(
                  child: ListTile(
                    title: Text(
                      widget.usuario.name,
                      style: Theme.of(context).textTheme.displaySmall,
                      maxLines: 1,
                    ),
                    subtitle: Row(
                      children: [
                        StarRating(stars: 4.2, size: 15).build(context),
                        const SizedBox(width: 10),
                        Text(
                          "4.2",
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "(8 aulas)",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        title("Minha conta"),
        ListTile(
          leading: Icon(Ionicons.pencil_outline),
          title: Text("Editar Perfil"),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditProfileScreen(usuario: widget.usuario),
            ),
          ),
        ),
        ListTile(
          leading: Icon(Ionicons.document_outline),
          title: Text("Meus Documentos"),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MyDocumentsScreen(usuario: widget.usuario),
            ),
          ),
        ),
        ListTile(
          leading: Icon(Ionicons.key_outline),
          title: Text("Alterar Senha"),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
          ),
        ),
        ListTile(
          leading: Icon(Ionicons.mail_outline),
          title: Text("Alterar E-mail"),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChangeEmailScreen()),
          ),
        ),
        title("Aulas"),
        if (isAluno) ...[
          ListTile(
            leading: const Icon(Ionicons.time_outline),
            title: const Text("Horas de direção"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HorasDirecaoScreen(usuario: widget.usuario),
              ),
            ),
          ),
        ],
        ListTile(
          leading: Icon(Ionicons.star_outline),
          title: Text("Minhas avaliações"),
        ),
        if (isAluno) ...[
          ListTile(
            leading: const Icon(Ionicons.heart_outline),
            title: const Text("Instrutores Favoritos"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FavoritosScreen(usuario: widget.usuario),
              ),
            ),
          ),
        ],
        title("Pagamentos"),
        ListTile(
          leading: Icon(Ionicons.card_outline),
          title: Text("Meus cartões"),
        ),
        ListTile(
          leading: const Icon(Ionicons.receipt_outline),
          title: const Text("Histórico de Cobranças"),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HistoricoCobrancasScreen(usuario: widget.usuario),
            ),
          ),
        ),
        title("Suporte"),
        ListTile(
          leading: Icon(Ionicons.help_outline),
          title: Text("Central de Ajuda"),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CentralAjudaScreen()),
          ),
        ),
        ListTile(
          leading: Icon(Ionicons.information_circle_outline),
          title: Text("Termos e Políticas"),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TermosPoliticasScreen()),
          ),
        ),
        ListTile(
          leading: Icon(Ionicons.phone_portrait_outline),
          title: Text("Avaliar o App"),
        ),
        title("Conta"),
        ListTile(
          onTap: () {
            DialogServices().alertDialog(
              context,
              "Deseja Encerrar sua sessão?",
              title: "Tem certeza?",
              buttonTitle1: "Encerrar Sessão",
              buttonTitle2: "Cancelar",
              colorButton1: Colors.black,
              colorButton2: Colors.grey,
              onTap2: () => Navigator.pop(context),
              onTap1: () {
                Navigator.pop(context);
                FirebaseAuth.instance.signOut().then((_) {
                  Navigator.pushAndRemoveUntil(
                    // ignore: use_build_context_synchronously
                    context,
                    MaterialPageRoute(builder: (_) => BaseScreen()),
                    (predicate) => false,
                  );
                });
              },
            );
          },
          title: Text("Encerrar Sessão"),
          leading: Icon(Ionicons.log_out_outline),
        ),
        ListTile(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DeleteAccountScreen(usuario: widget.usuario),
            ),
          ),
          leading: Icon(
            Ionicons.phone_portrait_outline,
            color: AppColors.emergency,
          ),
          title: Text(
            "Excluir Conta",
            style: TextStyle(color: AppColors.emergency),
          ),
        ),
      ],
    );
  }

  Widget title(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
