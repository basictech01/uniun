import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/features/vishnu/drawer/bloc/drawer_bloc.dart';
import 'package:uniun/features/vishnu/drawer/widgets/vishnu_drawer.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockDrawerBloc extends MockBloc<DrawerEvent, DrawerState>
    implements DrawerBloc {}

/// Covers: the drawer showing a count (not a dot) for public groups, private
/// groups, DMs and followed notes, and nothing for a surface with no unread.
void main() {
  late _MockDrawerBloc bloc;

  DrawerLoaded loaded({
    List<DrawerGroupItem> groups = const [],
    List<DrawerPrivateGroupItem> privateGroups = const [],
    List<DrawerDmItem> dms = const [],
    List<DrawerFollowedNoteItem> followedNotes = const [],
  }) => DrawerLoaded(
    userName: 'Me',
    npub: 'npub1xyz',
    pubkeyHex: 'ab',
    followedNotes: followedNotes,
    groups: groups,
    privateGroups: privateGroups,
    dms: dms,
    followedUsers: const [],
    myRelays: const [],
  );

  setUp(() => bloc = _MockDrawerBloc());

  Future<void> open(WidgetTester t, DrawerLoaded state) async {
    // Tall enough that every section of the lazy drawer list is built.
    t.view.physicalSize = const Size(800, 4000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    when(() => bloc.state).thenReturn(state);
    final key = GlobalKey<ScaffoldState>();
    await t.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<DrawerBloc>.value(
          value: bloc,
          child: Scaffold(
            key: key,
            drawer: const VishnuDrawer(),
            body: const SizedBox(),
          ),
        ),
      ),
    );
    key.currentState!.openDrawer();
    await t.pumpAndSettle();
  }

  testWidgets('a public group shows how many notes are unread', (t) async {
    await open(
      t,
      loaded(
        groups: const [
          DrawerGroupItem(id: 'g', name: 'Design', unreadCount: 5),
        ],
      ),
    );

    expect(find.text('Design'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('a private group shows how many notes are unread', (t) async {
    await open(
      t,
      loaded(
        privateGroups: const [
          DrawerPrivateGroupItem(id: 'p', name: 'Inner', unreadCount: 3),
        ],
      ),
    );

    expect(find.text('Inner'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('DMs and followed notes keep their counts', (t) async {
    await open(
      t,
      loaded(
        dms: const [DrawerDmItem(pubkey: 'k', name: 'Asha', unreadCount: 2)],
        followedNotes: const [
          DrawerFollowedNoteItem(
            eventId: 'n',
            contentPreview: 'Launch checklist',
            newReferenceCount: 4,
          ),
        ],
      ),
    );

    expect(find.text('2'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('nothing unread shows no badge', (t) async {
    await open(
      t,
      loaded(
        groups: const [DrawerGroupItem(id: 'g', name: 'Design')],
        privateGroups: const [DrawerPrivateGroupItem(id: 'p', name: 'Inner')],
      ),
    );

    expect(find.text('0'), findsNothing);
  });

  testWidgets('the number follows the state when notes are read', (t) async {
    whenListen(
      bloc,
      Stream.fromIterable([
        loaded(
          groups: const [
            DrawerGroupItem(id: 'g', name: 'Design', unreadCount: 2),
          ],
        ),
      ]),
      initialState: loaded(
        groups: const [
          DrawerGroupItem(id: 'g', name: 'Design', unreadCount: 5),
        ],
      ),
    );
    t.view.physicalSize = const Size(800, 4000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final key = GlobalKey<ScaffoldState>();
    await t.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<DrawerBloc>.value(
          value: bloc,
          child: Scaffold(
            key: key,
            drawer: const VishnuDrawer(),
            body: const SizedBox(),
          ),
        ),
      ),
    );
    key.currentState!.openDrawer();
    await t.pumpAndSettle();

    expect(find.text('2'), findsOneWidget);
    expect(find.text('5'), findsNothing);
  });
}
