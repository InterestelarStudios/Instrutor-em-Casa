import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:instrutor_em_casa/models/aula.dart';
import 'package:instrutor_em_casa/screens/agendar_aula/widgets/selection_tile.dart';
import 'package:instrutor_em_casa/screens/profile/pdf_viewer_screen.dart';
import 'package:instrutor_em_casa/widgets/theme.dart';

class AgendarAula3 extends StatefulWidget {
  const AgendarAula3({
    super.key,
    required this.onChangedPayment,
    required this.onChangedTerms,
    required this.resumeWidget,
  });

  final Widget resumeWidget;
  final ValueChanged<PaymentType> onChangedPayment;
  final ValueChanged<bool> onChangedTerms;

  @override
  State<AgendarAula3> createState() => _AgendarAula3State();
}

class _AgendarAula3State extends State<AgendarAula3> with AutomaticKeepAliveClientMixin {
  PaymentType? paymentType;
  bool acceptedTerms = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final availableTypes = PaymentType.values.where((t) => t != PaymentType.dinheiro).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        sessionTitle("Resumo e Pagamento"),
        widget.resumeWidget,
        sessionTitle("Método de Pagamento"),
        ListView.builder(
          itemCount: availableTypes.length,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index){
            final type = availableTypes[index];
            return SelectOptionTile(
              value: type,
              groupValue: paymentType,
              label: paymentTypeTranslate(type),
              onChanged: (value){
                setState(() {
                  paymentType = value;
                  widget.onChangedPayment.call(paymentType!);
                });
              }
            );
          }
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Checkbox(
              value: acceptedTerms,
              activeColor: AppColors.primary,
              onChanged: (value) {
                setState(() {
                  acceptedTerms = value ?? false;
                  widget.onChangedTerms.call(acceptedTerms);
                });
              },
            ),
            Expanded(
              child: RichText(
                text: TextSpan(
                  text: "Eu li e concordo com o ",
                  style: Theme.of(context).textTheme.bodySmall,
                  children: [
                    TextSpan(
                      text: "Contrato de Prestação de Serviços",
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PdfViewerScreen(
                                title: "Contrato do Aluno",
                                assetPath: "assets/contrato_aluno.pdf",
                              ),
                            ),
                          );
                        },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  String paymentTypeTranslate(PaymentType type){
    switch (type) {
      case PaymentType.pix:
        return "PIX";
      case PaymentType.credito:
        return "Cartão de Crédito";
      case PaymentType.debito:
        return "Cartão de Débito";
      default:
        return "Dinheiro";
    }
  }

  Widget sessionTitle(String value){
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(value, style: TextTheme.of(context).titleLarge,),
    );
  }
  
  @override
  bool get wantKeepAlive => true;
}