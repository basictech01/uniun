import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/common/widgets/note_card/cubit/note_card_cubit.dart';
import 'package:uniun/common/widgets/note_card/note_card.dart';
import 'package:uniun/common/widgets/thread/thread_conversation_body.dart';
import 'package:uniun/common/widgets/thread/unread_trail_mark.dart';
import 'package:uniun/domain/entities/followed_note/thread_unread_marker.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/l10n/app_localizations.dart';

import '../../../_helpers/fixtures.dart';

class _MockNoteCardCubit extends MockCubit<NoteCardState>
    implements NoteCardCubit {}

/// Covers: ThreadConversationBody drawing the followed-note trail above each
/// reply, tapping a reply, and the thread without any markers.
void main() {
  late _MockNoteCardCubit cardCubit;

  setUp(() async {
    cardCubit = _MockNoteCardCubit();
    when(() => cardCubit.state).thenReturn(const NoteCardState());
    when(() => cardCubit.note).thenReturn(aNote(id: 'x'));
    await GetIt.instance.reset();
    GetIt.instance.registerFactoryParam<NoteCardCubit, NoteEntity, void>(
      (_, __) => cardCubit,
    );
  });

  tearDown(() => GetIt.instance.reset());

  Widget host({
    required List<NoteEntity> replies,
    Map<String, ThreadUnreadMarker> markers = const {},
    void Function(String id)? onOpen,
  }) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: ThreadConversationBody(
        root: aNote(id: 'root'),
        profiles: const {},
        replies: replies,
        unreadMarkers: markers,
        onOpenThread: onOpen ?? (_) {},
      ),
    ),
  );

  List<NoteEntity> replies(int n) => [
    for (var i = 1; i <= n; i++) aNote(id: 'r$i', content: 'reply $i'),
  ];

  testWidgets('a reply with an unread note below says New reply inside', (
    t,
  ) async {
    await t.pumpWidget(
      host(
        replies: replies(3),
        markers: const {
          'r1': ThreadUnreadMarker(unread: false, unreadInside: true),
        },
      ),
    );

    expect(find.text('New reply inside'), findsOneWidget);
    expect(find.text('New'), findsNothing);
  });

  testWidgets('an unread reply says New', (t) async {
    await t.pumpWidget(
      host(
        replies: replies(3),
        markers: const {
          'r2': ThreadUnreadMarker(unread: true, unreadInside: false),
        },
      ),
    );

    expect(find.text('New'), findsOneWidget);
  });

  testWidgets('markers for several replies show on their own cards only', (
    t,
  ) async {
    await t.pumpWidget(
      host(
        replies: replies(4),
        markers: const {
          'r1': ThreadUnreadMarker(unread: false, unreadInside: true),
          'r3': ThreadUnreadMarker(unread: true, unreadInside: false),
        },
      ),
    );

    expect(find.byType(UnreadTrailMark), findsNWidgets(4));
    expect(find.text('New reply inside'), findsOneWidget);
    expect(find.text('New'), findsOneWidget);
  });

  testWidgets('no markers draws no trail at all', (t) async {
    await t.pumpWidget(host(replies: replies(3)));

    expect(find.text('New'), findsNothing);
    expect(find.text('New reply inside'), findsNothing);
  });

  testWidgets('a marker for a note that is not listed is ignored', (t) async {
    await t.pumpWidget(
      host(
        replies: replies(2),
        markers: const {
          'ghost': ThreadUnreadMarker(unread: true, unreadInside: true),
        },
      ),
    );

    expect(find.text('New'), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('tapping a reply opens its own thread', (t) async {
    String? opened;
    await t.pumpWidget(host(replies: replies(2), onOpen: (id) => opened = id));

    await t.tap(find.byType(NoteCard).first);

    expect(opened, 'r1');
  });

  testWidgets('a thread with no replies shows no trail', (t) async {
    await t.pumpWidget(host(replies: const []));

    expect(find.byType(UnreadTrailMark), findsNothing);
  });
}
