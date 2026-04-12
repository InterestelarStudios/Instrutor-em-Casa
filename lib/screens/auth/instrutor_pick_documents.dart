import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  bool loading = false;

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
            onTap: loading ? null : () async {
              final result = await FilePicker.pickFiles();
              setState(() {
                credencial = result!.files.first;
              });
            },
            title: Text("Toque para Anexar"),
            leading: Icon(Icons.attach_file_rounded),
            subtitle: credencial == null ? null : Text(credencial!.name),
          ),
          const SizedBox(height: 20,),
          Text("CNH", style: Theme.of(context).textTheme.titleLarge,),
          ListTile(
            selected: cnh != null,
            onTap: loading ? null : () async {
              final result = await FilePicker.pickFiles();
              setState(() {
                cnh = result!.files.first;
              });
            },
            contentPadding: const EdgeInsets.only(),
            title: Text("Toque para Anexar"),
            leading: Icon(Icons.attach_file_rounded),
            subtitle: cnh == null ? null : Text(cnh!.name),
          ),
        ],
      ),
      bottomNavigationBar: credencial != null && cnh != null ?
      Container(
        height: 50,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: FilledButton(
          onPressed: loading ? null : () async {
            setState(() {
              loading = true;
            });
            final user = FirebaseAuth.instance.currentUser;

            String? credentialUrl;
            String? cnhUrl;

            try{
              credentialUrl = await FirestoreUploadFiles().uploadDingleFile(
                arquivo: File(credencial!.path!),
                diretorio: "documents/${user!.uid}",
                fileName: "credential"
              );

              cnhUrl = await FirestoreUploadFiles().uploadDingleFile(
                arquivo: File(credencial!.path!),
                diretorio: "documents/${user.uid}",
                fileName: "cnh"
              );
            } catch (e){
              setState(() {
                loading = false;
              });
              DialogServices().alertDialog(context, "Erro ao subir arquivos, por favor contate o suporte.");
              return;
            }

            FirebaseFirestore.instance.collection("users").doc(user.uid).update({
              "type" : UserType.instrutor.name,
              "instrutor" : InstrutorData(
                active: false,
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
                horas: 0
              ).toMap()
            }).then((_){
              Navigator.pop(context);
            }).catchError((e){
              setState(() {
                loading = false;
              });
              DialogServices().alertDialog(context, "Erro ao subir arquivos, por favor contate o suporte.");
            });
          },
          child: loading ? const CircularProgressIndicator() : Text("Prosseguir")
        ),
      ) : null,
    );
  }
}