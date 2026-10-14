import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instrutor_em_casa/models/aula.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/screens/aluno_screens/aulas_screen/widgets/aula_build.dart';
import 'package:instrutor_em_casa/screens/instrutor_screens/area_instrutor_screen.dart';
import 'package:instrutor_em_casa/widgets/active_lesson_widget.dart';
import 'package:instrutor_em_casa/widgets/chip.dart';
import 'package:instrutor_em_casa/widgets/theme.dart';

class HomeScreenInstrutor extends StatefulWidget {
  const HomeScreenInstrutor({super.key, required this.usuario});
  final Usuario usuario;

  @override
  State<HomeScreenInstrutor> createState() => _HomeScreenInstrutorState();
}

class _HomeScreenInstrutorState extends State<HomeScreenInstrutor> with AutomaticKeepAliveClientMixin{
  late Query<Aula> queryAulaConfirmadas;
  late Query<Aula> queryAulaAtivas;
  bool refreshingStatus = false;

  Query<Aula> setQuery(List<LessonStatus> statuses){
    return FirebaseFirestore.instance
    .collection("aulas")
    .where("instrutor.id", isEqualTo: widget.usuario.id)
    .where("status", whereIn: statuses.map((e) => e.name).toList())
    .orderBy("date", descending: false)
    .withConverter<Aula>(
      fromFirestore: (snapshot, options)=> Aula.fromMap(snapshot.data()!),
      toFirestore: (snapshot, options)=> {}
    );
  }

  @override
  void initState() {
    super.initState();
    queryAulaConfirmadas = setQuery([LessonStatus.accepted, LessonStatus.requested]);
    queryAulaAtivas = setQuery([LessonStatus.active]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection("users").doc(widget.usuario.id).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final userData = snapshot.data?.data();
        final String? inLesson = userData?['inLesson'];
        final bool isActive = userData?['instrutor']?['active'] ?? false;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 20,),
            Text(
              "Olá, ${widget.usuario.name.split(" ").first}!",
              style: Theme.of(context).textTheme.displayMedium,
            ),
            Text(
              "Está pronto para sua próxima aula?",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20,),
            _buildStatusServico(isActive),

            if (inLesson != null) ...[
              ActiveLessonWidget(lessonId: inLesson, usuario: widget.usuario),
              const SizedBox(height: 20),
            ],
            const SizedBox(height: 20,),
            sessionTitle("Aulas em andamento"),
            firestoreList(queryAulaAtivas),
            const SizedBox(height: 20,),
            sessionTitle("Próximas aulas (Confirmadas)"),
            firestoreList(queryAulaConfirmadas),
          ],
        );
      }
    );
  }


  Widget _buildStatusServico(bool isActive) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AreaInstrutorScreen(usuario: widget.usuario),
            ),
          );
        },
        borderRadius: AppRadius.radiusLg,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Status de Serviço", style: AppTextStyles.h3),
                    Text(
                      "Clique para gerenciar seu status",
                      style: AppTextStyles.body.copyWith(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              AppChip(
                title: isActive ? "Online" : "Offline",
                type: isActive ? AppChipType.done : AppChipType.danger,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget firestoreList(Query<Aula> query){
    return FirestoreListView<Aula>(
      query: query,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      emptyBuilder: (context) => Card(
        margin: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        elevation: 0,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            child: Icon(Icons.calendar_today_outlined, color: Theme.of(context).primaryColor, size: 20,),
          ),
          title: Text(
            "Tudo certo!",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            "Não há aulas nesta sessão no momento.",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ),
      ),
      itemBuilder: (context, snapshot){
        final aula = snapshot.data();
        return AulaBuild(aula: aula, usuario: widget.usuario);
      }
    );
  }

  Widget sessionTitle(String value){
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(value, style: Theme.of(context).textTheme.titleMedium,),
    );
  }
  
  @override
  bool get wantKeepAlive => true;
}