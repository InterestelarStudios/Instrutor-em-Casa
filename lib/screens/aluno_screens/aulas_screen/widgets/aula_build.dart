import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instrutor_em_casa/models/aula.dart';
import 'package:instrutor_em_casa/models/chat.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/screens/aula_details/aula_details_screen.dart';
import 'package:instrutor_em_casa/screens/chat/widgets/conversa_screen.dart';
import 'package:instrutor_em_casa/widgets/avatar.dart';
import 'package:instrutor_em_casa/widgets/chip.dart';
import 'package:instrutor_em_casa/widgets/dialog_services.dart';
import 'package:instrutor_em_casa/widgets/theme.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

class AulaBuild extends StatelessWidget {
  const AulaBuild({super.key, required this.aula, required this.usuario});
  final Aula aula;
  final Usuario usuario;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ()=> Navigator.push(
        context, MaterialPageRoute(
          builder: (_)=> AulaDetailsScreen(aula: aula, usuario: usuario)
        )
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.only(bottom: 10),
                leading: UserAvatar(
                  user: aula.instrutor
                ),
                title: Text(aula.instrutor.name, style: Theme.of(context).textTheme.titleLarge,),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Builder(
                      builder: (context) {
                        String dateFormated(String type){
                          return DateFormat(type).format(aula.date.toDate());
                        }
                        return Text("${dateFormated(DateFormat.MONTH_DAY)} às ${dateFormated(DateFormat.HOUR24_MINUTE)}h");
                      }
                    ),
                    const SizedBox(height: 5),
                    Text("Pacote: ${aula.horasContratadas}h (${aula.horasRestantes}h restantes)", 
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primary)),
                  ],
                ),
                trailing: AppChip(title: "Cat. ${aula.category.name}", circle: false,),
              ),
              const Divider(),
              SizedBox(height: 10,),
              Row(
                children: [
                  CircleAvatar(radius: 3, backgroundColor: aula.statusColor(),),
                  SizedBox(width: 5,),
                  Expanded(
                    child: Text(aula.statusValue(), style: TextStyle(color: aula.statusColor()),),
                  ),
                  SizedBox(width: 10,),
                  if(aula.status == LessonStatus.accepted)
                  ElevatedButton.icon(
                    onPressed: () async {
                      DialogServices.loading2(context);
                      final query = await FirebaseFirestore.instance.collection("chats")
                      .where("usersId", arrayContains: aula.aluno.id).get();
                      
                      final chatDoc = query.docs.where((doc) => (doc.data()['usersId'] as List).contains(aula.instrutor.id)).firstOrNull;

                      if (context.mounted) Navigator.pop(context);
                      
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context)=> TelaConversa(
                              usuario: usuario,
                              chat: chatDoc != null ?
                              Conversa.fromMap(chatDoc.data(), usuario.id):
                              Conversa(
                                id: "",
                                users: [aula.aluno, aula.instrutor],
                                usersId: [aula.aluno.id, aula.instrutor.id],
                                mensagensNaoLidas: 0
                              ),
                            ),
                          ),
                        );
                      }
                    },
                    icon: Icon(Ionicons.chatbox_outline),
                    label: Text("Acessar chat")
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}