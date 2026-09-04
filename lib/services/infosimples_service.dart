import 'package:cloud_functions/cloud_functions.dart';
import 'package:instrutor_em_casa/models/vehicle.dart';

class InfosimplesService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'southamerica-east1',
  );

  /// Consulta dados de veículos através do Cloud Functions de forma segura sem expor tokens
  static Future<Vehicle> consultVehicle({
    required String plate,
    required String renavam,
    required String uf,
  }) async {
    final cleanPlate = plate
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
    final cleanRenavam = renavam.replaceAll(RegExp(r'[^0-9]'), '');
    final cleanUf = uf.trim().toLowerCase();

    if (cleanPlate.isEmpty || cleanRenavam.isEmpty || cleanUf.isEmpty) {
      throw "Placa, Renavam e UF são obrigatórios.";
    }

    try {
      final callable = _functions.httpsCallable('consultVehicleData');
      final result = await callable.call({
        'plate': cleanPlate,
        'renavam': cleanRenavam,
        'uf': cleanUf,
      });

      if (result.data != null) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          result.data as Map,
        );
        return Vehicle.fromMap(data);
      } else {
        throw "Dados do veículo não retornados.";
      }
    } on FirebaseFunctionsException catch (e) {
      throw e.message ?? "Erro ao consultar veículo.";
    } catch (e) {
      throw "Erro inesperado ao consultar veículo: $e";
    }
  }
}
