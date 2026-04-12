import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class FirestoreUploadFiles {

  Future<String> uploadDingleFile({
    required File arquivo,
    required String diretorio,
    String? fileName,
  }) async {
    try {
      final storage = FirebaseStorage.instance;

      // Extrai o nome do arquivo do caminho (Ex: /cache/perfil.jpg -> perfil.jpg)
      String nomeOriginal = fileName == null ? arquivo.path.split('/').last : "$fileName.${arquivo.path.split('/').last.split('.').last}";
      
      // Gera um nome único para evitar sobrescrever arquivos com o mesmo nome
      String nomeUnico = "${DateTime.now().millisecondsSinceEpoch}_$nomeOriginal";

      // Cria a referência no Firebase Storage
      Reference ref = storage.ref().child(diretorio).child(nomeUnico);

      // Inicia o upload e aguarda a conclusão
      UploadTask uploadTask = ref.putFile(arquivo);
      TaskSnapshot snapshot = await uploadTask;

      // Recupera e retorna a URL pública do arquivo
      String urlDownload = await snapshot.ref.getDownloadURL();
      
      return urlDownload;

    } on FirebaseException catch (e) {
      // Você pode usar sua função de tratamento de erro aqui
      throw Exception("Erro no Firebase Storage: ${e.code}");
    } catch (e) {
      throw Exception("Erro ao fazer upload do arquivo: $e");
    }
  }

}