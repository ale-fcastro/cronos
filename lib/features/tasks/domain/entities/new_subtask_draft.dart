import 'package:equatable/equatable.dart';

/// Subtarea capturada en el formulario de creación (de una tarea suelta o
/// de una regla de repetición), antes de que exista un id de tarea al que
/// colgarla. Se persiste junto con la tarea (o con cada ocurrencia
/// generada, si viene de una regla) recién al confirmar.
class NewSubtaskDraft extends Equatable {
  const NewSubtaskDraft({required this.title, this.description});

  final String title;
  final String? description;

  @override
  List<Object?> get props => [title, description];
}
