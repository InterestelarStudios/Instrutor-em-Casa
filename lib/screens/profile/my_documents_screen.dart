import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:instrutor_em_casa/models/instrutor.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/services/firestore_upload_files.dart';
import 'package:instrutor_em_casa/widgets/chip.dart';
import 'package:instrutor_em_casa/widgets/dialog_services.dart';
import 'package:instrutor_em_casa/widgets/theme.dart';
import 'package:ionicons/ionicons.dart';
import 'package:url_launcher/url_launcher.dart';

class MyDocumentsScreen extends StatefulWidget {
  const MyDocumentsScreen({super.key, required this.usuario});
  final Usuario usuario;

  @override
  State<MyDocumentsScreen> createState() => _MyDocumentsScreenState();
}

class _MyDocumentsScreenState extends State<MyDocumentsScreen> {
  late Usuario usuario;

  @override
  void initState() {
    super.initState();
    usuario = widget.usuario;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Meus Documentos"),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection("users").doc(usuario.id).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.exists) {
            usuario = Usuario.fromMap(snapshot.data!.data()!);
          }

          if (usuario.type == UserType.instrutor) {
            return _buildInstrutorDocs();
          } else {
            return _buildAlunoDocs();
          }
        },
      ),
    );
  }

  Widget _buildInstrutorDocs() {
    final instrutor = usuario.instrutor;
    if (instrutor == null) return const Center(child: Text("Dados do instrutor não encontrados."));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [

        _buildDocumentTile(context, "Credencial", instrutor.credencial, DocumentType.credencial),
        _buildDocumentTile(context, "Selfie de Identificação", instrutor.face, DocumentType.face),
        const SizedBox(height: 20),
        _buildVerificationStatus(instrutor.asaasStatus),
      ],
    );
  }

  Widget _buildAlunoDocs() {
    final aluno = usuario.aluno;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildDocumentTile(
          context,
          "Certidão da Prova Teórica (Legislação)",
          aluno?.certidaoTeorica ?? aluno?.ladv,
          DocumentType.certidaoTeorica,
        ),
        _buildDocumentTile(context, "CNH", aluno?.cnh, DocumentType.cnh),
        if (aluno == null)
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Text(
              "Anexe seus documentos para solicitar aulas.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
      ],
    );
  }

  Widget _buildVerificationStatus(String? status) {
    return Card(
      color: Colors.blue[50],
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            const Icon(Ionicons.informationCircleOutline, color: Colors.blue),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                "Status Geral de Verificação: ${status ?? 'PENDENTE'}",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentTile(BuildContext context, String title, UserDocument? doc, DocumentType type) {
    final bool isApproved = doc?.status == DocumentStatus.approved;
    final bool isSended = doc?.status == DocumentStatus.sended;

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      elevation: 0,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(15),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                AppChip(
                  title: doc == null ? "Não enviado" : _statusTranslate(doc.status),
                  type: doc == null ? AppChipType.inactive : _statusType(doc.status),
                ),
                if (doc?.message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      doc!.message!,
                      style: const TextStyle(color: AppColors.emergency, fontSize: 12),
                    ),
                  ),
              ],
            ),
            trailing: doc != null 
              ? IconButton(
                  icon: const Icon(Ionicons.eyeOutline),
                  onPressed: () => launchUrl(Uri.parse(doc.url)),
                )
              : null,
          ),
          if (!isApproved && !isSended)
            Padding(
              padding: const EdgeInsets.only(bottom: 15, left: 15, right: 15),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _pickAndUpload(title, type),
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Enviar Documento"),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickAndUpload(String title, DocumentType type) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      
      // ignore: use_build_context_synchronously
      DialogServices.loading2(context);

      try {
        String url = await FirestoreUploadFiles().uploadDingleFile(
          arquivo: file,
          diretorio: "documentos/${usuario.id}",
          fileName: type.name,
        );

        Map<String, dynamic> updateData = {};
        if (usuario.type == UserType.instrutor) {
          String field = type.name;
          updateData["instrutor.$field.url"] = url;
          updateData["instrutor.$field.status"] = DocumentStatus.sended.name;
          updateData["instrutor.$field.type"] = type.name;
        } else {
          String field = type.name;
          // A certidão da prova teórica não passa por verificação manual e já sobe como aprovada
          final status = (type == DocumentType.certidaoTeorica)
              ? DocumentStatus.approved
              : DocumentStatus.sended;

          updateData["aluno.$field.url"] = url;
          updateData["aluno.$field.status"] = status.name;
          updateData["aluno.$field.type"] = type.name;
        }

        await FirebaseFirestore.instance.collection("users").doc(usuario.id).update(updateData);
        
        // ignore: use_build_context_synchronously
        Navigator.pop(context);
        final String successMessage = (type == DocumentType.certidaoTeorica)
            ? "Certidão teórica anexada e aprovada com sucesso! Você já pode agendar suas aulas."
            : "Documento enviado com sucesso! Aguarde a aprovação.";
        // ignore: use_build_context_synchronously
        DialogServices().alertDialog(context, successMessage, title: "Sucesso");
      } catch (e) {
        // ignore: use_build_context_synchronously
        Navigator.pop(context);
        // ignore: use_build_context_synchronously
        DialogServices().alertDialog(context, "Erro ao enviar documento: $e");
      }
    }
  }

  String _statusTranslate(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.sended:
        return "Em análise";
      case DocumentStatus.approved:
        return "Aprovado";
      case DocumentStatus.refused:
        return "Recusado";
      case DocumentStatus.expired:
        return "Expirado";
    }
  }

  AppChipType _statusType(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.approved:
        return AppChipType.done;
      case DocumentStatus.refused:
        return AppChipType.danger;
      case DocumentStatus.expired:
        return AppChipType.waiting;
      default:
        return AppChipType.none;
    }
  }
}
