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
    required this.alunoId,
    required this.instrutorId,
  });

  final int hours;
  final int hoursPerSession;
  final ValueChanged<List<SessaoAula>> onChangedSessions;
  final String alunoId;
  final String instrutorId;

  @override
  State<AgendarAula2> createState() => _AgendarAula2State();
}

class _AgendarAula2State extends State<AgendarAula2> with AutomaticKeepAliveClientMixin {
  List<SessaoAula> sessions = [];
  List<ScheduledRange> _existingSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeSessions();
    _loadExistingSessions();
  }

  Future<void> _loadExistingSessions() async {
    try {
      final studentQuery = await FirebaseFirestore.instance
          .collection("aulas")
          .where("aluno.id", isEqualTo: widget.alunoId)
          .where("status", whereIn: ["requested", "accepted", "active", "partially_done"])
          .get();

      final instructorQuery = await FirebaseFirestore.instance
          .collection("aulas")
          .where("instrutor.id", isEqualTo: widget.instrutorId)
          .where("status", whereIn: ["requested", "accepted", "active", "partially_done"])
          .get();

      List<ScheduledRange> ranges = [];

      for (var doc in studentQuery.docs) {
        final aulaData = doc.data();
        final sessionsList = (aulaData['sessions'] as List<dynamic>?) ?? [];
        final instrutorName = aulaData['instrutor']['name'] as String? ?? "Instrutor";
        for (var sMap in sessionsList) {
          final statusStr = sMap['status'] as String? ?? 'scheduled';
          if (statusStr == 'completed' || statusStr == 'missed') continue;

          final date = (sMap['date'] as Timestamp).toDate();
          final duration = sMap['duration'] as int? ?? 1;
          ranges.add(ScheduledRange(
            start: date,
            end: date.add(Duration(hours: duration)),
            label: "aluno",
            otherName: instrutorName,
          ));
        }
      }

      for (var doc in instructorQuery.docs) {
        final aulaData = doc.data();
        final sessionsList = (aulaData['sessions'] as List<dynamic>?) ?? [];
        final alunoName = aulaData['aluno']['name'] as String? ?? "Aluno";
        for (var sMap in sessionsList) {
          final statusStr = sMap['status'] as String? ?? 'scheduled';
          if (statusStr == 'completed' || statusStr == 'missed') continue;

          final date = (sMap['date'] as Timestamp).toDate();
          final duration = sMap['duration'] as int? ?? 1;
          ranges.add(ScheduledRange(
            start: date,
            end: date.add(Duration(hours: duration)),
            label: "instrutor",
            otherName: alunoName,
          ));
        }
      }

      if (mounted) {
        setState(() {
          _existingSessions = ranges;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint("Erro ao carregar sessões existentes: $e");
    }
  }

  String? _checkConflict(DateTime start, int durationHours) {
    final end = start.add(Duration(hours: durationHours));

    for (var existing in _existingSessions) {
      final bufferedExistingStart = existing.start.subtract(const Duration(minutes: 30));
      final bufferedExistingEnd = existing.end.add(const Duration(minutes: 30));

      if (start.isBefore(bufferedExistingEnd) && end.isAfter(bufferedExistingStart)) {
        final formattedDate = DateFormat('dd/MM/yyyy').format(existing.start);
        final formattedStart = DateFormat('HH:mm').format(existing.start);
        final formattedEnd = DateFormat('HH:mm').format(existing.end);

        if (existing.label == "aluno") {
          return "Você já possui uma aula agendada para este dia ($formattedDate) das $formattedStart às $formattedEnd com o instrutor ${existing.otherName}. Por favor, selecione outro horário.";
        } else {
          return "O instrutor já possui uma aula agendada para este dia ($formattedDate) das $formattedStart às $formattedEnd com o aluno ${existing.otherName}. Por favor, selecione outro horário.";
        }
      }
    }
    return null;
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
    if (_isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aguarde, verificando disponibilidade de horários...")),
      );
      return;
    }

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
        final startDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        final conflictMessage = _checkConflict(startDateTime, sessions[index].duration);
        if (conflictMessage != null) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Conflito de Horário"),
                content: Text(conflictMessage),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Entendi"),
                  ),
                ],
              ),
            );
          }
          return;
        }

        setState(() {
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

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 15),
            Text("Verificando disponibilidade de horários...", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

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

class ScheduledRange {
  final DateTime start;
  final DateTime end;
  final String label; // "aluno" or "instrutor"
  final String otherName; // Name of the other party

  ScheduledRange({
    required this.start,
    required this.end,
    required this.label,
    required this.otherName,
  });
}
