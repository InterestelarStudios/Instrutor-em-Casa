import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:instrutor_em_casa/models/aula.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/screens/aluno_screens/buscar_instrutores/buscar_instrutores.dart';
import 'package:instrutor_em_casa/screens/aula_details/aula_details_screen.dart';
import 'package:instrutor_em_casa/screens/profile/horas_direcao_screen.dart';
import 'package:instrutor_em_casa/widgets/active_lesson_widget.dart';
import 'package:instrutor_em_casa/widgets/loading_box.dart';
import 'package:instrutor_em_casa/widgets/theme.dart';
import 'package:ionicons/ionicons.dart';
import 'package:iconsax/iconsax.dart';

class HomeScreenAluno extends StatefulWidget {
  const HomeScreenAluno({super.key, required this.usuario, required this.position, this.onNavigateToTab});
  final Usuario usuario;
  final Position? position;
  final ValueChanged<int>? onNavigateToTab;

  @override
  State<HomeScreenAluno> createState() => _HomeScreenAlunoState();
}

class _HomeScreenAlunoState extends State<HomeScreenAluno> with AutomaticKeepAliveClientMixin{
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  String? mapStyle;

  Future<void> loadMapStyle() async {
    try {
      String style = await rootBundle.loadString('assets/map_style.json');
      setState(() {
        mapStyle = style;
      });
    } catch (e) {
      debugPrint("Erro ao carregar estilo: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    loadMapStyle();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection("users").doc(widget.usuario.id).snapshots(),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data();
        final String? inLesson = userData?['inLesson'];

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
          children: [
            const SizedBox(height: AppSpacing.lg),
            _buildHeader(),
            const SizedBox(height: AppSpacing.lg),
            
            if (inLesson != null) ...[
              ActiveLessonWidget(lessonId: inLesson, usuario: widget.usuario),
              const SizedBox(height: AppSpacing.md),
            ],

            _buildQuickStats(),
            const SizedBox(height: AppSpacing.xl),

            _buildSectionTitle("Encontrar Instrutor"),
            const SizedBox(height: AppSpacing.sm),
            _buildMapCard(),
            const SizedBox(height: AppSpacing.xl),

            _buildSectionTitle("Categorias de Habilitação"),
            const SizedBox(height: AppSpacing.sm),
            _buildCategories(),
            const SizedBox(height: AppSpacing.xl),

            _buildSectionTitle("Meus Treinamentos Ativos"),
            const SizedBox(height: AppSpacing.sm),
            _buildActivePackages(),
            const SizedBox(height: AppSpacing.xxl),
          ],
        );
      }
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Olá, ${widget.usuario.name.split(" ").first}!",
          style: AppTextStyles.h1,
        ),
        const SizedBox(height: 4),
        Text(
          "Qual será o seu treino de hoje?",
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.h3.copyWith(fontSize: 18),
    );
  }

  Widget _buildQuickStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("aulas")
          .where("aluno.id", isEqualTo: widget.usuario.id)
          .snapshots(),
      builder: (context, snapshot) {
        int completedHours = 0;
        int activePackages = 0;

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final aula = Aula.fromMap(doc.data() as Map<String, dynamic>);
            completedHours += (aula.horasContratadas - aula.horasRestantes);
            if (aula.status != LessonStatus.done && aula.status != LessonStatus.refused && aula.status != LessonStatus.expired) {
              activePackages++;
            }
          }
        }

        return Row(
          children: [
            Expanded(
              child: _statCard(
                icon: Iconsax.timer_1,
                label: "Horas Realizadas",
                value: "$completedHours h",
                color: AppColors.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HorasDirecaoScreen(usuario: widget.usuario),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _statCard(
                icon: Iconsax.book_1,
                label: "Pacotes Ativos",
                value: "$activePackages",
                color: AppColors.success,
                onTap: () {
                  widget.onNavigateToTab?.call(1);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statCard({required IconData icon, required String label, required String value, required Color color, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.radiusLg,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(label, style: AppTextStyles.caption),
            Text(value, style: AppTextStyles.h2.copyWith(fontSize: 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildMapCard() {
    if (widget.position == null) {
      return const LoadingBox(height: 180);
    }

    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: AppRadius.radiusLg,
        boxShadow: AppShadows.md,
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.position!.latitude, widget.position!.longitude),
              zoom: 13
            ),
            zoomControlsEnabled: false,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            style: mapStyle,
          ),
          Positioned(
            bottom: 15,
            left: 15,
            right: 15,
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  useSafeArea: false,
                  builder: (context) {
                    return BuscarInstrutores(
                      usuario: widget.usuario,
                      position: LatLng(widget.position!.latitude, widget.position!.longitude),
                      style: mapStyle,
                    );
                  }
                );
              },
              icon: const Icon(Iconsax.location, size: 20),
              label: const Text("Buscar Instrutores"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    final categories = [
      {'name': 'A', 'label': 'Moto', 'icon': Ionicons.bicycle},
      {'name': 'B', 'label': 'Carro', 'icon': Ionicons.car},
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return GestureDetector(
            onTap: () {
              // Trigger search with this category pre-selected
              if (widget.position != null) {
                showDialog(
                  context: context,
                  useSafeArea: false,
                  builder: (context) {
                    return BuscarInstrutores(
                      usuario: widget.usuario,
                      position: LatLng(widget.position!.latitude, widget.position!.longitude),
                      style: mapStyle,
                      initialCategory: cat['name'] as String,
                    );
                  }
                );
              }
            },
            child: Column(
              children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: AppColors.primary50,
                    borderRadius: AppRadius.radiusMd,
                    border: Border.all(color: AppColors.primary100),
                  ),
                  child: Icon(cat['icon'] as IconData, color: AppColors.primary600, size: 28),
                ),
                const SizedBox(height: 8),
                Text("Cat. ${cat['name']}", style: AppTextStyles.label.copyWith(color: AppColors.textPrimary)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivePackages() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("aulas")
          .where("aluno.id", isEqualTo: widget.usuario.id)
          .where("status", whereIn: ['accepted', 'active'])
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingBox(height: 100);
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: AppRadius.radiusLg,
              border: Border.all(color: AppColors.border, style: BorderStyle.solid),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.info_circle, color: AppColors.textMuted),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Você ainda não tem nenhum pacote de aulas ativo.",
                    style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final aula = Aula.fromMap(doc.data() as Map<String, dynamic>);
            final progress = (aula.horasContratadas - aula.horasRestantes) / aula.horasContratadas;

            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                contentPadding: const EdgeInsets.all(AppSpacing.cardPadding),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.primary50, borderRadius: AppRadius.radiusSm),
                  child: const Icon(Iconsax.teacher, color: AppColors.primary600),
                ),
                title: Text(aula.instrutor.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: AppRadius.radiusFull,
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: AppColors.gray200,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary600),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${aula.horasContratadas - aula.horasRestantes}h de ${aula.horasContratadas}h concluídas",
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AulaDetailsScreen(
                        aula: aula,
                        usuario: widget.usuario,
                      ),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
