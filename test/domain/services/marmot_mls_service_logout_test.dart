import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:uniun/domain/services/marmot_mls_service.dart';

import '../../_helpers/fake_path_provider.dart';

/// Logout removes MLS database files and signer secrets for the old account.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late PathProviderPlatform originalPathProvider;
  const secure = FlutterSecureStorage();

  setUp(() async {
    root = await Directory.systemTemp.createTemp('uniun_mls_logout_');
    originalPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = FakePathProviderPlatform(
      docs: root.path,
      support: root.path,
    );
    FlutterSecureStorage.setMockInitialValues({});
  });

  tearDown(() async {
    PathProviderPlatform.instance = originalPathProvider;
    await root.delete(recursive: true);
  });

  test(
    'removes database, sidecars, and signer keys but keeps unrelated files',
    () async {
      final database = File(p.join(root.path, 'mls_data.db'));
      final wal = File(p.join(root.path, 'mls_data.db-wal'));
      final unrelated = File(p.join(root.path, 'keep.txt'));
      await database.writeAsString('old private groups');
      await wal.writeAsString('old pending MLS writes');
      await unrelated.writeAsString('device file');
      await secure.write(key: 'uniun_mls_db_key', value: 'old-db-key');
      await secure.write(
        key: 'uniun_mls_signer_private_key',
        value: 'old-private-key',
      );
      await secure.write(
        key: 'uniun_mls_signer_public_key',
        value: 'old-public-key',
      );

      await MarmotMlsService().resetForLogout();

      expect(await database.exists(), isFalse);
      expect(await wal.exists(), isFalse);
      expect(await unrelated.readAsString(), 'device file');
      expect(await secure.read(key: 'uniun_mls_db_key'), isNull);
      expect(await secure.read(key: 'uniun_mls_signer_private_key'), isNull);
      expect(await secure.read(key: 'uniun_mls_signer_public_key'), isNull);
    },
  );
}
