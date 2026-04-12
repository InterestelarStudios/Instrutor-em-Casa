import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/screens/auth/instrutor_pick_documents.dart';

class UserTypeSelectScreen extends StatefulWidget {
  const UserTypeSelectScreen({super.key});

  @override
  State<UserTypeSelectScreen> createState() => _UserTypeSelectScreenState();
}

class _UserTypeSelectScreenState extends State<UserTypeSelectScreen> {
  UserType? type;
  double opacity = 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: AnimatedOpacity(
        opacity: opacity,
        duration: const Duration(milliseconds: 500),
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 80,),
                Text(
                  "Como você quer usar o app?",
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 20,),
                Text(
                  "Escolha seu tipo de conta para começarmos a configurar sua experiência.",
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20,),
                Wrap(
                  spacing: 10,
                  children: UserType.values.map((currentType){
                    final name = currentType.name[0].toUpperCase() + currentType.name.substring(1).toLowerCase();
                    return RawChip(
                      selected: type == currentType,
                      onSelected: (value) {
                        setState(() {
                          type = currentType;
                        });
                      },
                      backgroundColor: Colors.white,
                      checkmarkColor: Theme.of(context).primaryColor,
                      label: Text(name)
                    );
                  }).toList(),
                )
              ],
            ),
          ),
          bottomNavigationBar: type == null ? null :
          Container(
            height: 50,
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: FilledButton(
              onPressed: (){
                if(type == UserType.instrutor){
                  showDialog(
                    context: context,
                    useSafeArea: false,
                    builder: (context){
                      return InstrutorPickDocuments();
                    }
                  );
                } else {
                  setState(() {
                    opacity = 0;
                  });
                  Future.delayed(Duration(milliseconds: 600))
                  .then((_){
                    final user = FirebaseAuth.instance.currentUser!;
                    FirebaseFirestore.instance.collection("users").doc(user.uid).update({
                      "type" : type!.name,
                    });
                  });
                }
              },
              child: Text("Prosseguir")
            ),
          ),
        ),
      ),
    );
  }
}