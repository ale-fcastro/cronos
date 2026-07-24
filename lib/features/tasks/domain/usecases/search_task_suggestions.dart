import '../entities/task_suggestion.dart';
import '../repositories/tasks_repository.dart';

class SearchTaskSuggestions {
  const SearchTaskSuggestions(this._repository);

  final TasksRepository _repository;

  Future<List<TaskSuggestion>> call(String query) =>
      _repository.searchSuggestions(query);
}
