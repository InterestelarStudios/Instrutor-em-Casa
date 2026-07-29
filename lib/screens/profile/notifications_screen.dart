import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instrutor_em_casa/models/notification.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/widgets/theme.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, required this.usuario});
  final Usuario usuario;

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('notifications')
        .where('visibleTo', arrayContainsAny: [usuario.id, 'all'])
        .orderBy('created', descending: true)
        .withConverter<AppNotification>(
          fromFirestore: (snapshot, _) => AppNotification.fromMap(snapshot.data()!),
          toFirestore: (notification, _) => notification.toMap(),
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notificações"),
      ),
      body: StreamBuilder<QuerySnapshot<AppNotification>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint("Erro na busca de notificações: ${snapshot.error}");
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Erro ao carregar notificações. Verifique se o índice do Firestore foi criado.\n\n${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Ionicons.notifications_off_outline,
                        size: 60,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 25),
                    Text(
                      "Tudo limpo por aqui!",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.gray950,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Você não tem nenhuma notificação no momento. Novas mensagens e alertas aparecerão aqui.",
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final notification = docs[index].data();
              return _buildNotificationTile(context, notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, AppNotification notification) {
    return Card(
      elevation: 0,
      color: notification.read ? Colors.transparent : AppColors.primary.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => _markAsRead(context, notification),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (notification.read ? Colors.grey : AppColors.primary).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            notification.read ? Ionicons.notifications_outline : Ionicons.notifications,
            color: notification.read ? Colors.grey : AppColors.primary,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.description),
            const SizedBox(height: 5),
            Text(
              DateFormat("dd/MM 'às' HH:mm").format(notification.created.toDate()),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        trailing: !notification.read 
          ? Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle))
          : null,
      ),
    );
  }

  Future<void> _markAsRead(BuildContext context, AppNotification notification) async {
    if (notification.read) return;

    final batch = FirebaseFirestore.instance.batch();
    
    // Marca como lida
    batch.update(
      FirebaseFirestore.instance.collection('notifications').doc(notification.id),
      {'read': true},
    );

    // Decrementa o contador do usuário
    batch.update(
      FirebaseFirestore.instance.collection('users').doc(usuario.id),
      {'notificationsCount': FieldValue.increment(-1)},
    );

    await batch.commit();

    // Navegação se houver rota
    if (notification.route != null) {
      // TODO: Implement deep linking or navigation based on route
      print("Navegando para: ${notification.route} com ID: ${notification.contentId}");
    }
  }
}
