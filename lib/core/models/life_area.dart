import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show Color;

/// Área de vida: taxonomía fija del producto (no editable por el usuario),
/// usada para clasificar tareas, actividades y eventos.
class LifeArea extends Equatable {
  const LifeArea({required this.id, required this.name, required this.color});

  final String id;
  final String name;
  final Color color;

  @override
  List<Object?> get props => [id, name, color];
}
