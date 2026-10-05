import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/llm/llm_backend_type.dart';
import 'package:uniun/domain/entities/llm/llm_model_info.dart';
import 'package:uniun/domain/usecases/llm_usecases.dart';
import 'package:uniun/features/shiv/chat/cubit/chat_image_support_cubit.dart';

class _MockActiveModel extends Mock implements GetActiveLlmModelUseCase {}

/// Covers: ChatImageSupportCubit — true only when the active model reads
/// images; no model, a lookup failure, and a closed cubit all mean false/no-op.
void main() {
  late _MockActiveModel active;

  LlmModelInfo model({required bool images}) => LlmModelInfo(
    id: 'm',
    displayName: 'M',
    backend: LlmBackendType.localGemma,
    supportsImages: images,
  );

  setUp(() => active = _MockActiveModel());

  blocTest<ChatImageSupportCubit, bool>(
    'a vision model turns the attach button on',
    build: () {
      when(
        () => active.call(),
      ).thenAnswer((_) async => Right(model(images: true)));
      return ChatImageSupportCubit(active);
    },
    act: (c) => c.refresh(),
    expect: () => [true],
  );

  blocTest<ChatImageSupportCubit, bool>(
    'a text-only model leaves it off',
    build: () {
      when(
        () => active.call(),
      ).thenAnswer((_) async => Right(model(images: false)));
      return ChatImageSupportCubit(active);
    },
    act: (c) => c.refresh(),
    // A cubit's first emit always goes out, even when it equals the seed.
    expect: () => [false],
  );

  blocTest<ChatImageSupportCubit, bool>(
    'switching from a vision model to a text-only one turns it off',
    build: () {
      var calls = 0;
      when(
        () => active.call(),
      ).thenAnswer((_) async => Right(model(images: calls++ == 0)));
      return ChatImageSupportCubit(active);
    },
    act: (c) async {
      await c.refresh();
      await c.refresh();
    },
    expect: () => [true, false],
  );

  blocTest<ChatImageSupportCubit, bool>(
    'no model chosen means no button',
    build: () {
      when(() => active.call()).thenAnswer((_) async => const Right(null));
      return ChatImageSupportCubit(active);
    },
    act: (c) => c.refresh(),
    expect: () => [false],
  );

  blocTest<ChatImageSupportCubit, bool>(
    'a failed lookup means no button, not a crash',
    seed: () => true,
    build: () {
      when(
        () => active.call(),
      ).thenAnswer((_) async => const Left(Failure.errorFailure('x')));
      return ChatImageSupportCubit(active);
    },
    act: (c) => c.refresh(),
    expect: () => [false],
  );

  test('a lookup finishing after the cubit closed does not emit', () async {
    when(() => active.call()).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return Right(model(images: true));
    });
    final cubit = ChatImageSupportCubit(active);

    final pending = cubit.refresh();
    await cubit.close();

    await expectLater(pending, completes);
    expect(cubit.state, isFalse);
  });
}
