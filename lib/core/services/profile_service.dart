import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import '../database/app_database.dart';

/// Clave en `settings` donde vive el nombre del usuario -- pública para que
/// otros servicios (p.ej. AiSummaryService) puedan leerla directo de la
/// base sin depender de que ProfileService ya esté cargado.
const profileNameKey = 'profile_name';

/// Foto de perfil del usuario (opcional). Se guarda una copia propia del
/// archivo elegido -- el path original (galería/cámara) puede dejar de ser
/// válido -- y se persiste en settings para sobrevivir reinicios.
class ProfileService {
  ProfileService(this._database) {
    _load();
  }

  final AppDatabase _database;
  static const _key = 'profile_image_path';

  /// Notifica cuando cambia la foto (o se quita). Null = sin foto: el
  /// avatar cae a la inicial.
  final ValueNotifier<String?> imagePath = ValueNotifier(null);

  /// Nombre del usuario (opcional), usado para personalizar saludos y
  /// mensajes de Croni en toda la app, y lo que se comparte con la IA.
  final ValueNotifier<String?> name = ValueNotifier(null);

  Future<void> _load() async {
    try {
      final db = await _database.database;
      final rows = await db.query('settings', where: 'key = ?', whereArgs: [_key]);
      if (rows.isNotEmpty) {
        final path = rows.first['value'] as String;
        if (await File(path).exists()) imagePath.value = path;
      }
      final nameRows = await db.query('settings', where: 'key = ?', whereArgs: [profileNameKey]);
      if (nameRows.isNotEmpty) name.value = nameRows.first['value'] as String;
    } catch (_) {
      // Sin foto/nombre por defecto si algo falla al leer disco: nunca debe
      // romper el arranque de la app.
    }
  }

  /// Copia [sourcePath] al almacenamiento propio de la app y lo recuerda
  /// como foto de perfil.
  Future<void> setImage(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final ext = sourcePath.contains('.') ? sourcePath.split('.').last : 'jpg';
    final dest = '${dir.path}/profile.$ext';
    await File(sourcePath).copy(dest);

    final db = await _database.database;
    await db.insert(
      'settings',
      {'key': _key, 'value': dest},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    imagePath.value = dest;
  }

  Future<void> clearImage() async {
    final db = await _database.database;
    await db.delete('settings', where: 'key = ?', whereArgs: [_key]);
    imagePath.value = null;
  }

  /// Guarda el nombre elegido; una cadena vacía lo borra (vuelve a mensajes
  /// genéricos, sin nombre).
  Future<void> setName(String value) async {
    final trimmed = value.trim();
    final db = await _database.database;
    if (trimmed.isEmpty) {
      await db.delete('settings', where: 'key = ?', whereArgs: [profileNameKey]);
      name.value = null;
    } else {
      await db.insert(
        'settings',
        {'key': profileNameKey, 'value': trimmed},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      name.value = trimmed;
    }
  }
}
