import 'dart:async';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instrutor_em_casa/models/aula.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/screens/aula_details/aula_details_screen.dart';
import 'package:instrutor_em_casa/widgets/theme.dart';
import 'package:ionicons/ionicons.dart';

class ActiveLessonWidget extends StatefulWidget {
  const ActiveLessonWidget({super.key, required this.lessonId, required this.usuario});
  final String lessonId;
  final Usuario usuario;

  @override
  State<ActiveLessonWidget> createState() => _ActiveLessonWidgetState();
}

class _ActiveLessonWidgetState extends State<ActiveLessonWidget> with SingleTickerProviderStateMixin {
  Timer? _timer;
  Duration _duration = Duration.zero;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection("aulas").doc(widget.lessonId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox();

        final aula = Aula.fromMap(snapshot.data!.data()!);
        
        // Find the active session (either en route or started)
        final activeSession = aula.sessions.firstWhere(
          (s) => (s.journeyState == JourneyState.enRoute && s.start == null) || (s.start != null && s.end == null),
          orElse: () => aula.sessions.first,
        );
        
        final bool isEnRoute = activeSession.journeyState == JourneyState.enRoute && activeSession.start == null;
        final bool isInProgress = activeSession.start != null && activeSession.end == null;

        if (!isEnRoute && !isInProgress) return const SizedBox();

        String title = isInProgress ? "AULA EM ANDAMENTO" : "INSTRUTOR A CAMINHO";
        Color baseColor = isInProgress ? AppColors.success : AppColors.primary;
        IconData icon = isInProgress ? Ionicons.play_circle : Ionicons.car;

        if (isInProgress) {
          _duration = DateTime.now().difference(activeSession.start!.toDate());
        }

        final hours = _duration.inHours.toString().padLeft(2, '0');
        final minutes = (_duration.inMinutes % 60).toString().padLeft(2, '0');
        final seconds = (_duration.inSeconds % 60).toString().padLeft(2, '0');

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: baseColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Card(
                color: baseColor,
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AulaDetailsScreen(
                          aula: aula,
                          usuario: widget.usuario,
                        ),
                      ),
                    );
                  },
                  borderRadius: AppRadius.radiusLg,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    child: Row(
                      children: [
                        Icon(icon, color: Colors.white, size: 30),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white, 
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                "Categoria ${aula.category.name}",
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        if (isInProgress)
                          Text(
                            "$hours:$minutes:$seconds",
                            style: const TextStyle(
                              color: Colors.white, 
                              fontWeight: FontWeight.bold, 
                              fontSize: 20,
                              fontFeatures: [ui.FontFeature.tabularFigures()],
                            ),
                          )
                        else
                          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
