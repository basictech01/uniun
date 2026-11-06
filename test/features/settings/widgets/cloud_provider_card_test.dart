import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/common/atoms/uniun_button.dart';
import 'package:uniun/domain/entities/llm/llm_backend_type.dart';
import 'package:uniun/domain/repositories/user_repository.dart';
import 'package:uniun/domain/usecases/ai_model_usecases.dart';
import 'package:uniun/domain/usecases/llm_usecases.dart';
import 'package:uniun/features/settings/widgets/cloud_provider_card.dart';
import 'package:uniun/l10n/app_localizations.dart';

class _MockConnected extends Mock implements IsUniunCloudConnectedUseCase {}

class _MockBackend extends Mock implements GetActiveLlmBackendUseCase {}

class _MockActiveModel extends Mock implements GetActiveLlmModelUseCase {}

class _MockLocalModel extends Mock implements GetActiveAIModelUseCase {}

class _MockListCloud extends Mock implements ListCloudLlmModelsUseCase {}

class _MockStatus extends Mock implements GetUniunCloudStatusUseCase {}

class _MockUserRepo extends Mock implements UserRepository {}

/// Covers: the manage sheet's Upgrade button, which looks up the active keys
/// before opening the pricing page.
void main() {
  late _MockUserRepo userRepo;

  setUp(() async {
    await GetIt.instance.reset();
    userRepo = _MockUserRepo();
    final connected = _MockConnected();
    final backend = _MockBackend();
    final activeModel = _MockActiveModel();
    final localModel = _MockLocalModel();
    final listCloud = _MockListCloud();
    final status = _MockStatus();
    when(() => connected.call()).thenAnswer((_) async => true);
    when(() => backend.call())
        .thenAnswer((_) async => const Right(LlmBackendType.localGemma));
    when(() => activeModel.call()).thenAnswer((_) async => const Right(null));
    when(() => localModel.call()).thenAnswer((_) async => const Right(null));
    when(() => listCloud.call()).thenAnswer((_) async => const Right([]));
    when(() => status.call())
        .thenAnswer((_) async => const Right((plan: 'free', balance: 12)));
    when(() => userRepo.getActiveKeysHex()).thenAnswer((_) async => null);
    GetIt.instance
      ..registerFactory<IsUniunCloudConnectedUseCase>(() => connected)
      ..registerFactory<GetActiveLlmBackendUseCase>(() => backend)
      ..registerFactory<GetActiveLlmModelUseCase>(() => activeModel)
      ..registerFactory<GetActiveAIModelUseCase>(() => localModel)
      ..registerFactory<ListCloudLlmModelsUseCase>(() => listCloud)
      ..registerFactory<GetUniunCloudStatusUseCase>(() => status)
      ..registerFactory<UserRepository>(() => userRepo);
  });

  tearDown(() => GetIt.instance.reset());

  testWidgets('Upgrade button looks up the active keys', (t) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: CloudProviderCard()),
      ),
    );
    await t.pump(const Duration(milliseconds: 100));
    await t.tap(find.byIcon(Icons.cloud_done_outlined));
    await t.pump(const Duration(milliseconds: 500));
    await t.pump(const Duration(milliseconds: 500));

    await t.tap(find.byType(UniunButton));
    await t.pump();

    verify(() => userRepo.getActiveKeysHex()).called(1);
  });
}
