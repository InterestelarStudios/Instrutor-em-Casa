import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:instrutor_em_casa/firebase_options.dart';
import 'package:instrutor_em_casa/screens/base_screen.dart';
import 'package:instrutor_em_casa/services/background_location_service.dart';
import 'package:instrutor_em_casa/services/notification_service.dart';
import 'package:instrutor_em_casa/widgets/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await BackgroundLocationService.initializeService();
  await NotificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      
      theme: AppThemeData.light,
      locale: Locale("pt", "BR"),
      home: const BaseScreen(),
    );
  }
}