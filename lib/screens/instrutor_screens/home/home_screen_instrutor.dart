import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instrutor_em_casa/models/aula.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/screens/aluno_screens/aulas_screen/widgets/aula_build.dart';

class HomeScreenInstrutor extends StatefulWidget {
  const HomeScreenInstrutor({super.key, required this.usuario});
  final Usuario usuario;

  @override
  State<HomeScreenInstrutor> createState() => _HomeScreenInstrutorState();
}

class _HomeScreenInstrutorState extends State<HomeScreenInstrutor> with AutomaticKeepAliveClientMixin{
  late Query<Aula> queryAulaSolicitadas;
  late Query<Aula> queryAulaConfirmadas;

  Query<Aula> setQuery(LessonStatus status){
    return FirebaseFirestore.instance
    .collection("aulas")
    .where("instrutor.id", isEqualTo: widget.usuario.id)
    .where("status", isEqualTo: status.name)
    .orderBy("date", descending: false)
    .withConverter<Aula>(
      fromFirestore: (snapshot, options)=> Aula.fromMap(snapshot.data()!),
      toFirestore: (snapshot, options)=> {}
    );
  }

  @override
  void initState() {
    super.initState();
    queryAulaSolicitadas = setQuery(LessonStatus.requested);
    queryAulaConfirmadas = setQuery(LessonStatus.accepted);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
        sessionTitle("Aguardando confirmação"),
        firestoreList(queryAulaSolicitadas),
        sessionTitle("Confirmadas"),
        firestoreList(queryAulaConfirmadas),
      ],
    );
  }

  Widget firestoreList(Query<Aula> query){
    return FirestoreListView<Aula>(
      query: query,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, snapshot){
        final aula = snapshot.data();
        return AulaBuild(aula: aula, usuario: widget.usuario);
      }
    );
  }

  Widget sessionTitle(String value){
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(value,),
    );
  }
  
  @override
  bool get wantKeepAlive => true;
}