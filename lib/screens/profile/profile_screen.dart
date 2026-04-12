import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/screens/base_screen.dart';
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
                    title: Text(widget.usuario.name, style: Theme.of(context).textTheme.displaySmall, maxLines: 1,),
                    subtitle: Row(
                      children: [
                        StarRating(stars: 4.2, size: 15,).build(context),
                        const SizedBox(width: 10,),
                        Text("4.2", style: Theme.of(context).textTheme.titleSmall,),
                        const SizedBox(width: 5,),
                        Text("(8 aulas)", style: Theme.of(context).textTheme.bodySmall,)
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
        ),
        ListTile(
          leading: Icon(Ionicons.document_outline),
          title: Text("Meus Documentos"),
        ),
        ListTile(
          leading: Icon(Ionicons.key_outline),
          title: Text("Alterar Senha"),
        ),
        ListTile(
          leading: Icon(Ionicons.mail_outline),
          title: Text("Alterar E-mail"),
        ),
        title("Aulas"),
        ListTile(
          leading: Icon(Ionicons.time_outline),
          title: Text("Horas de direção"),
        ),
        ListTile(
          leading: Icon(Ionicons.star_outline),
          title: Text("Minhas avaliações"),
        ),
        ListTile(
          leading: Icon(Ionicons.heart_outline),
          title: Text("Instrutores Favoritos"),
        ),
        title("Pagamentos"),
        ListTile(
          leading: Icon(Ionicons.card_outline),
          title: Text("Meus cartões"),
        ),
        ListTile(
          leading: Icon(Ionicons.receipt_outline),
          title: Text("Histórico de Cobranças"),
        ),
        title("Suporte"),
        ListTile(
          leading: Icon(Ionicons.help_outline),
          title: Text("Central de Ajuda"),
        ),
        ListTile(
          leading: Icon(Ionicons.information_circle_outline),
          title: Text("Termos e Políticas"),
        ),
        ListTile(
          leading: Icon(Ionicons.phone_portrait_outline),
          title: Text("Avaliar o App"),
        ),
        title("Conta"),
        ListTile(
          onTap: (){
            DialogServices().alertDialog(
              context,
              "Deseja Encerrar sua sessão?",
              title: "Tem certeza?",
              buttonTitle1: "Encerrar Sessão",
              buttonTitle2: "Cancelar",
              colorButton1: Colors.black,
              colorButton2: Colors.grey,
              onTap2: ()=> Navigator.pop(context),
              onTap1: (){
                Navigator.pop(context);
                FirebaseAuth.instance.signOut()
                .then((_){
                  Navigator.pushAndRemoveUntil(
                    // ignore: use_build_context_synchronously
                    context,
                    MaterialPageRoute(builder: (_)=> BaseScreen()),
                    (predicate)=> false
                  );
                });
              }
            );
          },
          title: Text("Encerrar Sessão"),
          leading: Icon(Ionicons.log_out_outline),
        ),
        ListTile(
          leading: Icon(Ionicons.phone_portrait_outline, color: AppColors.emergency),
          title: Text("Excluir Conta", style: TextStyle(color: AppColors.emergency),),
        ),
      ],
    );
  }

  Widget title(String text){
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text("Minha conta", style: Theme.of(context).textTheme.bodySmall),
    );
  }
}