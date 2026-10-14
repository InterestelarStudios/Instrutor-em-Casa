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
  BuildContext? _loadingDialogContext;

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
        date: Timestamp.fromDate(DateTime(2000)),
        duration: duration,
      ));
      remainingHours -= duration;
    }

    for (var s in newSessions) {
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

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        _loadingDialogContext = dialogCtx;
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: CircularProgressIndicator(
                      strokeWidth: 3.5,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Verificando Disponibilidade",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Consultando agenda do aluno e do instrutor...",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _hideLoadingDialog() {
    if (_loadingDialogContext != null) {
      if (_loadingDialogContext!.mounted) {
        Navigator.of(_loadingDialogContext!).pop();
      }
      _loadingDialogContext = null;
    }
  }

  void _showConflictDialog({
    required bool isAluno,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_busy_rounded,
                color: Colors.red.shade600,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Horário Indisponível",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isAluno ? Colors.orange.shade50 : Colors.purple.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isAluno ? Colors.orange.shade200 : Colors.purple.shade200,
                ),
              ),
              child: Text(
                isAluno ? "Conflito na sua agenda (Aluno)" : "Conflito na agenda do Instrutor",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isAluno ? Colors.orange.shade900 : Colors.purple.shade900,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue.shade700,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Entendi"),
          ),
        ],
      ),
    );
  }

  Future<_ConflictCheckResult> _verifyAvailability({
    required DateTime candidateStart,
    required int durationHours,
    required int sessionIndex,
  }) async {
    final candidateEnd = candidateStart.add(Duration(hours: durationHours));

    // 1. Horário no passado
    if (candidateStart.isBefore(DateTime.now())) {
      return _ConflictCheckResult(
        hasConflict: true,
        isAluno: true,
        message: "Não será possível realizar a aula nesta data ou horário. O horário selecionado já passou. Por favor, escolha uma data e horário futuros.",
      );
    }

    // 2. Conflito com outras sessões deste mesmo pacote
    for (int i = 0; i < sessions.length; i++) {
      if (i == sessionIndex) continue;
      final other = sessions[i];
      final otherStart = other.date.toDate();
      if (otherStart.year <= 2000) continue;
      final otherEnd = otherStart.add(Duration(hours: other.duration));

      if (candidateStart.isBefore(otherEnd) && candidateEnd.isAfter(otherStart)) {
        final formattedDate = DateFormat('dd/MM/yyyy').format(otherStart);
        final formattedStart = DateFormat('HH:mm').format(otherStart);
        final formattedEnd = DateFormat('HH:mm').format(otherEnd);

        return _ConflictCheckResult(
          hasConflict: true,
          isAluno: true,
          message: "Não será possível realizar a aula nesta data ou horário.\n\n"
              "Você já selecionou a Sessão ${i + 1} para este mesmo período ($formattedDate das $formattedStart às $formattedEnd).\n\n"
              "Por favor, escolha outro horário.",
        );
      }
    }

    // 3. Consulta em tempo real no Firestore para aluno e instrutor
    final results = await Future.wait([
      FirebaseFirestore.instance
          .collection("aulas")
          .where("aluno.id", isEqualTo: widget.alunoId)
          .where("status", whereIn: ["requested", "accepted", "active", "partially_done"])
          .get(),
      FirebaseFirestore.instance
          .collection("aulas")
          .where("instrutor.id", isEqualTo: widget.instrutorId)
          .where("status", whereIn: ["requested", "accepted", "active", "partially_done"])
          .get(),
    ]);

    final alunoDocs = results[0].docs;
    final instrutorDocs = results[1].docs;

    // 4. Verificar conflito do aluno
    for (var doc in alunoDocs) {
      final aulaData = doc.data();
      final sessionsList = (aulaData['sessions'] as List<dynamic>?) ?? [];

      if (sessionsList.isNotEmpty) {
        for (var sMap in sessionsList) {
          if (sMap is! Map<String, dynamic>) continue;
          final statusStr = sMap['status'] as String? ?? 'scheduled';
          if (statusStr == 'completed' || statusStr == 'missed') continue;

          DateTime? existingStart;
          if (sMap['date'] is Timestamp) {
            existingStart = (sMap['date'] as Timestamp).toDate();
          } else if (sMap['date'] is String) {
            existingStart = DateTime.tryParse(sMap['date'] as String);
          }
          if (existingStart == null || existingStart.year <= 2000) continue;

          final duration = (sMap['duration'] as num?)?.toInt() ?? 1;
          final existingEnd = existingStart.add(Duration(hours: duration));

          if (candidateStart.isBefore(existingEnd) && candidateEnd.isAfter(existingStart)) {
            final formattedDate = DateFormat('dd/MM/yyyy').format(existingStart);
            final formattedStart = DateFormat('HH:mm').format(existingStart);
            final formattedEnd = DateFormat('HH:mm').format(existingEnd);

            return _ConflictCheckResult(
              hasConflict: true,
              isAluno: true,
              message: "Não será possível realizar a aula nesta data ou horário.\n\n"
                  "Você já possui uma aula agendada para o dia $formattedDate das $formattedStart às $formattedEnd.\n\n"
                  "Por favor, escolha outro horário.",
            );
          }
        }
      } else {
        DateTime? existingStart;
        if (aulaData['date'] is Timestamp) {
          existingStart = (aulaData['date'] as Timestamp).toDate();
        } else if (aulaData['date'] is String) {
          existingStart = DateTime.tryParse(aulaData['date'] as String);
        }
        if (existingStart != null && existingStart.year > 2000) {
          final duration = (aulaData['horasContratadas'] as num?)?.toInt() ?? 1;
          final existingEnd = existingStart.add(Duration(hours: duration));

          if (candidateStart.isBefore(existingEnd) && candidateEnd.isAfter(existingStart)) {
            final formattedDate = DateFormat('dd/MM/yyyy').format(existingStart);
            final formattedStart = DateFormat('HH:mm').format(existingStart);
            final formattedEnd = DateFormat('HH:mm').format(existingEnd);

            return _ConflictCheckResult(
              hasConflict: true,
              isAluno: true,
              message: "Não será possível realizar a aula nesta data ou horário.\n\n"
                  "Você já possui uma aula agendada para o dia $formattedDate das $formattedStart às $formattedEnd.\n\n"
                  "Por favor, escolha outro horário.",
            );
          }
        }
      }
    }

    // 5. Verificar conflito do instrutor (incluindo aulas anteriores que ocupem o horário)
    for (var doc in instrutorDocs) {
      final aulaData = doc.data();
      final sessionsList = (aulaData['sessions'] as List<dynamic>?) ?? [];

      if (sessionsList.isNotEmpty) {
        for (var sMap in sessionsList) {
          if (sMap is! Map<String, dynamic>) continue;
          final statusStr = sMap['status'] as String? ?? 'scheduled';
          if (statusStr == 'completed' || statusStr == 'missed') continue;

          DateTime? existingStart;
          if (sMap['date'] is Timestamp) {
            existingStart = (sMap['date'] as Timestamp).toDate();
          } else if (sMap['date'] is String) {
            existingStart = DateTime.tryParse(sMap['date'] as String);
          }
          if (existingStart == null || existingStart.year <= 2000) continue;

          final duration = (sMap['duration'] as num?)?.toInt() ?? 1;
          final existingEnd = existingStart.add(Duration(hours: duration));

          if (candidateStart.isBefore(existingEnd) && candidateEnd.isAfter(existingStart)) {
            final formattedDate = DateFormat('dd/MM/yyyy').format(existingStart);
            final formattedStart = DateFormat('HH:mm').format(existingStart);
            final formattedEnd = DateFormat('HH:mm').format(existingEnd);

            return _ConflictCheckResult(
              hasConflict: true,
              isAluno: false,
              message: "Não será possível realizar a aula nesta data ou horário.\n\n"
                  "O instrutor já possui uma aula agendada que ocupa este horário (dia $formattedDate das $formattedStart às $formattedEnd).\n\n"
                  "Por favor, selecione outro horário.",
            );
          }
        }
      } else {
        DateTime? existingStart;
        if (aulaData['date'] is Timestamp) {
          existingStart = (aulaData['date'] as Timestamp).toDate();
        } else if (aulaData['date'] is String) {
          existingStart = DateTime.tryParse(aulaData['date'] as String);
        }
        if (existingStart != null && existingStart.year > 2000) {
          final duration = (aulaData['horasContratadas'] as num?)?.toInt() ?? 1;
          final existingEnd = existingStart.add(Duration(hours: duration));

          if (candidateStart.isBefore(existingEnd) && candidateEnd.isAfter(existingStart)) {
            final formattedDate = DateFormat('dd/MM/yyyy').format(existingStart);
            final formattedStart = DateFormat('HH:mm').format(existingStart);
            final formattedEnd = DateFormat('HH:mm').format(existingEnd);

            return _ConflictCheckResult(
              hasConflict: true,
              isAluno: false,
              message: "Não será possível realizar a aula nesta data ou horário.\n\n"
                  "O instrutor já possui uma aula agendada que ocupa este horário (dia $formattedDate das $formattedStart às $formattedEnd).\n\n"
                  "Por favor, selecione outro horário.",
            );
          }
        }
      }
    }

    return _ConflictCheckResult(hasConflict: false);
  }

  Future<void> _pickDateTime(int index) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _getInitialDate(index),
      firstDate: _getMinDate(index),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      helpText: "Selecione a data da Sessão ${index + 1}",
    );

    if (pickedDate == null || !mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      helpText: "Horário de início da aula",
    );

    if (pickedTime == null || !mounted) return;

    final startDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    // Exibir o popup de loading "Verificando Disponibilidade"
    _showLoadingDialog();

    _ConflictCheckResult? conflictResult;
    try {
      final checkFuture = _verifyAvailability(
        candidateStart: startDateTime,
        durationHours: sessions[index].duration,
        sessionIndex: index,
      );
      final delayFuture = Future.delayed(const Duration(milliseconds: 600));

      final results = await Future.wait([checkFuture, delayFuture]);
      conflictResult = results[0] as _ConflictCheckResult;
    } catch (e) {
      debugPrint("Erro ao verificar disponibilidade: $e");
    } finally {
      if (mounted) {
        _hideLoadingDialog();
      }
    }

    if (!mounted) return;

    if (conflictResult == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Erro de Verificação"),
          content: const Text(
            "Não foi possível verificar a disponibilidade no momento. Verifique sua conexão e tente novamente.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    if (conflictResult.hasConflict) {
      _showConflictDialog(
        isAluno: conflictResult.isAluno,
        message: conflictResult.message ??
            "Não será possível realizar a aula nesta data ou horário.",
      );
      return;
    }

    // Sem conflito: define data e horário da sessão
    setState(() {
      sessions[index].date = Timestamp.fromDate(startDateTime);
      sessions[index].start = null;
      sessions[index].end = null;
      _validateAndResetSubsequent(index);
    });
    widget.onChangedSessions.call(sessions);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text("Horário da Sessão ${index + 1} confirmado!"),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  DateTime _getMinDate(int index) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (index == 0) return today;

    final prevDate = sessions[index - 1].date.toDate();
    if (prevDate.year > 2000) {
      final prevDay = DateTime(prevDate.year, prevDate.month, prevDate.day);
      return prevDay.isAfter(today) ? prevDay : today;
    }
    return today;
  }

  DateTime _getInitialDate(int index) {
    final min = _getMinDate(index);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final baseMin = min.isBefore(today) ? today : min;

    final currDate = sessions[index].date.toDate();
    if (currDate.year > 2000 && !currDate.isBefore(baseMin)) {
      return DateTime(currDate.year, currDate.month, currDate.day);
    }
    return baseMin;
  }

  void _validateAndResetSubsequent(int startIndex) {
    for (int i = startIndex + 1; i < sessions.length; i++) {
      final prevSession = sessions[i - 1];
      final prevDate = prevSession.date.toDate();
      if (prevDate.year <= 2000) continue;
      final prevEnd = prevDate.add(Duration(hours: prevSession.duration));

      final currSession = sessions[i];
      final currDate = currSession.date.toDate();
      if (currDate.year > 2000) {
        if (currDate.isBefore(prevEnd)) {
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

class _ConflictCheckResult {
  final bool hasConflict;
  final bool isAluno;
  final String? message;

  _ConflictCheckResult({
    required this.hasConflict,
    this.isAluno = false,
    this.message,
  });
}

