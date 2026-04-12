import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/screens/aluno_screens/aluno_base_screen.dart';
import 'package:instrutor_em_casa/screens/auth/location_instrutor_select.dart';
import 'package:instrutor_em_casa/screens/auth/splash_screen.dart';
import 'package:instrutor_em_casa/screens/auth/usertype_select_scren.dart';
import 'package:instrutor_em_casa/screens/instrutor_screens/instrutor_base_screen.dart';

class BaseScreen extends StatefulWidget {
  const BaseScreen({super.key});

  @override
  State<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  late User? user;
  Stream<DocumentSnapshot<Usuario>>? streamUser;

  void addListenersUser(){
    streamUser = FirebaseFirestore.instance.collection("users").doc(user!.uid)
    .withConverter(
      fromFirestore: (snapshot, options)=> Usuario.fromMap(snapshot.data()!),
      toFirestore: (snapshot, options)=> {}
    )
    .snapshots();
  }


  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    if(user != null){
      addListenersUser();
    }
  }

  @override
  Widget build(BuildContext context) {

    if(user == null){
      return SplashScreen(
        onGetUser: (value){
          setState(() {
            user = value;
            addListenersUser();
          });
        }
      );
    }

    return StreamBuilder(
      stream: streamUser,
      builder: (context, snapshot){
        if(snapshot.connectionState == ConnectionState.waiting){
          return Scaffold(
            body: const Center(child: CircularProgressIndicator(),),
          );
        }

        final usuario = snapshot.data!.data();

        if(usuario!.type == null){
          return UserTypeSelectScreen();
        }

        if(usuario.type == UserType.aluno){
          return AlunoBaseScreen(usuario: usuario);
        } else {

          if(usuario.geo == null){
            return InstrutorLocationPicker();
          }

          return InstrutorBaseScreen(usuario: usuario);
        }
        
      }
    );
  }
}