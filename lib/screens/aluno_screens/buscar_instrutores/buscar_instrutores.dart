// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:instrutor_em_casa/models/instrutor.dart';
import 'package:instrutor_em_casa/models/precos_config.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/screens/user_details/user_details.dart';
import 'package:instrutor_em_casa/services/precos_service.dart';
import 'package:instrutor_em_casa/widgets/avatar.dart';
import 'package:instrutor_em_casa/widgets/loading_box.dart';
import 'package:instrutor_em_casa/widgets/stars.dart';
import 'package:instrutor_em_casa/widgets/theme.dart';
import 'package:ionicons/ionicons.dart';

class BuscarInstrutores extends StatefulWidget {
  const BuscarInstrutores({super.key, required this.usuario, required this.position, required this.style, this.initialCategory});
  final Usuario usuario;
  final LatLng position;
  final String? style;
  final String? initialCategory;

  @override
  State<BuscarInstrutores> createState() => _BuscarInstrutoresState();
}

class _BuscarInstrutoresState extends State<BuscarInstrutores> {
  final _controller = Completer<GoogleMapController>();
  late Stream<List<DocumentSnapshot<Map<String, dynamic>>>> stream;
  double radius = 10; // Default radius in Km
  String? selectedCategory;

  PrecosConfig _precosConfig = const PrecosConfig();
  StreamSubscription<PrecosConfig>? _precosSub;

  String _getHourPriceRange(Usuario instrutor) {
    final categories = instrutor.instrutor?.categories ?? [];
    if (categories.isEmpty) {
      return _precosConfig.categoriaB.toStringAsFixed(0);
    }

    if (selectedCategory != null) {
      final catEnum = CNHCategory.values.where((c) => c.name == selectedCategory).firstOrNull;
      if (catEnum != null) {
        return _precosConfig.getPriceForCategory(catEnum).toStringAsFixed(0);
      }
      return _precosConfig.categoriaB.toStringAsFixed(0);
    }

    // Calcula preços de todas as categorias atendidas pelo instrutor
    final prices = categories.map((c) => _precosConfig.getPriceForCategory(c)).toSet().toList();
    prices.sort();

    if (prices.isEmpty) {
      return _precosConfig.categoriaB.toStringAsFixed(0);
    }

    if (prices.length == 1 || prices.first == prices.last) {
      return prices.first.toStringAsFixed(0);
    }

    return "${prices.first.toStringAsFixed(0)} - ${prices.last.toStringAsFixed(0)}";
  }

  Stream<List<DocumentSnapshot<Map<String, dynamic>>>> addListenersInstrutores() {
    // 1. Centro da busca
    final GeoFirePoint center = GeoFirePoint(GeoPoint(widget.position.latitude, widget.position.longitude));

    // 2. Referência da coleção
    final collectionReference = FirebaseFirestore.instance.collection('users');

    // 3. Função para extrair o GeoPoint (mesma lógica anterior)
    GeoPoint geopointFrom(Map<String, dynamic> data) =>
        (data['geo'] as Map<String, dynamic>)['geopoint'] as GeoPoint;

    // 4. Retorno com QueryBuilder para filtros adicionais
    return GeoCollectionReference<Map<String, dynamic>>(collectionReference)
        .subscribeWithin(
      center: center,
      radiusInKm: radius,
      field: 'geo',
      geopointFrom: geopointFrom,
      strictMode: true,
      queryBuilder: (query) {
        var filtrada = query
            .where('type', isEqualTo: "instrutor")
            .where('instrutor.active', isEqualTo: true);
        
        if (selectedCategory != null) {
          filtrada = filtrada.where('instrutor.categories', arrayContains: selectedCategory);
        }
        
        return filtrada;
      },
    );
  }

  void _updateFilter(String? category) {
    setState(() {
      selectedCategory = category;
      stream = addListenersInstrutores();
    });
  }

  void _updateRadius(double newRadius) async {
    setState(() {
      radius = newRadius;
      stream = addListenersInstrutores();
    });

    // Adjust zoom based on radius
    final controller = await _controller.future;
    double zoom = 11.5;
    if (radius <= 5) zoom = 13;
    else if (radius <= 10) zoom = 12;
    else if (radius <= 20) zoom = 11;
    else if (radius <= 50) zoom = 9.5;
    else zoom = 8;

    controller.animateCamera(CameraUpdate.newLatLngZoom(widget.position, zoom));
  }

