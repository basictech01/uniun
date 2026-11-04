import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/common/atoms/uniun_button.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/domain/usecases/app_settings_usecases.dart';
import 'package:uniun/domain/usecases/llm_usecases.dart';
import 'package:uniun/domain/usecases/scheduler_usecases.dart';
import 'package:uniun/features/shiv/nataraj/bloc/nataraj_bloc.dart';
import 'package:uniun/features/shiv/nataraj/pages/nataraj_deck_page.dart';
import 'package:uniun/l10n/app_localizations.dart';

class _MockBloc extends MockBloc<NatarajEvent, NatarajState>
    implements NatarajBloc {}

class _MockForeground extends Mock implements SetForegroundKindUseCase {}

class _MockCoachSeen extends Mock implements GetNatarajCoachSeenUseCase {}

class _MockHasModel extends Mock implements HasActiveLlmModelUseCase {}

/// Covers: the error screen's Change model opens model selection; the no-idea
/// screen's Retry reloads the deck.
void main() {
  late _MockBloc bloc;
  late List<String> visited;

  setUpAll(() => registerFallbackValue(const NatarajEvent.loadDeck([])));

  setUp(() async {
    await GetIt.instance.reset();
    bloc = _MockBloc();
    visited = [];
    final fg = _MockForeground();
    final seen = _MockCoachSeen();
    final hasModel = _MockHasModel();
    when(() => fg.call(any())).thenAnswer((_) async => const Right(unit));
    when(() => seen.call()).thenAnswer((_) async => const Right(true));
    when(() => hasModel.call()).thenAnswer((_) async => true);
    GetIt.instance
      ..registerFactory<NatarajBloc>(() => bloc)
      ..registerFactory<SetForegroundKindUseCase>(() => fg)
      ..registerFactory<GetNatarajCoachSeenUseCase>(() => seen)
      ..registerFactory<HasActiveLlmModelUseCase>(() => hasModel);
  });

  tearDown(() => GetIt.instance.reset());

  Future<void> pump(WidgetTester t, NatarajStatus status) async {
    final state = NatarajState(status: status, manasIds: const ['m1']);
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, const Stream<NatarajState>.empty(), initialState: state);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const NatarajDeckPage()),
        GoRoute(
          path: '/models',
          name: AppRoutes.aiModelSelection,
          builder: (_, _) {
            visited.add('models');
            return const SizedBox();
          },
        ),
      ],
    );
    await t.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await t.pump();
    await t.pump();
  }

  testWidgets('error: Change model opens model selection', (t) async {
    await pump(t, NatarajStatus.error);

    await t.tap(find.byType(UniunButton));
    await t.pumpAndSettle();

    expect(visited, ['models']);
  });

  testWidgets('no idea: Retry reloads the deck', (t) async {
    await pump(t, NatarajStatus.noIdea);

    await t.tap(find.byType(UniunButton));

    verify(
      () => bloc.add(const NatarajEvent.loadDeck(['m1'])),
    ).called(greaterThanOrEqualTo(1));
  });
}
