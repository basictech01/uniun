// Real-device check of the unread dots on the real pages: a public group, a
// DM, a private group and a followed note's thread. Seeds notes and unread rows
// into the app's Isar, opens each page with real DI, scrolls the way a person
// does and checks the unread rows. Removes only the rows it added (ids start
// with "e2e-unread-").
//
//   scripts/device_test.sh run integration_test/unread_dots_e2e_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/common/widgets/chat/new_notes_divider.dart';
import 'package:uniun/core/notes/note_kinds.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/core/utils/fast_hash.dart';
import 'package:uniun/data/models/dm/dm_conversation_model.dart';
import 'package:uniun/data/models/followed_note_model.dart';
import 'package:uniun/data/models/group_model.dart';
import 'package:uniun/data/models/note_relation_model.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/models/notes/unread_note_model.dart';
import 'package:uniun/data/models/private_group_model.dart';
import 'package:uniun/features/dm/chat/pages/dm_chat_page.dart';
import 'package:uniun/features/groups/feed/pages/group_feed_page.dart';
import 'package:uniun/features/private_groups/detail/pages/private_group_detail_page.dart';
import 'package:uniun/features/thread/pages/thread_page.dart';
import 'package:uniun/l10n/app_localizations.dart';

import '../test/_helpers/isar_seeds.dart';
import '../test/_helpers/isar_test_harness.dart'
    show groupSeed, privateGroupSeed;

const _prefix = 'e2e-unread-';
// A real-looking hex pubkey: the DM page decodes it.
final _dmPub = 'ab' * 32;

