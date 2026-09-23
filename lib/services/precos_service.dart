import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instrutor_em_casa/models/precos_config.dart';

class PrecosService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'configuracoes';
  static const String _doc = 'precos';

  /// Obtém as configurações de preços do Firestore com fallback seguro para os padrões
  static Future<PrecosConfig> getPrecos() async {
    try {
      final doc = await _firestore.collection(_collection).doc(_doc).get();
      if (doc.exists && doc.data() != null) {
        return PrecosConfig.fromMap(doc.data()!);
      }
    } catch (e) {
      // Retorna os valores padrão caso ocorra algum erro (offline ou documento ainda não criado)
    }
    return const PrecosConfig();
  }

  /// Escuta em tempo real atualizações nos preços
  static Stream<PrecosConfig> streamPrecos() {
    return _firestore
        .collection(_collection)
        .doc(_doc)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return PrecosConfig.fromMap(snapshot.data()!);
      }
      return const PrecosConfig();
    }).handleError((_) => const PrecosConfig());
  }
}
