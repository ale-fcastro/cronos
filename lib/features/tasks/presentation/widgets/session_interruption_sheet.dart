import 'package:flutter/material.dart';

import '../../../../core/models/event_category.dart';
import '../../../../core/models/life_area.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../shared/shared.dart';
import '../../domain/entities/task_detail.dart';

class SessionInterruptionDraft {
  const SessionInterruptionDraft({
    required this.startedAt,
    required this.endedAt,
    required this.reason,
    this.areaId,
  });

  final DateTime startedAt;
  final DateTime endedAt;
  final String reason;
  final String? areaId;
}

/// Selector visual de un tramo improductivo dentro de una sesión.
/// Los extremos de la barra representan el inicio y fin reales de la sesión;
/// el segmento acentuado se convertirá en Evento y dejará de sumar a la tarea.
Future<SessionInterruptionDraft?> showSessionInterruptionSheet(
  BuildContext context, {
  required TaskSession session,
  required List<LifeArea> lifeAreas,
}) {
  return showModalBottomSheet<SessionInterruptionDraft>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _SessionInterruptionSheet(session: session, lifeAreas: lifeAreas),
  );
}

class _SessionInterruptionSheet extends StatefulWidget {
  const _SessionInterruptionSheet(
      {required this.session, required this.lifeAreas});

  final TaskSession session;
  final List<LifeArea> lifeAreas;

  @override
  State<_SessionInterruptionSheet> createState() =>
      _SessionInterruptionSheetState();
}

class _SessionInterruptionSheetState extends State<_SessionInterruptionSheet> {
  late final DateTime _effectiveEnd;
  late final double _durationSeconds;
  late RangeValues _range;
  String _reason = eventCategories.first;
  String? _areaId;

  @override
  void initState() {
    super.initState();
    _effectiveEnd = widget.session.endedAt ?? DateTime.now();
    _durationSeconds =
        _effectiveEnd.difference(widget.session.startedAt).inSeconds.toDouble();
    _range = RangeValues(_durationSeconds / 3, _durationSeconds * 2 / 3);
  }

  DateTime _at(double seconds) =>
      widget.session.startedAt.add(Duration(seconds: seconds.round()));

  String _durationLabel(RangeValues values) {
    final minutes = ((values.end - values.start) / 60).round();
    return minutes < 60 ? '${minutes}m' : '${minutes ~/ 60}h ${minutes % 60}m';
  }

  @override
  Widget build(BuildContext context) {
    final max = _durationSeconds.clamp(1, double.infinity).toDouble();
    final canSave = _range.end - _range.start >= 60 &&
        _range.start > 0 &&
        _range.end < _durationSeconds;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        MediaQuery.viewPaddingOf(context).bottom + AppSpacing.xl,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                    child:
                        Text('Corregir tiempo', style: AppTextStyles.headline)),
                AppIconButton(
                  icon: AppIcons.close,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Gaps.vSm,
            Text(
              'Marcá en la barra cuándo empezó y terminó la interrupción.',
              style:
                  AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
            Gaps.vLg,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.mono(fmtTime(widget.session.startedAt)),
                Text(
                  '${fmtTime(_at(_range.start))} — ${fmtTime(_at(_range.end))}',
                  style: AppTextStyles.title.copyWith(color: AppColors.accent),
                ),
                AppText.mono(fmtTime(_effectiveEnd)),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.accent,
                inactiveTrackColor: AppColors.surfaceContainer,
                rangeThumbShape:
                    const RoundRangeSliderThumbShape(enabledThumbRadius: 11),
                trackHeight: 10,
              ),
              child: RangeSlider(
                min: 0,
                max: max,
                divisions: (_durationSeconds / 60).floor().clamp(2, 240),
                values: RangeValues(
                  _range.start.clamp(0, max),
                  _range.end.clamp(0, max),
                ),
                labels: RangeLabels(
                    fmtTime(_at(_range.start)), fmtTime(_at(_range.end))),
                onChanged: _durationSeconds < 120
                    ? null
                    : (value) => setState(() {
                          _range = value;
                        }),
              ),
            ),
            Center(
              child: StatusBadge(
                label: '${_durationLabel(_range)} que no sumarán a la tarea',
                color: AppColors.accent,
              ),
            ),
            Gaps.vLg,
            const Text('¿Qué pasó?', style: AppTextStyles.label),
            Gaps.vSm,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final reason in eventCategories)
                  ChoiceChip(
                    label: Text(reason),
                    selected: _reason == reason,
                    onSelected: (_) => setState(() => _reason = reason),
                  ),
              ],
            ),
            if (widget.lifeAreas.isNotEmpty) ...[
              Gaps.vLg,
              const Text('Área de vida (opcional)', style: AppTextStyles.label),
              Gaps.vSm,
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final area in widget.lifeAreas)
                    ChoiceChip(
                      avatar:
                          CircleAvatar(backgroundColor: area.color, radius: 5),
                      label: Text(area.name),
                      selected: _areaId == area.id,
                      onSelected: (selected) =>
                          setState(() => _areaId = selected ? area.id : null),
                    ),
                ],
              ),
            ],
            Gaps.vXl,
            PrimaryButton(
              label: 'Separar interrupción',
              onPressed: !canSave
                  ? null
                  : () => Navigator.of(context).pop(
                        SessionInterruptionDraft(
                          startedAt: _at(_range.start),
                          endedAt: _at(_range.end),
                          reason: _reason,
                          areaId: _areaId,
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
