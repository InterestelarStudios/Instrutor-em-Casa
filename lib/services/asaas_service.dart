import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:instrutor_em_casa/models/aula.dart';

class AsaasService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'southamerica-east1',
  );

  /// Cria a cobrança no Asaas de forma 100% segura através do Cloud Functions
  static Future<Map<String, dynamic>?> createPayment({
    required Aula aula,
    required String billingType,
  }) async {
    try {
      final callable = _functions.httpsCallable('createPaymentSession');
      final result = await callable.call({
        'aulaData': {
          'id': aula.id,
          'category': aula.category.name,
          'price': {'amount': aula.price.amount},
          'aluno': {'id': aula.aluno.id, 'name': aula.aluno.name},
          'instrutor': {'id': aula.instrutor.id, 'name': aula.instrutor.name},
        },
        'billingType': billingType, // 'PIX', 'CREDIT_CARD', 'UNDEFINED'
      });

      if (result.data != null) {
        return Map<String, dynamic>.from(result.data as Map);
      }
      return null;
    } on FirebaseFunctionsException catch (e) {
      debugPrint("FirebaseFunctionsException code: ${e.code}, message: ${e.message}, details: ${e.details}");
      throw e.message ?? "Erro ao processar pagamento.";
    } catch (e) {
      debugPrint("Erro inesperado ao processar pagamento: $e");
      throw "Erro inesperado ao processar pagamento: $e";
    }
  }
}
