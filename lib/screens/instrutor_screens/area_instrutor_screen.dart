import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:instrutor_em_casa/models/instrutor.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/screens/auth/location_instrutor_select.dart';
import 'package:instrutor_em_casa/services/firestore_upload_files.dart';
import 'package:instrutor_em_casa/widgets/chip.dart';
import 'package:instrutor_em_casa/widgets/dialog_services.dart';
import 'package:instrutor_em_casa/widgets/theme.dart';
import 'package:instrutor_em_casa/screens/instrutor_screens/gerenciar_veiculos_screen.dart';
import 'package:ionicons/ionicons.dart';

class AreaInstrutorScreen extends StatefulWidget {
  const AreaInstrutorScreen({super.key, required this.usuario});
  final Usuario usuario;

  @override
  State<AreaInstrutorScreen> createState() => _AreaInstrutorScreenState();
}

class _AreaInstrutorScreenState extends State<AreaInstrutorScreen> {
  bool active = false;

  late DocumentStatus? credencialStatus;
  late DocumentStatus? faceStatus;
  late List<CNHCategory> selectedCategories;
  final _pixFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    active = widget.usuario.instrutor?.active ?? false;

    credencialStatus = widget.usuario.instrutor?.credencial.status;
    faceStatus = widget.usuario.instrutor?.face.status;
    selectedCategories = List.from(widget.usuario.instrutor?.categories ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(widget.usuario.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final liveUser = Usuario.fromMap(snapshot.data!.data()!);

        // Sincroniza estados com base na escuta ativa
        active = liveUser.instrutor?.active ?? false;
        credencialStatus = liveUser.instrutor?.credencial.status;
        faceStatus = liveUser.instrutor?.face.status;
        selectedCategories = List.from(liveUser.instrutor?.categories ?? []);

        return Scaffold(
          appBar: AppBar(title: const Text("Área do Instrutor")),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              _buildStatusOnline(liveUser),
              const SizedBox(height: AppSpacing.sectionGap),
              _buildSectionTitle("Categorias"),
              _buildCategoriasCard(),
              const SizedBox(height: AppSpacing.sectionGap),
              _buildSectionTitle("Área de Atuação"),
              _buildLocalizacaoCard(liveUser),
              const SizedBox(height: AppSpacing.sectionGap),

              // Veículo Padrão e Gerenciamento
              _buildVeiculoHeader(liveUser),
              const SizedBox(height: AppSpacing.sm),
              _buildVeiculoCard(liveUser),
              const SizedBox(height: AppSpacing.sectionGap),

              _buildSectionTitle("Dados de Transferência"),
              _buildPixCard(liveUser),
              const SizedBox(height: AppSpacing.sectionGap),

              _buildSectionTitle("Documentos"),
              _buildDocumentoItem(
                "Credencial de Instrutor",
                credencialStatus,
                DocumentType.credencial,
              ),
              const SizedBox(height: AppSpacing.itemGap),
              _buildDocumentoItem(
                "Foto do seu Rosto",
                faceStatus,
                DocumentType.id,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVeiculoHeader(Usuario liveUser) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Veículo Padrão",
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        TextButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    GerenciarVeiculosScreen(usuario: liveUser),
              ),
            );
          },
          icon: const Icon(Icons.settings_outlined, size: 16),
          label: const Text("Gerenciar Veículos"),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Widget _buildVeiculoCard(Usuario liveUser) {
    final defaultVehicle = liveUser.instrutor?.defaultVehicle;

    if (defaultVehicle == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Ionicons.carOutline, color: AppColors.textMuted, size: 40),
              const SizedBox(height: 10),
              Text(
                "Nenhum veículo selecionado",
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Cadastre um veículo para utilizar em suas aulas práticas.",
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary50,
                borderRadius: AppRadius.radiusMd,
              ),
              child: Icon(Ionicons.car, color: AppColors.primary600, size: 28),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${defaultVehicle.brand} ${defaultVehicle.model}",
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Placa: ${defaultVehicle.plate} • Cor: ${defaultVehicle.color}",
                    style: AppTextStyles.caption.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Categoria: ${defaultVehicle.category} • ${defaultVehicle.fuel}",
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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

  Widget _buildStatusOnline(Usuario liveUser) {
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
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: active,
              onChanged: (value) {
                if (value) {
                  List<String> errors = [];

                  if (credencialStatus != DocumentStatus.approved) {
                    errors.add("Credencial não aprovada");
                  }
                  if (faceStatus != DocumentStatus.approved) {
                    errors.add("Foto do rosto não aprovada");
                  }
                  if (selectedCategories.isEmpty) {
                    errors.add("Nenhuma categoria de aula selecionada");
                  }
                  if (liveUser.instrutor?.defaultVehicle == null) {
                    errors.add("Nenhum veículo cadastrado/selecionado");
                  }

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
              : "Categorias: ${selectedCategories.map((e) => e.name).join(', ')}",
        ),
        trailing: Icon(
          selectedCategories.isEmpty
              ? Icons.info_outline
              : Icons.check_circle_outline,
          color: selectedCategories.isEmpty
              ? AppColors.warning500
              : AppColors.success,
        ),
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
                children: CNHCategory.values
                    .where(
                      (category) =>
                          category == CNHCategory.A ||
                          category == CNHCategory.B,
                    )
                    .map((category) {
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
                    })
                    .toList(),
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
                          "instrutor.categories": selectedCategories
                              .map((e) => e.name)
                              .toList(),
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

  Widget _buildLocalizacaoCard(Usuario liveUser) {
    String locationText = "Toque para configurar sua localização";
    LatLng? initialPos;

    if (liveUser.geo != null && liveUser.geo!['geopoint'] != null) {
      final gp = liveUser.geo!['geopoint'];
      if (gp is GeoPoint) {
        initialPos = LatLng(gp.latitude, gp.longitude);
        locationText = "Ponto configurado (${gp.latitude.toStringAsFixed(3)}, ${gp.longitude.toStringAsFixed(3)})";
      }
    }

    return Card(
      child: ListTile(
        leading: Icon(Ionicons.mapOutline, color: AppColors.primary),
        title: const Text("Localização de Atendimento"),
        subtitle: Text(locationText),
        trailing: const Icon(Icons.chevron_right, color: AppColors.primary),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InstrutorLocationPicker(
                initialPosition: initialPos,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDocumentoItem(
    String title,
    DocumentStatus? status,
    DocumentType type,
  ) {
    final bool canResubmit =
        status == DocumentStatus.refused || status == DocumentStatus.expired;

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Ionicons.documentOutline, color: AppColors.primary),
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
                    FilePickerResult? result = await FilePicker.platform
                        .pickFiles();
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
                      DialogServices().alertDialog(
                        context,
                        "Por favor, selecione um arquivo.",
                      );
                      return;
                    }

                    // Show loading
                    Navigator.pop(context); // Close dialog
                    DialogServices.loading2(context);

                    try {
                      String url = await FirestoreUploadFiles()
                          .uploadDingleFile(
                            arquivo: selectedFile!,
                            diretorio: "documentos/${widget.usuario.id}",
                            fileName: type.name,
                          );

                      Map<String, dynamic> updateData = {};
                      if (type == DocumentType.id) {
                        updateData["image"] = url;
                        updateData["instrutor.face.url"] = url;
                        updateData["instrutor.face.status"] =
                            DocumentStatus.sended.name;
                      } else {
                        updateData["instrutor.credencial.url"] = url;
                        updateData["instrutor.credencial.status"] =
                            DocumentStatus.sended.name;
                      }

                      await FirebaseFirestore.instance
                          .collection("users")
                          .doc(widget.usuario.id)
                          .update(updateData);

                      if (mounted) {
                        Navigator.pop(context); // Close loading
                        setState(() {
                          if (type == DocumentType.credencial) {
                            credencialStatus = DocumentStatus.sended;
                          } else if (type == DocumentType.id) {
                            faceStatus = DocumentStatus.sended;
                          }
                        });
                        DialogServices().alertDialog(
                          context,
                          "Documento enviado com sucesso!",
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        Navigator.pop(context); // Close loading
                        DialogServices().alertDialog(
                          context,
                          "Erro ao enviar documento: $e",
                        );
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

  String getPixKeyTypeLabel(String? type) {
    switch (type) {
      case "CPF":
        return "CPF";
      case "CNPJ":
        return "CNPJ";
      case "EMAIL":
        return "E-mail";
      case "PHONE":
        return "Telefone";
      case "EVP":
        return "Chave Aleatória";
      default:
        return "Não cadastrado";
    }
  }

  Widget _buildPixCard(Usuario liveUser) {
    final pixKeyType = liveUser.instrutor?.pixKeyType;
    final pixKey = liveUser.instrutor?.pixKey;
    final hasPix = pixKeyType != null && pixKey != null && pixKey.isNotEmpty;

    return Card(
      child: ListTile(
        leading: Icon(Icons.pix, color: AppColors.primary),
        title: const Text("Chave PIX de Recebimento"),
        subtitle: Text(
          hasPix
              ? "${getPixKeyTypeLabel(pixKeyType)}: $pixKey"
              : "Toque para cadastrar seus dados de transferência",
        ),
        trailing: Icon(
          hasPix ? Icons.check_circle_outline : Icons.info_outline,
          color: hasPix ? AppColors.success : AppColors.warning500,
        ),
        onTap: () => _showPixDialog(liveUser),
      ),
    );
  }

  void _showPixDialog(Usuario liveUser) {
    String? selectedType = liveUser.instrutor?.pixKeyType ?? 'CPF';

    final allowedTypes = ['CPF', 'CNPJ', 'EMAIL', 'PHONE', 'EVP'];
    if (!allowedTypes.contains(selectedType)) {
      selectedType = 'CPF';
    }

    final keyController = TextEditingController(
      text: liveUser.instrutor?.pixKey,
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
            return AlertDialog(
              title: const Text("Dados de Transferência (PIX)"),
              content: Form(
                key: _pixFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: "Tipo de Chave",
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'CPF', child: Text("CPF")),
                        DropdownMenuItem(value: 'CNPJ', child: Text("CNPJ")),
                        DropdownMenuItem(value: 'EMAIL', child: Text("E-mail")),
                        DropdownMenuItem(
                          value: 'PHONE',
                          child: Text("Telefone"),
                        ),
                        DropdownMenuItem(
                          value: 'EVP',
                          child: Text("Chave Aleatória"),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: keyController,
                      decoration: const InputDecoration(
                        labelText: "Chave PIX",
                        border: OutlineInputBorder(),
                        hintText: "Digite sua chave PIX",
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "A chave PIX é obrigatória";
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final formState = _pixFormKey.currentState;
                    if (formState != null && formState.validate()) {
                      Navigator.pop(
                        dialogContext,
                      ); // Close dialog using dialogContext
                      DialogServices.loading2(
                        context,
                      ); // Open loading using screen context

                      try {
                        await FirebaseFirestore.instance
                            .collection("users")
                            .doc(widget.usuario.id)
                            .update({
                              "instrutor.pixKeyType": selectedType,
                              "instrutor.pixKey": keyController.text.trim(),
                            });

                        if (mounted) {
                          Navigator.pop(
                            context,
                          ); // Close loading using screen context
                          setState(() {});
                        }
                      } catch (e) {
                        if (mounted) {
                          Navigator.pop(
                            context,
                          ); // Close loading using screen context
                          DialogServices().alertDialog(
                            context,
                            "Erro ao atualizar dados: $e",
                          );
                        }
                      }
                    }
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
}
