import 'package:flutter/material.dart';

/// Mapa semantico de iconos (Material Symbols, trazo simple).
/// Los widgets referencian AppIcons.x, nunca Icons.x directamente,
/// para poder cambiar el set completo en un solo lugar.
abstract final class AppIcons {
  // Navegacion
  static const today = Icons.radio_button_checked_outlined;
  static const agenda = Icons.subject_rounded;
  static const tasks = Icons.check_box_outlined;
  static const analyze = Icons.bar_chart_rounded;
  static const add = Icons.add_rounded;
  static const back = Icons.chevron_left_rounded;
  static const forward = Icons.chevron_right_rounded;
  static const close = Icons.close_rounded;
  static const expand = Icons.keyboard_arrow_down_rounded;

  // Tracking
  static const play = Icons.play_arrow_rounded;
  static const pause = Icons.pause_rounded;
  static const stop = Icons.stop_rounded;
  static const timer = Icons.schedule_rounded;

  // Estado
  static const done = Icons.check_rounded;
  static const late_ = Icons.error_outline_rounded;
  static const trendUp = Icons.arrow_drop_up_rounded;
  static const trendDown = Icons.arrow_drop_down_rounded;

  // Otros
  static const settings = Icons.settings_outlined;
  static const notes = Icons.notes_rounded;
  static const project = Icons.folder_outlined;
  static const category = Icons.label_outline_rounded;
  static const delete = Icons.delete_outline_rounded;
  static const edit = Icons.edit_outlined;
}
