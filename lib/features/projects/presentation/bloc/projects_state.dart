import 'package:equatable/equatable.dart';
import '../../domain/entities/project.dart';

class ProjectsState extends Equatable {
  const ProjectsState({this.projects = const [], this.loading = true});

  final List<Project> projects;
  final bool loading;

  ProjectsState copyWith({List<Project>? projects, bool? loading}) {
    return ProjectsState(
      projects: projects ?? this.projects,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [projects, loading];
}
