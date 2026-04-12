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
      DialogServices().alertDialog(context, 'O serviço de localização está desativado.');
      return null;
    }

    // 2. Verifica e solicita permissão
    permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
      if (permissao == LocationPermission.denied) {
        DialogServices().alertDialog(context, 'Permissão de localização negada.');
        return null;
      }
    }

    if (permissao == LocationPermission.deniedForever) {
      DialogServices().alertDialog(context, 'As permissões de localização foram negadas permanentemente.');
      return null;
    }

    // 3. Pega a posição atual (Latitude e Longitude)
    final position = await Geolocator.getCurrentPosition();
    return position;
  }

}