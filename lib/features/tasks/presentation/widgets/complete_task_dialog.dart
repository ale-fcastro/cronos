import 'package:flutter/material.dart';

import '../../../../shared/shared.dart';

/// Resultado de [CompleteTaskDialog]: o se completó (con el horario real
/// si hubo que preguntarlo), o se marcó como no hecha (con el motivo).
sealed class CompleteTaskResult {}

class CompleteTaskDone extends CompleteTaskResult {
  CompleteTaskDone({this.start, this.end});
  final DateTime? start;
  final DateTime? end;
}

class CompleteTaskFailed extends CompleteTaskResult {
  CompleteTaskFailed(this.reason);
  final String reason;
}

/// Pregunta si la tarea [title] realmente se hizo antes de dejarla
/// finalizar — no se puede completar "porque sí". Si dice que sí y nunca
/// hubo cronómetro de por medio ([hasTrackedTime] = false), pide el
/// horario real para que quede alguna evidencia. Si dice que no, exige un
/// motivo antes de marcarla como no hecha. Devuelve null si cancela.
Future<CompleteTaskResult?> showCompleteTaskDialog(
  BuildContext context, {
  required String title,
  required bool hasTrackedTime,
}) {
  return showDialog<CompleteTaskResult>(
    context: context,
    builder: (_) => _CompleteTaskDialog(title: title, hasTrackedTime: hasTrackedTime),
  );
}

enum _Step { ask, whenDone, whyNot }

class _CompleteTaskDialog extends StatefulWidget {
  const _CompleteTaskDialog({required this.title, required this.hasTrackedTime});

  final String title;
  final bool hasTrackedTime;

  @override
  State<_CompleteTaskDialog> createState() => _CompleteTaskDialogState();
}

class _CompleteTaskDialogState extends State<_CompleteTaskDialog> {
  _Step _step = _Step.ask;
  TimeOfDay _start = TimeOfDay.now();
  TimeOfDay _end = TimeOfDay.now();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
      helpText: isStart ? 'Empezaste a las' : 'Terminaste a las',
    );
    if (picked == null) return;
    setState(() => isStart ? _start = picked : _end = picked);
  }

  DateTime _todayAt(TimeOfDay t) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, t.hour, t.minute);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: switch (_step) {
          _Step.ask => _askView(),
          _Step.whenDone => _whenDoneView(),
          _Step.whyNot => _whyNotView(),
        },
      ),
    );
  }

  Widget _askView() {
    final question = widget.hasTrackedTime
        ? '¿Ya terminaste "${widget.title}"?'
        : '¿Hiciste "${widget.title}"?';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question, style: AppTextStyles.headline.copyWith(fontSize: 18)),
        Gaps.vSm,
        const AppCaption('No se puede finalizar una tarea sin confirmar esto.'),
        Gaps.vXl,
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: 'No, todavía no',
                onPressed: () => setState(() => _step = _Step.whyNot),
              ),
            ),
            Gaps.hSm,
            Expanded(
              child: PrimaryButton(
                label: 'Sí, la hice',
                onPressed: () {
                  if (widget.hasTrackedTime) {
                    Navigator.of(context).pop(CompleteTaskDone());
                  } else {
                    setState(() => _step = _Step.whenDone);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _whenDoneView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('¿En qué horario lo hiciste?', style: AppTextStyles.headline.copyWith(fontSize: 18)),
        Gaps.vSm,
        const AppCaption(
          'Esta tarea nunca se arrancó con el cronómetro — contanos cuándo '
          'la hiciste de verdad.',
        ),
        Gaps.vLg,
        Row(
          children: [
            Expanded(
              child: TimePickerField(
                label: 'Empezó',
                valueText: _start.format(context),
                onTap: () => _pickTime(isStart: true),
              ),
            ),
            Gaps.hSm,
            Expanded(
              child: TimePickerField(
                label: 'Terminó',
                valueText: _end.format(context),
                onTap: () => _pickTime(isStart: false),
              ),
            ),
          ],
        ),
        Gaps.vXl,
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: 'Atrás',
                onPressed: () => setState(() => _step = _Step.ask),
              ),
            ),
            Gaps.hSm,
            Expanded(
              child: PrimaryButton(
                label: 'Listo',
                onPressed: () {
                  var start = _todayAt(_start);
                  var end = _todayAt(_end);
                  if (!end.isAfter(start)) end = end.add(const Duration(days: 1));
                  Navigator.of(context).pop(CompleteTaskDone(start: start, end: end));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _whyNotView() {
    final reason = _reasonController.text.trim();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Se va a marcar como no hecha', style: AppTextStyles.headline.copyWith(fontSize: 18)),
        Gaps.vSm,
        const AppCaption('Contanos qué pasó, para que quede en el historial.'),
        Gaps.vLg,
        AppTextField(
          label: 'Motivo',
          hint: 'Me quedé sin tiempo, surgió otra cosa…',
          controller: _reasonController,
          onChanged: (_) => setState(() {}),
        ),
        Gaps.vXl,
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: 'Atrás',
                onPressed: () => setState(() => _step = _Step.ask),
              ),
            ),
            Gaps.hSm,
            Expanded(
              child: PrimaryButton(
                label: 'Marcar como no hecha',
                onPressed: reason.isEmpty
                    ? null
                    : () => Navigator.of(context).pop(CompleteTaskFailed(reason)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
