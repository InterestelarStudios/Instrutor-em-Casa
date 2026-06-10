import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instrutor_em_casa/models/chat.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/screens/chat/widgets/conversa_screen.dart';
import 'package:instrutor_em_casa/widgets/avatar.dart';

class ConversasScreen extends StatefulWidget {
  const ConversasScreen({super.key, required this.usuario});
  final Usuario usuario;

  @override
  State<ConversasScreen> createState() => _ConversasScreenState();
}

class _ConversasScreenState extends State<ConversasScreen> with AutomaticKeepAliveClientMixin{
  late Query<Conversa> query;

  @override
  void initState() {
    super.initState();
    query = FirebaseFirestore.instance
    .collection("chats")
    .where("usersId", arrayContains: widget.usuario.id)
    .orderBy("ultimaMensagem.date", descending: true)
    .withConverter(fromFirestore: (snapshot, options)=> Conversa.fromMap(snapshot.data()!, widget.usuario.id), toFirestore: (snapshot, options)=> {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text("Chat", style: Theme.of(context).textTheme.displayMedium,),
        const SizedBox(height: 20,),
        FirestoreListView(
          query: query,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          emptyBuilder: (context) => Card(
            margin: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            elevation: 0,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                child: Icon(Icons.chat_bubble_outline_rounded, color: Theme.of(context).primaryColor, size: 20,),
              ),
              title: const Text(
                "Nenhuma conversa",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "Suas mensagens aparecerão aqui assim que você iniciar um chat.",
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
          ),
          itemBuilder: (context, snapshot) {
            final conversa = snapshot.data();
            return chatBuild(conversa);
          },
        )
      ],
    );
  }

  Widget chatBuild(Conversa conversa){
    final otherUser = conversa.users.where((e)=> e.id != widget.usuario.id).first;
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        leading: UserAvatar(user: otherUser),
        title: Text(
          otherUser.name,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        subtitle: conversa.ultimaMensagem == null ? null :
        Text(
          "${conversa.ultimaMensagem!.user.id == widget.usuario.id ? "Você: " : ""}${conversa.ultimaMensagem!.message}",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: conversa.mensagensNaoLidas > 0 ? Colors.black : Colors.grey,
            fontWeight: conversa.mensagensNaoLidas > 0 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (conversa.ultimaMensagem != null)
            Text(
              "${conversa.ultimaMensagem!.date.toDate().hour.toString().padLeft(2, '0')}:${conversa.ultimaMensagem!.date.toDate().minute.toString().padLeft(2, '0')}",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            if (conversa.mensagensNaoLidas > 0)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.teal,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  conversa.mensagensNaoLidas.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        onTap: () {
          // Navegar para conversa existente
          // Aqui você passaria as mensagens reais carregadas do banco.
          // Para o mock, passamos apenas a última como exemplo.
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TelaConversa(
                usuario: widget.usuario,
                chat: conversa
              ),
            ),
          );
        },
      ),
    );
  }
  
  @override
  bool get wantKeepAlive => true;

}