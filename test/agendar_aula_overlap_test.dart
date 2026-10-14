import 'package:flutter_test/flutter_test.dart';

bool hasOverlap(DateTime newStart, DateTime newEnd, DateTime existingStart, DateTime existingEnd) {
  return newStart.isBefore(existingEnd) && newEnd.isAfter(existingStart);
}

void main() {
  group('Verificação de conflito de horários de aula', () {
    test('Detecta conflito quando aula anterior de 2h começou 1h antes', () {
      // Instrutor tem aula das 14:00 às 16:00 (2 horas)
      final existingStart = DateTime(2026, 10, 15, 14, 0);
      final existingEnd = DateTime(2026, 10, 15, 16, 0);

      // Aluno tenta agendar às 15:00 por 1 hora
      final newStart = DateTime(2026, 10, 15, 15, 0);
      final newEnd = DateTime(2026, 10, 15, 16, 0);

      expect(hasOverlap(newStart, newEnd, existingStart, existingEnd), isTrue);
    });

    test('Permite agendamento imediatamente após o término da aula anterior', () {
      // Instrutor tem aula das 14:00 às 15:00 (1 hora)
      final existingStart = DateTime(2026, 10, 15, 14, 0);
      final existingEnd = DateTime(2026, 10, 15, 15, 0);

      // Aluno tenta agendar às 15:00 por 1 hora
      final newStart = DateTime(2026, 10, 15, 15, 0);
      final newEnd = DateTime(2026, 10, 15, 16, 0);

      expect(hasOverlap(newStart, newEnd, existingStart, existingEnd), isFalse);
    });

    test('Detecta conflito quando a nova aula é mais longa e engloba aula existente', () {
      // Instrutor tem aula das 15:00 às 16:00
      final existingStart = DateTime(2026, 10, 15, 15, 0);
      final existingEnd = DateTime(2026, 10, 15, 16, 0);

      // Nova aula de 3 horas das 14:00 às 17:00
      final newStart = DateTime(2026, 10, 15, 14, 0);
      final newEnd = DateTime(2026, 10, 15, 17, 0);

      expect(hasOverlap(newStart, newEnd, existingStart, existingEnd), isTrue);
    });

    test('Não detecta conflito em dias diferentes no mesmo horário', () {
      final existingStart = DateTime(2026, 10, 15, 14, 0);
      final existingEnd = DateTime(2026, 10, 15, 16, 0);

      final newStart = DateTime(2026, 10, 16, 14, 0);
      final newEnd = DateTime(2026, 10, 16, 16, 0);

      expect(hasOverlap(newStart, newEnd, existingStart, existingEnd), isFalse);
    });
  });
}
