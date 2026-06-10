import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/models/aula.dart';

class AsaasService {
  static const String baseUrl = 'https://sandbox.asaas.com/api/v3';
  static const String apiKey = 'SUA_CHAVE_API_ASAAS_AQUI'; // O usuário deve substituir aqui

  /// Cria uma subconta para o instrutor
  static Future<Map<String, dynamic>?> createSubAccount(Usuario user) async {
    final url = Uri.parse('$baseUrl/accounts');
    final response = await http.post(
      url,
      headers: {
        'access_token': apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': user.name,
        'email': user.email,
        'cpfCnpj': user.data.cpf,
        'phone': user.data.phone,
        'mobilePhone': user.data.phone,
        'companyType': 'INDIVIDUAL',
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Erro ao criar subconta: ${response.body}');
      return null;
    }
  }

  /// Busca documentos pendentes da subconta
  static Future<List<dynamic>> getPendingDocuments(String subAccountApiKey) async {
    final url = Uri.parse('$baseUrl/myAccount/documents');
    final response = await http.get(
      url,
      headers: {
        'access_token': subAccountApiKey,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    } else {
      print('Erro ao buscar documentos: ${response.body}');
      return [];
    }
  }

  /// Faz upload de documento para a subconta
  static Future<bool> uploadDocument({
    required String subAccountApiKey,
    required String groupId,
    required File file,
    required String type,
  }) async {
    final url = Uri.parse('$baseUrl/myAccount/documents/$groupId');
    final request = http.MultipartRequest('POST', url)
      ..headers['access_token'] = subAccountApiKey
      ..fields['type'] = type
      ..files.add(await http.MultipartFile.fromPath('documentFile', file.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      return true;
    } else {
      final responseBody = await response.stream.bytesToString();
      print('Erro ao subir documento: $responseBody');
      return false;
    }
  }

  /// Cria um cliente no Asaas (o aluno)
  static Future<String?> createCustomer(Usuario user) async {
    final url = Uri.parse('$baseUrl/customers');
    final response = await http.post(
      url,
      headers: {
        'access_token': apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': user.name,
        'email': user.email,
        'cpfCnpj': user.data.cpf,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['id'];
    } else {
      print('Erro ao criar cliente: ${response.body}');
      return null;
    }
  }

  /// Cria um pagamento com split
  static Future<Map<String, dynamic>?> createPayment({
    required Aula aula,
    required String customerId,
    required String walletId,
    required String billingType, // PIX, CREDIT_CARD
    Map<String, dynamic>? creditCard,
    Map<String, dynamic>? creditCardHolderInfo,
  }) async {
    final url = Uri.parse('$baseUrl/payments');
    
    // Calcula o split (ex: 80% para o instrutor, 20% para a plataforma)
    // O Asaas desconta a taxa do valor total e depois divide o líquido.
    final split = [
      {
        'walletId': walletId,
        'percentualValue': 80.0, // Exemplo: 80% para o instrutor
      }
    ];

    final body = {
      'customer': customerId,
      'billingType': billingType,
      'value': aula.price.amount,
      'dueDate': DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0],
      'description': 'Aula de Direção - ${aula.category.name}',
      'externalReference': aula.id,
      'split': split,
    };

    if (billingType == 'CREDIT_CARD') {
      body['creditCard'] = creditCard!;
      body['creditCardHolderInfo'] = creditCardHolderInfo!;
      body['remoteIp'] = '127.0.0.1'; // Em produção, usar o IP real do cliente
    }

    final response = await http.post(
      url,
      headers: {
        'access_token': apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Erro ao criar pagamento: ${response.body}');
      return null;
    }
  }

  /// Consulta o status da conta
  static Future<Map<String, dynamic>?> getAccountStatus(String subAccountApiKey) async {
    final url = Uri.parse('$baseUrl/myAccount/status');
    final response = await http.get(
      url,
      headers: {
        'access_token': subAccountApiKey,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Erro ao buscar status da conta: ${response.body}');
      return null;
    }
  }

  /// Busca o saldo da subconta
  static Future<double> getBalance(String subAccountApiKey) async {
    final url = Uri.parse('$baseUrl/finance/balance');
    final response = await http.get(
      url,
      headers: {
        'access_token': subAccountApiKey,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['balance'] as num).toDouble();
    } else {
      print('Erro ao buscar saldo: ${response.body}');
      return 0.0;
    }
  }

  /// Solicita transferência do saldo
  static Future<bool> requestTransfer({
    required String subAccountApiKey,
    required double value,
  }) async {
    final url = Uri.parse('$baseUrl/transfers');
    final response = await http.post(
      url,
      headers: {
        'access_token': subAccountApiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'value': value,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print('Erro ao solicitar transferência: ${response.body}');
      return false;
    }
  }
}
