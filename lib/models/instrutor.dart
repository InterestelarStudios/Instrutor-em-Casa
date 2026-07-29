// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:instrutor_em_casa/models/vehicle.dart';

enum CNHCategory {A, B, C, D, E}

class InstrutorData {

  bool active;
  UserDocument credencial;
  UserDocument face;
  List<CNHCategory> categories;
  String? about;
  num aulas;
  num horas;
  String? asaasStatus;
  num rating;
  int ratingCount;
  Vehicle? defaultVehicle;
  String? pixKeyType;
  String? pixKey;
  
  InstrutorData({
    required this.active,
    required this.credencial,
    required this.face,
    required this.categories,
    this.about,
    required this.aulas,
    required this.horas,
    this.asaasStatus,
    this.rating = 5.0,
    this.ratingCount = 0,
    this.defaultVehicle,
    this.pixKeyType,
    this.pixKey,
  });


  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'active': active,
      'credencial': credencial.toMap(),
      'face': face.toMap(),
      'categories': categories.map((x) => x.name).toList(),
      'about': about,
      'aulas': aulas,
      'horas': horas,
      'asaasStatus': asaasStatus,
      'rating': rating,
      'ratingCount': ratingCount,
      'defaultVehicle': defaultVehicle?.toMap(),
      'pixKeyType': pixKeyType,
      'pixKey': pixKey,
    };
  }

  factory InstrutorData.fromMap(Map<String, dynamic> map) {
    return InstrutorData(
      active: map['active'] as bool,
      credencial: UserDocument.fromMap(map['credencial'] as Map<String,dynamic>),
      face: UserDocument.fromMap(map['face'] as Map<String,dynamic>),
      categories: map['categories'].map<CNHCategory>((value)=> CNHCategory.values.where((e)=> e.name == value).first).toList(),
      about: map['about'] != null ? map['about'] as String : null,
      aulas: map['aulas'] as num,
      horas: map['horas'] as num,
      asaasStatus: map['asaasStatus'] as String?,
      rating: map['rating'] as num? ?? 5.0,
      ratingCount: map['ratingCount'] as int? ?? 0,
      defaultVehicle: map['defaultVehicle'] != null ? Vehicle.fromMap(map['defaultVehicle'] as Map<String, dynamic>) : null,
      pixKeyType: map['pixKeyType'] as String?,
      pixKey: map['pixKey'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory InstrutorData.fromJson(String source) => InstrutorData.fromMap(json.decode(source) as Map<String, dynamic>);
}

enum DocumentType {id, cnh, credencial, lav, crlv, face, ladv}
enum DocumentStatus {approved, refused, expired, sended}

class UserDocument {

  DocumentType type;
  DocumentStatus status;
  String url;
  String? message;

  UserDocument({
    required this.type,
    required this.status,
    required this.url,
    this.message,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'type': type.name,
      'status': status.name,
      'url': url,
      'message': message,
    };
  }

  factory UserDocument.fromMap(Map<String, dynamic> map) {
    return UserDocument(
      type: DocumentType.values.where((e)=> e.name == map['type']).first,
      status: DocumentStatus.values.where((e)=> e.name == map['status']).first,
      url: map['url'] as String,
      message: map['message'] != null ? map['message'] as String : null,
    );
  }
}
