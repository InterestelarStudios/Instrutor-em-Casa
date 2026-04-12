// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:instrutor_em_casa/models/usuario.dart';

class Mensagem {
  String id;
  String chatId;
  UserDetails user;
  Timestamp date;
  String message;

  Mensagem({
    required this.id,
    required this.chatId,
    required this.user,
    required this.date,
    required this.message,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'chatId': chatId,
      'user': user.toMap(),
      'date': date,
      'message': message,
    };
  }

  factory Mensagem.fromMap(Map<String, dynamic> map) {
    return Mensagem(
      id: map['id'] as String,
      chatId: map['chatId'] as String,
      user: UserDetails.fromMap(map['user'] as Map<String,dynamic>),
      date: map['date'] as Timestamp,
      message: map['message'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory Mensagem.fromJson(String source) => Mensagem.fromMap(json.decode(source) as Map<String, dynamic>);
}

/// Representa um item na lista de conversas recentes
class Conversa {
  String id;
  List<UserDetails> users;
  List usersId;
  Mensagem? ultimaMensagem;
  int mensagensNaoLidas;

  Conversa({
    required this.id,
    required this.users,
    required this.usersId,
    this.ultimaMensagem,
    required this.mensagensNaoLidas,
  });



  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'users': users.map((x) => x.toMap()).toList(),
      'usersId': usersId,
      'ultimaMensagem': ultimaMensagem?.toMap(),
    };
  }

  factory Conversa.fromMap(Map<String, dynamic> map, String myUserId) {
    return Conversa(
      id: map['id'] as String,
      users: map['users'].map<UserDetails>((e)=> UserDetails.fromMap(e)).toList(),
      usersId: List.from((map['usersId'] as List)),
      ultimaMensagem: map["ultimaMensagem"] != null ? Mensagem.fromMap(map['ultimaMensagem'] as Map<String,dynamic>) : null,
      mensagensNaoLidas: map[myUserId] == null ? 0 : map[myUserId] as int,
    );
  }
}
