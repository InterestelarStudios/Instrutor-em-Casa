import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instrutor_em_casa/models/aula.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/widgets/dialog_services.dart';
import 'package:instrutor_em_casa/widgets/theme.dart';
import 'package:ionicons/ionicons.dart';

class CancellationScreen extends StatefulWidget {
  const CancellationScreen({super.key, required this.aula, required this.usuario});
  final Aula aula;
  final Usuario usuario;

  @override
  State<CancellationScreen> createState() => _CancellationScreenState();
}

class _CancellationScreenState extends State<CancellationScreen> {
  final TextEditingController _reasonController = TextEditingController();
  bool loading = false;

  List<String> get suggestions {
    if (widget.usuario.type == UserType.instrutor) {
      return [
        "Problemas mecânicos no veículo",
        "Imprevisto pessoal",
        "Local de encontro inacessível",
        "Aluno não compareceu",
        "Condições climáticas adversas",
      ];
    } else {
      return [
        "Imprevisto de última hora",
        "Problemas de saúde",
        "Não poderei comparecer",
        "Desejo trocar de instrutor",
        "Erro no agendamento",
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cancelar Aula"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          const Icon(Ionicons.alert_circle_outline, size: 80, color: AppColors.emergency),
          const SizedBox(height: 20),
          Text(
            "Por que você deseja cancelar?",
            style: AppTextStyles.h2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            "Seu feedback nos ajuda a melhorar a experiência da plataforma.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          const Text("Sugestões:", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((s) => ActionChip(
              label: Text(s),
              onPressed: () {
                setState(() {
                  _reasonController.text = s;
                });
              },
            )).toList(),
          ),
          const SizedBox(height: 30),
          TextField(
            controller: _reasonController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Descreva o motivo detalhadamente...",
              fillColor: Colors.grey[100],
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: loading ? null : _confirmCancellation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emergency,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: loading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Confirmar Cancelamento", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancellation() async {
    if (_reasonController.text.trim().isEmpty) {
      DialogServices().alertDialog(context, "Por favor, informe o motivo do cancelamento.");
      return;
    }

    setState(() => loading = true);

    try {
      final bool hasSessionsDone = widget.aula.horasContratadas > widget.aula.horasRestantes;
      final LessonStatus newStatus = hasSessionsDone ? LessonStatus.partially_done : LessonStatus.canceled;

      await FirebaseFirestore.instance.collection("aulas").doc(widget.aula.id).update({
        "status": newStatus.name,
        "cancellationReason": _reasonController.text.trim(),
        "canceledBy": widget.usuario.id,
        "canceledAt": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context); // Close cancellation screen
        Navigator.pop(context); // Back to previous screen (Details or Home)
        DialogServices.paymentAlert(
          context,
          success: true,
          message: "Aula cancelada com sucesso.",
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        DialogServices().alertDialog(context, "Erro ao cancelar aula: $e");
      }
    }
  }
}
