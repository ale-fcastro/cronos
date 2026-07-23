import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Campo de busqueda compacto con icono.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    this.hint = 'Buscar',
    this.controller,
    this.onChanged,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded,
            size: 20, color: AppColors.textTertiary),
        isDense: true,
      ),
    );
  }
}
