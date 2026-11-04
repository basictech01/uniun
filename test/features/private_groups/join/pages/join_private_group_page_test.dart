import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/common/atoms/uniun_button.dart';
import 'package:uniun/common/widgets/drop_loading_indicator.dart';
import 'package:uniun/features/private_groups/join/bloc/join_private_group_bloc.dart';
import 'package:uniun/features/private_groups/join/pages/join_private_group_page.dart';
import 'package:uniun/domain/usecases/get_relays_usecase.dart';
import 'package:uniun/l10n/app_localizations.dart';

class _MockBloc extends MockBloc<JoinPrivateGroupEvent, JoinPrivateGroupState>
    implements JoinPrivateGroupBloc {}

class _MockRelays extends Mock implements GetRelaysUseCase {}

class _FakeEvent extends Fake implements JoinPrivateGroupEvent {}

/// Covers: the submit button sends its event with the typed text, and while
/// submitting it shows the loader and ignores taps.
void main() {
  late _MockBloc bloc;

  setUpAll(() => registerFallbackValue(_FakeEvent()));

  setUp(() async {
    await GetIt.instance.reset();
    bloc = _MockBloc();
    
    final relays = _MockRelays();
    when(() => relays.call()).thenAnswer((_) async => const Right([]));
    GetIt.instance.registerFactory<GetRelaysUseCase>(() => relays);
    GetIt.instance.registerFactory<JoinPrivateGroupBloc>(() => bloc);
  });

  tearDown(() => GetIt.instance.reset());

  Future<void> pump(WidgetTester t, JoinPrivateGroupState state) async {
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, Stream<JoinPrivateGroupState>.empty(), initialState: state);
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: JoinPrivateGroupPage(),
      ),
    );
    await t.pump();
  }

  testWidgets('tapping the button sends the submit event', (t) async {
    await pump(t, JoinPrivateGroupState());
    await t.enterText(find.byType(TextField).first, 'abc');

    await t.ensureVisible(find.byType(UniunButton));
    await t.tap(find.byType(UniunButton));

    verify(() => bloc.add(any(that: isA<SubmitJoinPrivateGroupEvent>()))).called(1);
  });

  testWidgets('while submitting: loader shown, tap ignored', (t) async {
    await pump(t, JoinPrivateGroupState(isSubmitting: true));

    expect(find.byType(DropLoadingIndicator), findsWidgets);
    await t.ensureVisible(find.byType(UniunButton));
    await t.tap(find.byType(UniunButton), warnIfMissed: false);

    verifyNever(() => bloc.add(any(that: isA<SubmitJoinPrivateGroupEvent>())));
  });
}
