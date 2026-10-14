import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:instrutor_em_casa/models/rating.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/widgets/stars.dart';
import 'package:instrutor_em_casa/widgets/theme.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

class MinhasAvaliacoesScreen extends StatefulWidget {
  const MinhasAvaliacoesScreen({super.key, required this.usuario});
  final Usuario usuario;

  @override
  State<MinhasAvaliacoesScreen> createState() => _MinhasAvaliacoesScreenState();
}

class _MinhasAvaliacoesScreenState extends State<MinhasAvaliacoesScreen> {
  final Map<String, Map<String, dynamic>?> _userCache = {};

  Future<Map<String, dynamic>?> _getUserInfo(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _userCache[userId] = {
          'name': data['name'] ?? 'Usuário',
          'image': data['image'],
          'type': data['type'],
        };
        return _userCache[userId];
      }
    } catch (_) {}
    _userCache[userId] = null;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isInstrutor = widget.usuario.type == UserType.instrutor;
    final ratingMedia = widget.usuario.instrutor?.rating.toDouble() ?? 5.0;
    final ratingCount = widget.usuario.instrutor?.ratingCount ?? 0;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: IconButton(
              icon: const Icon(Ionicons.chevron_back_outline, color: AppColors.textPrimary, size: 24),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          titleSpacing: 4,
          title: Text(
            "Minhas Avaliações",
            style: GoogleFonts.sora(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
            unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
            tabs: const [
              Tab(text: "Recebidas"),
              Tab(text: "Enviadas"),
            ],
          ),
        ),
        body: Column(
          children: [
            if (isInstrutor) _buildInstructorSummary(ratingMedia, ratingCount),
            Expanded(
              child: TabBarView(
                children: [
                  _buildRatingsList(
                    isReceived: true,
                    emptyMessage: "Você ainda não recebeu nenhuma avaliação.",
                  ),
                  _buildRatingsList(
                    isReceived: false,
                    emptyMessage: "Você ainda não enviou nenhuma avaliação.",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructorSummary(double media, int total) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.radiusLg,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  media.toStringAsFixed(1),
                  style: GoogleFonts.sora(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                StarRating(stars: media, size: 14),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Sua Reputação",
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  total == 1 ? "1 avaliação de aluno" : "$total avaliações de alunos",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Mantenha uma boa pontuação para receber mais solicitações de aulas.",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingsList({
    required bool isReceived,
    required String emptyMessage,
  }) {
    final queryField = isReceived ? 'toUserId' : 'fromUserId';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ratings')
          .where(queryField, isEqualTo: widget.usuario.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                "Erro ao carregar avaliações: ${snapshot.error}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Ionicons.star_outline,
                      size: 48,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Nenhuma avaliação",
                    style: GoogleFonts.sora(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    emptyMessage,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Ordena em memória por data mais recente
        final ratings = docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Rating.fromMap(data, id: doc.id);
        }).toList();

        ratings.sort((a, b) {
          final dateA = a.created?.toDate() ?? DateTime(2000);
          final dateB = b.created?.toDate() ?? DateTime(2000);
          return dateB.compareTo(dateA);
        });

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: ratings.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final rating = ratings[index];
            final otherUserId = isReceived ? rating.fromUserId : rating.toUserId;

            return _buildRatingCard(
              rating: rating,
              otherUserId: otherUserId,
              isReceived: isReceived,
            );
          },
        );
      },
    );
  }

  Widget _buildRatingCard({
    required Rating rating,
    required String otherUserId,
    required bool isReceived,
  }) {
    final date = rating.created != null
        ? DateFormat('dd/MM/yyyy • HH:mm').format(rating.created!.toDate())
        : "Data indisponível";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<Map<String, dynamic>?>(
            future: _getUserInfo(otherUserId),
            builder: (context, snapshot) {
              final userInfo = snapshot.data;
              final name = userInfo?['name'] ?? (isReceived ? "Aluno" : "Instrutor");
              final image = userInfo?['image'] as String?;
              final type = userInfo?['type'] as String?;
              final userLabel = type == 'instrutor' ? 'Instrutor' : 'Aluno';

              return Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary100,
                    backgroundImage: image != null ? CachedNetworkImageProvider(image) : null,
                    child: image == null
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : "?",
                            style: GoogleFonts.sora(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.sora(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          isReceived ? "Avaliado por $userLabel" : "Avaliação para $userLabel",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StarRating(stars: rating.stars.toDouble(), size: 14),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          if (rating.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.gray200),
              ),
              child: Text(
                "“${rating.comment.trim()}”",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
