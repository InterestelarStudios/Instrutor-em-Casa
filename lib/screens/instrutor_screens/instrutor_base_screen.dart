import 'package:bottom_bar/bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iconsax/iconsax.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/screens/chat/conversas_screen.dart';
import 'package:instrutor_em_casa/screens/instrutor_screens/home/home_screen_instrutor.dart';
import 'package:instrutor_em_casa/screens/instrutor_screens/ganhos_screen.dart';
import 'package:instrutor_em_casa/screens/profile/notifications_screen.dart';
import 'package:instrutor_em_casa/screens/profile/profile_screen.dart';
import 'package:instrutor_em_casa/widgets/loading_box.dart';
import 'package:ionicons/ionicons.dart';

class InstrutorBaseScreen extends StatefulWidget {
  const InstrutorBaseScreen({super.key, required this.usuario});
  final Usuario usuario;

  @override
  State<InstrutorBaseScreen> createState() => _InstrutorBaseScreenState();
}

class _InstrutorBaseScreenState extends State<InstrutorBaseScreen> {
  int page = 0;
  Position? position;
  String? locale;
  final pageController = PageController();
  bool loadingLocation = true;
  double opacity = 0;

  void obterEnderecoAtual() async {
    try {
      // 1. Verifica se o serviço de localização (GPS) está ligado
      final servicoAtivo = await Geolocator.isLocationServiceEnabled();
      if (!servicoAtivo) return;

      // 2. Verifica e solicita permissão
      LocationPermission permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
        if (permissao == LocationPermission.denied) return;
      }

      if (permissao == LocationPermission.deniedForever) return;

      // 3. Pega a posição atual (Latitude e Longitude)
      position = await Geolocator.getCurrentPosition();

      if (position != null) {
        // 4. Geocoding: Transforma coordenadas em endereço
        List<Placemark> locais = await placemarkFromCoordinates(
          position!.latitude,
          position!.longitude,
        );

        if (locais.isNotEmpty) {
          Placemark place = locais[0];
          final subAdmin = place.subAdministrativeArea ?? place.locality ?? '';
          final admin = place.administrativeArea ?? '';
          if (subAdmin.isNotEmpty && admin.isNotEmpty) {
            locale = "$subAdmin - $admin";
          } else if (subAdmin.isNotEmpty) {
            locale = subAdmin;
          } else if (admin.isNotEmpty) {
            locale = admin;
          }
        }
      }
    } catch (e) {
      debugPrint("Erro ao obter endereço do instrutor: $e");
    } finally {
      if (mounted) {
        setState(() {
          loadingLocation = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    obterEnderecoAtual();
    Future.delayed(const Duration(milliseconds: 50)).then((_){
      setState(() {
        opacity = 1;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Container(
      color: Colors.white,
      child: AnimatedOpacity(
        opacity: opacity,
        duration: const Duration(milliseconds: 500),
        child: Scaffold(
          appBar: AppBar(
            centerTitle: false,
            title: loadingLocation ?
            LoadingBox(height: 30, width: 250) :
            locale == null ? null : Row(
              children: [
                Icon(Icons.location_on, color: Theme.of(context).primaryColor, size: 20,),
                SizedBox(width: 5,),
                Text(
                  locale!,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            actions: [
              SizedBox(
                height: 50,
                width: 50,
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => NotificationsScreen(usuario: widget.usuario),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          const begin = Offset(1.0, 0.0);
                          const end = Offset.zero;
                          const curve = Curves.ease;
                          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                          return SlideTransition(
                            position: animation.drive(tween),
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                  backgroundColor: Colors.grey[200],
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(20)
                  ),
                  child: widget.usuario.notificationsCount > 0 
                    ? Badge.count(
                        count: widget.usuario.notificationsCount,
                        child: Icon(Iconsax.notification, color: Colors.grey[800],),
                      )
                    : Icon(Iconsax.notification, color: Colors.grey[800],),
                ),
              ),
              const SizedBox(width: 20,),
            ],
          ),
          body: PageView(
            controller: pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              HomeScreenInstrutor(usuario: widget.usuario),
              GanhosScreen(usuario: widget.usuario),
              ConversasScreen(usuario: widget.usuario,),
              ProfileScreen(usuario: widget.usuario),
            ],
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 2,
                color: Colors.grey[100],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
                child: BottomBar(
                  selectedIndex: page,
                  onTap: (value){
                    setState(() {
                      page = value;
                      pageController.animateToPage(page, duration: Duration(milliseconds: 300), curve: Curves.ease);
                    });
                  },
                  items: [
                    BottomBarItem(
                      icon: Icon(Iconsax.home),
                      activeColor: primary,
                      title: Text("Home"),
                    ),
                    BottomBarItem(
                      icon: Icon(Icons.monetization_on_outlined),
                      activeColor: primary,
                      title: Text("Ganhos"),
                    ),
                    BottomBarItem(
                      icon: Icon(Ionicons.chatbox_outline),
                      activeColor: primary,
                      title: Text("Chat"),
                    ),
                    BottomBarItem(
                      icon: Icon(Iconsax.profile_circle),
                      activeColor: primary,
                      title: Text("Perfil"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
