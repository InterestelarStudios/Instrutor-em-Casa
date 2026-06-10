import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:instrutor_em_casa/models/aula.dart';
import 'package:instrutor_em_casa/models/instrutor.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/screens/agendar_aula/steps/step1/agendar_aula_1.dart';
import 'package:instrutor_em_casa/screens/agendar_aula/steps/step2/agendar_aula_2.dart';
import 'package:instrutor_em_casa/screens/agendar_aula/steps/step3/agendar_aula_3.dart';
import 'package:instrutor_em_casa/screens/agendar_aula/widgets/stepper.dart';
import 'package:instrutor_em_casa/services/asaas_service.dart';
import 'package:instrutor_em_casa/widgets/dialog_services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AgendarAulaScreen extends StatefulWidget {
  const AgendarAulaScreen({super.key, required this.usuario, required this.myUser,});
  final Usuario usuario;
  final Usuario myUser;

  @override
  State<AgendarAulaScreen> createState() => _AgendarAulaScreenState();
}

class _AgendarAulaScreenState extends State<AgendarAulaScreen> {
  final pageController = PageController();
  int page = 0;
  CNHCategory? category;
  LessonType? lessonType;
  LessonVehicle? lessonVehicle;
  int? hours;
  int hoursPerSession = 1;
  List<SessaoAula> sessions = [];
  PaymentType? paymentType;
  late Position position;
  bool success = false;
  bool processingPayment = false;

