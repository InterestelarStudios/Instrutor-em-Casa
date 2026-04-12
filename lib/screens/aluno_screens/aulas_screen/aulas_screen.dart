import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instrutor_em_casa/models/aula.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/screens/aluno_screens/aulas_screen/widgets/aula_build.dart';
import 'package:instrutor_em_casa/widgets/loading_box.dart';

class AulasAlunoScreen extends StatefulWidget {
  const AulasAlunoScreen({super.key, required this.usuario});
  final Usuario usuario;

  @override
  State<AulasAlunoScreen> createState() => _AulasAlunoScreenState();
}

class _AulasAlunoScreenState extends State<AulasAlunoScreen> with AutomaticKeepAliveClientMixin{
  late Query<Aula> query;

  @override
  void initState() {
    super.initState();
    query = FirebaseFirestore.instance
    .collection("aulas")
    .where("aluno.id", isEqualTo: widget.usuario.id)
    .orderBy("date", descending: false)
    .withConverter<Aula>(
      fromFirestore: (snapshot, options)=> Aula.fromMap(snapshot.data()!),
      toFirestore: (snapshot, options)=> {}
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text("Minhas aulas", style: Theme.of(context).textTheme.displayMedium,),
        FirestoreListView<Aula>(
          query: query,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 20),
          loadingBuilder: (context)=> ListView.builder(
            itemCount: 5,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemBuilder: (context, index){
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: LoadingBox(height: 200,),
              );
            }
          ),
          itemBuilder: (context, snapshot){
            final aula = snapshot.data();
            return AulaBuild(aula: aula, usuario: widget.usuario);
          }
        ),
      ],
    );
  }
  
  @override
  bool get wantKeepAlive => true;
}