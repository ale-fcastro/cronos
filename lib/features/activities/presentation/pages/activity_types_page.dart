import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../shared/shared.dart';
import '../bloc/activities_cubit.dart';
import '../bloc/activities_state.dart';
import '../widgets/create_activity_type_dialog.dart';
import '../widgets/manage_linked_apps_sheet.dart';

/// Pantalla "Categorías": gestiona los tipos de actividad (crear se hace
/// desde el registro con el FAB; acá se ven y se borran).
class ActivityTypesPage extends StatelessWidget {
  const ActivityTypesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ActivitiesCubit>(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: AppSpacing.page,
            child: BlocBuilder<ActivitiesCubit, ActivitiesState>(
              builder: (context, state) {
                final cubit = context.read<ActivitiesCubit>();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppIconButton(
                          icon: Icons.chevron_left_rounded,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Gaps.hSm,
                        const Text('Categorías', style: AppTextStyles.headline),
                      ],
                    ),
                    Gaps.vSm,
                    const AppCaption(
                      'Para agregar una nueva, tocá "Nueva actividad" al registrar. '
                      'Tocá una categoría para editarla.',
                    ),
                    Gaps.vLg,
                    if (state.isLoading)
                      const Expanded(child: LoadingView())
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: state.activities!.length,
                          separatorBuilder: (_, __) => Gaps.vSm,
                          itemBuilder: (context, i) {
                            final a = state.activities![i];
                            return AppCard(
                              padding: AppSpacing.cardDense,
                              onTap: () async {
                                final input = await showEditActivityTypeDialog(
                                  context,
                                  activity: a,
                                  lifeAreas: state.lifeAreas,
                                );
                                if (input != null) {
                                  cubit.updateActivityType(a.id, input);
                                }
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: a.color,
                                          borderRadius:
                                              const BorderRadius.all(Radius.circular(3)),
                                        ),
                                      ),
                                      Gaps.hSm,
                                      Text(a.name, style: AppTextStyles.body),
                                      Gaps.hSm,
                                      Text(a.impact.label,
                                          style: AppTextStyles.metricCaption.copyWith(
                                              color: AppColors.textTertiary, fontSize: 12)),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      AppIconButton(
                                        icon: Icons.apps_rounded,
                                        onPressed: () async {
                                          final linked = await cubit.getLinkedApps(a.id);
                                          if (!context.mounted) return;
                                          final picked = await showManageLinkedAppsSheet(
                                            context,
                                            activityTypeName: a.name,
                                            initiallyLinked: linked,
                                          );
                                          if (picked != null) {
                                            cubit.setLinkedApps(a.id, picked);
                                          }
                                        },
                                      ),
                                      AppIconButton(
                                        icon: Icons.delete_outline_rounded,
                                        color: AppColors.danger,
                                        onPressed: () async {
                                          final confirmed = await DeleteDialog.show(
                                            context,
                                            title: 'Eliminar "${a.name}"',
                                            message:
                                                'Las sesiones ya registradas con esta categoría dejarán de listarse.',
                                          );
                                          if (confirmed) cubit.removeActivityType(a.id);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
