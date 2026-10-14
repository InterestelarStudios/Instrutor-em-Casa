import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:instrutor_em_casa/models/usuario.dart';
import 'package:instrutor_em_casa/widgets/theme.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:url_launcher/url_launcher.dart';

class HistoricoCobrancasScreen extends StatefulWidget {
  const HistoricoCobrancasScreen({super.key, required this.usuario});
  final Usuario usuario;

  @override
  State<HistoricoCobrancasScreen> createState() => _HistoricoCobrancasScreenState();
}

class _HistoricoCobrancasScreenState extends State<HistoricoCobrancasScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leadingWidth: 48,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(Ionicons.chevronBackOutline, color: AppColors.textPrimary, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        titleSpacing: 4,
        title: Text(
          "Histórico de Cobranças",
          style: GoogleFonts.sora(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("cobrancas")
            .where("alunoId", isEqualTo: widget.usuario.id)
            .orderBy("created", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Erro ao carregar cobranças: ${snapshot.error}",
                style: GoogleFonts.dmSans(color: AppColors.danger),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Ionicons.receiptOutline,
                    size: 64,
                    color: AppColors.gray300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Nenhuma cobrança encontrada",
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String status = data['status'] ?? 'PENDING';
              final double value = (data['value'] as num?)?.toDouble() ?? 0.0;
              final String billingType = data['billingType'] ?? 'PIX';
              final String? invoiceUrl = data['invoiceUrl'];
              final Timestamp? created = data['created'] as Timestamp?;
              final String formattedDate = created != null
                  ? DateFormat("dd/MM/yyyy HH:mm").format(created.toDate())
                  : "";

              final isUnpaid = status.toUpperCase() == 'PENDING' || status.toUpperCase() == 'OVERDUE';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: AppColors.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.radiusLg,
                  side: const BorderSide(color: AppColors.border, width: 1),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  onTap: isUnpaid && invoiceUrl != null
                      ? () => launchUrl(Uri.parse(invoiceUrl))
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Treinamento de Direção",
                              style: GoogleFonts.sora(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              NumberFormat.simpleCurrency(locale: 'pt_BR').format(value),
                              style: GoogleFonts.sora(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "$formattedDate • ${getBillingTypeLabel(billingType)}",
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: getStatusColor(status).withAlpha(30),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                getStatusLabel(status),
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: getStatusColor(status),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (isUnpaid && invoiceUrl != null) ...[
                          const Padding(
                            padding: EdgeInsets.only(top: 12.0),
                            child: Divider(),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  "Pagar Agora",
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Ionicons.arrowForwardOutline,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          )
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String getBillingTypeLabel(String type) {
    switch (type.toUpperCase()) {
      case 'PIX':
        return "PIX";
      case 'CREDIT_CARD':
        return "Cartão de Crédito";
      case 'DEBIT_CARD':
      case 'UNDEFINED':
        return "Cartão de Débito";
      default:
        return "Cartão";
    }
  }

  String getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return "Pendente";
      case 'RECEIVED':
      case 'CONFIRMED':
      case 'RECEIVED_IN_CASH':
      case 'CONFIRMED_IN_CASH':
        return "Pago";
      case 'OVERDUE':
        return "Vencido";
      case 'REFUNDED':
        return "Reembolsado";
      case 'REFUSED':
        return "Recusado";
      case 'CANCELED':
        return "Cancelado";
      default:
        return "Pendente";
    }
  }

  Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'RECEIVED':
      case 'CONFIRMED':
      case 'RECEIVED_IN_CASH':
      case 'CONFIRMED_IN_CASH':
        return AppColors.success;
      case 'PENDING':
        return AppColors.warning;
      case 'OVERDUE':
      case 'REFUSED':
        return AppColors.danger;
      case 'REFUNDED':
        return Colors.blue;
      case 'CANCELED':
      default:
        return AppColors.textMuted;
    }
  }
}
