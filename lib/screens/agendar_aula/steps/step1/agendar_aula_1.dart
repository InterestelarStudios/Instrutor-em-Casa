import 'package:flutter/material.dart';
import 'package:instrutor_em_casa/models/aula.dart';
import 'package:instrutor_em_casa/models/instrutor.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/models/vehicle.dart';
import 'package:instrutor_em_casa/screens/agendar_aula/widgets/selection_tile.dart';
import 'package:instrutor_em_casa/screens/profile/my_documents_screen.dart';

class AgendarAula1 extends StatefulWidget {
  const AgendarAula1({
    super.key,
    required this.onChangedLessonCategory,
    required this.onChangedLessonTime,
    required this.onChangedLessonType,
    required this.onChangedLessonVehicle,
    required this.onChangedHoursPerSession,
    required this.instrutorCategories,
    required this.usuario,
    required this.defaultVehicle,
  });
  final ValueChanged<CNHCategory> onChangedLessonCategory;
  final ValueChanged<LessonType> onChangedLessonType;
  final ValueChanged<LessonVehicle> onChangedLessonVehicle;
  final ValueChanged<int> onChangedLessonTime;
  final ValueChanged<int> onChangedHoursPerSession;
  final List<CNHCategory> instrutorCategories;
  final Usuario usuario;
  final Vehicle? defaultVehicle;

  @override
  State<AgendarAula1> createState() => _AgendarAula1State();
}

class _AgendarAula1State extends State<AgendarAula1> with AutomaticKeepAliveClientMixin {
  CNHCategory? category;
  LessonType? lessonType;
  LessonVehicle? lessonVehicle;
  int hours = 1;
  int hoursPerSession = 1;

  @override
  void initState() {
    super.initState();
    // Initialize with default values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onChangedLessonTime.call(hours);
      widget.onChangedHoursPerSession.call(hoursPerSession);
    });
  }

  void _validateAndChangeType(LessonType type) {
    final bool hasLadv = widget.usuario.aluno?.ladv?.status == DocumentStatus.approved;
    final bool hasCnh = widget.usuario.aluno?.cnh?.status == DocumentStatus.approved;

    if (type == LessonType.obrigatorio || type == LessonType.treinamento) {
      if (!hasLadv) {
        _showDocError("LADV");
        return;
      }
    } else if (type == LessonType.habilitado) {
      if (!hasCnh) {
        _showDocError("CNH");
        return;
      }
    }

    setState(() {
      lessonType = type;
      widget.onChangedLessonType.call(lessonType!);
    });
  }

  void _showDocError(String docName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Documento necessário"),
        content: Text("Você precisa anexar e ter aprovado o seu documento de $docName para solicitar este tipo de aula."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Depois")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyDocumentsScreen(usuario: widget.usuario)),
              );
            },
            child: const Text("Enviar Agora"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        sessionTitle("Categoria de Aula"),
        Wrap(
          spacing: 5,
          children: widget.instrutorCategories.map((e){
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
              onChanged: (value) => _validateAndChangeType(value as LessonType),
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
        if (lessonVehicle == LessonVehicle.instrutor)
          _buildDefaultVehicleCard(),
        sessionTitle(
          "Pacote de Horas: $hours h",
          description: "Escolha a quantidade total de horas que deseja contratar para o seu treinamento.",
        ),
        Slider(
          value: hours.toDouble(),
          min: 1,
          max: 20,
          divisions: 19,
          label: "$hours h",
          onChanged: (value){
            setState(() {
              hours = value.toInt();
              widget.onChangedLessonTime.call(hours);
            });
          },
        ),
        sessionTitle(
          "Duração por Sessão: $hoursPerSession h",
          description: "Defina quanto tempo durará cada encontro individual com o instrutor.",
        ),
        Slider(
          value: hoursPerSession.toDouble(),
          min: 1,
          max: 3,
          divisions: 2,
          label: "$hoursPerSession h",
          onChanged: (value){
            setState(() {
              hoursPerSession = value.toInt();
              widget.onChangedHoursPerSession.call(hoursPerSession);
            });
          },
        ),
      ],
    );
  }

  Widget sessionTitle(String value, {String? description}){
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge,),
          if(description != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              description, 
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultVehicleCard() {
    final vehicle = widget.defaultVehicle;

    if (vehicle == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          "O instrutor não possui veículo padrão cadastrado.",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.red[700],
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(top: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.directions_car, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${vehicle.brand} ${vehicle.model}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Cor: ${vehicle.color} • Categoria: ${vehicle.category}",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    "Combustível: ${vehicle.fuel}",
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
