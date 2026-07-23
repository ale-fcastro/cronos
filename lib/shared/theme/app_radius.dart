import 'package:flutter/widgets.dart';

/// Radios de esquina. Tarjetas 12-16, chips 6-8, pill para timers/botones redondos.
abstract final class AppRadius {
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 10;
  static const double lg = 12;
  static const double xl = 14;
  static const double xxl = 16;
  static const double pill = 999;

  static const chip = BorderRadius.all(Radius.circular(xs));
  static const control = BorderRadius.all(Radius.circular(md));
  static const card = BorderRadius.all(Radius.circular(lg));
  static const cardLarge = BorderRadius.all(Radius.circular(xxl));
  static const rounded = BorderRadius.all(Radius.circular(pill));
}
