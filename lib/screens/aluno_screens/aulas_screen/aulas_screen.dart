import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:instrutor_em_casa/models/aula.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/screens/aluno_screens/aulas_screen/widgets/aula_build.dart';
import 'package:instrutor_em_casa/screens/aluno_screens/buscar_instrutores/buscar_instrutores.dart';
import 'package:instrutor_em_casa/services/location_services.dart';
import 'package:instrutor_em_casa/widgets/loading_box.dart';

class AulasAlunoScreen extends StatefulWidget {
  const AulasAlunoScreen({super.key, required this.usuario, this.position});
  final Usuario usuario;
  final Position? position;

  @override
  State<AulasAlunoScreen> createState() => _AulasAlunoScreenState();
}

class _AulasAlunoScreenState extends State<AulasAlunoScreen>
    with AutomaticKeepAliveClientMixin {
  late Query<Aula> query;

  @override
  void initState() {
    super.initState();
    query = FirebaseFirestore.instance
        .collection("aulas")
        .where("aluno.id", isEqualTo: widget.usuario.id)
        .orderBy("date", descending: false)
        .withConverter<Aula>(
          fromFirestore: (snapshot, options) => Aula.fromMap(snapshot.data()!),
          toFirestore: (snapshot, options) => {},
        );
  }

  Future<void> _buscarInstrutores() async {
    Position? pos = widget.position;
    if (pos == null) {
      try {
        pos = await LocationServices().pickCurrentLocation(context);
      } catch (e) {
        // Ignora erro de geolocalização e prossegue
      }
    }

    if (pos == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Não foi possível obter sua localização atual."),
          ),
        );
      }
      return;
    }

    String? style;
    try {
      style = await rootBundle.loadString('assets/map_style.json');
    } catch (_) {}

    if (mounted) {
      showDialog(
        context: context,
        useSafeArea: false,
        builder: (context) {
          return BuscarInstrutores(
            usuario: widget.usuario,
            position: LatLng(pos!.latitude, pos.longitude),
            style: style,
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            "Minhas aulas",
            style: Theme.of(context).textTheme.displayMedium,
          ),
          FirestoreListView<Aula>(
            query: query,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 20),
            loadingBuilder: (context) => ListView.builder(
              itemCount: 5,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: LoadingBox(height: 200),
                );
              },
            ),
            itemBuilder: (context, snapshot) {
              final aula = snapshot.data();
              return AulaBuild(aula: aula, usuario: widget.usuario);
            },
            emptyBuilder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  elevation: 0,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.school_outlined,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      "Nenhuma aula ainda",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Você ainda não agendou nenhuma aula. Que tal começar agora?",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: _buscarInstrutores,
                  icon: const Icon(Icons.search),
                  label: const Text("Buscar Instrutores"),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "buscarInstrutores",
        onPressed: _buscarInstrutores,
        icon: const Icon(Iconsax.calendar_add),
        label: const Text("Agendar Aula"),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
