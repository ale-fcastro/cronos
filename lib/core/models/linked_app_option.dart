import 'package:equatable/equatable.dart';

/// Una app instalada con su uso reciente, para elegir al vincular una tarea
/// o al clasificar apps por área de vida.
class LinkedAppOption extends Equatable {
  const LinkedAppOption({
    required this.packageName,
    required this.appName,
    this.recentUsage = Duration.zero,
  });

  final String packageName;
  final String appName;

  /// Tiempo en primer plano dentro de la ventana consultada.
  final Duration recentUsage;

  @override
  List<Object?> get props => [packageName, appName, recentUsage];
}
