import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/common/widgets/thread/unread_trail_mark.dart';
import 'package:uniun/domain/entities/followed_note/thread_unread_marker.dart';
import 'package:uniun/l10n/app_localizations.dart';

Widget _host(ThreadUnreadMarker? marker) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: UnreadTrailMark(marker: marker)),
);

/// Covers: UnreadTrailMark showing "New" for an unread note, "New reply
/// inside" for a trail, and nothing otherwise.
void main() {
  testWidgets('an unread note says New with a dot', (t) async {
    await t.pumpWidget(
      _host(const ThreadUnreadMarker(unread: true, unreadInside: false)),
    );

    expect(find.text('New'), findsOneWidget);
    expect(find.byKey(const ValueKey('unread-trail-dot')), findsOneWidget);
  });

  testWidgets('an unread reply further down says New reply inside', (t) async {
    await t.pumpWidget(
      _host(const ThreadUnreadMarker(unread: false, unreadInside: true)),
    );

    expect(find.text('New reply inside'), findsOneWidget);
    expect(find.text('New'), findsNothing);
  });

  testWidgets('unread itself wins over unread inside', (t) async {
    await t.pumpWidget(
      _host(const ThreadUnreadMarker(unread: true, unreadInside: true)),
    );

    expect(find.text('New'), findsOneWidget);
    expect(find.text('New reply inside'), findsNothing);
  });

  testWidgets('no marker draws nothing', (t) async {
    await t.pumpWidget(_host(null));

    expect(find.byKey(const ValueKey('unread-trail-dot')), findsNothing);
  });

  testWidgets('a marker with nothing unread draws nothing', (t) async {
    await t.pumpWidget(
      _host(const ThreadUnreadMarker(unread: false, unreadInside: false)),
    );

    expect(find.byKey(const ValueKey('unread-trail-dot')), findsNothing);
  });
}
