import 'package:flutter/material.dart' show Color;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/diagnostics/error_reporting.dart';
import '../../../../core/services/life_areas_service.dart';
import 'life_areas_state.dart';

class LifeAreasCubit extends Cubit<LifeAreasState> {
  LifeAreasCubit(this._service) : super(const LifeAreasState()) {
    load();
  }

  final LifeAreasService _service;

  Future<void> load() async {
    try {
      final areas = await _service.getAll();
      if (isClosed) return;
      emit(LifeAreasState(areas: areas, loading: false));
    } catch (e, st) {
      reportError('LifeAreasCubit.load', e, st);
    }
  }

  Future<void> create(String name, Color color) async {
    if (name.trim().isEmpty) return;
    try {
      await _service.create(name.trim(), color);
      await load();
    } catch (e, st) {
      reportError('LifeAreasCubit.create', e, st);
    }
  }

  Future<void> update(String id, String name, Color color) async {
    if (name.trim().isEmpty) return;
    try {
      await _service.update(id, name.trim(), color);
      await load();
    } catch (e, st) {
      reportError('LifeAreasCubit.update', e, st);
    }
  }

  Future<void> remove(String id) async {
    try {
      await _service.delete(id);
      await load();
    } catch (e, st) {
      reportError('LifeAreasCubit.remove', e, st);
    }
  }
}
