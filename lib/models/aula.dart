// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instrutor_em_casa/models/instrutor.dart';

import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/widgets/theme.dart';

enum LessonStatus {requested, accepted, refused, expired, done}
enum LessonType {obrigatorio, treinamento, habilitado}
enum LessonVehicle {aluno, instrutor}
enum LessonTime {h1, h2, h3, h4}
enum PaymentType {pix, cartao, dinheiro}

class Aula {

  String id;
  UserDetails aluno;
  UserDetails instrutor;
  CNHCategory category;
  LessonStatus status;
  Timestamp date;
  Timestamp created;
  LessonTime duration;
  LessonType type;
  LessonVehicle vehicle;
  LessonPrice price;
  PaymentType paymentType;

  Aula({
    required this.id,
    required this.aluno,
    required this.instrutor,
    required this.category,
    required this.status,
    required this.date,
    required this.created,
    required this.duration,
    required this.type,
    required this.vehicle,
    required this.price,
    required this.paymentType,
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
      'duration': duration.name,
      'type': type.name,
      'vehicle': vehicle.name,
      'price': price.toMap(),
      'paymentType' : paymentType.name,
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
      duration: LessonTime.values.where((e)=> e.name == map['duration']).first,
      type: LessonType.values.where((e)=> e.name == map['type']).first,
      vehicle: LessonVehicle.values.where((e)=> e.name == map['vehicle']).first,
      price: LessonPrice.fromMap(map['price'] as Map<String,dynamic>),
      paymentType: PaymentType.values.where((e)=> e.name == map['paymentType']).first,
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
      case LessonStatus.done:
        return AppColors.success;
      case LessonStatus.refused:
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
      case LessonStatus.done:
        return "Concluido";
      case LessonStatus.refused:
        return "Recusado";
      case LessonStatus.expired:
        return "Expirado";
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
