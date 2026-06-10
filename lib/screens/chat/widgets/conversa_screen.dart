// Arquivo: lib/screens/chat_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instrutor_em_casa/models/chat.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/widgets/avatar.dart';
import 'package:instrutor_em_casa/widgets/theme.dart';

class TelaConversa extends StatefulWidget {
  final Usuario usuario;
  final Conversa chat;

  const TelaConversa({
    super.key,
    required this.usuario,
    required this.chat,
  });

  @override
  State<TelaConversa> createState() => _TelaConversaState();
}

class _TelaConversaState extends State<TelaConversa> {
  late final Query<Mensagem> query;
  late UserDetails myUser;
  late UserDetails otherUser;
  final TextEditingController _controladorTexto = TextEditingController();
  final ScrollController _controladorScroll = ScrollController();
  late final Conversa chat;

  void addListeners(){
    query = FirebaseFirestore.instance
    .collection("messages")
    .where("chatId", isEqualTo: chat.id)
    .orderBy("date", descending: true)
    .withConverter(fromFirestore: (snapshot, options)=> Mensagem.fromMap(snapshot.data()!), toFirestore: (snapshot, options)=> {});
  }

  void read(){
    if(chat.id.isEmpty) return;
    FirebaseFirestore.instance.collection("chats").doc(chat.id).update({
      myUser.id : 0,
    });
  }

  @override
  void initState() {
    super.initState();
    chat = widget.chat;
    addListeners();
    myUser = widget.chat.users.where((e)=> e.id == widget.usuario.id).first;
    otherUser = widget.chat.users.where((e)=> e.id != widget.usuario.id).first;
    read();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ListTile(
          contentPadding: const EdgeInsets.only(),
          leading: UserAvatar(user: otherUser, radius: 40,),
          title: Text(otherUser.name, style: Theme.of(context).textTheme.titleLarge,),
          subtitle: Text(otherUser.type!.name),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: FirestoreListView(
              query: query,
              controller: _controladorScroll,
              padding: const EdgeInsets.all(20),
              reverse: true,
              emptyBuilder: (context)=> emptyBuilder(),
              itemBuilder: (context, snapshot){
                final message = snapshot.data();
                return messageWidget(message, message.user.id == myUser.id);
              }
            ),
          ),
          _construirAreaInput(),
        ],
      ),
    );
  }

  // Exibido quando a conversa não tem nenhuma mensagem ainda
  Widget emptyBuilder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nenhuma mensagem ainda.\nEnvie um "Olá" para !',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget messageWidget(Mensagem mensagem, bool isMinha) {
    return Align(
      alignment: isMinha ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(isMinha ? 50 : 20),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMinha ? 16 : 0),
            bottomRight: Radius.circular(isMinha ? 0 : 16),
          ),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              isMinha ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              mensagem.message,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              "${mensagem.date.toDate().hour.toString().padLeft(2, '0')}:${mensagem.date.toDate().minute.toString().padLeft(2, '0')}",
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirAreaInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controladorTexto,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Digite uma mensagem...',
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.teal,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: (){
                  if(_controladorTexto.text.isNotEmpty){
                    final messageFirestore = FirebaseFirestore.instance.collection("messages").doc();

                    final message = Mensagem(
                      id: messageFirestore.id,
                      chatId: chat.id,
                      user: myUser,
                      date: Timestamp.now(),
                      message: _controladorTexto.text,
                    );

                    if(chat.id.isEmpty){
                      final chatFirestore = FirebaseFirestore.instance.collection("chats").doc();
                      chat.id = chatFirestore.id;
                      message.chatId = chat.id;
                      chat.ultimaMensagem = message;
                      final chatMap = chat.toMap();
                      chatMap.addAll({otherUser.id : FieldValue.increment(1)});
                      chatFirestore.set(chatMap);
                      setState(() {
                        addListeners();
                      });
                    } else {
                      FirebaseFirestore.instance.collection("chats").doc(chat.id).update({
                        "ultimaMensagem" : message.toMap(),
                        otherUser.id : FieldValue.increment(1),
                      });
                    }

                    messageFirestore.set(message.toMap());
                  }
                  _controladorTexto.clear();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}