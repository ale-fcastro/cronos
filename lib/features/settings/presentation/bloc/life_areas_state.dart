import 'package:equatable/equatable.dart';
import '../../../../core/models/life_area.dart';

class LifeAreasState extends Equatable {
  const LifeAreasState({this.areas = const [], this.loading = true});

  final List<LifeArea> areas;
  final bool loading;

  LifeAreasState copyWith({List<LifeArea>? areas, bool? loading}) {
    return LifeAreasState(
      areas: areas ?? this.areas,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [areas, loading];
}
