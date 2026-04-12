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
  Map? geo;

  Usuario({
    required this.id,
    required this.name,
    required this.email,
    required this.data,
    required this.created,
    this.type,
    this.image,
    this.instrutor,
    this.geo,
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
      'geo' : geo,
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
      image: map['image'] != null ? map['type'] as String: null,
      instrutor: map['instrutor'] != null ? InstrutorData.fromMap(map['instrutor']): null,
      geo: map['geo'] != null ? map['geo'] as Map : null,
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
