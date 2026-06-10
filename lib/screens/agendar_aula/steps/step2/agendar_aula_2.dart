import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instrutor_em_casa/models/aula.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class AgendarAula2 extends StatefulWidget {
  const AgendarAula2({
    super.key,
    required this.hours,
    required this.hoursPerSession,
    required this.onChangedSessions,
  });

  final int hours;
  final int hoursPerSession;
  final ValueChanged<List<SessaoAula>> onChangedSessions;

  @override
  State<AgendarAula2> createState() => _AgendarAula2State();
}

class _AgendarAula2State extends State<AgendarAula2> with AutomaticKeepAliveClientMixin {
  List<SessaoAula> sessions = [];

  @override
  void initState() {
    super.initState();
    _initializeSessions();
  }

  @override
  void didUpdateWidget(AgendarAula2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hours != widget.hours || oldWidget.hoursPerSession != widget.hoursPerSession) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeSessions();
      });
    }
  }

  void _initializeSessions() {
    List<SessaoAula> newSessions = [];
    int remainingHours = widget.hours;
    
    while (remainingHours > 0) {
      int duration = remainingHours < widget.hoursPerSession ? remainingHours : widget.hoursPerSession;
      newSessions.add(SessaoAula(
        id: const Uuid().v4(),
        // Initialize with a dummy date to indicate 'not scheduled'
        date: Timestamp.fromDate(DateTime(2000)), 
        duration: duration,
      ));
      remainingHours -= duration;
    }
    
    // Ensure actual check-in fields are null
    for(var s in newSessions) {
      s.start = null;
      s.end = null;
    }

    setState(() {
      sessions = newSessions;
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onChangedSessions.call(sessions);
    });
  }

  Future<void> _pickDateTime(int index) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _getInitialDate(index),
      firstDate: _getMinDate(index),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      helpText: "Selecione a data da Sessão ${index + 1}",
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 8, minute: 0),
        helpText: "Horário de início da aula",
      );

      if (pickedTime != null) {
        setState(() {
          final startDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          
          sessions[index].date = Timestamp.fromDate(startDateTime);
          sessions[index].start = null; 
          sessions[index].end = null; 
          
          // Reset subsequent sessions if they violate the chronological rule
          _validateAndResetSubsequent(index);
        });
        widget.onChangedSessions.call(sessions);
      }
    }
  }

  DateTime _getMinDate(int index) {
    if (index == 0) return DateTime.now();
    // Next session must be at least one day after the previous one
    return sessions[index - 1].date.toDate().add(const Duration(days: 1));
  }

  DateTime _getInitialDate(int index) {
    DateTime min = _getMinDate(index);
    // If current session already has a date and it's valid, keep it, else use min
    if (sessions[index].date.toDate().year > 2000 && sessions[index].date.toDate().isAfter(min.subtract(const Duration(seconds: 1)))) {
      return sessions[index].date.toDate();
    }
    return min;
  }

  void _validateAndResetSubsequent(int startIndex) {
    for (int i = startIndex + 1; i < sessions.length; i++) {
      DateTime prevDate = sessions[i - 1].date.toDate();
      if (sessions[i].date.toDate().year > 2000) {
        DateTime currDate = sessions[i].date.toDate();
        if (!currDate.isAfter(prevDate)) {
          sessions[i].date = Timestamp.fromDate(DateTime(2000));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        final bool isScheduled = session.date.toDate().year > 2000;

        return Card(
          margin: const EdgeInsets.only(bottom: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(
              color: isScheduled ? Colors.blue.shade200 : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () => _pickDateTime(index),
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Sessão ${index + 1}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "${session.duration}h de aula",
                          style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  if (isScheduled) ...[
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd/MM/yyyy').format(session.date.toDate()),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 18, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          "${DateFormat('HH:mm').format(session.date.toDate())} às ${DateFormat('HH:mm').format(session.date.toDate().add(Duration(hours: session.duration)))}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ] else ...[
                    const Text(
                      "Toque para definir data e horário",
                      style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
