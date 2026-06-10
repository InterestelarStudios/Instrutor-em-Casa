// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:instrutor_em_casa/models/instrutor.dart';

enum UserType {aluno, instrutor}
enum UserGenre {masculino, feminino}

class Usuario {

  String id;
  String name;
  UserData data;
  String email;
  UserType? type;
  Timestamp created;
  String? image;
  InstrutorData? instrutor;
  AlunoData? aluno;
  Map? geo;
  String? inLesson;
  int notificationsCount;
  String? asaasId;
  String? walletId;
  PendingAvaliation? pendingAvaliation;
  String? about;

  Usuario({
    required this.id,
    required this.name,
    required this.email,
    required this.data,
    required this.created,
    this.type,
    this.image,
    this.instrutor,
    this.aluno,
    this.geo,
    this.inLesson,
    this.notificationsCount = 0,
    this.asaasId,
    this.walletId,
    this.pendingAvaliation,
    this.about,
  });

  UserDetails toDetails(){
    return UserDetails(
      id: id,
      name: name,
      type: type,
      image: image,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'data' : data.toMap(),
      'created': created,
      'type': type?.name,
      'image': image,
      'instrutor': instrutor?.toMap(),
      'aluno': aluno?.toMap(),
      'geo' : geo,
      'inLesson' : inLesson,
      'notificationsCount' : notificationsCount,
      'asaasId' : asaasId,
      'walletId' : walletId,
      'pendingAvaliation' : pendingAvaliation?.toMap(),
      'about' : about,
    };
  }

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      data: UserData.fromMap(map['data']),
      created: map['created'] as Timestamp,
      type: map['type'] != null ? UserType.values.where((e)=> e.name == map['type']).first : null,
      image: map['image'] != null ? map['image'] as String: null,
      instrutor: map['instrutor'] != null ? InstrutorData.fromMap(map['instrutor']): null,
      aluno: map['aluno'] != null ? AlunoData.fromMap(map['aluno']): null,
      geo: map['geo'] != null ? map['geo'] as Map : null,
      inLesson: map['inLesson'] as String?,
      notificationsCount: map['notificationsCount'] as int? ?? 0,
      asaasId: map['asaasId'] as String?,
      walletId: map['walletId'] as String?,
      pendingAvaliation: map['pendingAvaliation'] != null ? PendingAvaliation.fromMap(map['pendingAvaliation'] as Map<String,dynamic>) : null,
      about: map['about'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory Usuario.fromJson(String source) => Usuario.fromMap(json.decode(source) as Map<String, dynamic>);
}


class UserData {

  Timestamp birth;
  String cpf;
  String phone;
  UserGenre genre;
  
  UserData({
    required this.birth,
    required this.cpf,
    required this.phone,
    required this.genre,
  });


  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'birth': birth,
      'cpf': cpf,
      'phone': phone,
      'genre': genre.name,
    };
  }

  factory UserData.fromMap(Map<String, dynamic> map) {
    return UserData(
      birth: map['birth'] as Timestamp,
      cpf: map['cpf'] as String,
      phone: map['phone'] as String,
      genre: UserGenre.values.where((e)=> e.name == map['genre']).first,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserData.fromJson(String source) => UserData.fromMap(json.decode(source) as Map<String, dynamic>);
}

class AlunoData {
  UserDocument? ladv;
  UserDocument? cnh;

  AlunoData({
    this.ladv,
    this.cnh,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ladv': ladv?.toMap(),
      'cnh': cnh?.toMap(),
    };
  }

  factory AlunoData.fromMap(Map<String, dynamic> map) {
    return AlunoData(
      ladv: map['ladv'] != null ? UserDocument.fromMap(map['ladv'] as Map<String,dynamic>) : null,
      cnh: map['cnh'] != null ? UserDocument.fromMap(map['cnh'] as Map<String,dynamic>) : null,
    );
  }
}

class UserDetails {

  String id;
  String name;
  UserType? type;
  String? image;

  UserDetails({
    required this.id,
    required this.name,
    required this.type,
    this.image,
  });


  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'type': type?.name,
      'image': image,
    };
  }

  factory UserDetails.fromMap(Map<String, dynamic> map) {
    return UserDetails(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] != null ? UserType.values.where((e)=> e.name == map['type']).first : null,
      image: map['image'] != null ? map['image'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserDetails.fromJson(String source) => UserDetails.fromMap(json.decode(source) as Map<String, dynamic>);
}

class PendingAvaliation {
  final String lessonId;
  final String targetUserId;
  final String targetUserName;
  final String? targetUserImage;

  PendingAvaliation({
    required this.lessonId,
    required this.targetUserId,
    required this.targetUserName,
    this.targetUserImage,
  });

  Map<String, dynamic> toMap() {
    return {
      'lessonId': lessonId,
      'targetUserId': targetUserId,
      'targetUserName': targetUserName,
      'targetUserImage': targetUserImage,
    };
  }

  factory PendingAvaliation.fromMap(Map<String, dynamic> map) {
    return PendingAvaliation(
      lessonId: map['lessonId'] ?? '',
      targetUserId: map['targetUserId'] ?? '',
      targetUserName: map['targetUserName'] ?? '',
      targetUserImage: map['targetUserImage'],
    );
  }
}
