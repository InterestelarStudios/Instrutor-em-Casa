import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/widgets/avatar.dart';
import 'package:instrutor_em_casa/widgets/theme.dart';
import 'package:ionicons/ionicons.dart';

class RatingDialog extends StatefulWidget {
  const RatingDialog({super.key, required this.avaliation, required this.myUserId});
  final PendingAvaliation avaliation;
  final String myUserId;

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int stars = 5;
  final TextEditingController _commentController = TextEditingController();
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Avalie sua Experiência",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            UserAvatar(
              user: UserDetails(
                id: widget.avaliation.targetUserId,
                name: widget.avaliation.targetUserName,
                type: null,
                image: widget.avaliation.targetUserImage,
              ),
              radius: 60,
            ),
            const SizedBox(height: 15),
            Text(
              widget.avaliation.targetUserName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 5),
            const Text(
              "Como foi sua aula?",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () => setState(() => stars = index + 1),
                  icon: Icon(
                    index < stars ? Ionicons.star : Ionicons.starOutline,
                    color: index < stars ? Colors.amber : Colors.grey,
                    size: 35,
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Deixe um comentário (opcional)",
                fillColor: Colors.grey[100],
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: loading ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: loading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Enviar Avaliação", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRating() async {
    setState(() => loading = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      
      // 1. Save rating document
      final ratingId = FirebaseFirestore.instance.collection('ratings').doc().id;
      batch.set(FirebaseFirestore.instance.collection('ratings').doc(ratingId), {
        'id': ratingId,
        'lessonId': widget.avaliation.lessonId,
        'fromUserId': widget.myUserId,
        'toUserId': widget.avaliation.targetUserId,
        'stars': stars,
        'comment': _commentController.text,
        'created': FieldValue.serverTimestamp(),
      });

      // 2. Clear pending avaliation from user profile
      batch.update(FirebaseFirestore.instance.collection('users').doc(widget.myUserId), {
        'pendingAvaliation': null,
      });

      await batch.commit();
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao enviar avaliação: $e")),
        );
      }
    }
  }
}
