import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:instrutor_em_casa/services/location_services.dart';
import 'package:instrutor_em_casa/widgets/dialog_services.dart';
import 'package:instrutor_em_casa/widgets/loading_box.dart';

class InstrutorLocationPicker extends StatefulWidget {
  const InstrutorLocationPicker({super.key});

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
    final pickedPosition = await LocationServices().pickCurrentLocation(context);
    if(pickedPosition != null){
      setState(() {
        loadingLocation = false;
        position = LatLng(pickedPosition.latitude, pickedPosition.longitude);
        updateMarker();
      });
    }
  }

  void updateMarker(){
    markers.clear();
    markers.add(
      Marker(
        markerId: MarkerId("location"),
        position: LatLng(position.latitude, position.longitude),
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
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 80,),
            Text(
              "Localização",
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 20,),
            Text(
              "Marque sua localização de partida. Será utilizada para que alunos próximos de você possam te visualizar.",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20,),
            Expanded(
              child: loadingLocation ?
              LoadingBox() :
              ClipRRect(
                borderRadius: BorderRadiusGeometry.circular(20),
                child: GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: CameraPosition(
                    target: position,
                    zoom: 15
                  ),
                  zoomControlsEnabled: true,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                  onTap: (value){
                    setState(() {
                      position = value;
                      updateMarker();
                    });
                  },
                  // Exemplo de um marcador inicial
                  markers: markers,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: loadingLocation ? null :
      Container(
        height: 50,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: FilledButton(
          onPressed: loading ? null : (){
            setState(() {
              loading = true;
            });
            final user = FirebaseAuth.instance.currentUser;
            final GeoFirePoint geoFirePoint = GeoFirePoint(GeoPoint(position.latitude, position.longitude));
            FirebaseFirestore.instance.collection("users").doc(user!.uid)
            .update({
              "geo" : geoFirePoint.data
            }).catchError((e){
              setState(() {
                loading = false;
              });
              DialogServices().alertDialog(context, "Erro ao salvar localização, contate o suporte.");
            });
          },
          child: loading ? CircularProgressIndicator() : Text("Salvar Localização")
        ),
      ),
    );
  }
}