import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instrutor_em_casa/models/aula.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/screens/agendar_aula/steps/step1/agendar_aula_1.dart';
import 'package:instrutor_em_casa/widgets/chip.dart';
import 'package:instrutor_em_casa/widgets/dialog_services.dart';
import 'package:instrutor_em_casa/widgets/theme.dart';
import 'package:instrutor_em_casa/widgets/user_tile.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

class AulaDetailsScreen extends StatefulWidget {
  const AulaDetailsScreen({super.key, required this.aula, required this.usuario,});
  final Aula aula;
  final Usuario usuario;

  @override
  State<AulaDetailsScreen> createState() => _AulaDetailsScreenState();
}

class _AulaDetailsScreenState extends State<AulaDetailsScreen> {
  late Aula aula;

  @override
  void initState() {
    super.initState();
    aula = widget.aula;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Aula de Direção"),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ListTile(
            contentPadding: const EdgeInsets.only(),
            title: Text("Categoria ${aula.category.name}", style: Theme.of(context).textTheme.displaySmall,),
            subtitle: Builder(
              builder: (context) {
                String dateFormated(String type){
                  return DateFormat(type).format(aula.date.toDate());
                }
                return Text("${dateFormated(DateFormat.MONTH_DAY)} às ${dateFormated(DateFormat.HOUR24_MINUTE)}h");
              }
            ),
            trailing: Builder(
              builder: (context) {
                AppChipType chipType;
                switch (aula.status) {
                  case LessonStatus.accepted:
                    chipType = AppChipType.none;
                  case LessonStatus.done:
                    chipType = AppChipType.done;
                  case LessonStatus.requested:
                    chipType = AppChipType.waiting;
                  default:
                    chipType = AppChipType.inactive;
                }
                return AppChip(
                  title: aula.statusValue(),
                  type: chipType,
                );
              }
            ),
          ),
          if(widget.aula.instrutor.id == widget.usuario.id && aula.status == LessonStatus.requested)
          acceptOrRefuseWidget(),
          title("Aluno"),
          Card(
            margin: const EdgeInsets.only(bottom: 20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: UserTile(user: widget.aula.instrutor),
            ),
          ),
          title("Detalhes"),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  resumeRow(title: "Instrutor", value: aula.instrutor.name),
                  resumeRow(title: "Data", value: DateFormat(DateFormat.MONTH_DAY).format(aula.date.toDate())),
                  resumeRow(title: "Hora", value: DateFormat(DateFormat.HOUR24_MINUTE).format(aula.date.toDate())),
                  resumeRow(title: "Duração", value: lessonTimeTranslate(aula.duration)),
                  resumeRow(title: "Tipo de aula", value: lessonTypeTranslate(aula.type)),
                  resumeRow(title: "Veículo", value: lessonVehicleTranslate(aula.vehicle)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget title(String text){
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }

  Widget resumeRow({required String title, required String value}){
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(title, style: Theme.of(context).textTheme.bodySmall,)),
          Flexible(child: Text(value, style: Theme.of(context).textTheme.titleMedium,))
        ],
      ),
    );
  }

  void updateStatus(LessonStatus status){
    FirebaseFirestore.instance.collection("aulas").doc(aula.id).update({
      "status" : status.name,
    }).then((_){
      setState(() {
        aula.status = status;
      });
    });
  }

  Widget acceptOrRefuseWidget(){
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: (){
              updateStatus(LessonStatus.accepted);
            },
            label: Text("Aceitar"),
            icon: Icon(Ionicons.checkmark_done_outline),
          ),
        ),
        SizedBox(width: 10,),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: (){
              DialogServices().alertDialog(
                context,
                "Deseja recusar essa proposta de aula?",
                title: "Tem certeza?",
                buttonTitle1: "Recusar",
                buttonTitle2: "Cancelar",
                colorButton1: AppColors.emergency,
                colorButton2: Colors.grey,
                onTap2: ()=> Navigator.pop(context),
                onTap1: (){
                  Navigator.pop(context);
                  updateStatus(LessonStatus.refused);
                }
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.emergency,
              side: BorderSide(
                color: AppColors.emergency,
                width: 2,
              )
            ),
            label: Text("Recusar"),
            icon: Icon(Ionicons.close_outline),
          ),
        ),
      ],
    );
  }
}