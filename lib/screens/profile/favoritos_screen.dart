import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instrutor_em_casa/models/instrutor.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/screens/user_details/user_details.dart';
import 'package:instrutor_em_casa/widgets/avatar.dart';
import 'package:instrutor_em_casa/widgets/stars.dart';
import 'package:instrutor_em_casa/widgets/theme.dart';
import 'package:ionicons/ionicons.dart';

class FavoritosScreen extends StatefulWidget {
  const FavoritosScreen({super.key, required this.usuario});
  final Usuario usuario;

  @override
  State<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen> {
  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection("users")
        .doc(widget.usuario.id)
        .collection("favorites")
        .orderBy("createdAt", descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Instrutores Favoritos"),
      ),
      body: FirestoreListView(
        query: query,
        padding: const EdgeInsets.all(20),
        emptyBuilder: (context) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Ionicons.heart_dislike_outline, size: 60, color: Colors.grey[400]),
              const SizedBox(height: 15),
              Text(
                "Nenhum instrutor favorito",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              const Text(
                "Favorite instrutores na busca para encontrá-los aqui.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        itemBuilder: (context, snapshot) {
          final data = snapshot.data();
          final String instrutorId = data['id'] as String? ?? '';
          final String name = data['name'] as String? ?? '';
          final String? image = data['image'] as String?;
          final double rating = (data['rating'] as num? ?? 5.0).toDouble();
          final int ratingCount = (data['ratingCount'] as int? ?? 0);
          final List<dynamic> categoriesRaw = data['categories'] as List<dynamic>? ?? [];
          final List<CNHCategory> categories = categoriesRaw
              .map((val) => CNHCategory.values.firstWhere((e) => e.name == val, orElse: () => CNHCategory.A))
              .toList();

          return Card(
            margin: const EdgeInsets.only(bottom: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            elevation: 0,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              leading: UserAvatar(
                user: UserDetails(
                  id: instrutorId,
                  name: name,
                  image: image,
                  type: UserType.instrutor,
                ),
                radius: 25,
              ),
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      StarRating(stars: rating, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        "${rating.toStringAsFixed(1)} ($ratingCount)",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 5,
                    children: categories.map((cat) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary50,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        "Cat. ${cat.name}",
                        style: const TextStyle(color: AppColors.primary600, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    )).toList(),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Ionicons.heart, color: Colors.red),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection("users")
                      .doc(widget.usuario.id)
                      .collection("favorites")
                      .doc(instrutorId)
                      .delete();
                },
              ),
              onTap: () async {
                final docSnap = await FirebaseFirestore.instance
                    .collection("users")
                    .doc(instrutorId)
                    .get();

                if (docSnap.exists && context.mounted) {
                  final instrutorUser = Usuario.fromMap(docSnap.data()!);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserDetailsScreen(
                        usuario: instrutorUser,
                        myUser: widget.usuario,
                      ),
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}
