import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/screens/aluno_screens/buscar_instrutores/buscar_instrutores.dart';
import 'package:instrutor_em_casa/widgets/loading_box.dart';
import 'package:ionicons/ionicons.dart';

class HomeScreenAluno extends StatefulWidget {
  const HomeScreenAluno({super.key, required this.usuario, required this.position});
  final Usuario usuario;
  final Position? position;

  @override
  State<HomeScreenAluno> createState() => _HomeScreenAlunoState();
}

class _HomeScreenAlunoState extends State<HomeScreenAluno> with AutomaticKeepAliveClientMixin{
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  String? mapStyle;

  Future<void> loadMapStyle() async {
    try {
      String style = await rootBundle.loadString('assets/map_style.json');
      setState(() {
        mapStyle = style;
      });
    } catch (e) {
      debugPrint("Erro ao carregar estilo: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    loadMapStyle();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 20,),
        Text(
          "Olá, ${widget.usuario.name.split(" ").first}!",
          style: Theme.of(context).textTheme.displayMedium,
        ),
        Text(
          "Está pronto para sua próxima aula?",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20,),
        widget.position == null ?
        LoadingBox(height: 300,) :
        SizedBox(
          height: 300,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 25),
                child: ClipRRect(
                  borderRadius: BorderRadiusGeometry.circular(20),
                  child: GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        widget.position!.latitude, widget.position!.longitude
                      ),
                      zoom: 12
                    ),
                    zoomControlsEnabled: true,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    onMapCreated: (GoogleMapController controller) {
                      _controller.complete(controller);
                    },
                    style: mapStyle,
                    // Exemplo de um marcador inicial
                    markers: {
                      const Marker(
                        markerId: MarkerId('ponto_inicial'),
                        position: LatLng(-23.5505, -46.6333),
                        infoWindow: InfoWindow(title: 'Localização Selecionada'),
                      ),
                    },
                  ),
                ),
              ),
              SizedBox(
                height: 50,
                width: MediaQuery.of(context).size.width / 1.4,
                child: ElevatedButton.icon(
                  onPressed: (){
                    showDialog(
                      context: context,
                      useSafeArea: false,
                      builder: (context){
                        return BuscarInstrutores(
                          usuario: widget.usuario,
                          position: LatLng(
                            widget.position!.latitude,
                            widget.position!.longitude,
                          ),
                          style: mapStyle,
                        );
                      }
                    );
                  },
                  label: Text("Buscar por Instrutores"),
                  icon: Icon(Ionicons.locate_outline),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
  
  @override
  bool get wantKeepAlive => true;
}