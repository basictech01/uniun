import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uniun/common/qr/uniun_qr_scanner_page.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// Covers #305: a code that fails to decode shows one error, however many
/// camera frames report it.
void main() {
  Future<void> pump(WidgetTester t) => t.pumpWidget(
        const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: UniunQrScannerPage(),
        ),
      );

  void detect(WidgetTester t, String raw) {
    t.widget<MobileScanner>(find.byType(MobileScanner)).onDetect!(
      BarcodeCapture(barcodes: [Barcode(rawValue: raw)]),
    );
  }

  testWidgets('the same bad code in view shows one error, not a queue',
      (t) async {
    await pump(t);
    for (var i = 0; i < 20; i++) {
      detect(t, 'old-qr-without-json');
    }
    await t.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    // Past one snackbar's display time nothing queued behind it remains.
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(seconds: 1));
    }
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('a different bad code replaces the shown error', (t) async {
    await pump(t);
    detect(t, 'first bad code');
    await t.pump();
    detect(t, 'second bad code');
    await t.pump();
    await t.pump(const Duration(seconds: 1));

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('not JSON'), findsOneWidget);
  });

  testWidgets('empty and blank detections are ignored', (t) async {
    await pump(t);
    t.widget<MobileScanner>(find.byType(MobileScanner)).onDetect!(
      const BarcodeCapture(),
    );
    detect(t, '   ');
    await t.pump();

    expect(find.byType(SnackBar), findsNothing);
  });
}
