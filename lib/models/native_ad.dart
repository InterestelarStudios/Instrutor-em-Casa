// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class NativeAd {

  String id;
  String image;
  String? url;
  Timestamp? created;
  List audience;

  NativeAd({
    required this.id,
    required this.image,
    this.url,
    this.created,
    required this.audience,
  });


  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'image': image,
      'url': url,
      'created': created,
      'audience': audience,
    };
  }

  factory NativeAd.fromMap(Map<String, dynamic> map) {
    return NativeAd(
      id: map['id'] as String,
      image: map['image'] as String,
      url: map['url'] != null ? map['url'] as String : null,
      created: map['created'] != null ? map['created'] as Timestamp : null,
      audience: List.from((map['audience'] as List)),
    );
  }

  String toJson() => json.encode(toMap());

  factory NativeAd.fromJson(String source) => NativeAd.fromMap(json.decode(source) as Map<String, dynamic>);
}
