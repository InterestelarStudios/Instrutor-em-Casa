import 'package:cloud_firestore/cloud_firestore.dart';

class Transferencia {
  final String id;
  final String instrutorId;
  final double amount;
  final String pixKeyType;
  final String pixKey;
  final Timestamp date;
  final String status;
  final String? asaasTransferId;

  Transferencia({
    required this.id,
    required this.instrutorId,
    required this.amount,
    required this.pixKeyType,
    required this.pixKey,
    required this.date,
    required this.status,
    this.asaasTransferId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'instrutorId': instrutorId,
      'amount': amount,
      'pixKeyType': pixKeyType,
      'pixKey': pixKey,
      'date': date,
      'status': status,
      'asaasTransferId': asaasTransferId,
    };
  }

  factory Transferencia.fromMap(Map<String, dynamic> map) {
    return Transferencia(
      id: map['id'] as String? ?? '',
      instrutorId: map['instrutorId'] as String? ?? '',
      amount: (map['amount'] as num? ?? 0.0).toDouble(),
      pixKeyType: map['pixKeyType'] as String? ?? '',
      pixKey: map['pixKey'] as String? ?? '',
      date: map['date'] as Timestamp? ?? Timestamp.now(),
      status: map['status'] as String? ?? 'pending',
      asaasTransferId: map['asaasTransferId'] as String?,
    );
  }
}
