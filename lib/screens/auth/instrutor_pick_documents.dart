import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instrutor_em_casa/models/instrutor.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/screens/profile/pdf_viewer_screen.dart';

import 'package:instrutor_em_casa/services/firestore_upload_files.dart';
import 'package:instrutor_em_casa/widgets/dialog_services.dart';

class InstrutorPickDocuments extends StatefulWidget {
  const InstrutorPickDocuments({super.key});

  @override
  State<InstrutorPickDocuments> createState() => _InstrutorPickDocumentsState();
}

class _InstrutorPickDocumentsState extends State<InstrutorPickDocuments> {
  PlatformFile? credencial;
  PlatformFile? selfie;
  bool loading = false;

  Future<void> _pickDocument(ValueChanged<PlatformFile> onPicked) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text("Tirar Foto (Câmera)"),
              onTap: () async {
                Navigator.pop(context);
                final picked = await ImagePicker().pickImage(
                  source: ImageSource.camera,
                  imageQuality: 80,
                );
                if (picked != null) {
                  onPicked(PlatformFile(
                    name: picked.name,
                    path: picked.path,
                    size: await picked.length(),
                  ));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_search_rounded),
              title: const Text("Escolher da Galeria ou Arquivos"),
              onTap: () async {
                Navigator.pop(context);
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                );
                if (result != null) {
                  onPicked(result.files.first);
                }
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showInstructorContractDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Contrato do Instrutor"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Ao se tornar um instrutor parceiro, você concorda com os seguintes termos:"),
              const SizedBox(height: 15),
              _pointItem("Autonomia: Relação civil sem vínculo empregatício com a plataforma."),
              _pointItem("Regularidade: Manter CNH e credenciais de instrutor válidas."),
              _pointItem("Veículo: Responsabilidade total pela segurança e documentação do seu veículo."),
              _pointItem("Bypass: Proibido receber pagamentos por fora de alunos vindos do app."),
              _pointItem("Privacidade: Dados dos alunos são confidenciais e exclusivos para as aulas."),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PdfViewerScreen(
                        title: "Contrato do Instrutor",
                        assetPath: "assets/contrato_instrutor.pdf",
                      ),
                    ),
                  );
                },
                child: const Text("Ver contrato completo", style: TextStyle(decoration: TextDecoration.underline)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processDocuments();
            },
            child: const Text("Aceitar e Enviar"),
          ),
        ],
      ),
    );
  }

  Widget _pointItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Future<void> _processDocuments() async {
    setState(() {
      loading = true;
    });
    final firebaseUser = FirebaseAuth.instance.currentUser;

    String? credentialUrl;
    String? selfieUrl;

    try{
      // 1. Upload para Firebase Storage
      credentialUrl = await FirestoreUploadFiles().uploadDingleFile(
        arquivo: File(credencial!.path!),
        diretorio: "documents/${firebaseUser!.uid}",
        fileName: "credential"
      );

      selfieUrl = await FirestoreUploadFiles().uploadDingleFile(
        arquivo: File(selfie!.path!),
        diretorio: "documents/${firebaseUser.uid}",
        fileName: "selfie"
      );

      // 4. Atualizar Firestore com dados do Instrutor
      await FirebaseFirestore.instance.collection("users").doc(firebaseUser.uid).update({
        "type" : UserType.instrutor.name,
        "instrutor" : InstrutorData(
          active: false,
          asaasStatus: 'PENDING',
          credencial: UserDocument(
            type: DocumentType.credencial,
            status: DocumentStatus.sended,
            url: credentialUrl,
          ),
          categories: [],
          aulas: 0,
          horas: 0,
          face: UserDocument(
            type: DocumentType.face,
            status: DocumentStatus.sended,
            url: selfieUrl,
          ),
        ).toMap()
      });

      if (context.mounted) {
        Navigator.pop(context);
        DialogServices().alertDialog(context, "Seus documentos foram enviados! Você será notificado assim que for aprovado na plataforma!", title: "Seja bem vindo!");
      }

    } catch (e){
      setState(() {
        loading = false;
      });
      debugPrint(e.toString());
      if (context.mounted) {
        DialogServices().alertDialog(context, "Erro ao processar documentos: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            "Envio de Documentos",
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 20,),
          Text(
            "Olá, Instrutor! Para prosseguir com sua conta, precisamos que nos envie os seguintes documentos:",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 40,),
          Text("Credencial de Instrutor", style: Theme.of(context).textTheme.titleLarge,),
          ListTile(
            selected: credencial != null,
            contentPadding: const EdgeInsets.only(),
            onTap: loading ? null : () => _pickDocument((file) => setState(() => credencial = file)),
            title: const Text("Toque para Anexar"),
            leading: const Icon(Icons.attach_file_rounded),
            subtitle: credencial == null ? null : Text(credencial!.name),
          ),
          const SizedBox(height: 20,),
          Text("Selfie com Documento", style: Theme.of(context).textTheme.titleLarge,),
          ListTile(
            selected: selfie != null,
            onTap: loading ? null : () => _pickDocument((file) => setState(() => selfie = file)),
            contentPadding: const EdgeInsets.only(),
            title: const Text("Toque para Anexar"),
            leading: const Icon(Icons.add_a_photo_rounded),
            subtitle: selfie == null ? null : Text(selfie!.name),
          ),
        ],
      ),
      bottomNavigationBar: credencial != null && selfie != null ?
      Container(
        height: 50,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: FilledButton(
          onPressed: loading ? null : () async {
            _showInstructorContractDialog();
          },
          child: loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2,)) : const Text("Prosseguir")
        ),
      ) : null,
    );
  }
}
