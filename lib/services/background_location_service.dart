import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:instrutor_em_casa/firebase_options.dart';

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  String? currentLessonId;
  StreamSubscription<Position>? positionSubscription;

  service.on('startTracking').listen((event) {
    currentLessonId = event?['lessonId'];
    
    // Cancela subscrição anterior se existir
    positionSubscription?.cancel();

    if (currentLessonId != null) {
      // Inicia stream de localização para atualizações em tempo real
      positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5, // Atualiza a cada 5 metros de movimento
        ),
      ).listen((Position position) async {
        if (currentLessonId == null) return;

        try {
          await FirebaseFirestore.instance.collection("aulas").doc(currentLessonId).update({
            "liveLocation": {
              "latitude": position.latitude,
              "longitude": position.longitude,
              "timestamp": Timestamp.now(),
              "heading": position.heading,
              "speed": position.speed,
            }
          });
        } catch (e) {
          // ignore
        }
      });
    }
  });

  service.on('stopTracking').listen((event) {
    currentLessonId = null;
    positionSubscription?.cancel();
    service.stopSelf();
  });
}

@pragma('vm:entry-point')
class BackgroundLocationService {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'my_foreground',
        initialNotificationTitle: 'Rastreamento de Aula',
        initialNotificationContent: 'Compartilhando sua localização com o aluno',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }
}
