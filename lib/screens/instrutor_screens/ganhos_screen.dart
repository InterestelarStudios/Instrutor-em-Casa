import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/services/asaas_service.dart';
import 'package:instrutor_em_casa/widgets/theme.dart';
import 'package:intl/intl.dart';

class GanhosScreen extends StatefulWidget {
  const GanhosScreen({super.key, required this.usuario});
  final Usuario usuario;

  @override
  State<GanhosScreen> createState() => _GanhosScreenState();
}

class _GanhosScreenState extends State<GanhosScreen> {
  double asaasBalance = 0.0;
  bool loadingBalance = true;
  bool transferring = false;

  @override
  void initState() {
    super.initState();
    _fetchAsaasBalance();
  }

  Future<void> _fetchAsaasBalance() async {
    if (widget.usuario.instrutor?.asaasApiKey != null) {
      final balance = await AsaasService.getBalance(widget.usuario.instrutor!.asaasApiKey!);
      if (mounted) {
        setState(() {
          asaasBalance = balance;
          loadingBalance = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => loadingBalance = false);
      }
    }
  }

  Future<void> _requestTransfer() async {
    if (asaasBalance <= 0) return;

    setState(() => transferring = true);
    final success = await AsaasService.requestTransfer(
      subAccountApiKey: widget.usuario.instrutor!.asaasApiKey!,
      value: asaasBalance,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Transferência solicitada com sucesso!")),
      );
      _fetchAsaasBalance();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao solicitar transferência.")),
      );
    }
    setState(() => transferring = false);
  }

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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Ganhos do Mês",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          const Icon(Icons.trending_up, color: Colors.white),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        NumberFormat.currency(symbol: "R\$", locale: "pt_BR").format(monthlyTotal),
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
              
              const SizedBox(height: 20),
              
              // Card de Saldo Asaas
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue[50],
                            child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.blue),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Saldo para transferência",
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                                loadingBalance
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Text(
                                        NumberFormat.currency(symbol: "R\$", locale: "pt_BR").format(asaasBalance),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: (asaasBalance > 0 && !transferring) ? _requestTransfer : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 15),
                            ),
                            child: transferring
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text("Transferir"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),
              Text(
                "Histórico Recente",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              _buildHistoryList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHistoryList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection("aulas")
          .where("instrutor.id", isEqualTo: widget.usuario.id)
          .where("status", isEqualTo: "done")
          .orderBy("created", descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) {
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
                child: Icon(Icons.add, color: AppColors.success),
              ),
              title: Text("Aula - ${data['aluno']['name']}"),
              subtitle: Text(DateFormat("dd/MM/yyyy HH:mm").format(date)),
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
}
