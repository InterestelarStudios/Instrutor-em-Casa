// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Vehicle {
  String id;
  String plate;
  String renavam;
  String brand;
  String model;
  int yearFabrication;
  int yearModel;
  String color;
  String fuel;
  String chassis;
  String category;

  Vehicle({
    required this.id,
    required this.plate,
    required this.renavam,
    required this.brand,
    required this.model,
    required this.yearFabrication,
    required this.yearModel,
    required this.color,
    required this.fuel,
    required this.chassis,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'plate': plate,
      'renavam': renavam,
      'brand': brand,
      'model': model,
      'yearFabrication': yearFabrication,
      'yearModel': yearModel,
      'color': color,
      'fuel': fuel,
      'chassis': chassis,
      'category': category,
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] as String,
      plate: map['plate'] as String,
      renavam: map['renavam'] as String,
      brand: map['brand'] as String,
      model: map['model'] as String,
      yearFabrication: map['yearFabrication'] as int,
      yearModel: map['yearModel'] as int,
      color: map['color'] as String,
      fuel: map['fuel'] as String,
      chassis: map['chassis'] as String,
      category: map['category'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory Vehicle.fromJson(String source) => Vehicle.fromMap(json.decode(source) as Map<String, dynamic>);
}
