import 'package:flutter/material.dart';
import 'package:instrutor_em_casa/models/aula.dart';
import 'package:instrutor_em_casa/screens/agendar_aula/widgets/selection_tile.dart';

class AgendarAula3 extends StatefulWidget {
  const AgendarAula3({
    super.key,
    required this.onChangedPayment,
    required this.resumeWidget,
  });

  final Widget resumeWidget;
  final ValueChanged<PaymentType> onChangedPayment;

  @override
  State<AgendarAula3> createState() => _AgendarAula3State();
}

class _AgendarAula3State extends State<AgendarAula3> with AutomaticKeepAliveClientMixin {
  PaymentType? paymentType;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        sessionTitle("Resumo e Pagamento"),
        widget.resumeWidget,
        sessionTitle("Método de Pagamento"),
        ListView.builder(
          itemCount: PaymentType.values.length,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index){
            final type = PaymentType.values[index];
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
      ],
    );
  }

  String paymentTypeTranslate(PaymentType type){
    switch (type) {
      case PaymentType.pix:
        return "PIX";
      case PaymentType.cartao:
        return "Cartão de Crédito/Débito";
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