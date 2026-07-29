import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/models/vehicle.dart';
import 'package:instrutor_em_casa/services/infosimples_service.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _renavamController = TextEditingController();
  String? _selectedUf;

  final List<String> _ufs = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA',
    'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN',
    'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'
  ];

  bool _loading = false;
  Vehicle? _consultedVehicle;

  Future<void> _consultVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _consultedVehicle = null;
    });

    try {
      final vehicle = await InfosimplesService.consultVehicle(
        plate: _plateController.text,
        renavam: _renavamController.text,
        uf: _selectedUf!,
      );

      setState(() {
        _consultedVehicle = vehicle;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        DialogServices().alertDialog(
          context,
          "Não foi possível consultar os dados do veículo: $e",
          title: "Consulta Falhou",
        );
      }
    }
  }

  Future<void> _saveVehicle() async {
    if (_consultedVehicle == null) return;

    setState(() {
      _loading = true;
    });

    try {
      final docRef = FirebaseFirestore.instance
          .collection("users")
          .doc(widget.usuario.id)
          .collection("vehicles")
          .doc();

      // Atribui o ID gerado pelo Firestore
      _consultedVehicle!.id = docRef.id;

      // Salva na subcoleção de veículos do instrutor
      await docRef.set(_consultedVehicle!.toMap());

      // Verifica se o instrutor já possui um veículo padrão
      // Se não possuir, define o veículo cadastrado como padrão
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.usuario.id)
          .get();
      
      final userData = userDoc.data();
      final hasDefaultVehicle = userData?['instrutor']?['defaultVehicle'] != null;

      if (!hasDefaultVehicle) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(widget.usuario.id)
            .update({
          "instrutor.defaultVehicle": _consultedVehicle!.toMap(),
        });
      }

      if (mounted) {
        setState(() {
          _loading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Veículo cadastrado com sucesso!"),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true); // Retorna true indicando sucesso
      }
    } catch (e) {
      setState(() {
        _loading = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cadastrar Veículo"),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            Text(
              "Consulta Infosimples",
              style: AppTextStyles.h2.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 4),
            Text(
              "Insira a placa e o renavam do veículo. Faremos a busca dos dados cadastrais automaticamente junto ao Detran.",
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Campo Placa
            TextFormField(
              controller: _plateController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 7,
              decoration: const InputDecoration(
                labelText: "Placa do Veículo",
                hintText: "Ex: ABC1D23",
                prefixIcon: Icon(Ionicons.card_outline),
                counterText: "",
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Por favor, digite a placa.";
                }
                if (value.trim().length != 7) {
                  return "A placa deve conter 7 caracteres.";
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Campo Renavam
            TextFormField(
              controller: _renavamController,
              keyboardType: TextInputType.number,
              maxLength: 11,
              decoration: const InputDecoration(
                labelText: "RENAVAM",
                hintText: "Ex: 12345678901",
                prefixIcon: Icon(Iconsax.receipt_1),
                counterText: "",
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Por favor, digite o RENAVAM.";
                }
                if (value.trim().length < 9) {
                  return "O RENAVAM digitado é muito curto.";
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Campo UF (Estado)
            DropdownButtonFormField<String>(
              value: _selectedUf,
              decoration: const InputDecoration(
                labelText: "Estado (UF) de registro",
                hintText: "Selecione o estado",
                prefixIcon: Icon(Ionicons.map_outline),
              ),
              items: _ufs.map((uf) {
                return DropdownMenuItem(
                  value: uf,
                  child: Text(uf),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedUf = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Por favor, selecione a UF.";
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Botão Consultar
            ElevatedButton.icon(
              onPressed: _loading ? null : _consultVehicle,
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.search),
              label: Text(_loading ? "Consultando..." : "Buscar dados no Detran"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
              ),
            ),

            if (_consultedVehicle != null) ...[
              const SizedBox(height: AppSpacing.xl),
              _buildVehicleDetailsCard(),
              const SizedBox(height: AppSpacing.lg),
              
              ElevatedButton.icon(
                onPressed: _loading ? null : _saveVehicle,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text("Confirmar e Salvar Veículo"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleDetailsCard() {
    final vehicle = _consultedVehicle!;
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.radiusLg,
        side: const BorderSide(color: AppColors.primary100, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Ionicons.car_sport_outline, color: AppColors.primary600, size: 28),
                const SizedBox(width: 10),
                Text(
                  "Dados Retornados",
                  style: AppTextStyles.h3.copyWith(color: AppColors.primary600),
                ),
              ],
            ),
            const Divider(height: 25, thickness: 1.2),
            _buildDetailRow("Marca / Fabricante", vehicle.brand),
            _buildDetailRow("Modelo", vehicle.model),
            _buildDetailRow("Ano Fabricação / Modelo", "${vehicle.yearFabrication} / ${vehicle.yearModel}"),
            _buildDetailRow("Cor Predominante", vehicle.color),
            _buildDetailRow("Combustível", vehicle.fuel),
            _buildDetailRow("Chassi", vehicle.chassis),
            _buildDetailRow("Categoria", vehicle.category),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
