import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/diagnostics/error_reporting.dart';
import '../../domain/usecases/projects_usecases.dart';
import 'projects_state.dart';

class ProjectsCubit extends Cubit<ProjectsState> {
  ProjectsCubit(this._getProjects, this._createProject, this._deleteProject)
      : super(const ProjectsState()) {
    load();
  }

  final GetProjects _getProjects;
  final CreateProject _createProject;
  final DeleteProject _deleteProject;

  Future<void> load() async {
    try {
      final projects = await _getProjects();
      if (isClosed) return;
      emit(ProjectsState(projects: projects, loading: false));
    } catch (e, st) {
      reportError('ProjectsCubit.load', e, st);
    }
  }

  Future<void> add(String name) async {
    if (name.trim().isEmpty) return;
    try {
      await _createProject(name);
      await load();
    } catch (e, st) {
      reportError('ProjectsCubit.add', e, st);
    }
  }

  Future<void> remove(String id) async {
    try {
      await _deleteProject(id);
      await load();
    } catch (e, st) {
      reportError('ProjectsCubit.remove', e, st);
    }
  }
}
