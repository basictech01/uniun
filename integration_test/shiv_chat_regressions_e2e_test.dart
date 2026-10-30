// Real-device regression guards for three old Shiv issues that no longer show
// up by hand, so they are caught if they come back:
//
//   #199  "stuck with one response on every question": several different
//         questions in one conversation, then a new conversation, must each
//         get their own, on-topic reply. Run on every local chat model.
//   #123  the three dots and the Stop button were missing while a reply was
//         pending (seen with the cloud model only, which was down when this
//         was written, so it is checked here on the local model): the real
//         chat page is driven, and the dots and Stop must be there from the
//         moment the question is sent until the reply is done, and Stop must
//         end the turn.
//   #139  crash in Nataraj / Ganas (seen on an iPhone 13; this runs on the
//         Android phone, so it guards the shared path): the Nataraj deck is
//         filled repeatedly on a local model and process memory must stay
//         bounded. Gana's own runs are in `gana_local_engine_e2e_test`.
//
//   scripts/device_test.sh run integration_test/shiv_chat_regressions_e2e_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_edge_ai_diagnostics/flutter_edge_ai_diagnostics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/core/enum/message_role.dart';
import 'package:uniun/core/enum/note_type.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/domain/entities/ai_model/ai_model_entity.dart';
import 'package:uniun/domain/entities/llm/llm_backend_type.dart';
import 'package:uniun/domain/repositories/user_repository.dart';
import 'package:uniun/domain/repositories/vector_repository.dart';
import 'package:uniun/domain/usecases/llm_usecases.dart';
import 'package:uniun/domain/usecases/shiv_usecases.dart';
import 'package:uniun/features/shiv/chat/bloc/shiv_ai_bloc.dart';
import 'package:uniun/features/shiv/chat/pages/shiv_chat_page.dart';
import 'package:uniun/features/shiv/nataraj/engine/nataraj_generator.dart';
import 'package:uniun/features/shiv/rag/embedding/embedding_service.dart';
import 'package:uniun/l10n/app_localizations.dart';

import 'support/test_model.dart';

const _mib = 1024 * 1024;

Future<void> _boot() async {
  if (!getIt.isRegistered<Isar>()) await configureDependencies();
}

/// Sends [text] through the bloc and waits for the turn to end. Returns the
/// final assistant reply.
Future<String> _ask(ShivAIBloc bloc, String text) async {
  bloc.add(ShivAIEvent.sendMessage(text));
  await bloc.stream.firstWhere((s) => s.status == ShivChatStatus.streaming);
  final done = await bloc.stream
      .firstWhere(
        (s) =>
            s.status == ShivChatStatus.chatIdle ||
            s.status == ShivChatStatus.error,
      )
      .timeout(const Duration(minutes: 5));
  expect(done.status, ShivChatStatus.chatIdle, reason: done.errorMessage);
  final last = done.messages.last;
  expect(last.role, MessageRole.assistant);
  final isar = getIt<Isar>();
  final fed = <String>[];
  for (final id in done.lastTurnSourceNoteIds) {
    final n = await isar.noteModels.filter().eventIdEqualTo(id).findFirst();
    fed.add(n?.content ?? '(saved copy)');
  }
  // ignore: avoid_print
  print('ASK "$text" -> "${last.content.trim()}" | notes fed: $fed');
  return last.content.trim();
}

/// Conversations created by these tests, deleted again at the end.
final _createdChats = <String>[];

