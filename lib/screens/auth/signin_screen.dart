import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:instrutor_em_casa/widgets/dialog_services.dart';
import 'package:ionicons/ionicons.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key, required this.onChangedState, required this.onGetUser});
  final ValueChanged onChangedState;
  final ValueChanged<User> onGetUser;

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final formKey = GlobalKey<FormState>();
  final controllerEmail = TextEditingController();
  final controllerPass = TextEditingController();
  bool obscurePass = true;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 40,),
              Text(
                "Bem vindo de volta",
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 20,),
              Text(
                "Estamos felizes em te ver novamente, faça seu login para marcar novas aulas ou buscar por alunos interessados",
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 40,),
              
              TextFormField(
                enabled: !loading,
                controller: controllerEmail,
                decoration: InputDecoration(
                  labelText: "E-mail",
                  prefixIcon: Icon(Ionicons.mailOutline),
                ),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(60)
                ],
                keyboardType: TextInputType.emailAddress,
                validator: (text){
                  return !text!.contains("@") && !text.contains(".") ? "E-mail inválido" : null;
                },
              ),
              const SizedBox(height: 10,),
              TextFormField(
                enabled: !loading,
                controller: controllerPass,
                obscureText: obscurePass,
                decoration: InputDecoration(
                  labelText: "Senha",
                  prefixIcon: Icon(Ionicons.keyOutline),
                  suffixIcon: IconButton(
                    onPressed: ()=> setState(
                      ()=> obscurePass = !obscurePass
                    ),
                    icon: Icon(obscurePass ? Ionicons.eyeOutline : Ionicons.eyeOffOutline)
                  ),
                ),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(60)
                ],
                validator: (text){
                  return text!.length < 6 ? "A senha deve ter no mínimo 6 dígitos" : null;
                },
              ),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: loading ? null : (){
                    FocusScope.of(context).unfocus();
                    if(formKey.currentState!.validate()){
                      setState(() {
                        loading = !loading;
                      });
                      FirebaseAuth.instance.signInWithEmailAndPassword(
                        email: controllerEmail.text.trim(),
                        password: controllerPass.text,
                      ).then((onValue) async {
                        widget.onGetUser.call(onValue.user!);
                      }).catchError((e){
                        setState(() {
                          loading = false;
                          DialogServices.paymentAlert(context, success: false, message: signinErrors(e));
                        });
                      });
                    }
                  },
                  child: loading ? CircularProgressIndicator() : Text("Entrar")
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Não possui conta? "),
                  TextButton(
                    onPressed: loading ? null : ()=> widget.onChangedState.call(null),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.only()
                    ),
                    child: Text("Cadastro")
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  String signinErrors(dynamic e) {
  if (e is! FirebaseAuthException) {
    return "Ocorreu um erro inesperado. Tente novamente.";
  }

  switch (e.code) {
    case 'user-not-found':
      return "E-mail não cadastrado. Verifique os dados ou crie uma conta.";
    case 'wrong-password':
      return "Senha incorreta. Tente novamente ou recupere sua senha.";
    case 'invalid-email':
      return "O formato do e-mail é inválido.";
    case 'user-disabled':
      return "Esta conta foi desativada por um administrador.";
    case 'too-many-requests':
      return "Muitas tentativas falhas. Aguarde um momento e tente novamente.";
    case 'operation-not-allowed':
      return "O login com e-mail e senha não está habilitado no servidor.";
    // Caso o Firebase retorne o erro genérico de segurança:
    case 'invalid-credential':
      return "E-mail ou senha inválidos. Verifique as credenciais.";
    default:
      return "Erro ao realizar login: ${e.message ?? 'Tente novamente.'}";
  }
}
}