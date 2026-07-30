import 'package:equatable/equatable.dart';

/// Regla de App Tracking que solo vincula una app a un ActivityType durante
/// una franja horaria (fuera de esa franja, gana la regla general si existe
/// -- ver AppTrackingResolver).
class TimeRule extends Equatable {
  const TimeRule({
    required this.packageName,
    required this.activityTypeId,
    required this.activityTypeName,
    required this.startMinute,
    required this.endMinute,
  });

  final String packageName;
  final String activityTypeId;
  final String activityTypeName;
  final int startMinute;
  final int endMinute;

  @override
  List<Object?> get props =>
      [packageName, activityTypeId, activityTypeName, startMinute, endMinute];
}
