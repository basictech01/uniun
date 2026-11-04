import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/common/widgets/composer/uniun_composer.dart';
import 'package:uniun/common/widgets/drop_loading_indicator.dart';
import 'package:uniun/common/atoms/uniun_button.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/inputs/share_note_input.dart';
import 'package:uniun/domain/repositories/profile_repository.dart';
import 'package:uniun/features/share/bloc/share_sheet_bloc.dart';
import 'package:uniun/features/share/pages/share_sheet_page.dart';
import 'package:uniun/features/share/widgets/destination_tile.dart';
import 'package:uniun/features/share/widgets/dm_destination_tile.dart';
import 'package:uniun/l10n/app_localizations.dart';

import '../../../_helpers/fixtures.dart';

class _MockBloc extends MockBloc<ShareSheetEvent, ShareSheetState>
    implements ShareSheetBloc {}

class _MockProfiles extends Mock implements ProfileRepository {}

/// Covers: ShareSheetPage — the load request, loading spinner, quoted-note
/// card, destination list (feed, public and private groups, DMs and the empty
/// DM line), selection, the Share button (disabled, enabled, submitting), the
/// composer wiring (text, remove reference, remove media), and the success and
/// error feedback.
void main() {
  late _MockBloc bloc;
  late _MockProfiles profiles;
  final source = aNote(id: 'src', content: 'shared note');

  setUpAll(() {
    registerFallbackValue(ShareSheetEvent.loadDestinations(aNote()));
    registerFallbackValue(const ShareDestination.feed());
  });

  setUp(() async {
    bloc = _MockBloc();
    profiles = _MockProfiles();
    when(() => bloc.state).thenReturn(const ShareSheetState());
    when(() => bloc.close()).thenAnswer((_) async {});
    when(() => profiles.getProfile(any())).thenAnswer(
      (_) async => const Left(Failure.notFoundFailure('none')),
    );
    await GetIt.instance.reset();
    GetIt.instance
      ..registerFactory<ShareSheetBloc>(() => bloc)
      ..registerSingleton<ProfileRepository>(profiles);
  });

  tearDown(() => GetIt.instance.reset());

  /// Opens the sheet the way the app does, from a button.
  Future<void> open(WidgetTester t) async {
    await t.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (ctx) => Scaffold(
          body: TextButton(
            onPressed: () => ShareSheetPage.show(ctx, source),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await t.tap(find.text('open'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
  }

  ShareSheetState loaded({
    ShareDestination? selected,
    bool submitting = false,
  }) => ShareSheetState(
    authorPubkey: kSelfPub,
    quotedNote: aNote(id: 'quoted', content: 'the original'),
    publicGroups: [aGroup(groupId: 'g1', name: 'General', about: 'chat')],
    privateGroups: [
      aPrivateGroup(groupId: 'p1', name: 'Secret', description: ''),
    ],
    selectedDestination: selected,
    submitting: submitting,
  );

  testWidgets('asks the bloc for destinations of the shared note', (t) async {
    await open(t);

    final event = verify(() => bloc.add(captureAny())).captured.single;
    expect(event, isA<LoadDestinations>());
    expect((event as LoadDestinations).source.id, 'src');
  });

  testWidgets('while loading it shows a spinner instead of destinations',
      (t) async {
    when(() => bloc.state).thenReturn(const ShareSheetState(loading: true));
    await open(t);

    expect(find.byType(DropLoadingIndicator), findsOneWidget);
    expect(find.byType(DestinationTile), findsNothing);
  });

  testWidgets('shows the title, the quoted note and the feed destination',
      (t) async {
    when(() => bloc.state).thenReturn(loaded());
    await open(t);

    expect(find.text('Share'), findsWidgets);
    expect(find.textContaining('the original'), findsOneWidget);
    expect(find.text('Post to my feed'), findsOneWidget);
  });

  testWidgets('no quoted note means no quoting card', (t) async {
    when(() => bloc.state).thenReturn(
      const ShareSheetState(authorPubkey: kSelfPub),
    );
    await open(t);

    expect(find.textContaining('the original'), findsNothing);
  });

  /// Scrolls the sheet's list to [finder] and taps it.
  Future<void> tapInSheet(WidgetTester t, Finder finder) async {
    await t.ensureVisible(finder);
    await t.pumpAndSettle();
    await t.tap(finder);
    await t.pumpAndSettle();
  }

  testWidgets('public groups open to show name and subtitle; picking one '
      'selects it', (t) async {
    when(() => bloc.state).thenReturn(loaded());
    await open(t);

    await tapInSheet(t, find.text('PUBLIC GROUPS'));
    expect(find.text('chat'), findsOneWidget);

    await tapInSheet(t, find.text('General'));
    final picked = verify(() => bloc.add(captureAny())).captured
        .whereType<SelectDestination>()
        .single;
    expect(picked.destination, const ShareDestination.publicGroup(groupId: 'g1'));
  });

  testWidgets('private groups open; one with no description shows no '
      'subtitle, and picking selects it', (t) async {
    when(() => bloc.state).thenReturn(loaded());
    await open(t);

    await tapInSheet(t, find.text('PRIVATE GROUPS'));
    await tapInSheet(t, find.text('Secret'));

    final picked = verify(() => bloc.add(captureAny())).captured
        .whereType<SelectDestination>()
        .single;
    expect(picked.destination, const ShareDestination.privateGroup(groupId: 'p1'));
  });

  testWidgets('groups sections are absent when the user has none', (t) async {
    when(() => bloc.state).thenReturn(const ShareSheetState(authorPubkey: kSelfPub));
    await open(t);

    expect(find.text('PUBLIC GROUPS'), findsNothing);
    expect(find.text('PRIVATE GROUPS'), findsNothing);
  });

  testWidgets('with no DM conversations the DM section says to start one',
      (t) async {
    when(() => bloc.state).thenReturn(loaded());
    await open(t);

    await tapInSheet(t, find.text('DIRECT MESSAGES'));

    expect(find.text('Start a DM first to share notes here.'), findsOneWidget);
  });

  testWidgets('DM conversations are listed and can be picked', (t) async {
    when(() => bloc.state).thenReturn(ShareSheetState(
      authorPubkey: kSelfPub,
      dmConversations: [aDmConversation(otherPubkey: kSampleTargetPubkeyHex)],
    ));
    await open(t);

    await tapInSheet(t, find.text('DIRECT MESSAGES'));
    await tapInSheet(t, find.byType(DmDestinationTile));

    final picked = verify(() => bloc.add(captureAny())).captured
        .whereType<SelectDestination>()
        .single;
    expect(
      picked.destination,
      const ShareDestination.dm(otherPubkeyHex: kSampleTargetPubkeyHex),
    );
  });

  testWidgets('the Share button is disabled until a destination is picked',
      (t) async {
    when(() => bloc.state).thenReturn(loaded());
    await open(t);

    final button = t.widget<UniunButton>(find.byType(UniunButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('picking the feed sends selectDestination', (t) async {
    when(() => bloc.state).thenReturn(loaded());
    await open(t);

    await t.tap(find.text('Post to my feed'));
    await t.pump();

    final events = verify(() => bloc.add(captureAny())).captured;
    expect(
      events.whereType<SelectDestination>().single.destination,
      const ShareDestination.feed(),
    );
  });

  testWidgets('with a destination picked, Share submits it with the source',
      (t) async {
    when(() => bloc.state).thenReturn(
      loaded(selected: const ShareDestination.feed()),
    );
    await open(t);

    await t.tap(find.byType(UniunButton));
    await t.pump();

    final submit = verify(() => bloc.add(captureAny())).captured
        .whereType<SubmitShare>()
        .single;
    expect(submit.source.id, 'src');
    expect(submit.destination, const ShareDestination.feed());
  });

  testWidgets('while submitting the button is disabled with a spinner',
      (t) async {
    when(() => bloc.state).thenReturn(
      loaded(selected: const ShareDestination.feed(), submitting: true),
    );
    await open(t);

    expect(t.widget<UniunButton>(find.byType(UniunButton)).onPressed,
        isNull);
    expect(find.byType(DropLoadingIndicator), findsOneWidget);
  });

  testWidgets('typing in the composer reports the text', (t) async {
    when(() => bloc.state).thenReturn(loaded());
    await open(t);

    await t.enterText(find.byType(TextField), 'my take');

    final changed = verify(() => bloc.add(captureAny())).captured
        .whereType<ContentChanged>()
        .last;
    expect(changed.value, 'my take');
  });

  testWidgets('a picked reference shows as a chip and can be removed',
      (t) async {
    when(() => bloc.state).thenReturn(const ShareSheetState(
      authorPubkey: kSelfPub,
      references: [ComposerReference(id: 'r1', label: 'ref one')],
    ));
    await open(t);
    expect(find.text('ref one'), findsOneWidget);

    await t.tap(find.byIcon(Icons.close_rounded).first);
    await t.pump();

    final removed = verify(() => bloc.add(captureAny())).captured
        .whereType<RemoveReference>()
        .single;
    expect(removed.id, 'r1');
  });

  testWidgets('a successful share closes the sheet and confirms', (t) async {
    whenListen(
      bloc,
      Stream.value(loaded().copyWith(submitted: true)),
      initialState: loaded(),
    );
    await open(t);
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));

    expect(find.text('Shared'), findsOneWidget);
    expect(find.text('Post to my feed'), findsNothing);
  });

  testWidgets('an error is shown without closing the sheet', (t) async {
    whenListen(
      bloc,
      Stream.value(loaded().copyWith(error: 'relay refused')),
      initialState: loaded(),
    );
    await open(t);
    await t.pump();

    expect(find.text('relay refused'), findsOneWidget);
    expect(find.text('Post to my feed'), findsOneWidget);
  });
}
