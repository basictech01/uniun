// Real-device check of the note vector store in its own isolate (#232): the same
// 300 saves and 300 searches run once with ToStore on the main isolate and once
// through NoteVectorStore, while a 2 ms timer on the main isolate records stalls
// (a stall over 16 ms is a dropped frame). Also checks that every stored vector
// is found by itself. Prints STORE lines; asserts recall and that the isolate
// store never stalls the main isolate for more than 250 ms.
//
//   scripts/device_test.sh run integration_test/note_vector_store_e2e_test.dart

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tostore/tostore.dart';
import 'package:uniun/data/datasources/note_vector_store.dart';

const _notes = 300;
// The embedder emits 768 values where the app declares 1024 (#234).
const _dim = 768;

List<double> _vec(int seed) {
  final r = Random(seed);
  final v = [for (var i = 0; i < _dim; i++) r.nextDouble() - .5];
  final norm = sqrt(v.fold<double>(0, (a, b) => a + b * b));
  return [for (final x in v) x / norm];
}

typedef _Run = ({
  int ms,
  double worstStallMs,
  int over16,
  int over50,
  int found,
});

/// Times [work] and records the largest gap between 2 ms timer ticks on this isolate.
Future<_Run> _measure(Future<int> Function() work) async {
  final gaps = <int>[];
  var last = DateTime.now().microsecondsSinceEpoch;
  final timer = Timer.periodic(const Duration(milliseconds: 2), (_) {
    final now = DateTime.now().microsecondsSinceEpoch;
    gaps.add(now - last);
    last = now;
  });
  final sw = Stopwatch()..start();
  final found = await work();
  timer.cancel();
  gaps.sort();
  return (
    ms: sw.elapsedMilliseconds,
    worstStallMs: gaps.last / 1000,
    over16: gaps.where((g) => g > 16000).length,
    over50: gaps.where((g) => g > 50000).length,
    found: found,
  );
}

String _line(String name, _Run r) =>
    'STORE $name: took ${r.ms} ms, worst main-isolate stall '
    '${r.worstStallMs.toStringAsFixed(1)} ms, stalls >16 ms: ${r.over16}, '
    '>50 ms: ${r.over50}, found by own vector: ${r.found}/$_notes';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the store in its own isolate keeps the main isolate smooth and '
      'finds what it saved', (tester) async {
    final base = await Directory.systemTemp.createTemp('store_e2e_');
    try {
      // The same work with ToStore opened on THIS isolate (what the app did).
      final onMain = await _measure(() async {
        final db = await ToStore.open(
          dbPath: '${base.path}/main',
          schemas: [
            const TableSchema(
              name: embeddingsTableName,
              primaryKeyConfig: PrimaryKeyConfig(
                name: embeddingsIdField,
                type: PrimaryKeyType.none,
              ),
              fields: [
                FieldSchema(
                  name: embeddingsVectorField,
                  type: DataType.vector,
                  vectorConfig: VectorFieldConfig(
                    dimensions: embeddingsDimensions,
                  ),
                ),
              ],
              indexes: [
                IndexSchema(
                  fields: [embeddingsVectorField],
                  type: IndexType.vector,
                  vectorConfig: VectorIndexConfig(),
                ),
              ],
            ),
          ],
        );
        for (var i = 0; i < _notes; i++) {
          await db.upsert(embeddingsTableName, {
            embeddingsIdField: 'n$i',
            embeddingsVectorField: _vec(i),
          });
          await db.flush();
        }
        var found = 0;
        for (var i = 0; i < _notes; i++) {
          final hits = await db.vectorSearch(
            embeddingsTableName,
            fieldName: embeddingsVectorField,
            queryVector: VectorData.fromList(_vec(i)),
            topK: 5,
          );
          if (hits.isNotEmpty && hits.first.primaryKey == 'n$i') found++;
        }
        await db.close();
        return found;
      });

      // The same work through the isolate-owned store.
      final store = await NoteVectorStore.open('${base.path}/isolate');
      final inIsolate = await _measure(() async {
        for (var i = 0; i < _notes; i++) {
          await store.upsert('n$i', _vec(i));
        }
        var found = 0;
        for (var i = 0; i < _notes; i++) {
          final hits = await store.search(_vec(i), topK: 5);
          if (hits.isNotEmpty && hits.first.id == 'n$i') found++;
        }
        return found;
      });
      await store.close();

      // ignore: avoid_print
      print(
        '\n${_line('ToStore on the main isolate', onMain)}'
        '\n${_line('NoteVectorStore in its own isolate', inIsolate)}\n',
      );

      expect(inIsolate.found, greaterThanOrEqualTo(_notes - 3));
      expect(inIsolate.worstStallMs, lessThan(250));
    } finally {
      await base.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 15)));
}
