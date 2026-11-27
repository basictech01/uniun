import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/common/qr/uniun_qr_payload.dart';
import 'package:uniun/common/qr/uniun_qr_scanner_page.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/repositories/uniun_repository.dart';
import 'package:uniun/domain/usecases/followed_user_usecases.dart';
import 'package:uniun/l10n/app_localizations.dart';

import '../../_helpers/fixtures.dart';

class _MockUniun extends Mock implements UniunRepository {}

class _MockFollowUser extends Mock implements FollowUserUseCase {}

/// Covers: a failed QR-login approval and a failed follow-from-QR show the
/// plain failure message.
void main() {
  late _MockUniun uniun;
  late _MockFollowUser followUser;

  setUpAll(() {
    registerFallbackValue(const FollowUserInput(pubkeyHex: ''));
  });

  setUp(() async {
    await GetIt.instance.reset();
    uniun = _MockUniun();
    followUser = _MockFollowUser();
    GetIt.instance
      ..registerFactory<UniunRepository>(() => uniun)
      ..registerFactory<FollowUserUseCase>(() => followUser);
  });

  tearDown(() => GetIt.instance.reset());

  Future<void> openScanner(WidgetTester t, UniunQrScanIntent intent) async {
    await t.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => UniunQrScannerPage(intent: intent),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
  }

  Future<void> scan(WidgetTester t, UniunQrPayload payload) async {
    t.widget<MobileScanner>(find.byType(MobileScanner)).onDetect!(
      BarcodeCapture(barcodes: [Barcode(rawValue: payload.encode())]),
    );
    await t.pumpAndSettle();
  }

  testWidgets('a failed QR-login approval shows only the failure message', (
    t,
  ) async {
    when(() => uniun.isConnected()).thenAnswer((_) async => true);
    when(
      () => uniun.approveQrLogin(any()),
    ).thenAnswer((_) async => const Left(Failure.errorFailure('boom')));
    await openScanner(t, UniunQrScanIntent.generic);

    await scan(
      t,
      const UniunQrPayload(kind: UniunQrKind.loginSession, id: 'session-1'),
    );

    expect(find.textContaining('boom'), findsOneWidget);
    expect(find.textContaining('Failure.'), findsNothing);
  });

  testWidgets('a failed follow from a QR shows only the failure message', (
    t,
  ) async {
    when(
      () => followUser.call(any()),
    ).thenAnswer((_) async => const Left(Failure.errorFailure('boom')));
    await openScanner(t, UniunQrScanIntent.follow);

    await scan(
      t,
      const UniunQrPayload(kind: UniunQrKind.user, id: kSampleTargetPubkeyHex),
    );

    expect(find.text('boom'), findsOneWidget);
    expect(find.textContaining('Failure.'), findsNothing);
  });
}
