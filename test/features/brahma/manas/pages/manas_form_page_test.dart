import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/common/atoms/uniun_button.dart';
import 'package:uniun/features/brahma/manas/bloc/manas_form_bloc.dart';
import 'package:uniun/features/brahma/manas/pages/manas_form_page.dart';
import 'package:uniun/l10n/app_localizations.dart';

class _MockBloc extends MockBloc<ManasFormEvent, ManasFormState>
    implements ManasFormBloc {}

/// Covers: the Delete button shows only when editing, asks for confirmation,
/// and sends the delete event once confirmed.
void main() {
  late _MockBloc bloc;

  setUpAll(() => registerFallbackValue(const ManasFormDeleteEvent()));

  setUp(() async {
    await GetIt.instance.reset();
    bloc = _MockBloc();
    GetIt.instance.registerFactory<ManasFormBloc>(() => bloc);
  });

  tearDown(() => GetIt.instance.reset());

  Future<void> pump(WidgetTester t, {required bool edit}) async {
    final state = ManasFormState(
      status: ManasFormStatus.ready,
      isEditMode: edit,
      manasId: edit ? 'm1' : null,
      name: 'Reading',
    );
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, const Stream<ManasFormState>.empty(), initialState: state);
    t.view.physicalSize = const Size(1080, 3000);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ManasFormPage(manasId: edit ? 'm1' : null),
      ),
    );
    await t.pump();
  }

  testWidgets('create mode has no Delete button', (t) async {
    await pump(t, edit: false);

    expect(find.byType(UniunButton), findsNothing);
  });

  testWidgets('edit mode: Delete asks first, then sends the event', (t) async {
    await pump(t, edit: true);
    final l10n = AppLocalizations.of(t.element(find.byType(UniunButton)))!;

    await t.ensureVisible(find.byType(UniunButton));
    await t.tap(find.byType(UniunButton));
    await t.pumpAndSettle();
    verifyNever(() => bloc.add(any(that: isA<ManasFormDeleteEvent>())));

    await t.tap(find.text(l10n.manasFormDeleteConfirmConfirm));
    await t.pumpAndSettle();

    verify(() => bloc.add(any(that: isA<ManasFormDeleteEvent>()))).called(1);
  });

  testWidgets('cancelling the confirmation sends nothing', (t) async {
    await pump(t, edit: true);
    final l10n = AppLocalizations.of(t.element(find.byType(UniunButton)))!;

    await t.ensureVisible(find.byType(UniunButton));
    await t.tap(find.byType(UniunButton));
    await t.pumpAndSettle();
    await t.tap(find.text(l10n.manasFormDeleteConfirmCancel));
    await t.pumpAndSettle();

    verifyNever(() => bloc.add(any(that: isA<ManasFormDeleteEvent>())));
  });
}
