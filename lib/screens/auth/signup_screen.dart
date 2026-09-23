import 'package:brasil_fields/brasil_fields.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/widgets/dialog_services.dart';
import 'package:ionicons/ionicons.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({
    super.key,
    required this.onChangedState,
    required this.onGetUser,
  });
  final ValueChanged onChangedState;
  final ValueChanged<User> onGetUser;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final formKey = GlobalKey<FormState>();
  final controllerName = TextEditingController();
  final controllerBirth = TextEditingController();
  final controllerCPF = TextEditingController();
  final controllerPhone = TextEditingController();
  final controllerCEP = TextEditingController();
  final controllerEmail = TextEditingController();
  final controllerPass = TextEditingController();
  bool obscurePass = true;
  bool loading = false;
  UserGenre? genre;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 40),
              Text(
                "Criar conta",
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 20),
              Text(
                "Crie sua conta para começar suas atividades no Instrutor em Casa Brasil.",
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 40),
              TextFormField(
                enabled: !loading,
                controller: controllerName,
                decoration: InputDecoration(
                  labelText: "Nome de Usuário",
                  prefixIcon: Icon(Ionicons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                inputFormatters: [LengthLimitingTextInputFormatter(60)],
                keyboardType: TextInputType.name,
                validator: (text) {
                  return text!.length < 10 ? "Nome muito curto" : null;
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<UserGenre>(
                items: UserGenre.values.map((e) {
                  final genre =
                      e.name[0].toUpperCase() +
                      e.name.substring(1).toLowerCase();
                  return DropdownMenuItem<UserGenre>(
                    value: e,
                    child: Text(genre),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    genre = value;
                  });
                },
                decoration: InputDecoration(
                  prefixIcon: Icon(Ionicons.male_female_outline),
                  labelText: "Gênero",
                ),
                validator: (value) =>
                    genre == null ? "Selecione seu gênero" : null,
                isExpanded: true,
                borderRadius: BorderRadius.circular(20),
              ),
              const SizedBox(height: 10),
              TextFormField(
                enabled: !loading,
                controller: controllerBirth,
                decoration: InputDecoration(
                  labelText: "Data de nascimento",
                  prefixIcon: Icon(Iconsax.cake),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  DataInputFormatter(),
                ],
                keyboardType: TextInputType.number,
                validator: (text) => validateBirthDate(text),
              ),
              const SizedBox(height: 10),
              TextFormField(
                enabled: !loading,
                controller: controllerCEP,
                decoration: InputDecoration(
                  labelText: "CEP (Obrigatório)",
                  prefixIcon: Icon(Ionicons.location_outline),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CepInputFormatter(),
                ],
                keyboardType: TextInputType.number,
                validator: (text) {
                  return text!.length < 10 ? "CEP inválido" : null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                enabled: !loading,
                controller: controllerCPF,
                decoration: InputDecoration(
                  labelText: "CPF",
                  prefixIcon: Icon(Ionicons.id_card_outline),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CpfInputFormatter(),
                ],
                keyboardType: TextInputType.number,
                validator: (text) => validateCPF(text),
              ),
              const SizedBox(height: 10),
              TextFormField(
                enabled: !loading,
                controller: controllerPhone,
                decoration: InputDecoration(
                  labelText: "Telefone",
                  prefixIcon: Icon(Ionicons.call_outline),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  TelefoneInputFormatter(),
                ],
                keyboardType: TextInputType.number,
                validator: (text) {
                  return text!.length < 15 ? "Telefone inválido" : null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                enabled: !loading,
                controller: controllerEmail,
                decoration: InputDecoration(
                  labelText: "E-mail",
                  prefixIcon: Icon(Ionicons.mail_outline),
                ),
                inputFormatters: [LengthLimitingTextInputFormatter(60)],
                keyboardType: TextInputType.emailAddress,
                validator: (text) {
                  return !text!.contains("@") && !text.contains(".")
                      ? "E-mail inválido"
                      : null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                enabled: !loading,
                controller: controllerPass,
                obscureText: obscurePass,
                decoration: InputDecoration(
                  labelText: "Senha",
                  prefixIcon: Icon(Ionicons.key_outline),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => obscurePass = !obscurePass),
                    icon: Icon(
                      obscurePass
                          ? Ionicons.eye_outline
                          : Ionicons.eye_off_outline,
                    ),
                  ),
                ),
                inputFormatters: [LengthLimitingTextInputFormatter(60)],
                validator: (text) {
                  return text!.length < 6
                      ? "A senha deve ter no mínimo 6 dígitos"
                      : null;
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
                  onPressed: loading
                      ? null
                      : () {
                          FocusScope.of(context).unfocus();
                          if (formKey.currentState!.validate()) {
                            setState(() {
                              loading = !loading;
                            });
                            final birthParts = controllerBirth.text.split("/");
                            final usuario = Usuario(
                              id: "",
                              name: controllerName.text.trim(),
                              data: UserData(
                                birth: Timestamp.fromDate(
                                  DateTime(
                                    int.parse(birthParts.last),
                                    int.parse(birthParts[1]),
                                    int.parse(birthParts.first),
                                  ),
                                ),
                                cpf: controllerCPF.text.replaceAll(
                                  RegExp(r'[^0-9]'),
                                  '',
                                ),
                                phone: controllerPhone.text.replaceAll(
                                  RegExp(r'[^0-9]'),
                                  '',
                                ),
                                postalCode: controllerCEP.text.replaceAll(
                                  RegExp(r'[^0-9]'),
                                  '',
                                ),
                                genre: genre!,
                              ),
                              created: Timestamp.now(),
                              email: controllerEmail.text.trim(),
                            );
                            FirebaseAuth.instance
                                .createUserWithEmailAndPassword(
                                  email: usuario.email,
                                  password: controllerPass.text,
                                )
                                .then((onValue) async {
                                  final userid = onValue.user!.uid;
                                  usuario.id = userid;
                                  await FirebaseFirestore.instance
                                      .collection("users")
                                      .doc(userid)
                                      .set(usuario.toMap());
                                  widget.onGetUser.call(onValue.user!);
                                })
                                .catchError((e) {
                                  setState(() {
                                    loading = false;
                                    DialogServices.paymentAlert(
                                      context,
                                      success: false,
                                      message: authErrors(e),
                                    );
                                  });
                                });
                          }
                        },
                  child: loading
                      ? CircularProgressIndicator()
                      : Text("Criar conta"),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Já possui conta?"),
                  TextButton(
                    onPressed: loading
                        ? null
                        : () => widget.onChangedState.call(null),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.only(),
                    ),
                    child: Text("Login"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String authErrors(dynamic e) {
    if (e is! FirebaseAuthException) {
      return "Ocorreu um erro inesperado. Tente novamente.";
    }

    switch (e.code) {
      case 'email-already-in-use':
        return "Este e-mail já está sendo utilizado por outra conta.";
      case 'invalid-email':
        return "O formato do e-mail inserido é inválido.";
      case 'operation-not-allowed':
        return "O cadastro por e-mail e senha não está habilitado.";
      case 'weak-password':
        return "A senha escolhida é muito fraca. Tente uma senha mais complexa.";
      case 'network-request-failed':
        return "Falha na conexão de rede. Verifique sua internet.";
      case 'user-disabled':
        return "Este usuário foi desativado.";
      case 'too-many-requests':
        return "Muitas solicitações em pouco tempo. Tente novamente mais tarde.";
      default:
        return "Erro no servidor: ${e.message ?? 'Tente novamente.'}";
    }
  }

  String? validateBirthDate(String? text) {
    if (text == null || text.length < 10) {
      return "Data inválida";
    }

    try {
      final parts = text.split("/");
      final birthYear = int.parse(parts.last);
      if (Timestamp.now().toDate().year - birthYear < 18) {
        return "Você precisa ter 18 anos para se cadastrar.";
      }
    } catch (e) {
      return "Data inválida";
    }

    return null;
  }

  String? validateCPF(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, informe o CPF';
    }

    // Remove qualquer caractere que não seja número
    final cpf = value.replaceAll(RegExp(r'\D'), '');

    // Verifica se tem 11 dígitos ou se é uma sequência repetida comum
    if (cpf.length != 11 || RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) {
      return 'CPF inválido';
    }

    // Validação do primeiro dígito verificador
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(cpf[i]) * (10 - i);
    }
    int firstDigit = (sum * 10) % 11;
    if (firstDigit == 10 || firstDigit == 11) firstDigit = 0;

    if (firstDigit != int.parse(cpf[9])) {
      return 'CPF inválido';
    }

    // Validação do segundo dígito verificador
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(cpf[i]) * (11 - i);
    }
    int secondDigit = (sum * 10) % 11;
    if (secondDigit == 10 || secondDigit == 11) secondDigit = 0;

    if (secondDigit != int.parse(cpf[10])) {
      return 'CPF inválido';
    }

    return null; // Retorna null se o CPF for válido
  }
}
