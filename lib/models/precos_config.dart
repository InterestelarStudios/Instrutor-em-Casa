import 'package:instrutor_em_casa/models/instrutor.dart';

class PrecosConfig {
  final double categoriaA;
  final double categoriaB;
  final double categoriaC;
  final double categoriaD;
  final double categoriaE;
  final double taxaDeslocamento;
  final double taxaComissao;

  const PrecosConfig({
    this.categoriaA = 100.0,
    this.categoriaB = 130.0,
    this.categoriaC = 130.0,
    this.categoriaD = 130.0,
    this.categoriaE = 130.0,
    this.taxaDeslocamento = 20.0,
    this.taxaComissao = 20.0,
  });

  double getPriceForCategory(CNHCategory category) {
    switch (category) {
      case CNHCategory.A:
        return categoriaA;
      case CNHCategory.B:
        return categoriaB;
      case CNHCategory.C:
        return categoriaC;
      case CNHCategory.D:
        return categoriaD;
      case CNHCategory.E:
        return categoriaE;
    }
  }

  factory PrecosConfig.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const PrecosConfig();

    return PrecosConfig(
      categoriaA: (map['categoria_a'] as num?)?.toDouble() ??
          (map['categoriaA'] as num?)?.toDouble() ??
          100.0,
      categoriaB: (map['categoria_b'] as num?)?.toDouble() ??
          (map['categoriaB'] as num?)?.toDouble() ??
          130.0,
      categoriaC: (map['categoria_c'] as num?)?.toDouble() ??
          (map['categoria_outras'] as num?)?.toDouble() ??
          130.0,
      categoriaD: (map['categoria_d'] as num?)?.toDouble() ??
          (map['categoria_outras'] as num?)?.toDouble() ??
          130.0,
      categoriaE: (map['categoria_e'] as num?)?.toDouble() ??
          (map['categoria_outras'] as num?)?.toDouble() ??
          130.0,
      taxaDeslocamento: (map['taxa_deslocamento'] as num?)?.toDouble() ??
          (map['taxaDeslocamento'] as num?)?.toDouble() ??
          20.0,
      taxaComissao: (map['taxa_comissao'] as num?)?.toDouble() ??
          (map['taxaComissao'] as num?)?.toDouble() ??
          20.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoria_a': categoriaA,
      'categoria_b': categoriaB,
      'categoria_c': categoriaC,
      'categoria_d': categoriaD,
      'categoria_e': categoriaE,
      'taxa_deslocamento': taxaDeslocamento,
      'taxa_comissao': taxaComissao,
    };
  }
}
