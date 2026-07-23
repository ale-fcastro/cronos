import '../../domain/entities/app_settings.dart';

class SettingsMockDatasource {
  Future<AppSettings> fetchSettings() async {
    return const AppSettings(
      workScheduleLabel: '09:00 – 18:00',
      studyScheduleLabel: '19:00 – 21:00',
      idealSleepLabel: '23:30',
      workingDays: [
        WorkingDay(label: 'L', active: true),
        WorkingDay(label: 'M', active: true),
        WorkingDay(label: 'X', active: true),
        WorkingDay(label: 'J', active: true),
        WorkingDay(label: 'V', active: true),
        WorkingDay(label: 'S', active: false),
        WorkingDay(label: 'D', active: false),
      ],
      categoriesCount: 7,
      projectsCount: 3,
      prioritiesLabel: 'P1–P3',
      scoreWeightsLabel: 'Cumplimiento 40 · Eficiencia 30 · Sueño 20 · Puntualidad 10',
    );
  }
}
