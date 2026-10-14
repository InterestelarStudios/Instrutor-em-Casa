import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:instrutor_em_casa/models/aula.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/widgets/theme.dart';
import 'package:ionicons/ionicons.dart';

class HorasDirecaoScreen extends StatefulWidget {
  const HorasDirecaoScreen({super.key, required this.usuario});
  final Usuario usuario;

  @override
  State<HorasDirecaoScreen> createState() => _HorasDirecaoScreenState();
}

class _HorasDirecaoScreenState extends State<HorasDirecaoScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leadingWidth: 48,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(Ionicons.chevronBackOutline, color: AppColors.textPrimary, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        titleSpacing: 4,
        title: Text(
          "Horas de Direção",
          style: GoogleFonts.sora(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("aulas")
            .where("aluno.id", isEqualTo: widget.usuario.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Erro ao carregar dados: ${snapshot.error}",
                style: GoogleFonts.dmSans(color: AppColors.danger),
              ),
            );
          }

          int horasDirigidas = 0;
          int aulasRealizadas = 0;
          int aulasDiurnas = 0;
          int aulasNoturnas = 0;
          int exigido = 0;

          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              final aula = Aula.fromMap(doc.data() as Map<String, dynamic>);

              // Exigido calculation: sum hours of valid packages
              if (aula.status != LessonStatus.refused && aula.status != LessonStatus.canceled) {
                exigido += aula.horasContratadas;
              }

              // Finished sessions calculation
              for (var session in aula.sessions) {
                if (session.end != null) {
                  horasDirigidas += session.duration;
                  aulasRealizadas += 1;

                  final sessionTime = session.start?.toDate() ?? session.date.toDate();
                  final hour = sessionTime.hour;
                  if (hour >= 6 && hour < 18) {
                    aulasDiurnas += 1;
                  } else {
                    aulasNoturnas += 1;
                  }
                }
              }
            }
          }

          // Fallback to 20h if zero required hours
          if (exigido == 0) {
            exigido = 20;
          }

          final double progress = (horasDirigidas / exigido).clamp(0.0, 1.0);
          final int percent = (progress * 100).toInt();

          String statusText;
          if (percent >= 100) {
            statusText = "Parabéns, você está apto para realizar sua prova de direção";
          } else {
            final restam = (exigido - horasDirigidas).clamp(0, exigido);
            statusText = "Continue praticando! Faltam ${restam}h para completar a carga horária exigida.";
          }

          return SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 220,
                          height: 220,
                          child: CustomPaint(
                            painter: ArcPainter(
                              progress: progress,
                              progressColor: AppColors.primary,
                              backgroundColor: AppColors.gray100,
                              strokeWidth: 10.0,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: GoogleFonts.sora(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                                children: [
                                  TextSpan(text: "$horasDirigidas / $exigido"),
                                  TextSpan(
                                    text: "h",
                                    style: GoogleFonts.sora(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Concluido / Exigido",
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "$percent%",
                    style: GoogleFonts.sora(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      statusText,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Card(
                    color: AppColors.surface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.radiusLg,
                      side: const BorderSide(color: AppColors.border, width: 1),
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          _buildStatRow("Horas Dirigidas", "${horasDirigidas}h"),
                          const SizedBox(height: 16),
                          _buildStatRow("Aulas Realizadas", "$aulasRealizadas"),
                          const SizedBox(height: 16),
                          _buildStatRow("Aulas Diurnas", "$aulasDiurnas"),
                          const SizedBox(height: 16),
                          _buildStatRow("Aulas noturnas", "$aulasNoturnas"),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class ArcPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;
  final double strokeWidth;

  ArcPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
    this.strokeWidth = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double startAngle = 3 * pi / 4;
    final double maxSweepAngle = 1.5 * pi;
    final double sweepAngle = maxSweepAngle * progress.clamp(0.0, 1.0);

    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, maxSweepAngle, false, bgPaint);

    if (sweepAngle > 0) {
      final fgPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweepAngle, false, fgPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
