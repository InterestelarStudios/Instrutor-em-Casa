import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instrutor_em_casa/models/instrutor.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/services/firestore_upload_files.dart';
import 'package:instrutor_em_casa/widgets/dialog_services.dart';

class InstrutorPickDocuments extends StatefulWidget {
  const InstrutorPickDocuments({super.key});

  @override
  State<InstrutorPickDocuments> createState() => _InstrutorPickDocumentsState();
}

class _InstrutorPickDocumentsState extends State<InstrutorPickDocuments> {
  PlatformFile? credencial;
  PlatformFile? cnh;
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
            title: Text("Toque para Anexar"),
            leading: Icon(Icons.attach_file_rounded),
            subtitle: credencial == null ? null : Text(credencial!.name),
          ),
          const SizedBox(height: 20,),
          Text("CNH", style: Theme.of(context).textTheme.titleLarge,),
          ListTile(
            selected: cnh != null,
            onTap: loading ? null : () => _pickDocument((file) => setState(() => cnh = file)),
            contentPadding: const EdgeInsets.only(),
            title: Text("Toque para Anexar"),
            leading: Icon(Icons.attach_file_rounded),
            subtitle: cnh == null ? null : Text(cnh!.name),
          ),
          const SizedBox(height: 20,),
          Text("Selfie com Documento", style: Theme.of(context).textTheme.titleLarge,),
          ListTile(
            selected: selfie != null,
            onTap: loading ? null : () => _pickDocument((file) => setState(() => selfie = file)),
            contentPadding: const EdgeInsets.only(),
            title: Text("Toque para Anexar"),
            leading: Icon(Icons.add_a_photo_rounded),
            subtitle: selfie == null ? null : Text(selfie!.name),
          ),
        ],
      ),
      bottomNavigationBar: credencial != null && cnh != null && selfie != null ?
      Container(
        height: 50,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: FilledButton(
          onPressed: loading ? null : () async {
            setState(() {
              loading = true;
            });
            final firebaseUser = FirebaseAuth.instance.currentUser;

            String? credentialUrl;
            String? cnhUrl;
            String? selfieUrl;

            try{
              // 1. Upload para Firebase Storage
              credentialUrl = await FirestoreUploadFiles().uploadDingleFile(
                arquivo: File(credencial!.path!),
                diretorio: "documents/${firebaseUser!.uid}",
                fileName: "credential"
              );

              cnhUrl = await FirestoreUploadFiles().uploadDingleFile(
                arquivo: File(cnh!.path!),
                diretorio: "documents/${firebaseUser.uid}",
                fileName: "cnh"
              );

              selfieUrl = await FirestoreUploadFiles().uploadDingleFile(
                arquivo: File(selfie!.path!),
                diretorio: "documents/${firebaseUser.uid}",
                fileName: "selfie"
              );

              // 2. Criar subconta no Asaas
              /*final asaasAccount = await AsaasService.createSubAccount(usuario);
              if (asaasAccount == null) throw "Erro ao criar conta no Asaas";

              final subAccountApiKey = asaasAccount['apiKey'];
              final walletId = asaasAccount['walletId'];
              final asaasId = asaasAccount['id'];

              // 3. Upload de documentos para o Asaas
              final pendingDocs = await AsaasService.getPendingDocuments(subAccountApiKey);
              
              for (var docGroup in pendingDocs) {
                // Mapeamento simples para demonstração: 
                // Se o grupo parecer de identificação, manda a CNH.
                // Se pedir selfie, manda a selfie.
                String docType = 'IDENTIFICATION';
                File fileToUpload = File(cnh!.path!);

                if (docGroup['type'] == 'IDENTIFICATION_SELFIE') {
                  docType = 'IDENTIFICATION_SELFIE';
                  fileToUpload = File(selfie!.path!);
                }

                await AsaasService.uploadDocument(
                  subAccountApiKey: subAccountApiKey,
                  groupId: docGroup['id'],
                  file: fileToUpload,
                  type: docType,
                );
              }*/

              // 4. Atualizar Firestore
              await FirebaseFirestore.instance.collection("users").doc(firebaseUser.uid).update({
                "type" : UserType.instrutor.name,
                //"asaasId" : asaasId,
                //"walletId" : walletId,
                "instrutor" : InstrutorData(
                  active: false,
                  //asaasApiKey: subAccountApiKey,
                  asaasStatus: 'PENDING',
                  cnh: UserDocument(
                    type: DocumentType.cnh,
                    status: DocumentStatus.sended,
                    url: cnhUrl,
                  ),
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

              Navigator.pop(context);
              DialogServices().alertDialog(context, "Sua conta foi criada e está em análise. Você será notificado assim que for aprovado!", title: "Seja bem vindo!");

            } catch (e){
              setState(() {
                loading = false;
              });
              debugPrint(e.toString());
              DialogServices().alertDialog(context, "Erro ao processar documentos: $e");
            }
          },
          child: loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2,)) : Text("Prosseguir")
        ),
      ) : null,
    );
  }
}