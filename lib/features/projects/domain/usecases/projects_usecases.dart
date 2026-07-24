import '../entities/project.dart';
import '../repositories/projects_repository.dart';

class GetProjects {
  const GetProjects(this._repository);
  final ProjectsRepository _repository;
  Future<List<Project>> call() => _repository.getProjects();
}

class CreateProject {
  const CreateProject(this._repository);
  final ProjectsRepository _repository;
  Future<void> call(String name) => _repository.createProject(name);
}

class DeleteProject {
  const DeleteProject(this._repository);
  final ProjectsRepository _repository;
  Future<void> call(String id) => _repository.deleteProject(id);
}
