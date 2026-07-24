import '../entities/project.dart';

abstract interface class ProjectsRepository {
  Future<List<Project>> getProjects();
  Future<void> createProject(String name);
  Future<void> deleteProject(String id);
}
