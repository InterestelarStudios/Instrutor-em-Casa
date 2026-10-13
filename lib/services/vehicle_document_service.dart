import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:instrutor_em_casa/models/vehicle.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class VehicleDocumentService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Extrai dados do veículo diretamente no dispositivo (100% On-Device, sem depender de APIs externas)
  static Future<Vehicle> extractVehicleData({
    required Uint8List bytes,
    required String mimeType,
    String? filePath,
  }) async {
    try {
      String rawText = "";

      final isPdf = mimeType.toLowerCase().contains("pdf") ||
          (filePath != null && filePath.toLowerCase().endsWith(".pdf"));

      if (isPdf) {
        // Leitura de PDF no próprio dispositivo via Syncfusion PDF
        final PdfDocument document = PdfDocument(inputBytes: bytes);
        rawText = PdfTextExtractor(document).extractText();
        document.dispose();
      } else {
        // Leitura de Imagem (Foto / Galeria) via Google ML Kit On-Device OCR
        File? tempFile;
        String imagePath = filePath ?? "";

        if (imagePath.isEmpty) {
          final tempDir = Directory.systemTemp;
          final tempTimestamp = DateTime.now().millisecondsSinceEpoch;
          tempFile = File('${tempDir.path}/temp_doc_$tempTimestamp.jpg');
          await tempFile.writeAsBytes(bytes);
          imagePath = tempFile.path;
        }

        final inputImage = InputImage.fromFilePath(imagePath);
        final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
        final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
        await textRecognizer.close();

        rawText = recognizedText.text;

        if (tempFile != null && await tempFile.exists()) {
          await tempFile.delete();
        }
      }

      if (rawText.trim().isEmpty) {
        throw "Não foi possível identificar texto no documento fornecido.";
      }

      return _parseVehicleDocumentText(rawText);
    } catch (e) {
      throw "Falha no reconhecimento óptico (OCR): $e";
    }
  }

  /// Analisador inteligente de regras e expressões regulares para CRLV / CRLV-e / LADV
  static Vehicle _parseVehicleDocumentText(String rawText) {
    // Normaliza o texto para caixa alta e quebra em linhas
    final upperText = rawText.toUpperCase();
    final lines = upperText.split(RegExp(r'[\r\n]+')).map((l) => l.trim()).toList();

    String plate = "";
    String renavam = "";
    String chassis = "";
    String brand = "";
    String model = "";
    int yearFabrication = 0;
    int yearModel = 0;
    String color = "";
    String fuel = "";
    String category = "";

    // 1. EXTRAÇÃO DA PLACA (Mercosul: ABC1D23 ou Antiga: ABC1234)
    final plateMercosulRegex = RegExp(r'\b[A-Z]{3}[0-9][A-Z][0-9]{2}\b');
    final plateOldRegex = RegExp(r'\b[A-Z]{3}[0-9]{4}\b');

    // Tenta achar linha com 'PLACA'
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains("PLACA")) {
        final match = plateMercosulRegex.firstMatch(lines[i]) ?? plateOldRegex.firstMatch(lines[i]);
        if (match != null) {
          plate = match.group(0)!;
          break;
        } else if (i + 1 < lines.length) {
          final nextMatch = plateMercosulRegex.firstMatch(lines[i + 1]) ?? plateOldRegex.firstMatch(lines[i + 1]);
          if (nextMatch != null) {
            plate = nextMatch.group(0)!;
            break;
          }
        }
      }
    }

    if (plate.isEmpty) {
      final match = plateMercosulRegex.firstMatch(upperText) ?? plateOldRegex.firstMatch(upperText);
      if (match != null) {
        plate = match.group(0)!;
      }
    }

    // 2. EXTRAÇÃO DO RENAVAM (9 a 11 dígitos)
    final renavamRegex = RegExp(r'\b\d{9,11}\b');
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains("RENAVAM")) {
        final match = renavamRegex.firstMatch(lines[i]);
        if (match != null) {
          renavam = match.group(0)!;
          break;
        } else if (i + 1 < lines.length) {
          final nextMatch = renavamRegex.firstMatch(lines[i + 1]);
          if (nextMatch != null) {
            renavam = nextMatch.group(0)!;
            break;
          }
        }
      }
    }

    if (renavam.isEmpty) {
      final matches = renavamRegex.allMatches(upperText);
      for (final m in matches) {
        final val = m.group(0)!;
        // Evita chassi ou outros números
        if (!val.startsWith("19") && !val.startsWith("20") || val.length >= 9) {
          renavam = val;
          break;
        }
      }
    }

    // 3. EXTRAÇÃO DO CHASSI (17 caracteres alfanuméricos)
    final chassisRegex = RegExp(r'\b[A-HJ-NPR-Z0-9]{17}\b');
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains("CHASSI")) {
        final match = chassisRegex.firstMatch(lines[i]);
        if (match != null) {
          chassis = match.group(0)!;
          break;
        } else if (i + 1 < lines.length) {
          final nextMatch = chassisRegex.firstMatch(lines[i + 1]);
          if (nextMatch != null) {
            chassis = nextMatch.group(0)!;
            break;
          }
        }
      }
    }

    if (chassis.isEmpty) {
      final match = chassisRegex.firstMatch(upperText);
      if (match != null) {
        chassis = match.group(0)!;
      }
    }

    // 4. EXTRAÇÃO DO ANO (FABRICAÇÃO / MODELO)
    // No CRLV digital brasileiro, os anos vêm na mesma linha separados por espaço (ex: "2021 2022") ou barra (ex: "2021/2022")
    final yearRegex = RegExp(r'\b(19\d{2}|20\d{2})\b');
    for (final line in lines) {
      final matches = yearRegex.allMatches(line).map((m) => int.parse(m.group(0)!)).toList();
      if (matches.length >= 2) {
        for (int k = 0; k < matches.length - 1; k++) {
          final y1 = matches[k];
          final y2 = matches[k + 1];
          if (y1 <= y2 && (y2 - y1 <= 1)) {
            yearFabrication = y1;
            yearModel = y2;
            break;
          }
        }
        if (yearFabrication > 0) break;
      }
    }

    final currentYear = DateTime.now().year;
    if (yearFabrication == 0) yearFabrication = currentYear;
    if (yearModel == 0) yearModel = yearFabrication;

    // 5. EXTRAÇÃO DE MARCA E MODELO
    // Dicionário com todas as abreviações e marcas oficiais do Denatran/CRLV
    final brandMap = {
      'CHEV': 'CHEVROLET',
      'CHEVROLET': 'CHEVROLET',
      'GM': 'CHEVROLET',
      'VW': 'VOLKSWAGEN',
      'VOLKS': 'VOLKSWAGEN',
      'VOLKSWAGEN': 'VOLKSWAGEN',
      'FIAT': 'FIAT',
      'TOYOTA': 'TOYOTA',
      'HYUNDAI': 'HYUNDAI',
      'RENAULT': 'RENAULT',
      'HONDA': 'HONDA',
      'FORD': 'FORD',
      'NISSAN': 'NISSAN',
      'JEEP': 'JEEP',
      'PEUGEOT': 'PEUGEOT',
      'CITROEN': 'CITROEN',
      'MITSUBISHI': 'MITSUBISHI',
      'CHERY': 'CAOA CHERY',
      'CAOA': 'CAOA CHERY',
      'BMW': 'BMW',
      'MERCEDES': 'MERCEDES-BENZ',
      'MB': 'MERCEDES-BENZ',
      'LR': 'LAND ROVER',
      'AUDI': 'AUDI',
      'KIA': 'KIA',
    };

    // 1º passo: busca por linha com barra '/' (padrão nacional: CHEV/ONIX PLUS 10MT LT2 ou FIAT/MOBI LIKE)
    for (final line in lines) {
      if (line.contains("/")) {
        final cleanLine = line.replaceAll(RegExp(r'^(I|NACIONAL)\/'), '').trim();
        final parts = cleanLine.split('/');
        if (parts.length >= 2) {
          final prefix = parts[0].trim().toUpperCase();
          if (brandMap.containsKey(prefix)) {
            brand = brandMap[prefix]!;
            model = parts.sublist(1).join("/").trim();
            break;
          }
        }
      }
    }

    // 2º passo: se não achou com barra, busca menções diretas de marca
    if (brand.isEmpty) {
      for (final entry in brandMap.entries) {
        if (upperText.contains(entry.key)) {
          brand = entry.value;
          break;
        }
      }
    }

    // 6. EXTRAÇÃO DA COR
    final colors = [
      'BRANCA', 'PRATA', 'PRETA', 'CINZA', 'VERMELHA', 'AZUL',
      'VERDE', 'AMARELA', 'MARROM', 'BEGE', 'LARANJA', 'PRETO', 'BRANCO'
    ];
    for (final c in colors) {
      if (upperText.contains(c)) {
        color = c == 'PRETO' ? 'PRETA' : (c == 'BRANCO' ? 'BRANCA' : c);
        break;
      }
    }

    // 7. EXTRAÇÃO DO COMBUSTÍVEL
    final fuels = ['FLEX', 'ALCOOL/GASOLINA', 'GASOLINA', 'DIESEL', 'ETANOL', 'ELETRICO', 'HIBRIDO'];
    for (final f in fuels) {
      if (upperText.contains(f)) {
        fuel = f;
        break;
      }
    }

    // 8. EXTRAÇÃO DA CATEGORIA
    if (upperText.contains("APRENDIZAGEM")) {
      category = "APRENDIZAGEM";
    } else if (upperText.contains("ALUGUEL")) {
      category = "ALUGUEL";
    } else if (upperText.contains("PARTICULAR")) {
      category = "PARTICULAR";
    }

    return Vehicle(
      id: "",
      plate: plate,
      renavam: renavam,
      brand: brand,
      model: model,
      yearFabrication: yearFabrication,
      yearModel: yearModel,
      color: color.isNotEmpty ? color : "BRANCA",
      fuel: fuel.isNotEmpty ? fuel : "FLEX",
      chassis: chassis,
      category: category.isNotEmpty ? category : "APRENDIZAGEM",
    );
  }

  /// Faz upload do documento anexado para o Firebase Storage
  static Future<String> uploadVehicleDocument({
    required String userId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    try {
      final ext = fileName.contains('.') ? fileName.split('.').last : 'pdf';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref().child('vehicle_documents/$userId/doc_$timestamp.$ext');

      final metadata = SettableMetadata(contentType: mimeType);
      final uploadTask = await ref.putData(bytes, metadata);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw "Erro ao enviar arquivo do documento: $e";
    }
  }
}
