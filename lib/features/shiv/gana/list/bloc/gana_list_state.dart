part of 'gana_list_bloc.dart';

enum GanaListStatus { initial, loading, ready, error }

class GanaListState {
  const GanaListState({
    this.status = GanaListStatus.initial,
    this.ganas = const [],
    this.lastRuns = const {},
    this.recentRuns = const {},
    this.errorMessage,
  });

  final GanaListStatus status;
  final List<GanaEntity> ganas;
  final Map<String, GanaRunEntity?> lastRuns;

  /// Newest-first run log per Gana (the last 10 the log keeps).
  final Map<String, List<GanaRunEntity>> recentRuns;
  final String? errorMessage;

  GanaListState copyWith({
    GanaListStatus? status,
    List<GanaEntity>? ganas,
    Map<String, GanaRunEntity?>? lastRuns,
    Map<String, List<GanaRunEntity>>? recentRuns,
    String? errorMessage,
  }) =>
      GanaListState(
        status: status ?? this.status,
        ganas: ganas ?? this.ganas,
        lastRuns: lastRuns ?? this.lastRuns,
        recentRuns: recentRuns ?? this.recentRuns,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}
