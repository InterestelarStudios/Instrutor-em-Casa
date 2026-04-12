import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final double stars;
  final double size;

  const StarRating({
    super.key, 
    required this.stars, 
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        // O index começa em 0, então a primeira estrela representa o valor 1
        double valorEstrela = index + 1.0;
        
        IconData icone;
        Color cor;

        if (stars >= valorEstrela) {
          // Estrela completa
          icone = Icons.star;
          cor = Colors.amber;
        } else if (stars >= valorEstrela - 0.5) {
          // Meia estrela
          icone = Icons.star_half;
          cor = Colors.amber;
        } else {
          // Estrela vazia
          icone = Icons.star;
          cor = Colors.grey[400]!;
        }

        return Icon(
          icone,
          color: cor,
          size: size,
        );
      }),
    );
  }
}