import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:instrutor_em_casa/models/aula.dart';
import 'package:instrutor_em_casa/models/instrutor.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/screens/agendar_aula/steps/step1/agendar_aula_1.dart';
import 'package:instrutor_em_casa/screens/agendar_aula/steps/step2/agendar_aula_2.dart';
import 'package:instrutor_em_casa/screens/agendar_aula/steps/step3/agendar_aula_3.dart';
import 'package:instrutor_em_casa/screens/agendar_aula/widgets/stepper.dart';
import 'package:instrutor_em_casa/widgets/dialog_services.dart';
import 'package:intl/intl.dart';

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
  LessonTime? time;
  DateTime? date;
  String? hour;
  PaymentType? paymentType;
  late Position position;
  bool success = false;

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

      if(time != null){
        price.hourPrice = int.parse(time!.name.replaceAll("h", "")) * 60;
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
                onPageChanged: (value){
                  setState(() {
                    page = value;
                  });
                },
                children: [
                  AgendarAula1(
                    onChangedLessonCategory: (value)=> setState(()=> category = value),
                    onChangedLessonTime: (value)=> setState(()=> time = value),
                    onChangedLessonType: (value)=> setState(()=> lessonType = value),
                    onChangedLessonVehicle: (value)=> setState(()=> lessonVehicle = value),
                  ),
                  AgendarAula2(
                    onChangedDate: (value)=> setState(()=> date = value),
                    onChangedTime: (value)=> setState(()=> hour = value),
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
                            resumeRow(title: "Data", value: DateFormat(DateFormat.MONTH_DAY).format(date!)),
                            resumeRow(title: "Hora", value: hour!),
                            resumeRow(title: "Duração", value: lessonTimeTranslate(time!)),
                            resumeRow(title: "Tipo de aula", value: lessonTypeTranslate(lessonType!)),
                            resumeRow(title: "Veículo", value: lessonVehicleTranslate(lessonVehicle!)),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: const Divider(),
                            ),
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
            onPressed: (){
              if(page < 2){
                pageController.nextPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.ease,
                );
              } else {
                DialogServices.loading2(context);
                final firestore = FirebaseFirestore.instance.collection("aulas").doc();
                final aula = Aula(
                  id: firestore.id,
                  aluno: widget.myUser.toDetails(),
                  instrutor: widget.usuario.toDetails(),
                  category: category!,
                  status: LessonStatus.requested,
                  date: Timestamp.fromDate(
                    DateTime(
                      date!.year,
                      date!.month,
                      date!.day,
                      int.parse(hour!.split(":").first),
                      int.parse(hour!.split(":").last),
                    )
                  ),
                  created: Timestamp.now(),
                  duration: time!,
                  type: lessonType!,
                  vehicle: lessonVehicle!,
                  price: price(),
                  paymentType: paymentType!,
                );
                firestore.set(aula.toMap())
                .then((_){
                  success = true;
                  Navigator.pop(context);
                  Navigator.pop(context);
                  Navigator.pop(context);
                  Navigator.pop(context);
                  DialogServices.paymentAlert(
                    context,
                    success: true,
                    message: "Proposta enviada, fique atento para a resposta do instrutor!"
                  );
                }).catchError((e){
                  Navigator.pop(context);
                  DialogServices().alertDialog(context, "Tivemos um problema ao agendar sua aula.");
                });
              }
            },
            child: Text("Próximo")
          ),
        ),
      ),
    );
  }

  bool next(){
    if(page == 0){
      if(category != null && time != null && lessonType != null && lessonVehicle != null){
        return true;
      } else {
        return false;
      }
    } else if(page == 1){
      if(date != null && hour != null){
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: Text(title, style: Theme.of(context).textTheme.bodySmall,)),
        Flexible(child: Text(value, style: Theme.of(context).textTheme.titleMedium,))
      ],
    );
  }
}