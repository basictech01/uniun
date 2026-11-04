import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/common/atoms/uniun_button.dart';
import 'package:uniun/common/widgets/drop_loading_indicator.dart';
import 'package:uniun/domain/usecases/get_relays_usecase.dart';
import 'package:uniun/features/dm/create/bloc/create_dm_bloc.dart';
import 'package:uniun/features/dm/create/pages/create_dm_page.dart';
import 'package:uniun/l10n/app_localizations.dart';

class _MockBloc extends MockBloc<CreateDmEvent, CreateDmState>
    implements CreateDmBloc {}

class _MockRelays extends Mock implements GetRelaysUseCase {}

/// Covers: the Start chat button sends the typed recipient, and while
/// submitting shows the loader and ignores taps.
void main() {
  late _MockBloc bloc;

  setUpAll(() => registerFallbackValue(LoadRelaysEvent()));

  setUp(() async {
    await GetIt.instance.reset();
    bloc = _MockBloc();
    final relays = _MockRelays();
    when(() => relays.call()).thenAnswer((_) async => const Right([]));
    GetIt.instance.registerFactory<GetRelaysUseCase>(() => relays);
    GetIt.instance.registerFactory<CreateDmBloc>(() => bloc);
  });

  tearDown(() => GetIt.instance.reset());

  Future<void> pump(WidgetTester t, CreateDmState state) async {
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, Stream<CreateDmState>.empty(), initialState: state);
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CreateDmPage(),
      ),
    );
    await t.pump();
  }

  testWidgets('tapping Start chat sends the typed recipient', (t) async {
    await pump(t, CreateDmState());
    await t.enterText(find.byType(TextField).first, 'abc123');

    await t.ensureVisible(find.byType(UniunButton).last);
    await t.tap(find.byType(UniunButton).last);

    final event = verify(() => bloc.add(captureAny())).captured
        .whereType<SubmitDmEvent>()
        .single;
    expect(event.otherPubkey, 'abc123');
  });

  testWidgets('while submitting: loader shown, tap ignored', (t) async {
    await pump(t, CreateDmState(isSubmitting: true));

    expect(find.byType(DropLoadingIndicator), findsWidgets);
    await t.ensureVisible(find.byType(UniunButton).last);
    await t.tap(find.byType(UniunButton).last, warnIfMissed: false);

    verifyNever(() => bloc.add(any(that: isA<SubmitDmEvent>())));
  });
}
