import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AgendarAula2 extends StatefulWidget {
  const AgendarAula2({
    super.key,
    required this.onChangedDate,
    required this.onChangedTime,
  });

  final ValueChanged<DateTime> onChangedDate;
  final ValueChanged<String> onChangedTime;

  @override
  State<AgendarAula2> createState() => _AgendarAula2State();
}

class _AgendarAula2State extends State<AgendarAula2> with AutomaticKeepAliveClientMixin {
  String? timeSelected;

  // Gera horários das 06:00 às 22:00 com intervalo de 30 min
  List<String> generateTimeSlots() {
    List<String> slots = [];
    for (int hour = 6; hour <= 22; hour++) {
      slots.add("${hour.toString().padLeft(2, '0')}:00");
      if (hour != 22) {
        slots.add("${hour.toString().padLeft(2, '0')}:30");
      }
    }
    return slots;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final times = generateTimeSlots();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        sessionTitle("Data da aula"),
        SizedBox(height: 10,),
        Card(
          child: Padding(
            padding: const EdgeInsets.only(top: 20),
            child: CalendarDatePicker(
              initialDate: Timestamp.now().toDate(),
              firstDate: Timestamp.now().toDate(),
              lastDate: Timestamp.now().toDate().add(Duration(days: 30)),
              onDateChanged: (value){
                widget.onChangedDate.call(value);
              }
            ),
          ),
        ),
        sessionTitle("Horário"),
        Wrap(
          spacing: 5,
          children: times.map((time) {
            final isSelected = timeSelected == time;
            
            return RawChip(
              label: Text(time),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  timeSelected = time;
                  widget.onChangedTime.call(timeSelected!);
                });
              },
              backgroundColor: Colors.white,
              showCheckmark: true,
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