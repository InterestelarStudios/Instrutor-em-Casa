import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:instrutor_em_casa/services/location_services.dart';
import 'package:instrutor_em_casa/widgets/dialog_services.dart';
import 'package:instrutor_em_casa/widgets/loading_box.dart';
import 'package:instrutor_em_casa/widgets/theme.dart';

class InstrutorLocationPicker extends StatefulWidget {
  const InstrutorLocationPicker({super.key, this.initialPosition});
  final LatLng? initialPosition;

  @override
  State<InstrutorLocationPicker> createState() => _InstrutorLocationPickerState();
}

class _InstrutorLocationPickerState extends State<InstrutorLocationPicker> {
  bool loadingLocation = true;
  late LatLng position;
  final _controller = Completer<GoogleMapController>();
  final markers = <Marker>{};
  bool loading = false;

  void pickPosition() async {
    try {
      if (widget.initialPosition != null) {
        position = widget.initialPosition!;
      } else {
        final pickedPosition = await LocationServices().pickCurrentLocation(context);
        if (pickedPosition != null) {
          position = LatLng(pickedPosition.latitude, pickedPosition.longitude);
        } else {
          position = const LatLng(-23.550520, -46.633308); // Fallback SP
        }
      }
    } catch (_) {
      position = widget.initialPosition ?? const LatLng(-23.550520, -46.633308);
    } finally {
      if (mounted) {
        setState(() {
          loadingLocation = false;
          updateMarker();
        });
      }
    }
  }

  void updateMarker() {
    markers.clear();
    markers.add(
      Marker(
        markerId: const MarkerId("location"),
        position: LatLng(position.latitude, position.longitude),
        infoWindow: const InfoWindow(title: "Ponto de Partida"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    pickPosition();
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return Scaffold(
      appBar: canPop
          ? AppBar(
              title: const Text("Alterar Localização"),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!canPop) const SizedBox(height: 60),
            Text(
              "Localização",
              style: Theme.of(context).textTheme.displayLarge ?? AppTextStyles.h1,
            ),
            const SizedBox(height: 10),
            Text(
              "Marque sua localização de partida no mapa. Será utilizada para que alunos próximos de você possam te visualizar.",
              style: Theme.of(context).textTheme.bodyLarge ?? AppTextStyles.body,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: loadingLocation
                  ? const LoadingBox()
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: GoogleMap(
                        mapType: MapType.normal,
                        initialCameraPosition: CameraPosition(
                          target: position,
                          zoom: 15,
                        ),
                        zoomControlsEnabled: true,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        onMapCreated: (GoogleMapController controller) {
                          if (!_controller.isCompleted) {
                            _controller.complete(controller);
                          }
                        },
                        onTap: (value) {
                          setState(() {
                            position = value;
                            updateMarker();
                          });
                        },
                        markers: markers,
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: loadingLocation
          ? null
          : Container(
              height: 52,
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: FilledButton(
                onPressed: loading
                    ? null
                    : () async {
                        setState(() {
                          loading = true;
                        });
                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) throw Exception("Usuário não autenticado");

                          final GeoFirePoint geoFirePoint = GeoFirePoint(
                            GeoPoint(position.latitude, position.longitude),
                          );

                          await FirebaseFirestore.instance
                              .collection("users")
                              .doc(user.uid)
                              .update({"geo": geoFirePoint.data});

                          if (mounted) {
                            setState(() {
                              loading = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Localização salva com sucesso!"),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context, true);
                            }
                          }
                        } catch (e) {
                          debugPrint("Erro ao salvar localização: $e");
                          if (mounted) {
                            setState(() {
                              loading = false;
                            });
                            DialogServices().alertDialog(
                              context,
                              "Erro ao salvar localização: $e",
                            );
                          }
                        }
                      },
                child: loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        "Salvar Localização",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
    );
  }
}