  void _showRadiusDialog() {
    showDialog(
      context: context,
      builder: (context) {
        double tempRadius = radius;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Raio de Busca"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("${tempRadius.toInt()} km"),
                  Slider(
                    value: tempRadius,
                    min: 5,
                    max: 100,
                    divisions: 19,
                    label: "${tempRadius.toInt()} km",
                    onChanged: (value) {
                      setDialogState(() {
                        tempRadius = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () {
                    _updateRadius(tempRadius);
                    Navigator.pop(context);
                  },
                  child: const Text("Atualizar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.initialCategory;
    stream = addListenersInstrutores();
    _precosSub = PrecosService.streamPrecos().listen((precos) {
      if (mounted) {
        setState(() {
          _precosConfig = precos;
        });
      }
    });
  }

  @override
  void dispose() {
    _precosSub?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height / 1.5,
            child: GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(
                target: widget.position,
                zoom: 11.5
              ),
              zoomControlsEnabled: true,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              style: widget.style,
              circles: {
                Circle(
                  circleId: CircleId("Center"),
                  center: widget.position,
                  radius: radius * 1000,
                  strokeColor: AppColors.primary,
                  fillColor: AppColors.primary.withAlpha(50),
                  strokeWidth: 1
                )
              },
              markers: {
                Marker(
                  markerId: const MarkerId('ponto_inicial'),
                  position: widget.position,
                  infoWindow: const InfoWindow(title: 'Sua Localização'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                ),
              },
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.4,
            maxChildSize: 0.88,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -3),
                    )
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.only(),
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 20, bottom: 0),
                        height: 7,
                        width: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey[100]
                        ),
                      ),
                    ),
                    const SizedBox(height: 20,),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text("Instrutores", style: Theme.of(context).textTheme.displaySmall,)
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildCategoryFilter(),
                    const SizedBox(height: 10),
                    StreamBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
                      stream: stream,
                      builder: (context, snapshot){
                        if(snapshot.connectionState == ConnectionState.waiting){
                          return ListView.builder(
                            itemCount: 5,
                            padding: const EdgeInsets.all(20),
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemBuilder: (context, index){
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: LoadingBox(
                                  height: 100,
                                ),
                              );
                            }
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(Ionicons.searchOutline, size: 50, color: AppColors.textMuted),
                                const SizedBox(height: 10),
                                Text(
                                  "Nenhum instrutor encontrado nesse raio.",
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          );
                        }

                        List<Usuario> instrutores = snapshot.data!.map<Usuario>((e)=> Usuario.fromMap(e.data()!)).toList();

                        return ListView.builder(
                          itemCount: instrutores.length,
                          padding: const EdgeInsets.all(20),
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemBuilder: (context, index){

                            final instrutor = instrutores[index];

                            return GestureDetector(
                              onTap: ()=> Navigator.push(
                                context, MaterialPageRoute(
                                  builder: (_)=> UserDetailsScreen(
                                    usuario: instrutor,
                                    myUser: widget.usuario
                                  ),
                                ),
                              ),
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      UserAvatar(user: instrutor.toDetails()),
                                      const SizedBox(width: 20,),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Text(instrutor.name, style: Theme.of(context).textTheme.titleLarge,),
                                            Row(
                                              children: [
                                                StarRating(stars: 4.2, size: 15,),
                                                const SizedBox(width: 10,),
                                                Text("4.2", style: Theme.of(context).textTheme.titleSmall,),
                                                const SizedBox(width: 5,),
                                                Text("(8 aulas)", style: Theme.of(context).textTheme.bodySmall,),
                                              ],
                                            ),
                                            const SizedBox(height: 10,),
                                            Divider(),
                                            const SizedBox(height: 10,),
                                            Row(
                                              children: [
                                                Text(
                                                  "R\$${_getHourPriceRange(instrutor)}",
                                                  style: Theme.of(context).textTheme.titleLarge,
                                                ),
                                                Text("/h",  style: Theme.of(context).textTheme.bodySmall,),
                                                Expanded(child: SizedBox()),
                                                Icon(Ionicons.location, color: AppColors.textMuted, size: 15,),
                                                Builder(
                                                  builder: (context){
                                                    final distance = Geolocator.distanceBetween(
                                                      instrutor.geo!['geopoint'].latitude,
                                                      instrutor.geo!['geopoint'].longitude,
                                                      widget.position.latitude,
                                                      widget.position.longitude
                                                    ) / 1000;
                                                    return Text("${distance.toStringAsFixed(1)} km²", style: Theme.of(context).textTheme.bodySmall,);
                                                  },
                                                )
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }
                        );
                      }
                    ),
                  ],
                )
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FloatingActionButton(
                    heroTag: "btnBack",
                    onPressed: ()=> Navigator.pop(context),
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.gray950,
                    elevation: 5,
                    mini: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusGeometry.circular(20)
                    ),
                    child: Icon(Icons.keyboard_arrow_left_rounded),
                  ),
                  GestureDetector(
                    onTap: _showRadiusDialog,
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Row(
                          children: [
                            Icon(Ionicons.locateOutline, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              "${radius.toInt()} km²",
                              style: AppTextStyles.h3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['A', 'B'];
    return SizedBox(
      height: 45,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isAll = selectedCategory == null;
            return ChoiceChip(
              label: const Text("Todos"),
              selected: isAll,
              onSelected: (selected) => _updateFilter(null),
              selectedColor: AppColors.primary100,
              labelStyle: TextStyle(
                color: isAll ? AppColors.primary600 : AppColors.textSecondary,
                fontWeight: isAll ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }

          final cat = categories[index - 1];
          final isSelected = selectedCategory == cat;

          return ChoiceChip(
            label: Text("Cat. $cat"),
            selected: isSelected,
            onSelected: (selected) => _updateFilter(selected ? cat : null),
            selectedColor: AppColors.primary100,
            labelStyle: TextStyle(
              color: isSelected ? AppColors.primary600 : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          );
        },
      ),
    );
  }
}