// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instrutor_em_casa/models/instrutor.dart';

import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/widgets/theme.dart';

enum LessonStatus {requested, accepted, refused, expired, active, done, canceled, partially_done, inactive}
enum LessonType {obrigatorio, treinamento, habilitado}
enum LessonVehicle {aluno, instrutor}
enum PaymentType {pix, credito, debito, dinheiro}
enum JourneyState {none, requested, enRoute, arrived}
enum SessionStatus {scheduled, completed, missed}

class SessaoAula {
  String id;
  Timestamp date;
  int duration; // hours in this session
  bool checkInAluno;
  bool checkInInstrutor;
  Timestamp? start;
  Timestamp? end;
  JourneyState journeyState;
  SessionStatus status;

  SessaoAula({
    required this.id,
    required this.date,
    required this.duration,
    this.checkInAluno = false,
    this.checkInInstrutor = false,
    this.start,
    this.end,
    this.journeyState = JourneyState.none,
    this.status = SessionStatus.scheduled,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'date': date,
      'duration': duration,
      'checkInAluno': checkInAluno,
      'checkInInstrutor': checkInInstrutor,
      'start': start,
      'end': end,
      'journeyState': journeyState.name,
      'status': status.name,
    };
  }

  factory SessaoAula.fromMap(Map<String, dynamic> map) {
    return SessaoAula(
      id: map['id'] as String,
      date: map['date'] as Timestamp,
      duration: map['duration'] as int,
      checkInAluno: map['checkInAluno'] as bool? ?? false,
      checkInInstrutor: map['checkInInstrutor'] as bool? ?? false,
      start: map['start'] as Timestamp?,
      end: map['end'] as Timestamp?,
      journeyState: map['journeyState'] != null 
        ? JourneyState.values.where((e) => e.name == map['journeyState']).first 
        : JourneyState.none,
      status: map['status'] != null 
        ? SessionStatus.values.where((e) => e.name == map['status']).first 
        : SessionStatus.scheduled,
    );
  }
}

class Aula {

  String id;
  UserDetails aluno;
  UserDetails instrutor;
  CNHCategory category;
  LessonStatus status;
  Timestamp date; // Initial date
  Timestamp created;
  int horasContratadas;
  int horasRestantes;
  List<SessaoAula> sessions;
  LessonType type;
  LessonVehicle vehicle;
  LessonPrice price;
  PaymentType paymentType;
  Map<String, dynamic>? liveLocation;

  Aula({
    required this.id,
    required this.aluno,
    required this.instrutor,
    required this.category,
    required this.status,
    required this.date,
    required this.created,
    required this.horasContratadas,
    required this.horasRestantes,
    required this.sessions,
    required this.type,
    required this.vehicle,
    required this.price,
    required this.paymentType,
    this.liveLocation,
  });


  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'aluno': aluno.toMap(),
      'instrutor': instrutor.toMap(),
      'category': category.name,
      'status': status.name,
      'date': date,
      'created': created,
      'horasContratadas': horasContratadas,
      'horasRestantes': horasRestantes,
      'sessions': sessions.map((x) => x.toMap()).toList(),
      'type': type.name,
      'vehicle': vehicle.name,
      'price': price.toMap(),
      'paymentType' : paymentType.name,
      'liveLocation': liveLocation,
    };
  }

  factory Aula.fromMap(Map<String, dynamic> map) {
    return Aula(
      id: map['id'] as String,
      aluno: UserDetails.fromMap(map['aluno'] as Map<String,dynamic>),
      instrutor: UserDetails.fromMap(map['instrutor'] as Map<String,dynamic>),
      category: CNHCategory.values.where((e)=> e.name == map['category']).first,
      status: LessonStatus.values.where((e)=> e.name == map['status']).first,
      date: map['date'] as Timestamp,
      created: map['created'] as Timestamp,
      horasContratadas: map['horasContratadas'] as int? ?? 1,
      horasRestantes: map['horasRestantes'] as int? ?? 1,
      sessions: (map['sessions'] as List<dynamic>?)?.map((x) => SessaoAula.fromMap(x as Map<String, dynamic>)).toList() ?? [],
      type: LessonType.values.where((e)=> e.name == map['type']).first,
      vehicle: LessonVehicle.values.where((e)=> e.name == map['vehicle']).first,
      price: LessonPrice.fromMap(map['price'] as Map<String,dynamic>),
      paymentType: PaymentType.values.where((e)=> e.name == map['paymentType']).first,
      liveLocation: map['liveLocation'] as Map<String, dynamic>?,
    );
  }

  String toJson() => json.encode(toMap());

  factory Aula.fromJson(String source) => Aula.fromMap(json.decode(source) as Map<String, dynamic>);

  Color statusColor(){
    switch (status) {
      case LessonStatus.requested:
        return AppColors.warning;
      case LessonStatus.accepted:
        return AppColors.primary;
      case LessonStatus.active:
        return AppColors.primary;
      case LessonStatus.done:
        return AppColors.success;
      case LessonStatus.refused:
        return AppColors.emergency;
      case LessonStatus.canceled:
        return AppColors.emergency;
      case LessonStatus.partially_done:
        return AppColors.success;
      case LessonStatus.inactive:
        return AppColors.emergency;
      default:
        return Colors.grey;
    }
  }

  String statusValue(){
    switch (status) {
      case LessonStatus.requested:
        return "Aguardando Confirmação";
      case LessonStatus.accepted:
        return "Confirmado";
      case LessonStatus.active:
        return "Em andamento";
      case LessonStatus.done:
        return "Concluido";
      case LessonStatus.refused:
        return "Recusado";
      case LessonStatus.expired:
        return "Expirado";
      case LessonStatus.canceled:
        return "Cancelado";
      case LessonStatus.partially_done:
        return "Concluido Parcialmente";
      case LessonStatus.inactive:
        return "Cancelado por Inatividade";
    }
  }

}

class LessonPrice {

  double amount;
  double hourPrice;
  double distance;

  LessonPrice({
    required this.amount,
    required this.hourPrice,
    required this.distance,
  });


  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'amount': amount,
      'hourPrice': hourPrice,
      'distance': distance,
    };
  }

  factory LessonPrice.fromMap(Map<String, dynamic> map) {
    return LessonPrice(
      amount: map['amount'] as double,
      hourPrice: map['hourPrice'] as double,
      distance: map['distance'] as double,
    );
  }

  String toJson() => json.encode(toMap());

  factory LessonPrice.fromJson(String source) => LessonPrice.fromMap(json.decode(source) as Map<String, dynamic>);
}
