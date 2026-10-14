import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/models/vehicle.dart';
import 'package:instrutor_em_casa/services/vehicle_document_service.dart';
import 'package:instrutor_em_casa/widgets/dialog_services.dart';
import 'package:instrutor_em_casa/widgets/theme.dart';
import 'package:ionicons/ionicons.dart';

class CadastrarVeiculoScreen extends StatefulWidget {
  final Usuario usuario;

  const CadastrarVeiculoScreen({super.key, required this.usuario});

  @override
  State<CadastrarVeiculoScreen> createState() => _CadastrarVeiculoScreenState();
}

class _CadastrarVeiculoScreenState extends State<CadastrarVeiculoScreen> {

  // Controladores dos dados do veículo
  final _plateController = TextEditingController();
  final _renavamController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearFabController = TextEditingController();
  final _yearModController = TextEditingController();
  final _colorController = TextEditingController();
  final _fuelController = TextEditingController();
  final _chassisController = TextEditingController();
  final _categoryController = TextEditingController(text: "APRENDIZAGEM");

  // Estado do documento e fluxo
  Uint8List? _documentBytes;
  String? _documentFileName;
  String? _documentMimeType;
  bool _extracting = false;
  bool _saving = false;
  bool _hasExtractedData = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _plateController.dispose();
    _renavamController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearFabController.dispose();
    _yearModController.dispose();
    _colorController.dispose();
    _fuelController.dispose();
    _chassisController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  /// Tira foto do documento com a câmera
  Future<void> _pickFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        await _processDocument(
          bytes: bytes,
          fileName: photo.name,
          mimeType: "image/jpeg",
          filePath: photo.path,
        );
      }
    } catch (e) {
      if (mounted) {
        DialogServices().alertDialog(context, "Erro ao acessar a câmera: $e");
      }
    }
  }

  /// Seleciona foto da galeria ou arquivo PDF (CRLV Digital)
  Future<void> _pickFromGalleryOrPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;
        Uint8List? bytes = pickedFile.bytes;
        if (bytes == null && pickedFile.path != null) {
          bytes = await File(pickedFile.path!).readAsBytes();
        }

        if (bytes == null) {
          throw "Não foi possível carregar os dados do arquivo selecionado.";
        }

        final ext = (pickedFile.extension ?? '').toLowerCase();
        final mimeType = ext == 'pdf' ? 'application/pdf' : 'image/jpeg';

        await _processDocument(
          bytes: bytes,
          fileName: pickedFile.name,
          mimeType: mimeType,
          filePath: pickedFile.path,
        );
      }
    } catch (e) {
      if (mounted) {
        DialogServices().alertDialog(context, "Erro ao selecionar arquivo: $e");
      }
    }
  }

  /// Processa o documento selecionado via OCR On-Device
  Future<void> _processDocument({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    String? filePath,
  }) async {
    setState(() {
      _extracting = true;
      _documentBytes = bytes;
      _documentFileName = fileName;
      _documentMimeType = mimeType;
    });

    try {
      final vehicle = await VehicleDocumentService.extractVehicleData(
        bytes: bytes,
        mimeType: mimeType,
        filePath: filePath,
      );

      setState(() {
        if (vehicle.plate.isNotEmpty) _plateController.text = vehicle.plate;
        if (vehicle.renavam.isNotEmpty) _renavamController.text = vehicle.renavam;
        if (vehicle.brand.isNotEmpty) _brandController.text = vehicle.brand;
        if (vehicle.model.isNotEmpty) _modelController.text = vehicle.model;
        if (vehicle.yearFabrication > 0) _yearFabController.text = vehicle.yearFabrication.toString();
        if (vehicle.yearModel > 0) _yearModController.text = vehicle.yearModel.toString();
        if (vehicle.color.isNotEmpty) _colorController.text = vehicle.color;
        if (vehicle.fuel.isNotEmpty) _fuelController.text = vehicle.fuel;
        if (vehicle.chassis.isNotEmpty) _chassisController.text = vehicle.chassis;
        if (vehicle.category.isNotEmpty) _categoryController.text = vehicle.category;

        _hasExtractedData = true;
        _extracting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Documento identificado! Confira os dados no card abaixo."),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _extracting = false;
        // Permite abrir os dados para preenchimento se a leitura falhar
        _hasExtractedData = true;
      });

      if (mounted) {
        DialogServices().alertDialog(
          context,
          "Não foi possível identificar todos os dados automaticamente do documento. Por favor, confira ou complete as informações.",
          title: "Aviso de Leitura",
        );
        _openEditModal();
      }
    }
  }

  /// Salva o veículo no Firestore e envia o documento para o Storage
  Future<void> _saveVehicle() async {
    if (_plateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, informe a placa do veículo.")),
      );
      _openEditModal();
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final currentYear = DateTime.now().year;
      final yearFab = int.tryParse(_yearFabController.text.trim()) ?? currentYear;
      final yearMod = int.tryParse(_yearModController.text.trim()) ?? yearFab;

      final userRef = FirebaseFirestore.instance
          .collection("users")
          .doc(widget.usuario.id);
      final docRef = userRef.collection("vehicles").doc();

      final vehicle = Vehicle(
        id: docRef.id,
        plate: _plateController.text.trim().toUpperCase(),
        renavam: _renavamController.text.trim(),
        brand: _brandController.text.trim().toUpperCase(),
        model: _modelController.text.trim().toUpperCase(),
        yearFabrication: yearFab,
        yearModel: yearMod,
        color: _colorController.text.trim().toUpperCase(),
        fuel: _fuelController.text.trim().toUpperCase(),
        chassis: _chassisController.text.trim().toUpperCase(),
        category: _categoryController.text.trim().toUpperCase(),
      );

      // Salva o veículo e define como padrão (se ainda não houver) em lote atômico e instantâneo
      final batch = FirebaseFirestore.instance.batch();
      batch.set(docRef, vehicle.toMap());

      if (widget.usuario.instrutor?.defaultVehicle == null) {
        batch.update(userRef, {
          "instrutor.defaultVehicle": vehicle.toMap(),
        });
        widget.usuario.instrutor?.defaultVehicle = vehicle;
      }

      await batch.commit();

      if (mounted) {
        setState(() {
          _saving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Veículo cadastrado com sucesso!"),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _saving = false;
      });
      if (mounted) {
        DialogServices().alertDialog(
          context,
          "Erro ao salvar o veículo: $e",
          title: "Erro de Salvamento",
        );
      }
    }
  }

  /// Abre BottomSheet para edição/revisão manual dos dados do veículo
  void _openEditModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 24,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Revisar Dados do Veículo", style: AppTextStyles.h3),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _plateController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: "Placa *"),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _renavamController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "RENAVAM *"),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _brandController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(labelText: "Marca *"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _modelController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(labelText: "Modelo *"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _yearFabController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Ano Fab. *"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _yearModController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Ano Mod. *"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _colorController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(labelText: "Cor *"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _fuelController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(labelText: "Combustível *"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _chassisController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: "Chassi"),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _categoryController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: "Categoria"),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: AppColors.primary600,
                  ),
                  child: const Text("Salvar Alterações"),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cadastrar Veículo"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Cadastro do Veículo",
              style: AppTextStyles.h2.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 6),
            Text(
              "Anexe a foto ou PDF do documento do veículo (CRLV ou LADV). A leitura dos dados é feita de forma instantânea no seu aparelho.",
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Card de Upload / Leitura
            _buildDocumentUploadCard(),

            // Se os dados foram extraídos, exibe o Card de Confirmação do Veículo
            if (_hasExtractedData) ...[
              const SizedBox(height: AppSpacing.xl),
              _buildVehicleConfirmationCard(),
              const SizedBox(height: AppSpacing.xl),

              // Botão Principal de Confirmação
              ElevatedButton.icon(
                onPressed: _saving ? null : _saveVehicle,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _saving ? "Salvando Veículo..." : "Confirmar e Salvar Veículo",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// Card de Anexar Documento
  Widget _buildDocumentUploadCard() {
    if (_extracting) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.primary50,
          borderRadius: AppRadius.radiusLg,
          border: Border.all(color: AppColors.primary200, width: 1.5),
        ),
        child: Column(
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 18),
            Text(
              "Lendo documento no dispositivo...",
              style: AppTextStyles.h3.copyWith(color: AppColors.primary600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              "Reconhecendo placa, renavam, chassi e características...",
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_documentBytes != null && _hasExtractedData) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: AppRadius.radiusLg,
          border: Border.all(color: Colors.green.shade200, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _documentMimeType == 'application/pdf'
                    ? Icons.picture_as_pdf
                    : Icons.image,
                color: Colors.green.shade800,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Text(
                        "Documento Anexado",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _documentFileName ?? "documento_veiculo",
                    style: TextStyle(fontSize: 12, color: Colors.green.shade800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: _pickFromGalleryOrPdf,
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text("Trocar", style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                side: BorderSide(color: Colors.green.shade400),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.document_upload, size: 40, color: AppColors.primary600),
          ),
          const SizedBox(height: 14),
          const Text(
            "Anexar Documento do Veículo",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 6),
          const Text(
            "CRLV-e, LADV ou autorização de trânsito em PDF ou Foto",
            style: TextStyle(fontSize: 13, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickFromCamera,
                  icon: const Icon(Ionicons.cameraOutline, size: 18),
                  label: const Text("Tirar Foto"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickFromGalleryOrPdf,
                  icon: const Icon(Ionicons.documentAttachOutline, size: 18),
                  label: const Text("Galeria ou PDF"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() {
                _hasExtractedData = true;
              });
              _openEditModal();
            },
            child: const Text(
              "Ou preencher dados manualmente",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  /// Card Visual com os Dados Confirmados do Veículo
  Widget _buildVehicleConfirmationCard() {
    final plate = _plateController.text.trim().isEmpty ? "SEM PLACA" : _plateController.text.trim();
    final brand = _brandController.text.trim().isEmpty ? "MARCA" : _brandController.text.trim();
    final model = _modelController.text.trim().isEmpty ? "MODELO" : _modelController.text.trim();
    final yearFab = _yearFabController.text.trim().isEmpty ? "----" : _yearFabController.text.trim();
    final yearMod = _yearModController.text.trim().isEmpty ? "----" : _yearModController.text.trim();
    final color = _colorController.text.trim().isEmpty ? "NÃO INFORMADA" : _colorController.text.trim();
    final fuel = _fuelController.text.trim().isEmpty ? "FLEX" : _fuelController.text.trim();
    final renavam = _renavamController.text.trim().isEmpty ? "NÃO INFORMADO" : _renavamController.text.trim();
    final chassis = _chassisController.text.trim().isEmpty ? "NÃO INFORMADO" : _chassisController.text.trim();
    final category = _categoryController.text.trim().isEmpty ? "APRENDIZAGEM" : _categoryController.text.trim();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.radiusLg,
        side: BorderSide(color: Colors.grey.shade200, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Topo com Placa e Botão Editar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Placa Estilo Mercosul
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF003399),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          "BRASIL",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        plate,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _openEditModal,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text("Editar dados"),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Título do Veículo
            Text(
              "$brand $model",
              style: AppTextStyles.h2.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 2),
            Text(
              "Ano Fab/Mod: $yearFab / $yearMod",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const Divider(height: 28, thickness: 1),

            // Detalhes em linhas
            _buildDetailItem("RENAVAM", renavam, Ionicons.receiptOutline),
            _buildDetailItem("Cor Predominante", color, Ionicons.colorPaletteOutline),
            _buildDetailItem("Combustível", fuel, Ionicons.flameOutline),
            _buildDetailItem("Categoria", category, Ionicons.ribbonOutline),
            _buildDetailItem("Chassi", chassis, Ionicons.barcodeOutline),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 10),
          Text(
            "$label:",
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
