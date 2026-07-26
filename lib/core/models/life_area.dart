import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show Color;

/// Área de vida: clasificación transversal de tareas, actividades y
/// eventos. El producto trae 8 por defecto; el usuario puede agregar,
/// renombrar/recolorear o borrar las suyas desde Configuración.
class LifeArea extends Equatable {
  const LifeArea({required this.id, required this.name, required this.color});

  final String id;
  final String name;
  final Color color;

  @override
  List<Object?> get props => [id, name, color];
}
