import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/services/firestore_upload_files.dart';
import 'package:instrutor_em_casa/widgets/avatar.dart';
import 'package:ionicons/ionicons.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.usuario});
  final Usuario usuario;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController controllerName;
  bool loading = false;
  File? selectedImage;

  @override
  void initState() {
    super.initState();
    controllerName = TextEditingController(text: widget.usuario.name);
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 500,
    );
    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  Future<void> _save() async {
    setState(() => loading = true);

    try {
      String? imageUrl = widget.usuario.image;

      if (selectedImage != null) {
        imageUrl = await FirestoreUploadFiles().uploadDingleFile(
          arquivo: selectedImage!,
          diretorio: "profile_pics",
          fileName: widget.usuario.id,
        );
      }

      await FirebaseFirestore.instance.collection("users").doc(widget.usuario.id).update({
        "name": controllerName.text.trim(),
        "image": imageUrl,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Perfil atualizado com sucesso!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao atualizar perfil: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Perfil"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Stack(
              children: [
                selectedImage != null
                    ? CircleAvatar(
                        radius: 60,
                        backgroundImage: FileImage(selectedImage!),
                      )
                    : UserAvatar(
                        user: widget.usuario.toDetails(),
                        radius: 60,
                      ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: FloatingActionButton.small(
                    onPressed: _pickImage,
                    child: const Icon(Ionicons.camera_outline),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          TextFormField(
            controller: controllerName,
            decoration: const InputDecoration(
              labelText: "Nome de Usuário",
              prefixIcon: Icon(Ionicons.person_outline),
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: loading ? null : _save,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Salvar Alterações"),
            ),
          ),
        ],
      ),
    );
  }
}
