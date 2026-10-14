import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:instrutor_em_casa/models/precos_config.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/screens/agendar_aula/agendar_aula_screen.dart';
import 'package:instrutor_em_casa/services/precos_service.dart';
import 'package:instrutor_em_casa/widgets/avatar.dart';
import 'package:instrutor_em_casa/widgets/stars.dart';
import 'package:instrutor_em_casa/widgets/theme.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

class UserDetailsScreen extends StatefulWidget {
  const UserDetailsScreen({
    super.key,
    required this.usuario,
    required this.myUser,
  });
  final Usuario usuario;
  final Usuario myUser;

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final bool isInstructor = widget.usuario.type == UserType.instrutor;
    final rating = isInstructor
        ? (widget.usuario.instrutor?.rating ?? 5.0)
        : 5.0;
    final ratingCount = isInstructor
        ? (widget.usuario.instrutor?.ratingCount ?? 0)
        : 0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderInfo(rating, ratingCount),
                  const SizedBox(height: AppSpacing.xl),

                  _buildSectionTitle("Sobre"),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    isInstructor
                        ? (widget.usuario.instrutor?.about ??
                              "Este instrutor ainda não adicionou uma apresentação.")
                        : "Aluno em treinamento na plataforma Instrutor em Casa.",
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _buildSectionTitle("Estatísticas"),
                  const SizedBox(height: AppSpacing.sm),
                  _buildStatsRow(isInstructor),
                  const SizedBox(height: AppSpacing.xl),

                  if (isInstructor) ...[
                    _buildSectionTitle("Categorias"),
                    const SizedBox(height: AppSpacing.sm),
                    _buildCategoriesChips(),
                    const SizedBox(height: AppSpacing.xl),

                    _buildSectionTitle("Veículo de Treinamento"),
                    const SizedBox(height: AppSpacing.sm),
                    _buildVeiculoCard(),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  _buildSectionTitle("Avaliações"),
                  const SizedBox(height: AppSpacing.sm),
                  _buildEvaluationsList(),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isInstructor && widget.myUser.id != widget.usuario.id
          ? _buildBottomAction()
          : null,
    );
  }

  Widget _buildSliverAppBar() {
    final rating = widget.usuario.instrutor?.rating ?? 5.0;
    final ratingCount = widget.usuario.instrutor?.ratingCount ?? 0;
    final showFavorite =
        widget.myUser.type == UserType.aluno &&
        widget.usuario.type == UserType.instrutor;

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      actions: [
        if (showFavorite)
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection("users")
                .doc(widget.myUser.id)
                .collection("favorites")
                .doc(widget.usuario.id)
                .snapshots(),
            builder: (context, snapshot) {
              final isFav = snapshot.hasData && snapshot.data!.exists;
              return IconButton(
                icon: Icon(
                  isFav ? Ionicons.heart : Ionicons.heart_outline,
                  color: isFav ? Colors.red : Colors.white,
                ),
                onPressed: () async {
                  final docRef = FirebaseFirestore.instance
                      .collection("users")
                      .doc(widget.myUser.id)
                      .collection("favorites")
                      .doc(widget.usuario.id);

                  if (isFav) {
                    await docRef.delete();
                  } else {
                    await docRef.set({
                      "id": widget.usuario.id,
                      "name": widget.usuario.name,
                      "image": widget.usuario.image,
                      "rating": rating,
                      "ratingCount": ratingCount,
                      "categories":
                          widget.usuario.instrutor?.categories
                              .map((c) => c.name)
                              .toList() ??
                          [],
                      "createdAt": FieldValue.serverTimestamp(),
                    });
                  }
                },
              );
            },
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary600, AppColors.primary400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Center(
              child: Hero(
                tag: 'avatar_${widget.usuario.id}',
                child: UserAvatar(user: widget.usuario.toDetails(), radius: 70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(num rating, int ratingCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(widget.usuario.name, style: AppTextStyles.h1)),
            if (widget.usuario.type == UserType.instrutor)
              const Icon(Icons.verified, color: AppColors.primary, size: 24),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            StarRating(stars: rating.toDouble(), size: 18),
            const SizedBox(width: 8),
            Text(
              rating.toStringAsFixed(1),
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              "($ratingCount avaliações)",
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTextStyles.h3.copyWith(fontSize: 18));
  }

  Widget _buildStatsRow(bool isInstructor) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            label: isInstructor ? "Aulas dadas" : "Aulas feitas",
            value: isInstructor
                ? "${widget.usuario.instrutor?.aulas ?? 0}"
                : "0",
            icon: Iconsax.teacher,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _statCard(
            label: "Horas totais",
            value: isInstructor
                ? "${widget.usuario.instrutor?.horas ?? 0}h"
                : "0h",
            icon: Iconsax.timer_1,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 10),
          Text(value, style: AppTextStyles.h2.copyWith(fontSize: 18)),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  PrecosConfig _precosConfig = const PrecosConfig();
  StreamSubscription<PrecosConfig>? _precosSub;

  @override
  void initState() {
    super.initState();
    _precosSub = PrecosService.streamPrecos().listen((precos) {
      if (mounted) {
        setState(() {
          _precosConfig = precos;
        });
      }
    });
  }

  @override
  void dispose() {
    _precosSub?.cancel();
    super.dispose();
  }

  Widget _buildCategoriesChips() {
    final categories = widget.usuario.instrutor?.categories ?? [];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final price = _precosConfig.getPriceForCategory(cat);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary50,
            borderRadius: AppRadius.radiusFull,
            border: Border.all(color: AppColors.primary100),
          ),
          child: Text(
            "Cat. ${cat.name} • R\$ ${price.toStringAsFixed(0)}/h",
            style: AppTextStyles.label.copyWith(
              color: AppColors.primary600,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEvaluationsList() {
    final query = FirebaseFirestore.instance
        .collection('ratings')
        .where('toUserId', isEqualTo: widget.usuario.id)
        .orderBy('created', descending: true)
        .limit(10);

    return FirestoreListView(
      query: query,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      emptyBuilder: (context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text(
          "Nenhuma avaliação ainda.",
          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      ),
      itemBuilder: (context, snapshot) {
        final data = snapshot.data();
        return _buildReviewTile(data);
      },
    );
  }

  Widget _buildReviewTile(Map<String, dynamic> data) {
    final stars = data['stars'] as int? ?? 5;
    final comment = data['comment'] as String? ?? "";
    final date = data['created'] != null
        ? (data['created'] as Timestamp).toDate()
        : DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StarRating(stars: stars.toDouble(), size: 14),
              Text(
                DateFormat('dd/MM/yyyy').format(date),
                style: AppTextStyles.caption.copyWith(fontSize: 10),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              comment,
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AgendarAulaScreen(
                usuario: widget.usuario,
                myUser: widget.myUser,
              ),
            ),
          ),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 55),
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
          ),
          label: const Text(
            "Solicitar Treinamento",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          icon: const Icon(Iconsax.calendar_1, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildVeiculoCard() {
    final defaultVehicle = widget.usuario.instrutor?.defaultVehicle;

    if (defaultVehicle == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              const Icon(Ionicons.car_outline, color: AppColors.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Nenhum veículo cadastrado pelo instrutor.",
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary50,
                borderRadius: AppRadius.radiusMd,
              ),
              child: const Icon(
                Ionicons.car,
                color: AppColors.primary600,
                size: 24,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${defaultVehicle.brand} ${defaultVehicle.model}",
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Cor: ${defaultVehicle.color} • Categoria: ${defaultVehicle.category}",
                    style: AppTextStyles.caption.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Combustível: ${defaultVehicle.fuel}",
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
