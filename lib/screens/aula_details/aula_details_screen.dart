import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:instrutor_em_casa/models/aula.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/screens/agendar_aula/steps/step1/agendar_aula_1.dart';
import 'package:instrutor_em_casa/screens/aula_details/cancellation_screen.dart';
import 'package:instrutor_em_casa/screens/aula_details/scanner_screen.dart';
import 'package:instrutor_em_casa/screens/aula_details/tracking_screen.dart';
import 'package:instrutor_em_casa/widgets/chip.dart';
import 'package:instrutor_em_casa/widgets/dialog_services.dart';
import 'package:instrutor_em_casa/widgets/theme.dart';
import 'package:instrutor_em_casa/widgets/user_tile.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
    bool isInstructor = aula.instrutor.id == widget.usuario.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pacote de Aulas"),
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'help') {
                // TODO: Navigate to support chat
              } else if (value == 'cancel') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CancellationScreen(aula: aula, usuario: widget.usuario),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'help',
                child: Row(
                  children: [
                    Icon(Ionicons.help_circle_outline, size: 20, color: Colors.blue),
                    SizedBox(width: 10),
                    Text("Ajuda com aula"),
                  ],
                ),
              ),
              if (aula.status != LessonStatus.done && 
                  aula.status != LessonStatus.canceled && 
                  aula.status != LessonStatus.refused &&
                  aula.status != LessonStatus.partially_done)
                const PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Ionicons.close_circle_outline, size: 20, color: AppColors.emergency),
                      SizedBox(width: 10),
                      Text("Cancelar aula"),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection("aulas").doc(aula.id).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.exists) {
            aula = Aula.fromMap(snapshot.data!.data()!);
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ListTile(
                contentPadding: const EdgeInsets.only(),
                title: Text("Categoria ${aula.category.name}", style: Theme.of(context).textTheme.displaySmall,),
                subtitle: Text("Início: ${DateFormat(DateFormat.MONTH_DAY).format(aula.date.toDate())} às ${DateFormat(DateFormat.HOUR24_MINUTE).format(aula.date.toDate())}h"),
                trailing: AppChip(
                  title: aula.statusValue(),
                  type: _getChipType(),
                ),
              ),
              
              if(isInstructor && aula.status == LessonStatus.requested)
              acceptOrRefuseWidget(),

              const SizedBox(height: 20),
              title("Progresso do Pacote"),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Horas Contratadas", style: Theme.of(context).textTheme.bodySmall),
                          Text("${aula.horasContratadas}h", style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Horas Restantes", style: Theme.of(context).textTheme.bodySmall),
                          Text("${aula.horasRestantes}h", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 15),
                      LinearProgressIndicator(
                        value: (aula.horasContratadas - aula.horasRestantes) / aula.horasContratadas,
                        backgroundColor: Colors.grey[200],
                        color: AppColors.primary,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              title("Sessões"),
              if(aula.sessions.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text("Nenhuma sessão registrada ainda.", textAlign: TextAlign.center),
                  ),
                )
              else
                ..._getOrderedSessions().map((session) {
                  final ordered = _getOrderedSessions();
                  final isCurrent = ordered.firstWhere((s) => s.end == null, orElse: () => ordered.last).id == session.id;
                  return _buildSessionCard(session, isCurrent);
                }),

              const SizedBox(height: 20),
              title(isInstructor ? "Aluno" : "Instrutor"),
              Card(
                margin: const EdgeInsets.only(bottom: 20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: UserTile(user: isInstructor ? aula.aluno : aula.instrutor),
                ),
              ),
              
              title("Detalhes do Pacote"),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      resumeRow(title: "Tipo de aula", value: lessonTypeTranslate(aula.type)),
                      resumeRow(title: "Veículo", value: lessonVehicleTranslate(aula.vehicle)),
                      resumeRow(title: "Pagamento", value: aula.paymentType.name.toUpperCase()),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  AppChipType _getChipType() {
    switch (aula.status) {
      case LessonStatus.accepted:
        return AppChipType.none;
      case LessonStatus.active:
        return AppChipType.none;
      case LessonStatus.done:
        return AppChipType.done;
      case LessonStatus.requested:
        return AppChipType.waiting;
      default:
        return AppChipType.inactive;
    }
  }

  List<SessaoAula> _getOrderedSessions() {
    List<SessaoAula> list = List.from(aula.sessions);
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  Widget _buildSessionCard(SessaoAula session, bool isCurrent) {
    bool isInstructor = aula.instrutor.id == widget.usuario.id;
    
    // Journey Buttons Logic
    bool canStartJourney = isInstructor && session.journeyState == JourneyState.none && session.start == null && isCurrent && (aula.status == LessonStatus.accepted || aula.status == LessonStatus.active);
    bool canAcceptJourney = !isInstructor && session.journeyState == JourneyState.requested && isCurrent;
    bool canTrack = session.journeyState == JourneyState.enRoute && isCurrent;
    bool canArrive = isInstructor && session.journeyState == JourneyState.enRoute && isCurrent;

    // Check-in logic: only if session is arrived and not started and isCurrent
    bool canCheckIn = session.journeyState == JourneyState.arrived && 
                      session.start == null && 
                      isCurrent && 
                      (aula.status == LessonStatus.accepted || aula.status == LessonStatus.active);

    bool bothCheckedIn = session.checkInAluno && session.checkInInstrutor;
    bool canStart = bothCheckedIn && session.start == null && isInstructor;
    bool canEnd = session.start != null && session.end == null && isInstructor;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat("dd/MM 'às' HH:mm").format(session.date.toDate()),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Row(
                  children: [
                    if (session.status == SessionStatus.missed)
                      const AppChip(title: "Perdida", type: AppChipType.danger),
                    const SizedBox(width: 5),
                    AppChip(
                      title: "${session.duration}h",
                      type: AppChipType.none,
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                _checkInIndicator("Aluno", session.checkInAluno),
                const SizedBox(width: 10),
                _checkInIndicator("Instrutor", session.checkInInstrutor),
              ],
            ),
            if(session.end != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text("Finalizada em: ${DateFormat("HH:mm").format(session.end!.toDate())}", style: const TextStyle(color: AppColors.success)),
              )
            else if(session.start != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text("Em andamento... (Início: ${DateFormat("HH:mm").format(session.start!.toDate())})", style: const TextStyle(color: AppColors.primary)),
              )
            else if (session.journeyState != JourneyState.none)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  session.journeyState == JourneyState.requested ? "Trajeto solicitado..." :
                  session.journeyState == JourneyState.enRoute ? "Instrutor a caminho..." : "Instrutor chegou!",
                  style: TextStyle(color: session.journeyState == JourneyState.arrived ? AppColors.success : AppColors.warning),
                ),
              ),
            
            if(session.end == null && isCurrent)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                children: [
                  if (session.status == SessionStatus.missed && !isInstructor && (aula.status == LessonStatus.accepted || aula.status == LessonStatus.active))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _rescheduleSession(session),
                          icon: const Icon(Ionicons.calendar_outline),
                          label: const Text("Remarcar Sessão"),
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      if (canStartJourney)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _updateJourney(session, JourneyState.requested),
                            icon: const Icon(Ionicons.navigate_outline),
                            label: const Text("Iniciar Trajeto"),
                          ),
                        ),
                      if (canAcceptJourney)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _updateJourney(session, JourneyState.enRoute),
                            icon: const Icon(Ionicons.checkmark_circle_outline),
                            label: const Text("Aceitar Trajeto"),
                          ),
                        ),
                      if (canTrack && !isInstructor)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TrackingScreen(aulaId: aula.id, otherUser: aula.instrutor))),
                            icon: const Icon(Ionicons.map_outline),
                            label: const Text("Acompanhar no Mapa"),
                          ),
                        ),
                      if (canArrive)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _updateJourney(session, JourneyState.arrived),
                            icon: const Icon(Ionicons.car_outline),
                            label: const Text("Cheguei"),
                          ),
                        ),
                    ],
                  ),
                  if (canCheckIn || canStart || canEnd) ... [
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if(canCheckIn && !bothCheckedIn)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (isInstructor) {
                                  _openScanner(session);
                                } else {
                                  _showQrCodeDialog();
                                }
                              },
                              child: const Text("Check-in"),
                            ),
                          ),
                        if(canStart)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _updateSession(session, start: true),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                              child: const Text("Iniciar Aula"),
                            ),
                          ),
                        if(canEnd)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _updateSession(session, end: true),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                              child: const Text("Finalizar Aula"),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateJourney(SessaoAula session, JourneyState newState) {
    bool isInstructor = aula.instrutor.id == widget.usuario.id;
    int index = aula.sessions.indexWhere((s) => s.id == session.id);
    if (index == -1) return;

    aula.sessions[index].journeyState = newState;

    FirebaseFirestore.instance.collection("aulas").doc(aula.id).update({
      "sessions": aula.sessions.map((s) => s.toMap()).toList(),
    }).then((_) {
      // Handle background service
      final service = FlutterBackgroundService();
      if (newState == JourneyState.enRoute && isInstructor) {
        service.startService();
        service.invoke("startTracking", {"lessonId": aula.id});
      } else if (newState == JourneyState.arrived && isInstructor) {
        service.invoke("stopTracking");
      }
    });
  }

  void _showQrCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Seu Check-in"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Mostre este QR Code ao instrutor para realizar o check-in da aula."),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              width: 200,
              child: QrImageView(
                data: aula.id,
                version: QrVersions.auto,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fechar")),
        ],
      ),
    );
  }

  void _openScanner(SessaoAula session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScannerScreen(
          onScan: (value) {
            if (value == aula.id) {
              _updateSession(session, checkIn: true, start: true);
            } else {
              DialogServices().alertDialog(context, "QR Code inválido para esta aula.");
            }
          },
        ),
      ),
    );
  }

  void _rescheduleSession(SessaoAula session) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (pickedDate != null) {
      // ignore: use_build_context_synchronously
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 8, minute: 0),
      );

      if (pickedTime != null) {
        final newDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        int index = aula.sessions.indexWhere((s) => s.id == session.id);
        if (index != -1) {
          aula.sessions[index].date = Timestamp.fromDate(newDate);
          aula.sessions[index].status = SessionStatus.scheduled;
          aula.sessions[index].journeyState = JourneyState.none;
          
          await FirebaseFirestore.instance.collection("aulas").doc(aula.id).update({
            "sessions": aula.sessions.map((s) => s.toMap()).toList(),
          });
          
          setState(() {});
        }
      }
    }
  }

  Widget _checkInIndicator(String label, bool checked) {
    return Row(
      children: [
        Icon(
          checked ? Ionicons.checkmark_circle : Ionicons.ellipse_outline,
          size: 16,
          color: checked ? AppColors.success : Colors.grey,
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  void _updateSession(SessaoAula session, {bool checkIn = false, bool start = false, bool end = false}) {
    // Find session in list
    int index = aula.sessions.indexWhere((s) => s.id == session.id);
    if (index == -1) return;

    if (checkIn) {
      // In scan logic, both are checked in
      aula.sessions[index].checkInInstrutor = true;
      aula.sessions[index].checkInAluno = true;
    }

    if (start) {
      aula.sessions[index].start = Timestamp.now();
      aula.status = LessonStatus.active;
    }

    if (end) {
      aula.sessions[index].end = Timestamp.now();
      aula.horasRestantes -= aula.sessions[index].duration;
      if (aula.horasRestantes <= 0) {
        aula.status = LessonStatus.done;
      }
    }

    final batch = FirebaseFirestore.instance.batch();
    final aulaRef = FirebaseFirestore.instance.collection("aulas").doc(aula.id);
    
    batch.update(aulaRef, {
      "sessions": aula.sessions.map((s) => s.toMap()).toList(),
      "status": aula.status.name,
      "horasRestantes": aula.horasRestantes,
    });

    if (start) {
      final alunoRef = FirebaseFirestore.instance.collection("users").doc(aula.aluno.id);
      final instrutorRef = FirebaseFirestore.instance.collection("users").doc(aula.instrutor.id);
      batch.update(alunoRef, {"inLesson": aula.id});
      batch.update(instrutorRef, {"inLesson": aula.id});
    }

    if (end) {
      final alunoRef = FirebaseFirestore.instance.collection("users").doc(aula.aluno.id);
      final instrutorRef = FirebaseFirestore.instance.collection("users").doc(aula.instrutor.id);
      
      if (aula.status == LessonStatus.done) {
        batch.update(alunoRef, {
          "inLesson": null,
          "pendingAvaliation": {
            "lessonId": aula.id,
            "targetUserId": aula.instrutor.id,
            "targetUserName": aula.instrutor.name,
            "targetUserImage": aula.instrutor.image,
          }
        });
        batch.update(instrutorRef, {
          "inLesson": null,
          "pendingAvaliation": {
            "lessonId": aula.id,
            "targetUserId": aula.aluno.id,
            "targetUserName": aula.aluno.name,
            "targetUserImage": aula.aluno.image,
          }
        });
      } else {
        batch.update(alunoRef, {"inLesson": null});
        batch.update(instrutorRef, {"inLesson": null});
      }
    }

    batch.commit().then((_) {
      setState(() {});
    });
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
