import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class DialogServices{
  DialogServices();

  DialogServices.loading(BuildContext context){
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context){
        // ignore: deprecated_member_use
        return WillPopScope(
          onWillPop: () async {
            return true;
          },
          child: Center(
            child: Container(
              height: 120,
              width: 120,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                //color: Colors.white,
              ),
              child: const CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          ),
        );
      }
    );
  }

  DialogServices.loading2(BuildContext context){
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context){
        // ignore: deprecated_member_use
        return WillPopScope(
          onWillPop: () async {
            return true;
          },
          child: Center(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)
              ),
              child: const Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          ),
        );
      }
    );
  }

  Future alertDialog(BuildContext context, String content, {String? title, Color? colorButton1, Color? colorButton2,
  VoidCallback? onTap1, VoidCallback? onTap2, String? buttonTitle1 = 'OK', String? buttonTitle2, Widget? contentWidget, EdgeInsetsGeometry? contentPadding,
  }) async {
    await showDialog(
      context: context,
      builder: (BuildContext context){
        return AlertDialog(
          title: Text(title ?? "Oops!"),
          contentPadding: contentPadding ?? const EdgeInsets.all(24),
          content: contentWidget ?? Text(content),
          actions: [
            buttonTitle1! == 'emptyButton' ? Container():
            TextButton(
              onPressed: onTap1 ?? ()=> Navigator.of(context).pop(),
              child: Text(buttonTitle1, style: TextStyle(color: colorButton1),)
            ),
            buttonTitle2 != null?
            TextButton(
              onPressed: onTap2 ?? (){},
              child: Text(buttonTitle2, style: TextStyle(color: colorButton2),)
            ) : Container(),
          ],
        );
      }
    );
  }

  DialogServices.paymentAlert(BuildContext context, {required bool success, required String message, Widget? icon}){
    showDialog(
      context: context,
      builder: (context){
        return AlertDialog(
          title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              icon ??
              Icon(
                success ? Ionicons.checkmark_done_circle_outline : Ionicons.close_circle_outline,
                color: success ? Colors.greenAccent[700] : Colors.redAccent[700],
                size: 60,
              ),
            ],
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), textAlign: TextAlign.center,),
            ],
          ),
          actions: [
            TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('OK'))
          ],
        );
      }
    );
  }
}

class PaymentDialog extends StatelessWidget {
  const PaymentDialog({super.key, required this.success, required this.message, this.pop = true});
  final bool success;
  final String message;
  final bool pop;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            success ? Ionicons.checkmark_done_circle_outline : Ionicons.close_circle_outline,
            color: success ? Colors.greenAccent[700] : Colors.redAccent[700],
            size: 60,
          ),
        ],
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), textAlign: TextAlign.center,),
        ],
      ),
      actions: [
        !pop ? const SizedBox():
        TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('OK'))
      ],
    );
  }
}