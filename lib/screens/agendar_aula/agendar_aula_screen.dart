import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:instrutor_em_casa/models/aula.dart';
import 'package:instrutor_em_casa/models/instrutor.dart';
import 'package:instrutor_em_casa/models/precos_config.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/services/precos_service.dart';
import 'package:instrutor_em_casa/screens/agendar_aula/steps/step1/agendar_aula_1.dart';
import 'package:instrutor_em_casa/screens/agendar_aula/steps/step2/agendar_aula_2.dart';
import 'package:instrutor_em_casa/screens/agendar_aula/steps/step3/agendar_aula_3.dart';
import 'package:instrutor_em_casa/screens/agendar_aula/widgets/stepper.dart';
import 'package:instrutor_em_casa/services/asaas_service.dart';
import 'package:instrutor_em_casa/widgets/dialog_services.dart';
import 'package:instrutor_em_casa/widgets/theme.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AgendarAulaScreen extends StatefulWidget {
  const AgendarAulaScreen({
    super.key,
    required this.usuario,
    required this.myUser,
  });
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
  bool acceptedTerms = false;
  PrecosConfig precosConfig = const PrecosConfig();

  void getPosition() {
    Geolocator.getCurrentPosition().then((value) {
      setState(() {
        position = value;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    getPosition();
    _loadPrecos();
  }

  Future<void> _loadPrecos() async {
    final config = await PrecosService.getPrecos();
    if (mounted) {
      setState(() {
        precosConfig = config;
      });
    }
  }

  LessonPrice price() {
    final price = LessonPrice(amount: 0, hourPrice: 0, distance: 0);

    if (hours != null && category != null) {
      double rate = precosConfig.getPriceForCategory(category!);
      price.hourPrice = (hours ?? 0) * rate;
      price.distance = precosConfig.taxaDeslocamento;
      price.amount = price.hourPrice + price.distance;
    }
    return price;
  }

  @override
  Widget build(BuildContext context) {
    bool didPop() {
      if (success) {
        return true;
      } else {
        return page <= 0;
      }
    }

    return PopScope(
      canPop: didPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (page > 0) {
          pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.ease,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(),
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
                onPageChanged: (value) {
                  setState(() {
                    page = value;
                  });
                },
                children: [
                  AgendarAula1(
                    onChangedLessonCategory: (value) =>
                        setState(() => category = value),
                    onChangedLessonTime: (value) =>
                        setState(() => hours = value),
                    onChangedLessonType: (value) =>
                        setState(() => lessonType = value),
                    onChangedLessonVehicle: (value) =>
                        setState(() => lessonVehicle = value),
                    onChangedHoursPerSession: (value) =>
                        setState(() => hoursPerSession = value),
                    instrutorCategories:
                        widget.usuario.instrutor?.categories ?? [],
                    usuario: widget.myUser,
                    defaultVehicle: widget.usuario.instrutor?.defaultVehicle,
                    precosConfig: precosConfig,
                  ),
                  AgendarAula2(
                    hours: hours ?? 1,
                    hoursPerSession: hoursPerSession,
                    onChangedSessions: (value) =>
                        setState(() => sessions = value),
                    alunoId: widget.myUser.id,
                    instrutorId: widget.usuario.id,
                  ),
                  AgendarAula3(
                    onChangedPayment: (value) =>
                        setState(() => paymentType = value),
                    onChangedTerms: (value) =>
                        setState(() => acceptedTerms = value),
                    resumeWidget: page < 2
                        ? const SizedBox()
                        : Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  resumeRow(
                                    title: "Instrutor",
                                    value: widget.usuario.name,
                                  ),
                                  resumeRow(
                                    title: "Tipo de aula",
                                    value: lessonTypeTranslate(lessonType!),
                                  ),
                                  resumeRow(
                                    title: "Veículo",
                                    value: lessonVehicleTranslate(
                                      lessonVehicle!,
                                    ),
                                  ),
                                  if (lessonVehicle ==
                                          LessonVehicle.instrutor &&
                                      widget
                                              .usuario
                                              .instrutor
                                              ?.defaultVehicle !=
                                          null) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 12,
                                        bottom: 8,
                                      ),
                                      child: Text(
                                        "(${widget.usuario.instrutor!.defaultVehicle!.brand} ${widget.usuario.instrutor!.defaultVehicle!.model} - ${widget.usuario.instrutor!.defaultVehicle!.color})",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textMuted,
                                            ),
                                      ),
                                    ),
                                  ],
                                  resumeRow(
                                    title: "Total de Horas",
                                    value: "$hours h",
                                  ),
                                  const SizedBox(height: 10),
                                  const Divider(),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Cronograma de Aulas:",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 10),
                                  ...sessions.map(
                                    (s) => Padding(
                                      padding: const EdgeInsets.only(bottom: 5),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "${DateFormat('dd/MM').format(s.date.toDate())} às ${DateFormat('HH:mm').format(s.date.toDate())}",
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                          Text(
                                            "${s.duration}h",
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Divider(),
                                  const SizedBox(height: 6),
                                  resumeRow(
                                    title: "Subtotal Aulas ($hours h)",
                                    value: NumberFormat.currency(
                                      symbol: "R\$",
                                      locale: "pt_BR",
                                    ).format(price().hourPrice),
                                  ),
                                  resumeRow(
                                    title: "Taxa de Deslocamento",
                                    value: NumberFormat.currency(
                                      symbol: "R\$",
                                      locale: "pt_BR",
                                    ).format(price().distance),
                                  ),
                                  const SizedBox(height: 6),
                                  const Divider(),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Total",
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        NumberFormat.currency(
                                          symbol: "R\$",
                                          locale: "pt_BR",
                                        ).format(price().amount),
                                        textAlign: TextAlign.right,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
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
        bottomNavigationBar: !next()
            ? null
            : Container(
                height: 50,
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: ElevatedButton(
                  onPressed: processingPayment
                      ? null
                      : () async {
                          if (page < 2) {
                            pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.ease,
                            );
                          } else {
                            _showContractPointsDialog();
                          }
                        },
                  child: processingPayment
                      ? const CircularProgressIndicator()
                      : Text(page < 2 ? "Próximo" : "Confirmar e Pagar"),
                ),
              ),
      ),
    );
  }

  void _showContractPointsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Resumo do Contrato"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Ao prosseguir, você confirma que está ciente dos seguintes pontos:",
              ),
              const SizedBox(height: 15),
              _pointItem(
                "Intermediação: A plataforma apenas conecta você a instrutores autônomos.",
              ),
              _pointItem(
                "Pagamentos: Devem ser feitos exclusivamente pelo app. Proibido pagar direto ao instrutor.",
              ),
              _pointItem(
                "Cancelamento: Reembolso parcial ou retenção dependendo da antecedência.",
              ),
              _pointItem(
                "Tolerância: Atrasos de no máximo 5 minutos por sessão.",
              ),
              _pointItem(
                "Documentação: Você deve portar sua Certidão Teórica ou CNH física durante as aulas.",
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Revisar"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              processPaymentAndBook(price());
            },
            child: const Text("Li e Concordo"),
          ),
        ],
      ),
    );
  }

  Widget _pointItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Future<void> processPaymentAndBook(LessonPrice price) async {
    setState(() => processingPayment = true);
    DialogServices.loading2(context);

    try {
      // 1. Preparar Aula
      final firestore = FirebaseFirestore.instance.collection("aulas").doc();
      final aula = Aula(
        id: firestore.id,
        aluno: widget.myUser.toDetails(),
        instrutor: widget.usuario.toDetails(),
        category: category!,
        status: LessonStatus.requested,
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

      String billingTypeStr;
      if (paymentType == PaymentType.pix) {
        billingTypeStr = 'PIX';
      } else if (paymentType == PaymentType.credito) {
        billingTypeStr = 'CREDIT_CARD';
      } else {
        billingTypeStr = 'UNDEFINED';
      }

      // 2. Processar Pagamento de forma 100% segura via Cloud Functions
      final payment = await AsaasService.createPayment(
        aula: aula,
        billingType: billingTypeStr,
      );

      if (payment == null) {
        throw "Não foi possível processar a cobrança no momento.";
      }

      final String paymentId = payment['paymentId'] ?? '';
      final String? invoiceUrl = payment['invoiceUrl'];
      final String paymentStatus = payment['paymentStatus'] ?? 'PENDING';
      final String? pixQrCode = payment['pixQrCode'];
      final String? pixPayload = payment['pixPayload'];

      aula.paymentId = paymentId;
      aula.invoiceUrl = invoiceUrl;
      aula.paymentStatus = paymentStatus;
      aula.pixQrCode = pixQrCode;
      aula.pixPayload = pixPayload;

      // 3. Salvar Aula no Firestore
      await firestore.set(aula.toMap());

      setState(() {
        success = true;
        processingPayment = false;
      });

      if (mounted) {
        Navigator.pop(context); // Fecha loading
      }

      if (paymentType == PaymentType.pix) {
        await showPixDialog(
          invoiceUrl: invoiceUrl,
          pixQrCode: pixQrCode,
          pixPayload: pixPayload,
        );
      } else if (invoiceUrl != null) {
        await launchUrl(Uri.parse(invoiceUrl));
      }

      if (mounted) {
        final navigator = Navigator.of(context);
        navigator.popUntil((route) => route.isFirst);
        DialogServices.paymentAlert(
          navigator.context,
          success: true,
          message:
              "Proposta enviada, fique atento para a resposta do instrutor!",
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => processingPayment = false);
        Navigator.pop(context); // Fecha loading
        DialogServices().alertDialog(context, "Erro no pagamento: $e");
      }
    }
  }

  Future<void> showPixDialog({
    String? invoiceUrl,
    String? pixQrCode,
    String? pixPayload,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
        backgroundColor: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Pagamento PIX",
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "Escaneie o QR Code no app do seu banco ou copie a chave Pix Copia e Cola:",
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: pixQrCode != null
                      ? Image.memory(
                          base64Decode(pixQrCode),
                          width: 200,
                          height: 200,
                        )
                      : (pixPayload != null
                            ? QrImageView(
                                data: pixPayload,
                                version: QrVersions.auto,
                                size: 200.0,
                              )
                            : (invoiceUrl != null
                                  ? QrImageView(
                                      data: invoiceUrl,
                                      version: QrVersions.auto,
                                      size: 200.0,
                                    )
                                  : const SizedBox(
                                      width: 200,
                                      height: 200,
                                      child: Center(child: Text("Sem QR Code")),
                                    ))),
                ),
              ),
              const SizedBox(height: 16),
              if (pixPayload != null && pixPayload.isNotEmpty) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: pixPayload));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Código Pix Copia e Cola copiado!"),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text("Copiar Pix Copia e Cola"),
                ),
                const SizedBox(height: 8),
              ],
              if (invoiceUrl != null && invoiceUrl.isNotEmpty) ...[
                OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse(invoiceUrl)),
                  icon: const Icon(Icons.open_in_browser, size: 18),
                  label: const Text("Abrir Fatura Completa"),
                ),
                const SizedBox(height: 8),
              ],
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Concluir"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool next() {
    if (page == 0) {
      if (category != null &&
          hours != null &&
          lessonType != null &&
          lessonVehicle != null) {
        return true;
      } else {
        return false;
      }
    } else if (page == 1) {
      if (sessions.isNotEmpty &&
          sessions.every((s) => s.date.toDate().year > 2000)) {
        return true;
      } else {
        return false;
      }
    } else if (page == 2) {
      if (paymentType != null && acceptedTerms) {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  Widget resumeRow({required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
