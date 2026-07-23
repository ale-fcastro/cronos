import 'package:equatable/equatable.dart';
import '../../domain/entities/app_settings.dart';

class SettingsState extends Equatable {
  const SettingsState({this.settings});

  final AppSettings? settings;

  bool get isLoading => settings == null;

  @override
  List<Object?> get props => [settings];
}
