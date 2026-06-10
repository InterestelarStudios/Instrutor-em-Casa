import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:instrutor_em_casa/widgets/theme.dart';
import 'package:ionicons/ionicons.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key, required this.onPermissionsGranted});
  final VoidCallback onPermissionsGranted;

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool locationGranted = false;
  bool cameraGranted = false;
  bool storageGranted = false;
  bool notificationGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final locationStatus = await Permission.location.status;
    final cameraStatus = await Permission.camera.status;
    final notificationStatus = await Permission.notification.status;
    
    bool isStorageGranted = false;
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        // Android 13+ uses more granular permissions
        isStorageGranted = await Permission.photos.isGranted;
      } else {
        isStorageGranted = await Permission.storage.isGranted;
      }
    } else {
      isStorageGranted = await Permission.storage.isGranted;
    }

    setState(() {
      locationGranted = locationStatus.isGranted;
      cameraGranted = cameraStatus.isGranted;
      storageGranted = isStorageGranted;
      notificationGranted = notificationStatus.isGranted;
    });

    if (locationGranted && cameraGranted && storageGranted && notificationGranted) {
      widget.onPermissionsGranted();
    }
  }

  Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        final status = await Permission.photos.request();
        if (status.isPermanentlyDenied) openAppSettings();
      } else {
        final status = await Permission.storage.request();
        if (status.isPermanentlyDenied) openAppSettings();
      }
    } else {
      final status = await Permission.storage.request();
      if (status.isPermanentlyDenied) openAppSettings();
    }
    _checkPermissions();
  }

  Future<void> _requestPermission(Permission permission) async {
    final status = await permission.request();
    if (status.isPermanentlyDenied) {
      openAppSettings();
    }
    _checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Text(
                "Permissões Necessárias",
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 15),
              Text(
                "Para garantir a melhor experiência e segurança, precisamos de algumas permissões do seu dispositivo.",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),
              _permissionTile(
                icon: Ionicons.location_outline,
                title: "Localização",
                description: "Para encontrar instrutores próximos e rastrear o trajeto das aulas.",
                isGranted: locationGranted,
                onTap: () => _requestPermission(Permission.location),
              ),
              const SizedBox(height: 20),
              _permissionTile(
                icon: Ionicons.camera_outline,
                title: "Câmera",
                description: "Para realizar o check-in via QR Code e tirar fotos dos documentos.",
                isGranted: cameraGranted,
                onTap: () => _requestPermission(Permission.camera),
              ),
              const SizedBox(height: 20),
              _permissionTile(
                icon: Ionicons.folder_open_outline,
                title: "Arquivos e Mídia",
                description: "Para selecionar documentos da sua galeria.",
                isGranted: storageGranted,
                onTap: _requestStoragePermission,
              ),
              const SizedBox(height: 20),
              _permissionTile(
                icon: Ionicons.notifications_outline,
                title: "Notificações",
                description: "Para acompanhar o trajeto da aula em tempo real.",
                isGranted: notificationGranted,
                onTap: () => _requestPermission(Permission.notification),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: (locationGranted && cameraGranted && storageGranted && notificationGranted) 
                  ? widget.onPermissionsGranted 
                  : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  backgroundColor: AppColors.primary,
                ),
                child: const Text("Continuar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _permissionTile({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: isGranted ? AppColors.success : Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isGranted ? AppColors.success : AppColors.primary).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: isGranted ? AppColors.success : AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description, style: const TextStyle(fontSize: 12)),
        trailing: isGranted 
          ? const Icon(Ionicons.checkmark_circle, color: AppColors.success)
          : TextButton(onPressed: onTap, child: const Text("Permitir")),
      ),
    );
  }
}