Future<ShivAIBloc> _openChat() async {
  final bloc = getIt<ShivAIBloc>();
  bloc.add(const ShivAIEvent.createConversation());
  final opened = await bloc.stream.firstWhere(
    (s) => s.activeConversation != null && s.status == ShivChatStatus.chatIdle,
  );
  _createdChats.add(opened.activeConversation!.conversationId);
  return bloc;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  LlmBackendType? backendBefore;

  setUpAll(() async {
    await _boot();
    backendBefore = (await getIt<GetActiveLlmBackendUseCase>().call())
        .getOrElse(() => LlmBackendType.localGemma);
  });

  tearDownAll(() async {
    for (final id in _createdChats) {
      await getIt<DeleteConversationUseCase>().call(id);
    }
    if (backendBefore != null) {
      await getIt<SetActiveLlmBackendUseCase>().call(backendBefore!);
    }
  });

  group('#199 every question gets its own reply', () {
    for (final id in [AIModelId.qwen25_05b, AIModelId.gemma4E2b]) {
      testWidgets(
        '${id.name}: different questions, different replies, also in a new chat',
        (tester) async {
          expect(await provisionTestModel(id), isTrue,
              reason: 'no ${id.name} fixture on the phone');
          await getIt<SetActiveLlmBackendUseCase>()
              .call(LlmBackendType.localGemma);

          // The bug needs a note in the library that has nothing to do with
          // the questions: the model used to copy it into every reply.
          final isar = getIt<Isar>();
          final vectors = getIt<VectorRepository>();
          final noteId = 'e2e-199-${DateTime.now().microsecondsSinceEpoch}';
          const noteText =
              'This is a test post. The celebration codeword is marmalade.';
          await isar.writeTxn(
            () => isar.noteModels.put(
              NoteModel(
                eventId: noteId,
                sig: '',
                authorPubkey: 'e2e',
                content: noteText,
                type: NoteType.text,
                eTagRefs: const [],
                pTagRefs: const [],
                tTags: const [],
                created: DateTime.now(),
              ),
            ),
          );
          await vectors.upsertNote(
            noteId,
            await getIt<EmbeddingService>().embedNote(noteText),
          );
          addTearDown(() async {
            await vectors.delete(noteId);
            await isar.writeTxn(
              () => isar.noteModels.filter().eventIdEqualTo(noteId).deleteAll(),
            );
          });

          var bloc = await _openChat();
          final a = await _ask(bloc, 'What is the capital of France? One word.');
          final b = await _ask(bloc, 'What is the capital of Japan? One word.');
          final c = await _ask(bloc, 'What is the capital of Italy? One word.');
          // ignore: avoid_print
          print('CHAT199[${id.name}] same chat: "$a" | "$b" | "$c"');
          // The bug: one reply repeated for every question, taken from a note
          // that has nothing to do with them.
          for (final reply in [a, b, c]) {
            expect(reply.toLowerCase(), isNot(contains('marmalade')),
                reason: 'the unrelated note was copied into the reply');
          }
          expect({a, b, c}.length, greaterThan(1),
              reason: 'three different questions got one reply');
          if (id == AIModelId.gemma4E2b) {
            expect(a.toLowerCase(), contains('paris'));
            expect(b.toLowerCase(), contains('tokyo'));
            expect(c.toLowerCase(), contains('rome'));
          }

          bloc.add(const ShivAIEvent.closeConversation());
          await bloc.close();

          bloc = await _openChat();
          final d = await _ask(bloc, 'What is the capital of Spain? One word.');
          // ignore: avoid_print
          print('CHAT199[${id.name}] new chat: "$d"');
          if (id == AIModelId.gemma4E2b) {
            expect(d.toLowerCase(), contains('madrid'));
          }
          expect(d.toLowerCase(), isNot(contains('marmalade')));
          expect(d, isNotEmpty);
          await bloc.close();
        },
        timeout: const Timeout(Duration(minutes: 20)),
      );
    }
  });

  group('#123 the dots and Stop while a reply is pending', () {
    testWidgets(
      'Gemma: dots and Stop show from send until the reply, and Stop ends '
      'the turn',
      (tester) async {
        expect(await provisionTestModel(AIModelId.gemma4E2b), isTrue,
            reason: 'no Gemma 4 E2B fixture on the phone');
        await _boot();
        await getIt<SetActiveLlmBackendUseCase>()
            .call(LlmBackendType.localGemma);

        final bloc = await _openChat();
        await tester.pumpWidget(
          BlocProvider.value(
            value: bloc,
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: ShivChatPage(onDrawerChanged: (_) {}),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));

        Finder dots() => find.byKey(const ValueKey('shiv-typing-indicator'));
        final stop = find.byIcon(Icons.stop_rounded);
        final send = find.byIcon(Icons.arrow_upward_rounded);

        await tester.enterText(
          find.byType(TextField).first,
          'Name one primary colour. Answer in one word.',
        );
        await tester.pump();
        await tester.tap(send);
        await tester.pump(const Duration(milliseconds: 300));

        // Straight after sending, before any token: dots and Stop are there.
        expect(stop, findsOneWidget, reason: 'Stop missing while waiting');
        expect(dots(), findsOneWidget, reason: 'dots missing while waiting');

        // Until the reply ends there is always something on screen: the dots,
        // or text. Never a blank bubble, and Stop stays.
        var sawText = false;
        final deadline = DateTime.now().add(const Duration(minutes: 4));
        while (bloc.state.status == ShivChatStatus.streaming &&
            DateTime.now().isBefore(deadline)) {
          await tester.pump(const Duration(milliseconds: 250));
          if (bloc.state.status != ShivChatStatus.streaming) break;
          expect(stop, findsOneWidget, reason: 'Stop vanished mid-reply');
          final streamed = bloc.state.streamingContent ?? '';
          if (streamed.trim().isEmpty) {
            expect(dots(), findsOneWidget, reason: 'blank bubble, no dots');
          } else {
            sawText = true;
            expect(dots(), findsNothing);
          }
        }
        await tester.pump(const Duration(milliseconds: 500));
        expect(bloc.state.status, ShivChatStatus.chatIdle,
            reason: bloc.state.errorMessage);
        expect(sawText || bloc.state.messages.last.content.isNotEmpty, isTrue,
            reason: 'the reply ended blank');
        expect(send, findsOneWidget, reason: 'Send did not come back');
        expect(dots(), findsNothing);

        // Second turn: stop it right away.
        await tester.enterText(find.byType(TextField).first, 'Tell me a story.');
        await tester.pump();
        await tester.tap(send);
        await tester.pump(const Duration(milliseconds: 300));
        if (bloc.state.status == ShivChatStatus.streaming) {
          expect(stop, findsOneWidget);
          await tester.tap(stop);
          await tester.pump(const Duration(milliseconds: 500));
          expect(bloc.state.status, ShivChatStatus.chatIdle,
              reason: 'Stop did not end the turn');
        }
        expect(send, findsOneWidget);
        expect(bloc.state.messages.last.content, isNotEmpty,
            reason: 'a stopped reply must not stay blank');
        await tester.pump(const Duration(seconds: 1));
      },
      timeout: const Timeout(Duration(minutes: 15)),
    );
  });

  group('#139 Nataraj on a local model', () {
    testWidgets('the deck fills three times with bounded memory',
        (tester) async {
      expect(await provisionTestModel(AIModelId.gemma4E2b), isTrue,
          reason: 'no Gemma 4 E2B fixture on the phone');
      await _boot();
      await getIt<SetActiveLlmBackendUseCase>().call(LlmBackendType.localGemma);

      var keys = await getIt<UserRepository>().getActiveKeysHex();
      if (keys == null) {
        expect((await getIt<UserRepository>().generateKey()).isRight(), isTrue);
        keys = await getIt<UserRepository>().getActiveKeysHex();
      }
      final isar = getIt<Isar>();
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final ids = [for (var i = 0; i < 4; i++) 'e2e-nataraj-$stamp-$i'];
      const texts = [
        'Sourdough needs a long, cold rise to build flavour.',
        'The trail to the lake is closed until the snow melts.',
        'A good index turns a minute-long query into milliseconds.',
        'Watercolour paper should be stretched before painting.',
      ];
      await isar.writeTxn(() async {
        for (final (i, id) in ids.indexed) {
          await isar.noteModels.put(
            NoteModel(
              eventId: id,
              sig: '',
              authorPubkey: keys!.pubkeyHex,
              content: texts[i],
              type: NoteType.text,
              eTagRefs: const [],
              pTagRefs: const [],
              tTags: const [],
              created: DateTime.now(),
            ),
          );
        }
      });

      try {
        final generator = getIt<NatarajGenerator>();
        final before =
            (await FlutterEdgeAiDiagnostics.memorySnapshot()).anonymousBytes!;
        var inserted = 0;
        for (var round = 0; round < 3; round++) {
          final r = await generator.fillBuffer(manasIds: const [], count: 1);
          // ignore: avoid_print
          print('NATARAJ round $round: ${r.state} inserted=${r.inserted}');
          expect(r.state, isNot(NatarajFillState.error));
          inserted += r.inserted;
        }
        final after =
            (await FlutterEdgeAiDiagnostics.memorySnapshot()).anonymousBytes!;
        // ignore: avoid_print
        print('NATARAJ inserted=$inserted memory growth='
            '${(after - before) ~/ _mib} MiB');
        expect(inserted, greaterThan(0), reason: 'no card was generated');
        expect((after - before) ~/ _mib, lessThan(300));
      } finally {
        await isar.writeTxn(
          () => isar.noteModels
              .filter()
              .eventIdStartsWith('e2e-nataraj-$stamp')
              .deleteAll(),
        );
      }
    }, timeout: const Timeout(Duration(minutes: 20)));
  });
}
