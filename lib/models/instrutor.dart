// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

enum CNHCategory {A, B, C, D, E}

class InstrutorData {

  bool active;
  UserDocument cnh;
  UserDocument credencial;
  List<CNHCategory> categories;
  String? about;
  num aulas;
  num horas;
  
  InstrutorData({
    required this.active,
    required this.cnh,
    required this.credencial,
    required this.categories,
    this.about,
    required this.aulas,
    required this.horas,
  });


  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'active': active,
      'cnh': cnh.toMap(),
      'credencial': credencial.toMap(),
      'categories': categories.map((x) => x.name).toList(),
      'about': about,
      'aulas': aulas,
      'horas': horas,
    };
  }

  factory InstrutorData.fromMap(Map<String, dynamic> map) {
    return InstrutorData(
      active: map['active'] as bool,
      cnh: UserDocument.fromMap(map['cnh'] as Map<String,dynamic>),
      credencial: UserDocument.fromMap(map['credencial'] as Map<String,dynamic>),
      categories: map['categories'].map<CNHCategory>((value)=> CNHCategory.values.where((e)=> e.name == value).first).toList(),
      about: map['about'] != null ? map['about'] as String : null,
      aulas: map['aulas'] as num,
      horas: map['horas'] as num,
    );
  }

  String toJson() => json.encode(toMap());

  factory InstrutorData.fromJson(String source) => InstrutorData.fromMap(json.decode(source) as Map<String, dynamic>);
}

enum DocumentType {id, cnh, credencial, lav, crlv}
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