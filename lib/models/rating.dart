import 'package:cloud_firestore/cloud_firestore.dart';

class Rating {
  final String id;
  final String lessonId;
  final String fromUserId;
  final String toUserId;
  final int stars;
  final String comment;
  final Timestamp? created;

  Rating({
    required this.id,
    required this.lessonId,
    required this.fromUserId,
    required this.toUserId,
    required this.stars,
    required this.comment,
    this.created,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lessonId': lessonId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'stars': stars,
      'comment': comment,
      'created': created,
    };
  }

  factory Rating.fromMap(Map<String, dynamic> map, {String? id}) {
    return Rating(
      id: id ?? (map['id'] as String? ?? ''),
      lessonId: map['lessonId'] as String? ?? '',
      fromUserId: map['fromUserId'] as String? ?? '',
      toUserId: map['toUserId'] as String? ?? '',
      stars: (map['stars'] as num?)?.toInt() ?? 5,
      comment: map['comment'] as String? ?? '',
      created: map['created'] as Timestamp?,
    );
  }
}
