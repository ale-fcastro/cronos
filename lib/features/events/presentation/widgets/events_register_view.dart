import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/shared.dart';
import '../../domain/entities/event_suggestion.dart';
import '../bloc/event_register_cubit.dart';
import '../bloc/event_register_state.dart';

/// Contenido de la pestaña "Evento" de la hoja de registro del FAB.
class EventsRegisterView extends StatelessWidget {
  const EventsRegisterView({super.key, this.onSubmitted});

  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EventRegisterCubit, EventRegisterState>(
      listener: (context, state) {
        if (state.submitted) onSubmitted?.call();
      },
      builder: (context, state) {
        final cubit = context.read<EventRegisterCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              label: '¿Qué pasó?',
              hint: 'Llamada, corte de luz, reunión…',
              autofocus: true,
              onChanged: cubit.setQuery,
            ),
            Gaps.vMd,
            if (state.suggestions.isNotEmpty) ...[
              const Text('DE TU HISTORIAL', style: AppTextStyles.overline),
              Gaps.vSm,
              for (final s in state.suggestions) ...[
                _SuggestionRow(
                  suggestion: s,
                  selected: s.title == state.query,
                  onTap: () => cubit.setQuery(s.title),
                ),
                Gaps.vSm,
              ],
              Gaps.vSm,
            ],
            const Text('Categoría', style: AppTextStyles.label),
            Gaps.vSm,
            TagSelector(
              options: [for (final c in eventCategories) TagOption(label: c)],
              selectedIndexes: {state.categoryIndex},
              onToggle: cubit.setCategory,
            ),
            if (state.lifeAreas.isNotEmpty) ...[
              Gaps.vMd,
              TagSelector(
                label: 'Área de vida',
                options: [
                  for (final a in state.lifeAreas)
                    TagOption(label: a.name, color: a.color),
                ],
                selectedIndexes: {
                  if (state.areaId != null)
                    state.lifeAreas.indexWhere((a) => a.id == state.areaId),
                },
                onToggle: (i) {
                  final tapped = state.lifeAreas[i].id;
                  cubit.setArea(state.areaId == tapped ? null : tapped);
                },
              ),
            ],
            Gaps.vMd,
            Row(
              children: [
                Expanded(
                  child: TimePickerField(
                    label: 'Inicio',
                    valueText: state.startLabel,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: state.effectiveStartMinute ~/ 60,
                          minute: state.effectiveStartMinute % 60,
                        ),
                      );
                      if (picked != null) {
                        cubit.setStart(picked.hour, picked.minute);
                      }
                    },
                  ),
                ),
                Gaps.hSm,
                Expanded(
                  child: TimePickerField(
                    label: 'Fin',
                    valueText: state.endLabel,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        cubit.setEnd(picked.hour, picked.minute);
                      }
                    },
                  ),
                ),
              ],
            ),
            Gaps.vLg,
            PrimaryButton(label: 'Registrar evento', expanded: true, onPressed: cubit.submit),
          ],
        );
      },
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.suggestion, required this.selected, required this.onTap});

  final EventSuggestion suggestion;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: AppSpacing.cardDense,
      highlighted: selected,
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(suggestion.title, style: AppTextStyles.title),
                AppCaption(suggestion.subtitle),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppText.mono(suggestion.countLabel,
                  style: TextStyle(color: selected ? AppColors.accent : AppColors.textSecondary)),
              AppCaption(suggestion.avgLabel),
            ],
          ),
        ],
      ),
    );
  }
}
