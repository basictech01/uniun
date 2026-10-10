// Aggregator entry point for ALL device-bound integration tests.
//
// Why this file exists: `flutter test integration_test/` installs the app
// FRESH per test file. If `flutter_gemma_bg_isolate_test.dart` needs a
// downloaded model and the next file reinstalls the APK, the model is gone
// → every subsequent test SKIPs. Running this aggregator instead bundles
// every test file's `main()` into a single app launch, so the model (and
// any other on-device state) persists across the whole suite.
//
// Run with:
//   flutter test integration_test/all_tests.dart -d <device-id>
//
// To add a new device-bound test: drop a `*_test.dart` file in this folder
// AND add an import + main() call below. (Yes it's manual — there is no
// glob in Dart imports. The list is the source of truth.)

import 'package:integration_test/integration_test.dart';

import 'gana_dashboard_e2e_test.dart' as gana_dashboard_e2e_test;
import 'chat_image_turn_test.dart' as chat_image_turn_test;
import 'cloud_concurrent_calls_test.dart' as cloud_concurrent_calls_test;
import 'flutter_gemma_bg_isolate_test.dart' as flutter_gemma_bg_isolate_test;
import 'gana_cloud_combinations_e2e_test.dart'
    as gana_cloud_combinations_e2e_test;
import 'gana_cloud_engine_e2e_test.dart' as gana_cloud_engine_e2e_test;
import 'gana_cloud_pipeline_test.dart' as gana_cloud_pipeline_test;
import 'note_save_timing_e2e_test.dart' as note_save_timing_e2e_test;
import 'chat_embed_contention_e2e_test.dart' as chat_embed_contention_e2e_test;
import 'embedding_priority_e2e_test.dart' as embedding_priority_e2e_test;
import 'note_embedding_queue_e2e_test.dart' as note_embedding_queue_e2e_test;
import 'note_vector_store_e2e_test.dart' as note_vector_store_e2e_test;
import 'unread_dots_e2e_test.dart' as unread_dots_e2e_test;
import 'knowledge_extraction_cost_e2e_test.dart'
    as knowledge_extraction_cost_e2e_test;
import 'gana_local_engine_e2e_test.dart' as gana_local_engine_e2e_test;
import 'document_rag_e2e_test.dart' as document_rag_e2e_test;
import 'document_viewer_e2e_test.dart' as document_viewer_e2e_test;
import 'scheduler_model_switch_test.dart' as scheduler_model_switch_test;
import 'scheduler_preemption_test.dart' as scheduler_preemption_test;
import 'logout_account_switch_e2e_test.dart' as logout_account_switch_e2e_test;
import 'manas_membership_e2e_test.dart' as manas_membership_e2e_test;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  flutter_gemma_bg_isolate_test.main();
  chat_image_turn_test.main();
  gana_dashboard_e2e_test.main();
  scheduler_preemption_test.main();
  scheduler_model_switch_test.main();
  gana_cloud_pipeline_test.main();
  cloud_concurrent_calls_test.main();
  gana_cloud_engine_e2e_test.main();
  gana_cloud_combinations_e2e_test.main();
  gana_local_engine_e2e_test.main();
  document_rag_e2e_test.main();
  document_viewer_e2e_test.main();
  note_embedding_queue_e2e_test.main();
  note_vector_store_e2e_test.main();
  embedding_priority_e2e_test.main();
  chat_embed_contention_e2e_test.main();
  note_save_timing_e2e_test.main();
  knowledge_extraction_cost_e2e_test.main();
  unread_dots_e2e_test.main();
  manas_membership_e2e_test.main();
  logout_account_switch_e2e_test.main();
}
