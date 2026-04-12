import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/screens/agendar_aula/agendar_aula_screen.dart';
import 'package:instrutor_em_casa/widgets/avatar.dart';
import 'package:instrutor_em_casa/widgets/theme.dart';

class UserDetailsScreen extends StatefulWidget {
  const UserDetailsScreen({super.key, required this.usuario, required this.myUser});
  final Usuario usuario;
  final Usuario myUser;

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        children: [
          Center(
            child: UserAvatar(
              user: widget.usuario.toDetails(),
              radius: 120,
              borderRadius: 100,
            ),
          ),
          SizedBox(height: 20,),
          Text(
            widget.usuario.name,
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Categoria CNH: "),
              Text(
                widget.usuario.instrutor!.categories.map((e)=> e.name).toList().toString()
                .replaceAll("[", "").replaceAll("]", ""),
                style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w800),
              )
            ],
          ),
          SizedBox(height: 10,),
          Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: AppColors.warning, size: 15,),
                    Text(" 4.9", style: Theme.of(context).textTheme.titleSmall,),
                    Text(" (30) Avaliações", style: Theme.of(context).textTheme.bodySmall,)
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 20,),
          titleDivider("Estatísticas"),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Aulas Realizadas", style: Theme.of(context).textTheme.bodySmall,),
                          SizedBox(height: 10,),
                          Text("160", style: Theme.of(context).textTheme.displayMedium)
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10,),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Horas Ensinadas", style: Theme.of(context).textTheme.bodySmall,),
                          SizedBox(height: 10,),
                          Text("60h", style: Theme.of(context).textTheme.displayMedium)
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar:
      widget.usuario.type == UserType.instrutor &&
      widget.myUser.id != widget.usuario.id ?
      Container(
        height: 50,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: ElevatedButton.icon(
          onPressed: ()=> Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_)=> AgendarAulaScreen(
                usuario: widget.usuario,
                myUser: widget.myUser,
              )
            ),
          ),
          label: Text("Agendar Aula"),
          icon: Icon(Iconsax.calendar_1),
        ),
      ):
      null,
    );
  }

  Widget titleDivider(String text){
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }

}