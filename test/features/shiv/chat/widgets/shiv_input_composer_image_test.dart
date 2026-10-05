import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uniun/features/shiv/chat/widgets/shiv_input_composer.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// Covers: ShivInputComposer's image attachment — the button exists only for a
/// model that reads images, a picked photo shows as a removable thumbnail, goes
/// out with the next message and is cleared, and is dropped if the model has
/// since changed to one that cannot read it.
void main() {
  final photo = Uint8List.fromList(
    img.encodePng(img.Image(width: 40, height: 30)),
  );

  late List<({String text, List<Uint8List> images})> sent;
  var pickCalls = 0;

  setUp(() {
    sent = [];
    pickCalls = 0;
  });

  Widget host({
    required bool supportsImages,
    Future<Uint8List?> Function()? pick,
    VoidCallback? onModelSheetClosed,
  }) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Align(
        alignment: Alignment.bottomCenter,
        child: ShivInputComposer(
          isStreaming: false,
          onStop: () {},
          supportsImages: supportsImages,
          onModelSheetClosed: onModelSheetClosed,
          pickImage:
              pick ??
              () async {
                pickCalls++;
                return photo;
              },
          onSend: (text, manasIds, images) =>
              sent.add((text: text, images: images)),
        ),
      ),
    ),
  );

  Future<void> type(WidgetTester t, String text) async {
    await t.enterText(find.byType(TextField), text);
    await t.pump();
  }

  Future<void> send(WidgetTester t) async {
    await t.tap(find.byIcon(Icons.arrow_upward_rounded));
    await t.pump();
  }

  group('the attach button', () {
    testWidgets('is there for a model that reads images', (t) async {
      await t.pumpWidget(host(supportsImages: true));

      expect(find.byTooltip('Attach an image'), findsOneWidget);
    });

    testWidgets('is not there for a text-only model', (t) async {
      await t.pumpWidget(host(supportsImages: false));

      expect(find.byTooltip('Attach an image'), findsNothing);
      expect(find.byIcon(Icons.image_outlined), findsNothing);
    });

    testWidgets('appears and disappears as the model changes', (t) async {
      await t.pumpWidget(host(supportsImages: false));
      await t.pumpWidget(host(supportsImages: true));
      expect(find.byTooltip('Attach an image'), findsOneWidget);

      await t.pumpWidget(host(supportsImages: false));
      expect(find.byTooltip('Attach an image'), findsNothing);
    });
  });

  group('attaching', () {
    testWidgets('a picked photo shows as a thumbnail', (t) async {
      await t.pumpWidget(host(supportsImages: true));

      await t.tap(find.byIcon(Icons.image_outlined));
      await t.pump();

      expect(pickCalls, 1);
      expect(find.byType(Image), findsOneWidget);
      expect(find.byTooltip('Remove image'), findsOneWidget);
    });

    testWidgets('backing out of the picker attaches nothing', (t) async {
      await t.pumpWidget(host(supportsImages: true, pick: () async => null));

      await t.tap(find.byIcon(Icons.image_outlined));
      await t.pump();

      expect(find.byType(Image), findsNothing);
    });

    testWidgets('the remove button takes it off again', (t) async {
      await t.pumpWidget(host(supportsImages: true));
      await t.tap(find.byIcon(Icons.image_outlined));
      await t.pump();

      await t.tap(find.byTooltip('Remove image'));
      await t.pump();

      expect(find.byType(Image), findsNothing);
    });

    testWidgets('picking again replaces the photo rather than adding one', (
      t,
    ) async {
      await t.pumpWidget(host(supportsImages: true));

      await t.tap(find.byIcon(Icons.image_outlined));
      await t.pump();
      await t.tap(find.byIcon(Icons.image_outlined));
      await t.pump();

      expect(find.byType(Image), findsOneWidget);
    });
  });

  group('sending', () {
    testWidgets('the photo goes out with the message and is then cleared', (
      t,
    ) async {
      await t.pumpWidget(host(supportsImages: true));
      await t.tap(find.byIcon(Icons.image_outlined));
      await t.pump();
      await type(t, 'what is this?');

      await send(t);

      expect(sent.single.text, 'what is this?');
      expect(sent.single.images, [photo]);
      expect(find.byType(Image), findsNothing, reason: 'cleared after sending');
    });

    testWidgets('a text-only message sends no images', (t) async {
      await t.pumpWidget(host(supportsImages: true));
      await type(t, 'hello');

      await send(t);

      expect(sent.single.images, isEmpty);
    });

    testWidgets('the next message does not repeat the previous photo', (
      t,
    ) async {
      await t.pumpWidget(host(supportsImages: true));
      await t.tap(find.byIcon(Icons.image_outlined));
      await t.pump();
      await type(t, 'first');
      await send(t);

      await type(t, 'second');
      await send(t);

      expect(sent[1].images, isEmpty);
    });

    testWidgets('a photo is dropped, not sent, once the model cannot read it', (
      t,
    ) async {
      await t.pumpWidget(host(supportsImages: true));
      await t.tap(find.byIcon(Icons.image_outlined));
      await t.pump();
      await t.pumpWidget(host(supportsImages: false));
      await type(t, 'still here');

      await send(t);

      expect(sent.single.images, isEmpty);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('a photo alone, with no text, is not sent', (t) async {
      await t.pumpWidget(host(supportsImages: true));
      await t.tap(find.byIcon(Icons.image_outlined));
      await t.pump();

      await t.tap(find.byIcon(Icons.arrow_upward_rounded));
      await t.pump();

      expect(sent, isEmpty, reason: 'a question is needed');
    });
  });
}
