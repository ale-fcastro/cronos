import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Tipografia Cronos: IBM Plex Sans para UI, IBM Plex Mono para toda cifra.
/// Los numeros son el producto: cualquier dato numerico usa un estilo *mono*.
abstract final class AppTextStyles {
  static const sans = 'IBMPlexSans';
  static const mono = 'IBMPlexMono';

  // Titulares
  static const headlineLarge = TextStyle(
      fontFamily: sans, fontSize: 24, fontWeight: FontWeight.w700,
      letterSpacing: -0.3, color: AppColors.textPrimary);
  static const headline = TextStyle(
      fontFamily: sans, fontSize: 22, fontWeight: FontWeight.w700,
      color: AppColors.textPrimary);
  static const title = TextStyle(
      fontFamily: sans, fontSize: 14, fontWeight: FontWeight.w600,
      color: AppColors.textPrimary);
  static const subtitle = TextStyle(
      fontFamily: sans, fontSize: 12, color: AppColors.textSecondary);

  // Cuerpo
  static const body = TextStyle(
      fontFamily: sans, fontSize: 13, color: AppColors.textPrimary, height: 1.45);
  static const bodySecondary = TextStyle(
      fontFamily: sans, fontSize: 13, color: AppColors.textSecondary, height: 1.45);
  static const label = TextStyle(
      fontFamily: sans, fontSize: 11, color: AppColors.textSecondary);
  static const caption = TextStyle(
      fontFamily: sans, fontSize: 10.5, color: AppColors.textTertiary);
  static const overline = TextStyle(
      fontFamily: sans, fontSize: 11, letterSpacing: 0.5,
      color: AppColors.textTertiary);

  // Cifras (mono)
  static const metricDisplay = TextStyle(
      fontFamily: mono, fontSize: 38, fontWeight: FontWeight.w600,
      letterSpacing: -1, color: AppColors.textPrimary);
  static const metricLarge = TextStyle(
      fontFamily: mono, fontSize: 26, fontWeight: FontWeight.w600,
      color: AppColors.textPrimary);
  static const metric = TextStyle(
      fontFamily: mono, fontSize: 20, fontWeight: FontWeight.w600,
      color: AppColors.textPrimary);
  static const metricMedium = TextStyle(
      fontFamily: mono, fontSize: 15, fontWeight: FontWeight.w600,
      color: AppColors.textPrimary);
  static const metricSmall = TextStyle(
      fontFamily: mono, fontSize: 12, color: AppColors.textSecondary);
  static const metricCaption = TextStyle(
      fontFamily: mono, fontSize: 11, color: AppColors.textTertiary);
}
