import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/widgets/theme.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.radius = 60, this.borderRadius = 15});
  final UserDetails? user;
  final double radius;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: radius,
      width: radius,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        image: user!.image == null ? null :
          DecorationImage(
            image: CachedNetworkImageProvider(user!.image!),
            fit: BoxFit.cover
          ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary400,
            AppColors.secondary400
          ]
        ),
      ),
      child: user!.image != null ? null :
      Center(
        child: Text(
          user!.name[0].toUpperCase(),
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        )
      ),
    );
  }
}