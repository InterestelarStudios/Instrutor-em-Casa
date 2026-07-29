import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instrutor_em_casa/models/transferencia.dart';
import 'package:instrutor_em_casa/models/usuario.dart';

import 'package:instrutor_em_casa/widgets/theme.dart';
import 'package:intl/intl.dart';

class GanhosScreen extends StatefulWidget {
  const GanhosScreen({super.key, required this.usuario});
  final Usuario usuario;

  @override
  State<GanhosScreen> createState() => _GanhosScreenState();
}

class _GanhosScreenState extends State<GanhosScreen> {


  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthYear = "${now.year}_${now.month.toString().padLeft(2, '0')}";

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection("ganhos")
            .doc(widget.usuario.id)
            .collection("meses")
            .doc(monthYear)
            .snapshots(),
        builder: (context, snapshot) {
          double monthlyTotal = 0.0;
          int aulasCount = 0;

          if (snapshot.hasData && snapshot.data!.exists) {
            monthlyTotal = (snapshot.data!.data()?['total'] as num).toDouble();
            aulasCount = snapshot.data!.data()?['aulasCount'] as int;
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection("transferencias")
                .where("instrutorId", isEqualTo: widget.usuario.id)
                .snapshots(),
            builder: (context, transfersSnapshot) {
              double transfersSum = 0.0;
              List<Transferencia> transfersList = [];

              if (transfersSnapshot.hasData) {
                transfersList = transfersSnapshot.data!.docs
                    .map((doc) => Transferencia.fromMap(doc.data()))
                    .toList();

                // Sort in-memory to prevent requiring firestore index
                transfersList.sort((a, b) => b.date.compareTo(a.date));

                for (var transfer in transfersList) {
                  final tDate = transfer.date.toDate();
                  if (tDate.year == now.year && tDate.month == now.month) {
                    transfersSum += transfer.amount;
                  }
                }
              }

              double displayTotal = monthlyTotal + transfersSum;

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    "Meus Ganhos",
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 20),
                  
                  // Card de Ganhos Mensais (Verde)
                  Card(
                    color: Colors.green[600],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(25),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Ganhos do Mês",
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                              Icon(Icons.trending_up, color: Colors.white),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            NumberFormat.currency(symbol: "R\$", locale: "pt_BR").format(displayTotal),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "$aulasCount aulas finalizadas este mês",
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  Text(
                    "Histórico de Aulas",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  _buildSimpleHistoryList(),

                  const SizedBox(height: 30),
                  Text(
                    "Transferências Recebidas",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  _buildTransfersList(transfersList),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSimpleHistoryList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection("aulas")
          .where("instrutor.id", isEqualTo: widget.usuario.id)
          .where("status", isEqualTo: "done")
          .orderBy("created", descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            elevation: 0,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              leading: CircleAvatar(
                backgroundColor: Colors.grey[100],
                child: const Icon(Icons.history, color: Colors.grey, size: 20,),
              ),
              title: const Text(
                "Sem histórico",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "Suas aulas finalizadas aparecerão aqui.",
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data();
            final amount = (data['price']['amount'] as num) * 0.8;
            final date = (data['created'] as Timestamp).toDate();

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 5),
              leading: const CircleAvatar(
                backgroundColor: AppColors.success,
                child: Icon(Icons.add, color: Colors.white),
              ),
              title: Text("Aula - ${data['aluno']['name']}"),
              subtitle: Text(DateFormat("dd/MM/yyyy").format(date)),
              trailing: Text(
                "+ ${NumberFormat.currency(symbol: "R\$", locale: "pt_BR").format(amount)}",
                style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String getPixKeyTypeLabel(String? type) {
    switch (type) {
      case "CPF":
        return "CPF";
      case "CNPJ":
        return "CNPJ";
      case "EMAIL":
        return "E-mail";
      case "PHONE":
        return "Telefone";
      case "EVP":
        return "Chave Aleatória";
      default:
        return type ?? "";
    }
  }

  Widget _buildTransfersList(List<Transferencia> transfers) {
    if (transfers.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        elevation: 0,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          leading: CircleAvatar(
            backgroundColor: Colors.grey[100],
            child: const Icon(Icons.swap_horiz, color: Colors.grey, size: 20,),
          ),
          title: const Text(
            "Sem histórico",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            "Suas transferências concluídas aparecerão aqui.",
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ),
      );
    }

    return Column(
      children: transfers.map((transfer) {
        final date = transfer.date.toDate();
        final amount = transfer.amount;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 5),
          leading: const CircleAvatar(
            backgroundColor: Colors.blue,
            child: Icon(Icons.pix, color: Colors.white, size: 18),
          ),
          title: const Text("Transferência PIX"),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(DateFormat("dd/MM/yyyy 'às' HH:mm").format(date)),
              Text(
                "Chave: (${getPixKeyTypeLabel(transfer.pixKeyType)}) ${transfer.pixKey}",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          trailing: Text(
            "+ ${NumberFormat.currency(symbol: "R\$", locale: "pt_BR").format(amount)}",
            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
          ),
        );
      }).toList(),
    );
  }
}
