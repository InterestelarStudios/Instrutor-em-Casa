import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instrutor_em_casa/screens/auth/signin_screen.dart';
import 'package:instrutor_em_casa/screens/auth/signup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onGetUser});
  final ValueChanged<User> onGetUser;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

enum AuthType {splash, signup, signin}

class _SplashScreenState extends State<SplashScreen> {
  AuthType authType = AuthType.splash;
  double opacity = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedOpacity(
        opacity: opacity,
        duration: const Duration(milliseconds: 500),
        curve: Curves.ease,
        child: Builder(
          builder: (context){
            switch (authType) {
              case AuthType.signup:
                return SignupScreen(
                  onChangedState: (value)=> changeState(AuthType.signin),
                  onGetUser: (user)=> widget.onGetUser.call(user),
                );
              case AuthType.signin:
                return SigninScreen(
                  onChangedState: (value)=> changeState(AuthType.signup),
                  onGetUser: (user)=> widget.onGetUser.call(user),
                );
              default:
                return splash();
            }
          }
        ),
      ),
    );
  }

  void changeState(AuthType type){
    setState(() {
      opacity = 0;
    });
    Future.delayed(const Duration(milliseconds: 500))
    .then((_){
      setState(() {
        authType = type;
        Future.delayed(const Duration(milliseconds: 50)).then((_){
          setState(() {
            opacity = 1;
          });
        });
      });
    });
  }

  Widget splash(){
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40,),
            Text(
              "Bem vindo ao Instrutor em Casa",
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 20,),
            Text(
              "Encontre instrutores verificados perto de você e agende sua aula de direção com segurança e praticidade.",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Expanded(child: SizedBox()),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: ()=> changeState(AuthType.signup),
                child: Text("Criar conta")
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Ou faça seu"),
                TextButton(
                  onPressed: ()=> changeState(AuthType.signin),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.only()
                  ),
                  child: Text("Login")
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

}