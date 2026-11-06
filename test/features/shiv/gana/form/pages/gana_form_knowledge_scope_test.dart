import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/common/atoms/uniun_button.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/domain/entities/llm/llm_backend_type.dart';
import 'package:uniun/domain/entities/manas/manas_entity.dart';
import 'package:uniun/domain/usecases/scheduler_usecases.dart';
import 'package:uniun/features/shiv/gana/form/bloc/gana_form_bloc.dart';
import 'package:uniun/features/shiv/gana/form/pages/gana_form_page.dart';
import 'package:uniun/l10n/app_localizations.dart';

class _MockFormBloc extends MockBloc<GanaFormEvent, GanaFormState>
    implements GanaFormBloc {}

class _MockSetForeground extends Mock implements SetForegroundKindUseCase {}

/// Covers: the knowledge-scope picker on the Gana form: No knowledge and
/// Brahma chips, their selection, the events they send, and the cloud warning.
void main() {
  late _MockFormBloc bloc;

  final manas = ManasEntity(
    manasId: 'm-1',
    name: 'Reading list',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  setUpAll(() {
    registerFallbackValue(const GanaFormSelectBrahmaEvent());
  });

  setUp(() async {
    bloc = _MockFormBloc();
    final fg = _MockSetForeground();
    when(() => fg.call(any())).thenAnswer((_) async => const Right(unit));
    await GetIt.instance.reset();
    GetIt.instance
      ..registerFactory<GanaFormBloc>(() => bloc)
      ..registerFactory<SetForegroundKindUseCase>(() => fg);
  });

  tearDown(() => GetIt.instance.reset());

  Future<void> show(WidgetTester t, GanaFormState state) async {
    t.view.physicalSize = const Size(800, 4000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    when(() => bloc.state).thenReturn(state);
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const GanaFormPage(),
      ),
    );
    await t.pump();
  }

  GanaFormState ready({
    bool noKnowledge = false,
    String? manasId,
    LlmBackendType? backend,
    List<ManasEntity>? manases,
  }) => GanaFormState(
    status: GanaFormStatus.ready,
    name: 'x',
    taskPrompt: 'y',
    noKnowledge: noKnowledge,
    selectedManasId: manasId,
    desiredBackend: backend,
    manases: manases ?? [manas],
  );

  FilterChip chip(WidgetTester t, String label) => t.widget<FilterChip>(
    find.ancestor(of: find.text(label), matching: find.byType(FilterChip)),
  );

  testWidgets('a new Gana starts on Brahma, not on no knowledge', (t) async {
    await show(t, ready());

    expect(chip(t, 'Brahma').selected, isTrue);
    expect(chip(t, 'No knowledge').selected, isFalse);
  });

  testWidgets('no knowledge shows as the selected choice', (t) async {
    await show(t, ready(noKnowledge: true));

    expect(chip(t, 'No knowledge').selected, isTrue);
    expect(chip(t, 'Brahma').selected, isFalse);
  });

  testWidgets('a picked Manas leaves both of those unselected', (t) async {
    await show(t, ready(manasId: 'm-1'));

    expect(chip(t, 'No knowledge').selected, isFalse);
    expect(chip(t, 'Brahma').selected, isFalse);
    expect(chip(t, 'Reading list').selected, isTrue);
  });

  testWidgets('tapping No knowledge sends its event', (t) async {
    await show(t, ready());

    await t.tap(find.text('No knowledge'));

    verify(
      () => bloc.add(any(that: isA<GanaFormSelectNoKnowledgeEvent>())),
    ).called(1);
  });

  testWidgets('tapping Brahma sends its event', (t) async {
    await show(t, ready(noKnowledge: true));

    await t.tap(find.text('Brahma'));

    verify(
      () => bloc.add(any(that: isA<GanaFormSelectBrahmaEvent>())),
    ).called(1);
  });

  testWidgets('both choices are there even with no Manases yet', (t) async {
    await show(t, ready(manases: const []));

    expect(find.text('No knowledge'), findsOneWidget);
    expect(find.text('Brahma'), findsOneWidget);
  });

  testWidgets('Brahma with a cloud model shows the privacy warning', (t) async {
    await show(t, ready(backend: LlmBackendType.uniunCloud));

    expect(
      find.byKey(const ValueKey('gana-brahma-cloud-warning')),
      findsOneWidget,
    );
  });

  testWidgets('no warning for no knowledge, a Manas or a local model', (
    t,
  ) async {
    for (final s in [
      ready(backend: LlmBackendType.uniunCloud, noKnowledge: true),
      ready(backend: LlmBackendType.uniunCloud, manasId: 'm-1'),
      ready(backend: LlmBackendType.localGemma),
      ready(),
    ]) {
      await show(t, s);
      expect(
        find.byKey(const ValueKey('gana-brahma-cloud-warning')),
        findsNothing,
      );
    }
  });

  testWidgets('Save sends the submit event when the Gana can be saved',
      (t) async {
    registerFallbackValue(const GanaFormSubmitEvent());
    await show(
      t,
      ready().copyWith(triggerIntervalMinutes: 30, maxOutputs: 10),
    );

    await t.tap(find.byType(UniunButton).last);

    verify(() => bloc.add(any(that: isA<GanaFormSubmitEvent>()))).called(1);
  });

  testWidgets('Save does nothing while the Gana is incomplete', (t) async {
    registerFallbackValue(const GanaFormSubmitEvent());
    await show(t, ready().copyWith(name: ''));

    await t.tap(find.byType(UniunButton).last, warnIfMissed: false);

    verifyNever(() => bloc.add(any(that: isA<GanaFormSubmitEvent>())));
  });
}
