import 'dart:async';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:instrutor_em_casa/models/aula.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:ionicons/ionicons.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key, required this.aulaId, required this.otherUser});
  final String aulaId;
  final UserDetails otherUser;

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  Set<Marker> _markers = {};
  bool _cameraInitialized = false;
  BitmapDescriptor? _avatarIcon;

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
  }

  Future<void> _loadCustomMarker() async {
    final icon = await _createCircularMarker(widget.otherUser.image);
    setState(() {
      _avatarIcon = icon;
    });
  }

  Future<BitmapDescriptor> _createCircularMarker(String? imageUrl) async {
    const double size = 120.0;
    const double radius = size / 2;
    const double border = 8.0;

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..isAntiAlias = true;

    // Background circle (border)
    paint.color = Colors.blue;
    canvas.drawCircle(const Offset(radius, radius), radius, paint);

    // Inner circle
    final Path path = Path()
      ..addOval(Rect.fromCircle(center: const Offset(radius, radius), radius: radius - border));
    canvas.clipPath(path);

    // Placeholder image (Gray background)
    paint.color = Colors.grey[300]!;
    canvas.drawRect(const Rect.fromLTWH(0, 0, size, size), paint);

    // Draw a default person icon as fallback
    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(Icons.person.codePoint),
      style: TextStyle(
        fontSize: size * 0.7,
        fontFamily: Icons.person.fontFamily,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(radius - textPainter.width / 2, radius - textPainter.height / 2));

    // Finish and convert to bytes
    final ui.Image image = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  void _updateMarkers(Aula aula) {
    if (aula.liveLocation == null || _avatarIcon == null) return;

    final instructorPos = LatLng(
      aula.liveLocation!['latitude'],
      aula.liveLocation!['longitude'],
    );

    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('instructor'),
          position: instructorPos,
          icon: _avatarIcon!,
          infoWindow: InfoWindow(title: widget.otherUser.name),
          rotation: (aula.liveLocation!['heading'] ?? 0).toDouble(),
          anchor: const Offset(0.5, 0.5),
        ),
      };
    });

    if (!_cameraInitialized) {
      _moveCamera(instructorPos, zoom: 16);
      _cameraInitialized = true;
    } else {
      _moveCamera(instructorPos);
    }
  }

  Future<void> _moveCamera(LatLng pos, {double? zoom}) async {
    final controller = await _controller.future;
    if (zoom != null) {
      controller.animateCamera(CameraUpdate.newLatLngZoom(pos, zoom));
    } else {
      controller.animateCamera(CameraUpdate.newLatLng(pos));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Acompanhando ${widget.otherUser.name}"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection("aulas").doc(widget.aulaId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final aula = Aula.fromMap(snapshot.data!.data()!);
          
          if (aula.liveLocation != null) {
             WidgetsBinding.instance.addPostFrameCallback((_) => _updateMarkers(aula));
          }

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: aula.liveLocation != null 
                    ? LatLng(aula.liveLocation!['latitude'], aula.liveLocation!['longitude'])
                    : const LatLng(-23.5505, -46.6333),
                  zoom: 15,
                ),
                markers: _markers,
                myLocationEnabled: false,
                zoomControlsEnabled: false,
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                },
              ),
              if (aula.liveLocation == null)
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)],
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 15),
                        Text("Aguardando sinal do GPS...", textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              PositionDetector(aula: aula),
            ],
          );
        },
      ),
    );
  }
}

class PositionDetector extends StatelessWidget {
  const PositionDetector({super.key, required this.aula});
  final Aula aula;

  @override
  Widget build(BuildContext context) {
    // Busca a sessão que está ativa no trajeto
    final session = aula.sessions.firstWhere(
      (s) => s.journeyState != JourneyState.none && s.end == null, 
      orElse: () => aula.sessions.first
    );
    
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: const [BoxShadow(blurRadius: 15, color: Colors.black12)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[50],
                  child: const Icon(Ionicons.car, color: Colors.blue),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.journeyState == JourneyState.arrived 
                          ? "Instrutor chegou!" 
                          : "Instrutor está a caminho",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        session.journeyState == JourneyState.arrived
                          ? "Você já pode iniciar a aula."
                          : "Acompanhe o trajeto em tempo real.",
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (session.journeyState == JourneyState.arrived)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Fazer Check-in"),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
