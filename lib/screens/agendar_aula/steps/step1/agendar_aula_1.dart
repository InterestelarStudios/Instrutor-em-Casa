import 'package:flutter/material.dart';
import 'package:instrutor_em_casa/models/aula.dart';
import 'package:instrutor_em_casa/models/instrutor.dart';
import 'package:instrutor_em_casa/screens/agendar_aula/widgets/selection_tile.dart';

class AgendarAula1 extends StatefulWidget {
  const AgendarAula1({
    super.key,
    required this.onChangedLessonCategory,
    required this.onChangedLessonTime,
    required this.onChangedLessonType,
    required this.onChangedLessonVehicle
  });
  final ValueChanged<CNHCategory> onChangedLessonCategory;
  final ValueChanged<LessonType> onChangedLessonType;
  final ValueChanged<LessonVehicle> onChangedLessonVehicle;
  final ValueChanged<LessonTime> onChangedLessonTime;

  @override
  State<AgendarAula1> createState() => _AgendarAula1State();
}

class _AgendarAula1State extends State<AgendarAula1> with AutomaticKeepAliveClientMixin {
  CNHCategory? category;
  LessonType? lessonType;
  LessonVehicle? lessonVehicle;
  LessonTime? time;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        sessionTitle("Categoria de Aula"),
        Wrap(
          spacing: 5,
          children: CNHCategory.values.map((e){
            return RawChip(
              onSelected: (value){
                setState(() {
                  category = e;
                  widget.onChangedLessonCategory.call(category!);
                });
              },
              selected: category == e,
              label: Text(e.name),
            );
          }).toList(),
        ),
        sessionTitle("Tipo de Aula"),
        ListView.builder(
          itemCount: LessonType.values.length,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index){
            final type = LessonType.values[index];
            return SelectOptionTile(
              value: type,
              groupValue: lessonType,
              label: lessonTypeTranslate(type),
              onChanged: (value){
                setState(() {
                  lessonType = value;
                  widget.onChangedLessonType.call(lessonType!);
                });
              }
            );
          }
        ),
        sessionTitle("Veículo"),
        ListView.builder(
          itemCount: LessonVehicle.values.length,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index){
            final type = LessonVehicle.values[index];
            return SelectOptionTile(
              value: type,
              groupValue: lessonVehicle,
              label: lessonVehicleTranslate(type),
              onChanged: (value){
                setState(() {
                  lessonVehicle = value;
                  widget.onChangedLessonVehicle.call(lessonVehicle!);
                });
              }
            );
          }
        ),
        sessionTitle("Horas de Aula"),
        Wrap(
          spacing: 5,
          children: LessonTime.values.map((e){
            return RawChip(
              onSelected: (value){
                setState(() {
                  time = e;
                  widget.onChangedLessonTime.call(time!);
                });
              },
              selected: time == e,
              label: Text(lessonTimeTranslate(e)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget sessionTitle(String value){
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(value, style: TextTheme.of(context).titleLarge,),
    );
  }
  
  @override
  bool get wantKeepAlive => true;
}

String lessonTypeTranslate(LessonType type){
  switch (type) {
    case LessonType.obrigatorio:
      return "Aula obrigatória (LADV)";
    case LessonType.treinamento:
      return "Aula de treinamento";
    default:
      return "Aula para habilitado";
  }
}

String lessonVehicleTranslate(LessonVehicle type){
  switch (type) {
    case LessonVehicle.aluno:
      return "Meu veículo";
    default:
      return "Veículo do Instrutor";
  }
}

String lessonTimeTranslate(LessonTime type){
  switch (type) {
    case LessonTime.h1:
      return "1h";
    case LessonTime.h2:
      return "2h";
    case LessonTime.h3:
      return "3h";
    case LessonTime.h4:
      return "4h";
  }
}