Widget _app(Widget home) => MaterialApp(
  theme: AppTheme.light,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late Isar isar;
  final base = DateTime.now().subtract(const Duration(days: 1));

  setUpAll(() async {
    await configureDependencies();
    isar = getIt<Isar>();
  });

  Future<void> addNote(
    String id, {
    required int kind,
    required DateTime created,
    String? groupId,
    String? privateGroupId,
    int? conversationId,
    bool unread = false,
    String? replyTo,
  }) => isar.writeTxn(() async {
    final m = noteRow(
      id,
      kind: kind,
      groupId: groupId,
      privateGroupId: privateGroupId,
      conversationId: conversationId,
      created: created,
      replyToEventId: replyTo,
      authorPubkey: 'e2e-unread-author',
    );
    await isar.noteModels.put(m);
    if (unread) await putUnreadRowInTxn(isar, m);
  });

  Future<int> unreadWith(String idPrefix) =>
      isar.unreadNoteModels.filter().eventIdStartsWith(idPrefix).count();

  Future<void> scrollToEnd(WidgetTester t) async {
    for (var i = 0; i < 8; i++) {
      await t.fling(
        find.byType(Scrollable).first,
        const Offset(0, -2500),
        4000,
      );
      await t.pump(const Duration(milliseconds: 400));
    }
    await t.pump(const Duration(seconds: 1));
  }

  /// Waits (up to [seconds]) for the unread rows with [idPrefix] to reach
  /// [want], pumping frames meanwhile; returns the last count seen.
  Future<int> waitForUnread(
    WidgetTester t,
    String idPrefix,
    int want, {
    int seconds = 10,
  }) async {
    var n = await unreadWith(idPrefix);
    for (var i = 0; i < seconds * 4 && n != want; i++) {
      await t.pump(const Duration(milliseconds: 250));
      n = await unreadWith(idPrefix);
    }
    return n;
  }

  Future<void> cleanup() async {
    await isar.writeTxn(() async {
      await isar.noteModels.filter().eventIdStartsWith(_prefix).deleteAll();
      await isar.unreadNoteModels
          .filter()
          .eventIdStartsWith(_prefix)
          .deleteAll();
      await isar.noteRelationModels
          .filter()
          .parentIdStartsWith(_prefix)
          .deleteAll();
      await isar.followedNoteModels
          .filter()
          .eventIdStartsWith(_prefix)
          .deleteAll();
      await isar.groupModels.filter().groupIdStartsWith(_prefix).deleteAll();
      await isar.privateGroupModels
          .filter()
          .groupIdStartsWith(_prefix)
          .deleteAll();
      await isar.dmConversationModels
          .filter()
          .otherPubkeyEqualTo(_dmPub)
          .deleteAll();
    });
  }

  tearDown(cleanup);
  // A run that was stopped half way leaves its rows behind.
  setUp(cleanup);

  testWidgets('public group: opens at the first unread, reading to the end '
      'clears the dot, a note arriving at the bottom is read', (t) async {
    const gid = '${_prefix}group';
    await isar.writeTxn(() => isar.groupModels.put(groupSeed(gid)));
    for (var i = 0; i < 15; i++) {
      await addNote(
        '${_prefix}g-read-$i',
        kind: kGroupMessageKind,
        groupId: gid,
        created: base.add(Duration(minutes: i)),
      );
    }
    for (var i = 0; i < 12; i++) {
      await addNote(
        '${_prefix}g-new-$i',
        kind: kGroupMessageKind,
        groupId: gid,
        created: base.add(Duration(hours: 1, minutes: i)),
        unread: true,
      );
    }

    await t.pumpWidget(_app(const GroupFeedPage(groupId: gid)));
    await t.pump(const Duration(seconds: 2));

    expect(find.byType(NewNotesDivider), findsOneWidget);
    expect(await unreadWith('${_prefix}g-new-'), greaterThan(0));

    await scrollToEnd(t);
    expect(
      await waitForUnread(t, '${_prefix}g-new-', 0),
      0,
      reason: 'reached the end',
    );

    await addNote(
      '${_prefix}g-late',
      kind: kGroupMessageKind,
      groupId: gid,
      created: DateTime.now(),
      unread: true,
    );
    await t.pump(const Duration(seconds: 2));
    expect(
      await waitForUnread(t, '${_prefix}g-late', 0),
      0,
      reason: 'arrived while at the bottom',
    );
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets(
    'DM: opens at the first unread and clears at the end',
    (t) async {
      final pub = _dmPub;
      await isar.writeTxn(
        () => isar.dmConversationModels.put(dmConversationRow(pub)),
      );
      final conv = fastHash(pub);
      for (var i = 0; i < 12; i++) {
        await addNote(
          '${_prefix}d-read-$i',
          kind: kDmTextKind,
          conversationId: conv,
          created: base.add(Duration(minutes: i)),
        );
      }
      for (var i = 0; i < 10; i++) {
        await addNote(
          '${_prefix}d-new-$i',
          kind: kDmTextKind,
          conversationId: conv,
          created: base.add(Duration(hours: 1, minutes: i)),
          unread: true,
        );
      }

      await t.pumpWidget(_app(DmChatPage(otherPubkey: pub)));
      await t.pump(const Duration(seconds: 2));

      expect(find.byType(NewNotesDivider), findsOneWidget);
      expect(await unreadWith('${_prefix}d-new-'), greaterThan(0));

      await scrollToEnd(t);
      expect(await waitForUnread(t, '${_prefix}d-new-', 0), 0);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  testWidgets('private group: opens at the first unread and clears at the '
      'end', (t) async {
    const gid = '${_prefix}pgroup';
    await isar.writeTxn(
      () => isar.privateGroupModels.put(privateGroupSeed(gid)),
    );
    for (var i = 0; i < 12; i++) {
      await addNote(
        '${_prefix}p-read-$i',
        kind: kPrivateGroupKind,
        privateGroupId: gid,
        created: base.add(Duration(minutes: i)),
      );
    }
    for (var i = 0; i < 10; i++) {
      await addNote(
        '${_prefix}p-new-$i',
        kind: kPrivateGroupKind,
        privateGroupId: gid,
        created: base.add(Duration(hours: 1, minutes: i)),
        unread: true,
      );
    }

    await t.pumpWidget(_app(const PrivateGroupDetailPage(groupId: gid)));
    await t.pump(const Duration(seconds: 3));

    if (find.text('Exception: No active user').evaluate().isNotEmpty) {
      // The private-group page needs a signed-in user; log in on the phone to
      // run this case. Said loudly so it is never mistaken for a pass.
      debugPrint('SKIPPED private group: the phone has no active user');
      return;
    }
    expect(find.byType(NewNotesDivider), findsOneWidget);

    await scrollToEnd(t);
    expect(await waitForUnread(t, '${_prefix}p-new-', 0), 0);
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('followed note: the trail shows on the parent and goes when the '
      'new reply is read', (t) async {
    const root = '${_prefix}root';
    const r1 = '${_prefix}r1';
    const r2 = '${_prefix}r2';
    const r3 = '${_prefix}r3';
    await isar.writeTxn(
      () => isar.followedNoteModels.put(
        FollowedNoteModel()
          ..eventId = root
          ..contentPreview = 'e2e followed'
          ..followedAt = DateTime.now(),
      ),
    );
    await addNote(root, kind: kNoteKind, created: base);
    await addNote(
      r1,
      kind: kNoteKind,
      created: base.add(const Duration(minutes: 1)),
      replyTo: root,
    );
    await addNote(
      r2,
      kind: kNoteKind,
      created: base.add(const Duration(minutes: 2)),
      replyTo: r1,
    );
    await addNote(
      r3,
      kind: kNoteKind,
      created: base.add(const Duration(minutes: 3)),
      replyTo: r2,
      unread: true,
    );
    await seedRelationEdge(isar, root, r1);
    await seedRelationEdge(isar, r1, r2);
    await seedRelationEdge(isar, r2, r3);

    await t.pumpWidget(_app(const ThreadPage(noteId: root)));
    await t.pump(const Duration(seconds: 2));

    expect(find.text('New reply inside'), findsOneWidget);
    expect(await unreadWith(r3), 1, reason: 'seeing the parent reads nothing');

    await isar.writeTxn(
      () => isar.unreadNoteModels.filter().eventIdEqualTo(r3).deleteAll(),
    );
    await t.pump(const Duration(seconds: 2));

    expect(find.text('New reply inside'), findsNothing);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
