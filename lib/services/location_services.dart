import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:instrutor_em_casa/widgets/dialog_services.dart';

class LocationServices {

  LocationServices();

  Future<Position?> pickCurrentLocation(BuildContext context) async {
    bool servicoAtivo;
    LocationPermission permissao;

    servicoAtivo = await Geolocator.isLocationServiceEnabled();
    if (!servicoAtivo) {
      if (context.mounted) {
        DialogServices().alertDialog(context, 'O serviço de localização está desativado.');
      }
      return null;
    }

    // 2. Verifica e solicita permissão
    permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
      if (permissao == LocationPermission.denied) {
        if (context.mounted) {
          DialogServices().alertDialog(context, 'Permissão de localização negada.');
        }
        return null;
      }
    }

    if (permissao == LocationPermission.deniedForever) {
      if (context.mounted) {
        DialogServices().alertDialog(context, 'As permissões de localização foram negadas permanentemente.');
      }
      return null;
    }

    // 3. Tenta obter a última posição conhecida para retorno rápido
    try {
      Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        // Tenta obter posição mais precisa com timeout curto se houver
        Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 4),
          ),
        ).then((fresh) {
          // Atualização de fundo se necessário
        }).catchError((_) {});
        return lastKnown;
      }
    } catch (_) {}

    // 4. Pega a posição atual com timeout de segurança
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return position;
    } catch (e) {
      debugPrint("Erro ao obter posição atual: $e");
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

}