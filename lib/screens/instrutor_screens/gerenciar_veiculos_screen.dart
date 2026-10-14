import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/models/vehicle.dart';
import 'package:instrutor_em_casa/screens/instrutor_screens/cadastrar_veiculo_screen.dart';
import 'package:instrutor_em_casa/widgets/chip.dart';
import 'package:instrutor_em_casa/widgets/dialog_services.dart';
import 'package:instrutor_em_casa/widgets/theme.dart';
import 'package:ionicons/ionicons.dart';

class GerenciarVeiculosScreen extends StatefulWidget {
  final Usuario usuario;

  const GerenciarVeiculosScreen({super.key, required this.usuario});

  @override
  State<GerenciarVeiculosScreen> createState() => _GerenciarVeiculosScreenState();
}

class _GerenciarVeiculosScreenState extends State<GerenciarVeiculosScreen> {
  Future<void> _setDefaultVehicle(Vehicle vehicle) async {
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.usuario.id)
          .update({
        "instrutor.defaultVehicle": vehicle.toMap(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Veículo ${vehicle.model} definido como padrão!"),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        DialogServices().alertDialog(
          context,
          "Erro ao definir veículo padrão: $e",
          title: "Erro",
        );
      }
    }
  }

  Future<void> _deleteVehicle(Vehicle vehicle, bool isDefault) async {
    DialogServices().alertDialog(
      context,
      "Deseja realmente excluir o veículo ${vehicle.brand} ${vehicle.model} (Placa: ${vehicle.plate})?",
      title: "Excluir Veículo",
      buttonTitle1: "Excluir",
      buttonTitle2: "Cancelar",
      colorButton1: AppColors.emergency,
      colorButton2: Colors.grey,
      onTap2: () => Navigator.pop(context),
      onTap1: () async {
        Navigator.pop(context); // Fecha o dialog
        try {
          // Deleta da subcoleção
          await FirebaseFirestore.instance
              .collection("users")
              .doc(widget.usuario.id)
              .collection("vehicles")
              .doc(vehicle.id)
              .delete();

          // Se for o veículo padrão, limpa o campo no documento do usuário
          if (isDefault) {
            await FirebaseFirestore.instance
                .collection("users")
                .doc(widget.usuario.id)
                .update({
              "instrutor.defaultVehicle": null,
            });
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Veículo excluído com sucesso!"),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            DialogServices().alertDialog(
              context,
              "Erro ao excluir veículo: $e",
              title: "Erro",
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Meus Veículos"),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(widget.usuario.id)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final liveUser = Usuario.fromMap(userSnapshot.data!.data()!);
          final defaultVehicleId = liveUser.instrutor?.defaultVehicle?.id;

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection("users")
                .doc(widget.usuario.id)
                .collection("vehicles")
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }

              final vehicles = snapshot.data!.docs
                  .map((doc) => Vehicle.fromMap(doc.data()))
                  .toList();

              return ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                itemCount: vehicles.length,
                itemBuilder: (context, index) {
                  final vehicle = vehicles[index];
                  final isDefault = vehicle.id == defaultVehicleId;

                  return _buildVehicleCard(vehicle, isDefault);
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CadastrarVeiculoScreen(usuario: widget.usuario),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text("Cadastrar Novo Veículo"),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 55),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Ionicons.car_outline,
                size: 60,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Nenhum veículo cadastrado",
              style: AppTextStyles.h3.copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Para realizar suas aulas práticas, você precisa cadastrar um veículo ativo. Toque no botão abaixo para adicionar.",
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle, bool isDefault) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.radiusLg,
        side: BorderSide(
          color: isDefault ? AppColors.primary200 : AppColors.border,
          width: isDefault ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDefault ? AppColors.primary50 : AppColors.gray100,
                    borderRadius: AppRadius.radiusMd,
                  ),
                  child: Icon(
                    Ionicons.car,
                    color: isDefault ? AppColors.primary600 : AppColors.gray600,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              "${vehicle.brand} ${vehicle.model}",
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (isDefault)
                            const AppChip(
                              title: "Padrão",
                              type: AppChipType.done,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Placa: ${vehicle.plate} • Cor: ${vehicle.color}",
                        style: AppTextStyles.caption.copyWith(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Categoria: ${vehicle.category} • ${vehicle.fuel}",
                        style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Chassi: ${vehicle.chassis}",
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!isDefault)
                  TextButton.icon(
                    onPressed: () => _setDefaultVehicle(vehicle),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text("Definir como Padrão"),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  )
                else
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.success, size: 18),
                      SizedBox(width: 6),
                      Text(
                        "Veículo ativo para aulas",
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                IconButton(
                  onPressed: () => _deleteVehicle(vehicle, isDefault),
                  icon: const Icon(Ionicons.trash_outline, color: AppColors.emergency, size: 20),
                  tooltip: "Excluir veículo",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
