import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:openmls/openmls.dart';
import 'package:path_provider/path_provider.dart';

@lazySingleton
class MarmotMlsService {
  static const _storage = FlutterSecureStorage();
  static const _mlsKeyKey = 'uniun_mls_db_key';
  static const _mlsSignerPrivateKey = 'uniun_mls_signer_private_key';
  static const _mlsSignerPublicKey = 'uniun_mls_signer_public_key';

  MlsEngine? _engine;
  MlsCiphersuite _ciphersuite =
      MlsCiphersuite.mls128DhkemX25519Aes128GcmSha256Ed25519;
  Uint8List? _sessionPrivateKey;
  Uint8List? _sessionPublicKey;
  bool _initialized = false;

  MlsEngine get engine {
    if (_engine == null) {
      throw Exception('MlsEngine not initialized. Call _ensureInitialized first.');
    }
    return _engine!;
  }

  /// Lazily initializes the MLS engine on first use.
  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await init();
  }

  Future<void> init() async {
    if (_initialized) return;

    await Openmls.init();

    // 1. Get or generate the 32-byte encryption key for MlsEngine
    String? b64Key = await _storage.read(key: _mlsKeyKey);
    Uint8List encryptionKey;
    if (b64Key != null) {
      encryptionKey = base64Decode(b64Key);
    } else {
      final random = Random.secure();
      encryptionKey = Uint8List.fromList(List.generate(32, (_) => random.nextInt(256)));
      await _storage.write(key: _mlsKeyKey, value: base64Encode(encryptionKey));
    }

    // 2. Open MlsEngine with SQLCipher using the app documents path
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = '${dir.path}/mls_data.db';

    _engine = await MlsEngine.create(
      dbPath: dbPath,
      encryptionKey: encryptionKey,
    );

    _ciphersuite = MlsCiphersuite.mls128DhkemX25519Aes128GcmSha256Ed25519;
    await _ensureSignerMaterial();
    _initialized = true;
    debugPrint("MarmotMlsService: initialized MlsEngine at $dbPath");
  }

  /// Closes the MLS engine safely.
  Future<void> close() async {
    if (_engine != null) {
      await _engine!.close();
      _engine = null;
      _initialized = false;
    }
  }

  /// Remove private-group state and signer material from the previous account.
  Future<void> resetForLogout() async {
    await close();
    final dir = await getApplicationDocumentsDirectory();
    await for (final entry in dir.list()) {
      if (entry is File &&
          entry.uri.pathSegments.last.startsWith('mls_data.db')) {
        await entry.delete();
      }
    }
    await _storage.delete(key: _mlsKeyKey);
    await _storage.delete(key: _mlsSignerPrivateKey);
    await _storage.delete(key: _mlsSignerPublicKey);
    _sessionPrivateKey = null;
    _sessionPublicKey = null;
  }

  /// Generates a new MLS Signature KeyPair for the user (internal, no init guard needed).
  MlsSignatureKeyPair _generateKeyPairInternal() {
    return MlsSignatureKeyPair.generate(ciphersuite: _ciphersuite);
  }

  /// Returns the serialized signer payload required for operations.
  Uint8List getSignerBytes() {
    final privateKey = _sessionPrivateKey;
    final publicKey = _sessionPublicKey;
    if (privateKey == null || publicKey == null) {
      throw Exception('MLS signer material not initialized.');
    }
    return serializeSigner(
      ciphersuite: _ciphersuite,
      privateKey: privateKey,
      publicKey: publicKey,
    );
  }

  Future<void> _ensureSignerMaterial() async {
    final savedPrivateB64 = await _storage.read(key: _mlsSignerPrivateKey);
    final savedPublicB64 = await _storage.read(key: _mlsSignerPublicKey);
    if (savedPrivateB64 != null && savedPublicB64 != null) {
      _sessionPrivateKey = base64Decode(savedPrivateB64);
      _sessionPublicKey = base64Decode(savedPublicB64);
      return;
    }

    final keyPair = _generateKeyPairInternal();
    final privateKey = keyPair.privateKey();
    final publicKey = keyPair.publicKey();
    _sessionPrivateKey = privateKey;
    _sessionPublicKey = publicKey;

    await _storage.write(
      key: _mlsSignerPrivateKey,
      value: base64Encode(privateKey),
    );
    await _storage.write(
      key: _mlsSignerPublicKey,
      value: base64Encode(publicKey),
    );
  }

  /// Generates an MLS KeyPackage for joining a group
  Future<String> generateKeyPackage({required String pubkeyHex}) async {
    await _ensureInitialized();
    final signerBytes = getSignerBytes();
    final signerPublicKey = _sessionPublicKey;
    if (signerPublicKey == null) {
      throw Exception('MLS signer public key is not initialized.');
    }
    final kpResult = await engine.createKeyPackage(
      ciphersuite: _ciphersuite,
      signerBytes: signerBytes,
      credentialIdentity: utf8.encode(pubkeyHex),
      signerPublicKey: signerPublicKey,
    );
    return base64Encode(kpResult.keyPackageBytes);
  }

  /// Creates a new local MLS group.
  Future<CreateGroupResult> createGroup({
    required String creatorPubkeyHex,
  }) async {
    await _ensureInitialized();
    final config = MlsGroupConfig.defaultConfig(ciphersuite: _ciphersuite);
    final signerBytes = getSignerBytes();
    final signerPublicKey = _sessionPublicKey;
    if (signerPublicKey == null) {
      throw Exception('MLS signer public key is not initialized.');
    }
    
    return await engine.createGroup(
      config: config,
      signerBytes: signerBytes,
      credentialIdentity: utf8.encode(creatorPubkeyHex),
      signerPublicKey: signerPublicKey,
    );
  }

  /// Encrypts an application message for the specified group
  Future<String> encryptMessage({
    required String groupId,
    required String content,
    bool groupIdIsBase64 = false,
  }) async {
    await _ensureInitialized();
    final signerBytes = getSignerBytes();
    final groupIdBytes = groupIdIsBase64 ? base64Decode(groupId) : utf8.encode(groupId);
    final result = await engine.createMessage(
      groupIdBytes: groupIdBytes,
      signerBytes: signerBytes,
      message: utf8.encode(content),
    );
    return base64Encode(result.ciphertext);
  }

  /// Decrypts an incoming message for the specified group
  Future<List<int>> decryptMessage({
    required String groupId,
    required String base64Payload,
    bool groupIdIsBase64 = false,
  }) async {
    await _ensureInitialized();
    final msgBytes = base64Decode(base64Payload);
    final groupIdBytes = groupIdIsBase64 ? base64Decode(groupId) : utf8.encode(groupId);
    final result = await engine.processMessage(
      groupIdBytes: groupIdBytes,
      messageBytes: msgBytes,
    );
    
    if (result.applicationMessage != null) {
      return result.applicationMessage!;
    }
    return [];
  }

  /// Adds a member to the MLS group using their KeyPackage
  Future<AddMembersResult> addMembers({
    required String groupId,
    required List<String> keyPackagesB64,
    bool groupIdIsBase64 = false,
  }) async {
    await _ensureInitialized();
    final signerBytes = getSignerBytes();
    final kpBytes = keyPackagesB64.map((b64) => base64Decode(b64)).toList();
    final groupIdBytes = groupIdIsBase64 ? base64Decode(groupId) : utf8.encode(groupId);

    return await engine.addMembers(
      groupIdBytes: groupIdBytes,
      signerBytes: signerBytes,
      keyPackagesBytes: kpBytes,
    );
  }

  /// Joins a group from an MLS Welcome message and returns the group id as base64.
  Future<String> joinGroupFromWelcome({
    required String welcomeB64,
  }) async {
    await _ensureInitialized();
    final signerBytes = getSignerBytes();
    final config = MlsGroupConfig.defaultConfig(ciphersuite: _ciphersuite);
    final result = await engine.joinGroupFromWelcome(
      config: config,
      welcomeBytes: base64Decode(welcomeB64),
      signerBytes: signerBytes,
    );
    return base64Encode(result.groupId);
  }

  /// Applies a non-application MLS protocol message (for example Commit).
  Future<void> processProtocolMessage({
    required String groupId,
    required String base64Payload,
    bool groupIdIsBase64 = false,
  }) async {
    await _ensureInitialized();
    final groupIdBytes = groupIdIsBase64 ? base64Decode(groupId) : utf8.encode(groupId);
    await engine.processMessage(
      groupIdBytes: groupIdBytes,
      messageBytes: base64Decode(base64Payload),
    );
  }

  /// Leaves a local MLS group.
  Future<void> leaveGroup({
    required String groupId,
    bool groupIdIsBase64 = false,
  }) async {
    await _ensureInitialized();
    final signerBytes = getSignerBytes();
    final groupIdBytes = groupIdIsBase64 ? base64Decode(groupId) : utf8.encode(groupId);
    await engine.leaveGroup(
      groupIdBytes: groupIdBytes,
      signerBytes: signerBytes,
    );
  }
}
