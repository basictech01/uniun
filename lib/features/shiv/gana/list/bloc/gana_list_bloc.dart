import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/data/models/gana_model.dart';
import 'package:uniun/domain/entities/gana/gana_entity.dart';
import 'package:uniun/domain/entities/gana/gana_run_entity.dart';
import 'package:uniun/domain/usecases/gana_usecases.dart';

part 'gana_list_event.dart';
part 'gana_list_state.dart';

/// Backs the Shiv drawer's Ganas section. Reactively reloads on any change
/// to the `Gana` collection.
@injectable
class GanaListBloc extends Bloc<GanaListEvent, GanaListState> {
  final GetGanasUseCase _getGanas;
  final GetGanaRunsUseCase _getRuns;
  final SetGanaEnabledUseCase _setEnabled;
  final DeleteGanaUseCase _delete;
  final Isar _isar;

  StreamSubscription<void>? _watcher;

  GanaListBloc(
    this._getGanas,
    this._getRuns,
    this._setEnabled,
    this._delete,
    this._isar,
  ) : super(const GanaListState()) {
    on<GanaListLoadEvent>(_onLoad, transformer: droppable());
    on<GanaListToggleEnabledEvent>(_onToggle, transformer: sequential());
    on<GanaListDeleteEvent>(_onDelete, transformer: sequential());
    on<_GanaListWatcherTickEvent>(_onWatcherTick, transformer: droppable());

    _watcher = _isar.ganaModels.watchLazy().listen((_) {
      if (!isClosed) add(const _GanaListWatcherTickEvent());
    });
  }

  @override
  Future<void> close() async {
    await _watcher?.cancel();
    return super.close();
  }

  Future<void> _onLoad(
      GanaListLoadEvent event, Emitter<GanaListState> emit) async {
    emit(state.copyWith(status: GanaListStatus.loading));
    await _refresh(emit);
  }

  Future<void> _onWatcherTick(
      _GanaListWatcherTickEvent event, Emitter<GanaListState> emit) async {
    // Don't flip back to loading — refresh silently to keep the drawer UX calm.
    await _refresh(emit);
  }

  Future<void> _refresh(Emitter<GanaListState> emit) async {
    final result = await _getGanas.call();
    final ganas = result.fold<List<GanaEntity>>((_) => const [], (l) => l);

    // Fetch most-recent run per Gana in parallel.
    final lastRuns = <String, GanaRunEntity?>{};
    final recentRuns = <String, List<GanaRunEntity>>{};
    for (final g in ganas) {
      final r = await _getRuns.call(g.ganaId);
      final runs = r.fold<List<GanaRunEntity>>((_) => const [], (l) => l);
      recentRuns[g.ganaId] = runs;
      lastRuns[g.ganaId] = runs.isEmpty ? null : runs.first;
    }

    emit(state.copyWith(
      status: GanaListStatus.ready,
      ganas: ganas,
      lastRuns: lastRuns,
      recentRuns: recentRuns,
    ));
  }

  Future<void> _onToggle(
      GanaListToggleEnabledEvent event, Emitter<GanaListState> emit) async {
    await _setEnabled.call(GanaToggleInput(event.ganaId, event.enabled));
    // Watcher will refresh; nothing else to do here.
  }

  Future<void> _onDelete(
      GanaListDeleteEvent event, Emitter<GanaListState> emit) async {
    await _delete.call(event.ganaId);
    // Watcher will refresh.
  }
}
