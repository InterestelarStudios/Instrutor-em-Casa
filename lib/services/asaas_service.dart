import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/models/aula.dart';
import 'package:intl/intl.dart';
import 'asaas_config.dart';

class AsaasService {
  // Configuração Produção
  static const String baseUrl =
      //"https://api-sandbox.asaas.com/v3";
      'https://api.asaas.com/v3';

  // ATENÇÃO: Esta chave deve ser a sua chave de produção/sandbox mestra (da plataforma)
  static const String masterApiKey = baseUrl == 'https://api.asaas.com/v3'
      ? AsaasConfig.prodApiKey
      : AsaasConfig.sandboxApiKey;

  /// Cria um cliente no Asaas (o aluno)
  static Future<String?> createCustomer(Usuario user) async {
    final url = Uri.parse('$baseUrl/customers');
    final body = {
      'name': user.name,
      'email': user.email,
      'cpfCnpj': user.data.cpf.replaceAll(RegExp(r'[^0-9]'), ''),
      'postalCode':
          user.data.postalCode?.replaceAll(RegExp(r'[^0-9]'), '') ?? '',
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'access_token': masterApiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['id'];
      } else {
        final errorData = jsonDecode(response.body);
        if (errorData['errors'] != null && errorData['errors'].isNotEmpty) {
          throw errorData['errors'][0]['description'];
        }
        return null;
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Cria um pagamento (100% responsabilidade da plataforma)
  static Future<Map<String, dynamic>?> createPayment({
    required Aula aula,
    required String customerId,
    required String billingType,
  }) async {
    final url = Uri.parse('$baseUrl/payments');

    final body = {
      'customer': customerId,
      'billingType': billingType, // PIX, CREDIT_CARD, UNDEFINED
      'value': aula.price.amount,
      'dueDate': DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now().add(const Duration(days: 1))),
      'description': 'Treinamento de Direção - ${aula.category.name}',
      'externalReference': aula.id, // ID da Aula para o Webhook identificar
    };

    final response = await http.post(
      url,
      headers: {
        'access_token': masterApiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      if (errorData['errors'] != null && errorData['errors'].isNotEmpty) {
        throw errorData['errors'][0]['description'];
      }
      return null;
    }
  }
}
