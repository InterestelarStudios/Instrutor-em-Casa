import 'package:flutter/material.dart';

class StepProgressIndicator extends StatelessWidget {
  final int totalSteps;
  final int currentStep;
  final String titlePrefix;

  const StepProgressIndicator({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    this.titlePrefix = "Agendamento",
  }) : assert(currentStep >= 1 && currentStep <= totalSteps,
            "A etapa atual deve estar entre 1 e o total de etapas.");

  @override
  Widget build(BuildContext context) {
    Color activeColor = Theme.of(context).primaryColor;
    const Color inactiveColor = Color(0xFFE0E0E0);
    const Color inactiveTextColor = Color(0xFF9E9E9E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Ocupa apenas o espaço necessário verticalmente
      children: [
        Text(
          "$titlePrefix - Etapa $currentStep/$totalSteps",
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 24),
        
        // A Row agora força o uso de todo o espaço horizontal
        SizedBox(
          width: double.infinity, // Força a largura total
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(totalSteps, (index) {
              final stepNumber = index + 1;
              final isCompleted = stepNumber < currentStep;
              final isActive = stepNumber == currentStep;
              final isLast = stepNumber == totalSteps;

              // Se não for o último, usamos Expanded para a linha crescer
              if (!isLast) {
                return Expanded(
                  child: Row(
                    children: [
                      _buildStepCircle(
                        stepNumber: stepNumber,
                        isCompleted: isCompleted,
                        isActive: isActive,
                        activeColor: activeColor,
                        inactiveColor: inactiveColor,
                        inactiveTextColor: inactiveTextColor,
                      ),
                      Expanded(
                        child: Container(
                          height: 4,
                          // A linha fica azul se o PRÓXIMO passo já estiver concluído ou for o atual
                          color: stepNumber < currentStep ? activeColor : inactiveColor,
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                // O último item não tem linha, então não precisa de Expanded interno
                return _buildStepCircle(
                  stepNumber: stepNumber,
                  isCompleted: isCompleted,
                  isActive: isActive,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  inactiveTextColor: inactiveTextColor,
                );
              }
            }),
          ),
        ),
      ],
    );
  }

  // Função auxiliar para construir o círculo (Check, Número Ativo, Número Inativo)
  Widget _buildStepCircle({
    required int stepNumber,
    required bool isCompleted,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
    required Color inactiveTextColor,
  }) {
    Widget content;
    Color bgColor;
    Border? border;

    if (isCompleted) {
      // Etapa Concluída: Círculo Azul com Check Branco
      bgColor = activeColor;
      content = const Icon(Icons.check, color: Colors.white, size: 16);
    } else if (isActive) {
      // Etapa Atual: Círculo Azul com Número Branco
      bgColor = activeColor;
      content = Text(
        "$stepNumber",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      );
    } else {
      // Etapa Futura: Círculo Cinza com Número Cinza Escuro
      bgColor = inactiveColor;
      content = Text(
        "$stepNumber",
        style: TextStyle(
          color: inactiveTextColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      );
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: border,
      ),
      child: Center(child: content),
    );
  }
}