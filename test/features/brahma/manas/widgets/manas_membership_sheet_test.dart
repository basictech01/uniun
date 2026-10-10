import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/manas/manas_entity.dart';
import 'package:uniun/domain/usecases/manas_usecases.dart';
import 'package:uniun/features/brahma/manas/widgets/manas_membership_sheet.dart';
import 'package:uniun/l10n/app_localizations.dart';

class _MGetList extends Mock implements GetManasListUseCase {}

class _MGetMemberships extends Mock implements GetManasIdsForNoteUseCase {}

class _MAdd extends Mock implements AddNoteToManasUseCase {}

class _MRemove extends Mock implements RemoveNoteFromManasUseCase {}

ManasEntity _manas(String id, {int count = 0, String? icon}) => ManasEntity(
      manasId: id,
      name: id,
      iconName: icon,
      noteCount: count,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

/// Widget tests for [ManasMembershipSheet]. The sheet reads its use cases
/// directly from `getIt`, so we register mock use cases per test. Verifies:
///   - Loads memberships on open; tiles render with the right check state
///   - Tapping an unchecked tile calls `AddNoteToManas` and re-fetches the list
///   - Tapping a checked tile calls `RemoveNoteFromManas`
///   - Empty Manas list still renders the sheet chrome
void main() {
  late _MGetList getList;
  late _MGetMemberships getMemberships;
  late _MAdd addLink;
  late _MRemove removeLink;

  setUpAll(() {
    registerFallbackValue(const ManasNoteLink('m', 'n'));
  });

  setUp(() async {
    getList = _MGetList();
    getMemberships = _MGetMemberships();
    addLink = _MAdd();
    removeLink = _MRemove();
    await GetIt.instance.reset();
    GetIt.instance.registerFactory<GetManasListUseCase>(() => getList);
    GetIt.instance.registerFactory<GetManasIdsForNoteUseCase>(() => getMemberships);
    GetIt.instance.registerFactory<AddNoteToManasUseCase>(() => addLink);
    GetIt.instance.registerFactory<RemoveNoteFromManasUseCase>(() => removeLink);
  });

  Widget host(String noteId) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: Builder(
        builder: (ctx) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => ManasMembershipSheet.show(ctx, noteId),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders a tile per Manas with correct check state', (tester) async {
    when(() => getList.call()).thenAnswer((_) async => Right([
          _manas('Work'),
          _manas('Research'),
          _manas('Personal'),
        ]));
    when(() => getMemberships.call('note-1'))
        .thenAnswer((_) async => const Right(['Research']));

    await tester.pumpWidget(host('note-1'));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Work'), findsOneWidget);
    expect(find.text('Research'), findsOneWidget);
    expect(find.text('Personal'), findsOneWidget);

    // One tile is "checked" (Research). The sheet uses Icons.check_circle to
    // mark inclusion — assert exactly one shows.
    final checks = find.byIcon(Icons.check_circle_rounded);
    expect(checks, findsOneWidget);
  });

  testWidgets('tapping an unchecked tile calls AddNoteToManas + refreshes', (tester) async {
    when(() => getList.call())
        .thenAnswer((_) async => Right([_manas('Work'), _manas('Personal')]));
    when(() => getMemberships.call('note-1'))
        .thenAnswer((_) async => const Right([]));
    when(() => addLink.call(any())).thenAnswer((_) async => const Right(unit));

    await tester.pumpWidget(host('note-1'));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Work'));
    await tester.pumpAndSettle();

    final captured =
        verify(() => addLink.call(captureAny())).captured.cast<ManasNoteLink>();
    expect(captured.single.manasId, 'Work');
    expect(captured.single.noteId, 'note-1');
    verifyNever(() => removeLink.call(any()));
    // Refresh: getList is called at least twice (initial + post-toggle).
    verify(() => getList.call()).called(greaterThanOrEqualTo(2));
  });

  testWidgets('tapping a checked tile calls RemoveNoteFromManas', (tester) async {
    when(() => getList.call())
        .thenAnswer((_) async => Right([_manas('Work', count: 1)]));
    when(() => getMemberships.call('note-1'))
        .thenAnswer((_) async => const Right(['Work']));
    when(() => removeLink.call(any()))
        .thenAnswer((_) async => const Right(unit));

    await tester.pumpWidget(host('note-1'));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Work'));
    await tester.pumpAndSettle();

    final captured =
        verify(() => removeLink.call(captureAny())).captured.cast<ManasNoteLink>();
    expect(captured.single.manasId, 'Work');
    expect(captured.single.noteId, 'note-1');
    verifyNever(() => addLink.call(any()));
  });

  testWidgets('reopening for another note starts from its own memberships',
      (tester) async {
    when(() => getList.call())
        .thenAnswer((_) async => Right([_manas('Work', count: 1)]));
    when(() => getMemberships.call('note-1'))
        .thenAnswer((_) async => const Right(['Work']));
    when(() => getMemberships.call('note-2'))
        .thenAnswer((_) async => const Right([]));
    when(() => addLink.call(any())).thenAnswer((_) async => const Right(unit));

    await tester.pumpWidget(host('note-1'));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    Navigator.of(tester.element(find.byType(ManasMembershipSheet))).pop();
    await tester.pumpAndSettle();
    await tester.pumpWidget(host('note-2'));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsOneWidget);
    await tester.tap(find.text('Work'));
    await tester.pumpAndSettle();

    final link =
        verify(() => addLink.call(captureAny())).captured.single as ManasNoteLink;
    expect(link.noteId, 'note-2');
    verifyNever(() => removeLink.call(any()));
  });

  testWidgets('empty Manas list — sheet still renders (no crash, no tiles)',
      (tester) async {
    when(() => getList.call()).thenAnswer((_) async => const Right([]));
    when(() => getMemberships.call(any()))
        .thenAnswer((_) async => const Right([]));

    await tester.pumpWidget(host('note-1'));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Sheet appears, but no Manas tile to assert; we just verify nothing
    // threw, by checking the modal route is on the stack.
    expect(find.byType(ManasMembershipSheet), findsOneWidget);
  });

  testWidgets('use case failures degrade gracefully (sheet still renders)',
      (tester) async {
    when(() => getList.call())
        .thenAnswer((_) async => const Left(Failure.errorFailure('boom')));
    when(() => getMemberships.call(any()))
        .thenAnswer((_) async => const Left(Failure.errorFailure('boom')));

    await tester.pumpWidget(host('note-1'));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Both failures fold to empty lists in the impl; the sheet remains
    // mounted and shows zero Manas tiles. No exception bubbles up.
    expect(find.byType(ManasMembershipSheet), findsOneWidget);
  });
}
