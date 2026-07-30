import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/models/linked_app_option.dart';
import '../../../../core/services/app_usage_service.dart';
import '../../../../shared/shared.dart';

/// Hoja para elegir qué apps arrancan solas el cronómetro de un
/// ActivityType (App Tracking). A diferencia del picker de "vincular tarea
/// con app" (una sola, de uso reciente), acá es multi-selección sobre
/// TODAS las apps instaladas -- por eso no reusa `showSelectionSheet`.
Future<List<String>?> showManageLinkedAppsSheet(
  BuildContext context, {
  required String activityTypeName,
  required List<String> initiallyLinked,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _ManageLinkedAppsSheet(
      activityTypeName: activityTypeName,
      initiallyLinked: initiallyLinked,
    ),
  );
}

class _ManageLinkedAppsSheet extends StatefulWidget {
  const _ManageLinkedAppsSheet({required this.activityTypeName, required this.initiallyLinked});

  final String activityTypeName;
  final List<String> initiallyLinked;

  @override
  State<_ManageLinkedAppsSheet> createState() => _ManageLinkedAppsSheetState();
}

class _ManageLinkedAppsSheetState extends State<_ManageLinkedAppsSheet> {
  List<LinkedAppOption>? _apps;
  late final Set<String> _selected = widget.initiallyLinked.toSet();

  @override
  void initState() {
    super.initState();
    sl<AppUsageService>().listInstalledApps().then((apps) {
      if (mounted) setState(() => _apps = apps);
    });
  }

  @override
  Widget build(BuildContext context) {
    final apps = _apps;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: AppRadius.card,
          border: Border.fromBorderSide(AppBorders.side),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text('Apps vinculadas a "${widget.activityTypeName}"',
                  style: AppTextStyles.label),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: AppCaption(
                'Abrir una de estas apps arranca sola el cronómetro de esta '
                'categoría (con App Tracking activado en Configuración).',
              ),
            ),
            if (apps == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (apps.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Text('No se pudo leer la lista de apps instaladas.',
                    style: AppTextStyles.bodySecondary),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  children: [
                    for (final app in apps)
                      InkWell(
                        onTap: () => setState(() {
                          if (_selected.contains(app.packageName)) {
                            _selected.remove(app.packageName);
                          } else {
                            _selected.add(app.packageName);
                          }
                        }),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              AppIconAvatar(name: app.appName, icon: app.icon, size: 30),
                              Gaps.hSm,
                              Expanded(child: Text(app.appName, style: AppTextStyles.body)),
                              Checkbox(
                                value: _selected.contains(app.packageName),
                                onChanged: (v) => setState(() {
                                  if (v ?? false) {
                                    _selected.add(app.packageName);
                                  } else {
                                    _selected.remove(app.packageName);
                                  }
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: PrimaryButton(
                label: 'Guardar',
                expanded: true,
                onPressed: () => Navigator.of(context).pop(_selected.toList()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
