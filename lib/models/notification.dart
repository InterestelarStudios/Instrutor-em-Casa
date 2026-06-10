import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String title;
  final String description;
  final Timestamp created;
  final String? route;
  final String? contentId;
  final bool read;
  final List<String> visibleTo;

  AppNotification({
    required this.id,
    required this.title,
    required this.description,
    required this.created,
    this.route,
    this.contentId,
    this.read = false,
    required this.visibleTo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'created': created,
      'route': route,
      'contentId': contentId,
      'read': read,
      'visibleTo': visibleTo,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      created: map['created'] ?? Timestamp.now(),
      route: map['route'],
      contentId: map['contentId'],
      read: map['read'] ?? false,
      visibleTo: List<String>.from(map['visibleTo'] ?? []),
    );
  }
}