  void getPosition() {
    Geolocator.getCurrentPosition().then((value){
      setState(() {
        position = value;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    getPosition();
  }
  
  @override
  Widget build(BuildContext context) {

    double distance(){
      return Geolocator.distanceBetween(
        widget.usuario.geo!["geopoint"].latitude,
        widget.usuario.geo!["geopoint"].longitude,
        position.latitude,
        position.longitude
      ) / 10000;
    }

    LessonPrice price(){
      final price = LessonPrice(
        amount: 0,
        hourPrice: 0,
        distance: 0,
      );

      if(hours != null){
        // Assuming R$ 60,00 per hour
        price.hourPrice = hours! * 60.0;
        price.amount = price.amount + price.hourPrice;
      }

      if(lessonVehicle != null){
        if(lessonVehicle == LessonVehicle.instrutor){
          price.distance = (distance() < 10 ? 10 : distance().ceilToDouble());
          price.amount = price.amount + price.distance;
        }
      }
      return price;
    }

    bool didPop(){
      if(success){
        return true;
      } else {
        return page <= 0;
      }
    }

    return PopScope(
      canPop: didPop(),
      onPopInvokedWithResult: (didPop, result) {
        if(page > 0){
          pageController.previousPage(duration: Duration(milliseconds: 300), curve: Curves.ease,);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: StepProgressIndicator(
                totalSteps: 3,
                currentStep: page + 1,
              ),
            ),
            Expanded(
              child: PageView(
                controller: pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (value){
                  setState(() {
                    page = value;
                  });
                },
                children: [
                  AgendarAula1(
                    onChangedLessonCategory: (value)=> setState(()=> category = value),
                    onChangedLessonTime: (value)=> setState(()=> hours = value),
                    onChangedLessonType: (value)=> setState(()=> lessonType = value),
                    onChangedLessonVehicle: (value)=> setState(()=> lessonVehicle = value),
                    onChangedHoursPerSession: (value)=> setState(()=> hoursPerSession = value),
                    instrutorCategories: widget.usuario.instrutor?.categories ?? [],
                    usuario: widget.myUser,
                  ),
                  AgendarAula2(
                    hours: hours ?? 1,
                    hoursPerSession: hoursPerSession,
                    onChangedSessions: (value)=> setState(()=> sessions = value),
                  ),
                  AgendarAula3(
                    onChangedPayment: (value)=> setState(()=> paymentType = value),
                    resumeWidget: page < 2 ? const SizedBox():
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            resumeRow(title: "Instrutor", value: widget.usuario.name),
                            resumeRow(title: "Tipo de aula", value: lessonTypeTranslate(lessonType!)),
                            resumeRow(title: "Veículo", value: lessonVehicleTranslate(lessonVehicle!)),
                            resumeRow(title: "Total de Horas", value: "$hours h"),
                            const SizedBox(height: 10),
                            const Divider(),
                            const SizedBox(height: 10),
                            Text("Cronograma de Aulas:", style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 10),
                            ...sessions.map((s) => Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${DateFormat('dd/MM').format(s.date.toDate())} às ${DateFormat('HH:mm').format(s.date.toDate())}",
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Text("${s.duration}h", style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                            )),
                            const SizedBox(height: 10),
                            const Divider(),
                            const SizedBox(height: 10),
                            Text(
                              NumberFormat.currency(symbol: "R\$", locale: "pt_BR").format(price().amount),
                              textAlign: TextAlign.right,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
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
        bottomNavigationBar: !next() ? null :
        Container(
          height: 50,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: ElevatedButton(
            onPressed: processingPayment ? null : () async {
              if(page < 2){
                pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.ease,
                );
              } else {
                processPaymentAndBook(price());
              }
            },
            child: processingPayment ? const CircularProgressIndicator() : Text("Próximo")
          ),
        ),
      ),
    );
  }

  Future<void> processPaymentAndBook(LessonPrice price) async {
    setState(() => processingPayment = true);
    DialogServices.loading2(context);

    try {
      // 1. Verificar/Criar Cliente no Asaas
      String? customerId = widget.myUser.asaasId;
      if (paymentType != PaymentType.dinheiro && customerId == null) {
        customerId = await AsaasService.createCustomer(widget.myUser);
        if (customerId == null) throw "Erro ao criar cliente no Asaas";
        await FirebaseFirestore.instance.collection("users").doc(widget.myUser.id).update({
          "asaasId": customerId,
        });
      }

      // 2. Preparar Aula
      final firestore = FirebaseFirestore.instance.collection("aulas").doc();
      final aula = Aula(
        id: firestore.id,
        aluno: widget.myUser.toDetails(),
        instrutor: widget.usuario.toDetails(),
        category: category!,
        status: LessonStatus.accepted,
        date: sessions.first.date,
        created: Timestamp.now(),
        horasContratadas: hours!,
        horasRestantes: hours!,
        sessions: sessions,
        type: lessonType!,
        vehicle: lessonVehicle!,
        price: price,
        paymentType: paymentType!,
      );

      // 3. Processar Pagamento conforme tipo
      if (paymentType == PaymentType.pix) {
        final payment = await AsaasService.createPayment(
          aula: aula,
          customerId: customerId!,
          walletId: widget.usuario.walletId!,
          billingType: 'PIX',
        );

        if (payment == null) throw "Erro ao gerar PIX";

        Navigator.pop(context); // Fecha loading
        await showPixDialog(payment['invoiceUrl'], payment['id']);
      } else if (paymentType == PaymentType.debito) {
        final payment = await AsaasService.createPayment(
          aula: aula,
          customerId: customerId!,
          walletId: widget.usuario.walletId!,
          billingType: 'UNDEFINED', // Deixa o cliente escolher no checkout
        );

        if (payment == null) throw "Erro ao gerar cobrança";

        Navigator.pop(context); // Fecha loading
        await launchUrl(Uri.parse(payment['invoiceUrl']));
      } else if (paymentType == PaymentType.credito) {
        // Aqui você solicitaria os dados do cartão em um diálogo
        // Para este exemplo, vamos simular que os dados foram coletados
        Navigator.pop(context);
        DialogServices().alertDialog(context, "Funcionalidade de Cartão de Crédito Direto requer coleta de dados segura (PCI). Redirecionando para checkout seguro Asaas.");
        
        final payment = await AsaasService.createPayment(
          aula: aula,
          customerId: customerId!,
          walletId: widget.usuario.walletId!,
          billingType: 'CREDIT_CARD',
        );
        if (payment == null) throw "Erro ao gerar cobrança";
        await launchUrl(Uri.parse(payment['invoiceUrl']));
      } else if (paymentType == PaymentType.dinheiro) {
        Navigator.pop(context); // Fecha loading
      }

      // 4. Salvar Aula no Firestore
      await firestore.set(aula.toMap());

      setState(() {
        success = true;
        processingPayment = false;
      });

      final navigator = Navigator.of(context);
      navigator.popUntil((route) => route.isFirst);
      
      DialogServices.paymentAlert(
        navigator.context,
        success: true,
        message: "Proposta enviada, fique atento para a resposta do instrutor!"
      );

    } catch (e) {
      setState(() => processingPayment = false);
      Navigator.pop(context); // Fecha loading
      DialogServices().alertDialog(context, "Erro no pagamento: $e");
    }
  }

  Future<void> showPixDialog(String invoiceUrl, String paymentId) async {
    // Nota: Para obter o código PIX copia e cola e o QR Code real, 
    // você precisaria chamar GET /v3/payments/{id}/pixQrCode
    // Aqui vamos simplificar mostrando o link da fatura ou um placeholder.
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Pagamento PIX"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Escaneie o QR Code ou use o link abaixo para pagar:"),
            const SizedBox(height: 20),
            QrImageView(
              data: invoiceUrl,
              version: QrVersions.auto,
              size: 200.0,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: invoiceUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Link copiado!")),
                );
              },
              child: const Text("Copiar Link de Pagamento"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Já paguei"),
          ),
        ],
      ),
    );
  }

  bool next(){
    if(page == 0){
      if(category != null && hours != null && lessonType != null && lessonVehicle != null){
        return true;
      } else {
        return false;
      }
    } else if(page == 1){
      if(sessions.isNotEmpty && sessions.every((s) => s.date.toDate().year > 2000)){
        return true;
      } else {
        return false;
      }
    } else if(page == 2){
      if(paymentType != null){
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  Widget resumeRow({required String title, required String value}){
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: Theme.of(context).textTheme.titleMedium)
        ],
      ),
    );
  }
}
