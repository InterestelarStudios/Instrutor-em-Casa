import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:instrutor_em_casa/models/instrutor.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/screens/auth/location_instrutor_select.dart';
import 'package:instrutor_em_casa/services/firestore_upload_files.dart';
import 'package:instrutor_em_casa/widgets/chip.dart';
import 'package:instrutor_em_casa/widgets/dialog_services.dart';
import 'package:instrutor_em_casa/widgets/theme.dart';
import 'package:ionicons/ionicons.dart';

class AreaInstrutorScreen extends StatefulWidget {
  const AreaInstrutorScreen({super.key, required this.usuario});
  final Usuario usuario;

  @override
  State<AreaInstrutorScreen> createState() => _AreaInstrutorScreenState();
}

class _AreaInstrutorScreenState extends State<AreaInstrutorScreen> {
  bool active = false;
  late DocumentStatus? cnhStatus;
  late DocumentStatus? credencialStatus;
  late DocumentStatus? faceStatus;
  late List<CNHCategory> selectedCategories;

  @override
  void initState() {
    super.initState();
    active = widget.usuario.instrutor?.active ?? false;
    cnhStatus = widget.usuario.instrutor?.cnh.status;
    credencialStatus = widget.usuario.instrutor?.credencial.status;
    faceStatus = widget.usuario.instrutor?.face.status;
    selectedCategories = List.from(widget.usuario.instrutor?.categories ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Área do Instrutor"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          _buildStatusOnline(),
          const SizedBox(height: AppSpacing.sectionGap),
          _buildSectionTitle("Categorias"),
          _buildCategoriasCard(),
          const SizedBox(height: AppSpacing.sectionGap),
          _buildSectionTitle("Área de Atuação"),
          _buildLocalizacaoCard(),
          const SizedBox(height: AppSpacing.sectionGap),
          _buildSectionTitle("Documentos"),
          _buildDocumentoItem("CNH", cnhStatus, DocumentType.cnh),
          const SizedBox(height: AppSpacing.itemGap),
          _buildDocumentoItem("Credencial de Instrutor", credencialStatus, DocumentType.credencial),
          const SizedBox(height: AppSpacing.itemGap),
          _buildDocumentoItem("Foto do seu Rosto", faceStatus, DocumentType.id),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildStatusOnline() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Status Online", style: AppTextStyles.h3),
                  Text(
                    "Ative para começar a receber proposta de aulas.",
                    style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Switch(
              value: active,
              onChanged: (value) {
                if (value) {
                  List<String> errors = [];
                  if (cnhStatus != DocumentStatus.approved) errors.add("CNH não aprovada");
                  if (credencialStatus != DocumentStatus.approved) errors.add("Credencial não aprovada");
                  if (faceStatus != DocumentStatus.approved) errors.add("Foto do rosto não aprovada");
                  if (selectedCategories.isEmpty) errors.add("Nenhuma categoria de aula selecionada");

                  if (errors.isNotEmpty) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Não é possível ficar online"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: errors.map((e) => Text("• $e")).toList(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Entendi"),
                          ),
                        ],
                      ),
                    );
                    return;
                  }
                }

                setState(() {
                  active = value;
                });
                FirebaseFirestore.instance
                    .collection("users")
                    .doc(widget.usuario.id)
                    .update({"instrutor.active": value});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriasCard() {
    return Card(
      child: ListTile(
        leading: Icon(Icons.smartphone_outlined, color: AppColors.primary),
        title: const Text("Categorias de Aula"),
        subtitle: Text(
          selectedCategories.isEmpty 
            ? "Toque para alterar" 
            : "Categorias: ${selectedCategories.map((e) => e.name).join(', ')}"
        ),
        trailing: Icon(selectedCategories.isEmpty ? Icons.info_outline : Icons.check_circle_outline, color: selectedCategories.isEmpty ? AppColors.warning500 : AppColors.success),
        onTap: _showCategoriesDialog,
      ),
    );
  }

  void _showCategoriesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        List<CNHCategory> tempCategories = List.from(selectedCategories);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Categorias de Aula"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: CNHCategory.values.map((category) {
                  return CheckboxListTile(
                    title: Text("Categoria ${category.name}"),
                    value: tempCategories.contains(category),
                    onChanged: (value) {
                      setDialogState(() {
                        if (value == true) {
                          tempCategories.add(category);
                        } else {
                          tempCategories.remove(category);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      selectedCategories = List.from(tempCategories);
                    });
                    
                    await FirebaseFirestore.instance
                        .collection("users")
                        .doc(widget.usuario.id)
                        .update({
                          "instrutor.categories": selectedCategories.map((e) => e.name).toList()
                        });
                        
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text("Salvar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLocalizacaoCard() {
    return Card(
      child: ListTile(
        leading: Icon(Ionicons.map_outline, color: AppColors.primary),
        title: const Text("Localização"),
        subtitle: const Text("Tarumã, Amazonas"), // Placeholder or reverse geocoding result
        trailing: const Icon(Icons.chevron_right, color: AppColors.primary),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InstrutorLocationPicker()),
          );
        },
      ),
    );
  }

  Widget _buildDocumentoItem(String title, DocumentStatus? status, DocumentType type) {
    final bool canResubmit = status == DocumentStatus.refused || status == DocumentStatus.expired;

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Ionicons.document_outline, color: AppColors.primary),
            title: Text(title),
            trailing: AppChip(
              title: _getStatusLabel(status),
              type: _getStatusType(status),
            ),
          ),
          if (canResubmit)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: TextButton.icon(
                onPressed: () => _showUploadDialog(title, type),
                icon: const Icon(Icons.attach_file),
                label: const Text("Enviar documento"),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  void _showUploadDialog(String title, DocumentType type) {
    File? selectedFile;
    final fileNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return SimpleDialog(
              title: Text("Enviar $title"),
              contentPadding: const EdgeInsets.all(AppSpacing.pagePadding),
              children: [
                TextFormField(
                  controller: fileNameController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "Documento",
                    hintText: "Clique para selecionar o arquivo",
                    suffixIcon: Icon(Icons.upload_file),
                  ),
                  onTap: () async {
                    FilePickerResult? result = await FilePicker.platform.pickFiles();
                    if (result != null) {
                      selectedFile = File(result.files.single.path!);
                      setDialogState(() {
                        fileNameController.text = result.files.single.name;
                      });
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedFile == null) {
                      DialogServices().alertDialog(context, "Por favor, selecione um arquivo.");
                      return;
                    }

                    // Show loading
                    Navigator.pop(context); // Close dialog
                    DialogServices.loading2(context);

                    try {
                      String url = await FirestoreUploadFiles().uploadDingleFile(
                        arquivo: selectedFile!,
                        diretorio: "documentos/${widget.usuario.id}",
                        fileName: type.name,
                      );

                      Map<String, dynamic> updateData = {};
                      if (type == DocumentType.id) {
                        updateData["image"] = url;
                        updateData["instrutor.face.url"] = url;
                        updateData["instrutor.face.status"] = DocumentStatus.sended.name;
                      } else {
                        String field = type == DocumentType.cnh ? "cnh" : "credencial";
                        updateData["instrutor.$field.url"] = url;
                        updateData["instrutor.$field.status"] = DocumentStatus.sended.name;
                      }

                      await FirebaseFirestore.instance
                          .collection("users")
                          .doc(widget.usuario.id)
                          .update(updateData);

                      if (mounted) {
                        Navigator.pop(context); // Close loading
                        setState(() {
                          if (type == DocumentType.cnh) {
                            cnhStatus = DocumentStatus.sended;
                          } else if (type == DocumentType.credencial) {
                            credencialStatus = DocumentStatus.sended;
                          } else if (type == DocumentType.id) {
                            faceStatus = DocumentStatus.sended;
                          }
                        });
                        DialogServices().alertDialog(context, "Documento enviado com sucesso!");
                      }
                    } catch (e) {
                      if (mounted) {
                        Navigator.pop(context); // Close loading
                        DialogServices().alertDialog(context, "Erro ao enviar documento: $e");
                      }
                    }
                  },
                  child: const Text("Enviar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getStatusLabel(DocumentStatus? status) {
    switch (status) {
      case DocumentStatus.approved:
        return "Aprovado";
      case DocumentStatus.refused:
        return "Recusado";
      case DocumentStatus.expired:
        return "Expirado";
      case DocumentStatus.sended:
      default:
        return "Em análise";
    }
  }

  AppChipType _getStatusType(DocumentStatus? status) {
    switch (status) {
      case DocumentStatus.approved:
        return AppChipType.done;
      case DocumentStatus.refused:
        return AppChipType.danger;
      case DocumentStatus.expired:
        return AppChipType.waiting;
      case DocumentStatus.sended:
      default:
        return AppChipType.none;
    }
  }
}
