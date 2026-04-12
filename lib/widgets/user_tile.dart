import 'package:flutter/material.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/widgets/avatar.dart';
import 'package:instrutor_em_casa/widgets/stars.dart';

class UserTile extends StatelessWidget {
  const UserTile({super.key, required this.user});
  final UserDetails user;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 0),
      leading: UserAvatar(user: user),
      title: Text(user.name, style: Theme.of(context).textTheme.titleLarge,),
      subtitle: Row(
        children: [
          StarRating(stars: 4.2, size: 15,).build(context),
          const SizedBox(width: 10,),
          Text("4.2", style: Theme.of(context).textTheme.titleSmall,),
          const SizedBox(width: 5,),
          Text("(8 aulas)", style: Theme.of(context).textTheme.bodySmall,),
        ],
      ),
    );
  }
}