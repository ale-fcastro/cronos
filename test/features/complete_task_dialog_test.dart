import 'package:flutter_test/flutter_test.dart';

import 'package:cronos/features/tasks/presentation/widgets/complete_task_dialog.dart';

void main() {
  test('CompleteTaskDone guarda el horario manual cuando lo hay', () {
    final start = DateTime(2026, 1, 1, 9);
    final end = DateTime(2026, 1, 1, 10);
    final result = CompleteTaskDone(start: start, end: end);
    expect(result.start, start);
    expect(result.end, end);
  });

  test('CompleteTaskDone sin horario manual (ya tenía cronómetro)', () {
    final result = CompleteTaskDone();
    expect(result.start, isNull);
    expect(result.end, isNull);
  });

  test('CompleteTaskFailed sin sustituto no pide abrir ninguna pestaña', () {
    final result = CompleteTaskFailed('Me quedé sin tiempo');
    expect(result.reason, 'Me quedé sin tiempo');
    expect(result.openSubstituteTab, isNull);
  });

  test('CompleteTaskFailed con sustituto guarda qué pestaña abrir', () {
    final asEvento = CompleteTaskFailed('Se cortó la luz', openSubstituteTab: 2);
    expect(asEvento.openSubstituteTab, 2);

    final comoActividad = CompleteTaskFailed('Me quedé durmiendo', openSubstituteTab: 1);
    expect(comoActividad.openSubstituteTab, 1);
  });
}
