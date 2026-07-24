import 'package:flutter_test/flutter_test.dart';

import 'package:cronos/core/services/app_usage_service.dart';

/// En desktop (donde corren los tests) el plugin usage_stats no está
/// disponible: el servicio debe degradar a resultados vacíos, nunca lanzar.
void main() {
  test('en una plataforma sin soporte, todo degrada a vacío/false', () async {
    final service = AppUsageService();

    expect(service.isSupported, isFalse);
    expect(await service.hasPermission(), isFalse);
    expect(await service.queryUsage(DateTime.now(), DateTime.now()), isEmpty);
    expect(
      await service.usageOf('com.example', DateTime.now(), DateTime.now()),
      Duration.zero,
    );
    // No debe lanzar.
    await service.requestPermission();
  });
}
