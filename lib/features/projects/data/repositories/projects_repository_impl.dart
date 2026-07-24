import '../../domain/entities/project.dart';
import '../../domain/repositories/projects_repository.dart';
import '../datasources/projects_local_datasource.dart';

class ProjectsRepositoryImpl implements ProjectsRepository {
  const ProjectsRepositoryImpl(this._datasource);

  final ProjectsLocalDatasource _datasource;

  @override
  Future<List<Project>> getProjects() => _datasource.fetchProjects();

  @override
  Future<void> createProject(String name) => _datasource.createProject(name);

  @override
  Future<void> deleteProject(String id) => _datasource.deleteProject(id);
}
