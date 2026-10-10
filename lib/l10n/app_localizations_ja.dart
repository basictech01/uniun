// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String appVersion(String version) {
    return 'UNIUN v$version';
  }

  @override
  String get appTagline => 'あなたのノート、あなたの\nネットワーク、あなたのアイデンティティ。';

  @override
  String get navVishnu => 'VISHNU';

  @override
  String get navBrahma => 'BRAHMA';

  @override
  String get navShiv => 'SHIV';

  @override
  String get actionCopy => 'コピー';

  @override
  String get actionCopied => 'コピーされました';

  @override
  String get actionRetry => '再試行';

  @override
  String get actionContinue => '続ける';

  @override
  String get actionDelete => '削除';

  @override
  String get actionSave => '保存';

  @override
  String get actionCancel => 'キャンセル';

  @override
  String get actionBack => '戻る';

  @override
  String get actionDone => '完了';

  @override
  String get actionSaved => '保存されました';

  @override
  String get actionFollow => 'フォローする';

  @override
  String get actionFollowing => 'フォロー中';

  @override
  String get drawerHome => 'ホーム';

  @override
  String get drawerSavedNotes => '保存されたノート';

  @override
  String get drawerGroups => 'グループ';

  @override
  String get drawerDirectMessages => 'ダイレクトメッセージ';

  @override
  String get drawerApps => 'アプリ';

  @override
  String get drawerAiAssistant => 'AIアシスタント';

  @override
  String get drawerSettings => '設定';

  @override
  String get drawerFollowingNotes => 'ウォッチ中のノート';

  @override
  String get drawerNoFollowedNotes => 'ウォッチ中のノートはありません';

  @override
  String get drawerNoGroups => 'まだグループがありません';

  @override
  String get drawerMyQrCode => '私のQRコード';

  @override
  String get drawerScanCode => 'コードをスキャン';

  @override
  String get drawerPrivateLabel => 'プライベート';

  @override
  String get drawerSearchKindDm => 'ダイレクトメッセージ';

  @override
  String get drawerSearchKindUser => 'フォロー中';

  @override
  String get joinGroupTitle => 'グループに参加する';

  @override
  String get joinGroupHeading => '既存のグループに参加する';

  @override
  String get joinGroupAction => 'グループに参加する';

  @override
  String get joinGroupIdLabel => 'グループID (16進数)';

  @override
  String get joinGroupRelaysTitle => 'グループリレー';

  @override
  String get joinGroupRelaysBody => 'このグループが動作するリレーを選択して、同期を開始します。';

  @override
  String get joinGroupSelectRelays => 'リレーの選択';

  @override
  String joinGroupSelectedRelays(int count) {
    return '選択したリレー: $count件';
  }

  @override
  String get joinGroupAddRelay => 'リレーの追加';

  @override
  String get joinGroupAddRelayAction => '追加';

  @override
  String get joinGroupRelayHint => 'wss://relay.example.com';

  @override
  String get joinGroupByQr => 'QRで参加';

  @override
  String get joinGroupScanCardTitle => 'グループのQRコードをスキャン';

  @override
  String get joinGroupScanCardSubtitle => 'UNIUNグループコードにカメラを向けてください';

  @override
  String get joinGroupOr => 'または';

  @override
  String get joinGroupIdHint => 'グループIDを貼り付け';

  @override
  String get joinGroupQrTitle => 'グループのQRコードをスキャン';

  @override
  String get joinGroupQrHint => 'グループIDとリレーリストを含むQRコードをスキャンします。';

  @override
  String get joinGroupQrFromGallery => 'ギャラリーからQRを選択';

  @override
  String get joinGroupQrGalleryError => '選択した画像に有効な QR コードが見つかりません。';

  @override
  String get joinGroupSuccess => 'グループに参加しました。';

  @override
  String get joinGroupErrorInvalidId =>
      'これは有効なグループ ID ではないようです。確認してもう一度試してください。';

  @override
  String get joinGroupErrorNoRelay => '少なくとも 1 つのリレーを選択してください。';

  @override
  String get joinGroupErrorRelaySaveFailed => 'リレーをローカルに保存できませんでした。';

  @override
  String get joinGroupErrorSaveFailed => 'グループに参加できませんでした。もう一度試してください。';

  @override
  String get groupMessageHint => 'グループにメッセージを送信…';

  @override
  String get chatMessageHint => 'メッセージ…';

  @override
  String get dmEncryptedNotice => 'メッセージはエンドツーエンドで暗号化されます';

  @override
  String get groupShareQrTitle => 'グループQRを共有する';

  @override
  String get groupShareQrBody => 'このQRコードをスキャンすると、必要なリレー情報を使ってグループに参加できます。';

  @override
  String get drawerNoMessages => 'まだメッセージはありません';

  @override
  String get drawerSearchHint => '検索';

  @override
  String get drawerSearchNoResults => '一致しません';

  @override
  String get drawerCopyNpub => 'npubをコピーする';

  @override
  String get drawerNpubCopied => 'npub がコピーされました';

  @override
  String drawerComingSoon(String feature) {
    return '$feature — 近日公開予定';
  }

  @override
  String get brahmaTitle => 'Brahma';

  @override
  String get brahmaTagline => 'Nostr に書いて公開する';

  @override
  String get brahmaHintText => '新しいノートを書く…';

  @override
  String get brahmaSubjectHintText => '件名 (オプション)';

  @override
  String get brahmaAddImage => '画像を追加';

  @override
  String get brahmaTagPeople => '人物にタグを付ける';

  @override
  String get brahmaReferenceNote => 'ノートを参照';

  @override
  String get brahmaMentionSheetTitle => 'ノートを参照';

  @override
  String get brahmaMentionSearchHint => 'ノートを検索…';

  @override
  String get brahmaMentionEmpty => 'ノートが見つかりませんでした';

  @override
  String get brahmaMentionSelected => '言及済み';

  @override
  String get composerReferenceTitle => '参照の追加';

  @override
  String get composerReferenceSearchHint => '検索…';

  @override
  String get composerReferenceEmpty => '結果はありません';

  @override
  String get composerReferenceTabAll => 'すべて';

  @override
  String get composerReferenceTabSaved => '保存されました';

  @override
  String get composerReferenceTabOwn => '私のノート';

  @override
  String get composerReferenceTabDrafts => '下書き';

  @override
  String get composerReferenceAdd => '追加';

  @override
  String get composerChatPickerTitle => 'ノートを使ってチャットする';

  @override
  String get composerChatPickerSubtitle => '対象のManasを選択';

  @override
  String get composerChatBrand => 'Shiv';

  @override
  String get composerChatAllNotes => 'すべてのノート';

  @override
  String get composerChatAllNotesSubtitle => 'Brahmaに質問';

  @override
  String composerChatManasNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ノート$count件',
      one: 'ノート1件',
    );
    return '$_temp0';
  }

  @override
  String composerChatScopeEyebrow(String scope) {
    return '$scope · デバイス上';
  }

  @override
  String composerChatGroundedHint(String scope) {
    return '$scopeに基づいて回答';
  }

  @override
  String get composerChatThinking => '考え中…';

  @override
  String get composerChatStop => '停止';

  @override
  String get composerChatNoModel => '有効なAIモデルがありません。Shivタブからダウンロードしてください。';

  @override
  String get composerChatError => '何か問題が発生しました。';

  @override
  String get composerChatUseAsReply => '返信として使用';

  @override
  String get threadReferencesLabel => '参照';

  @override
  String get threadReplyingToLabel => '返信先';

  @override
  String get brahmaCreateNote => 'ノートの作成';

  @override
  String get brahmaFailedToPublish => '公開できませんでした';

  @override
  String get brahmaGraphPreviewLabel => 'リファレンスグラフのプレビュー';

  @override
  String get brahmaInteractivePreview => 'インタラクティブなプレビュー';

  @override
  String get brahmaDraft => '下書き';

  @override
  String get markdownToolbarHeading => '見出し';

  @override
  String get markdownToolbarBold => '太字';

  @override
  String get markdownToolbarItalic => 'イタリック体';

  @override
  String get markdownToolbarCode => 'インラインコード';

  @override
  String get markdownToolbarBulletList => '箇条書きリスト';

  @override
  String get markdownToolbarNumberList => '番号付きリスト';

  @override
  String get markdownToolbarQuote => '引用';

  @override
  String get markdownToolbarLink => 'リンク';

  @override
  String get brahmaDraftSaved => '下書きが保存されました';

  @override
  String get brahmaDrafts => '下書き';

  @override
  String get brahmaPublish => '公開';

  @override
  String get brahmaDraftPublished => 'ノートとして公開しました';

  @override
  String get brahmaTags => 'タグ';

  @override
  String get brahmaPublishChainTitle => 'このノートは他の下書きを参照しています';

  @override
  String brahmaPublishChainSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '未公開の下書き$count件',
      one: '未公開の下書き1件',
    );
    return 'Nostrのノートは公開後に変更できません。$_temp0への参照を追加できるのは今だけです。';
  }

  @override
  String get brahmaPublishChain => 'チェーン全体を公開する';

  @override
  String brahmaPublishChainBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'リンク先の下書き$count件',
      one: 'リンク先の下書き1件',
    );
    return '最初に$_temp0を公開し、そのリンクをタグに含めてこのノートを公開します。';
  }

  @override
  String get brahmaPublishOnlyThis => 'これだけ公開';

  @override
  String get brahmaPublishOnlyThisSubtitle =>
      'このノートからドラフト参照を削除します。他のドラフトはそのまま残ります。';

  @override
  String get vishnuNoNotes => 'まだノートはありません';

  @override
  String get vishnuCreateFirst => 'Brahmaで最初のノートを作成するか、リレーの同期をお待ちください。';

  @override
  String get vishnuThread => 'スレッド';

  @override
  String vishnuReferences(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '参照$countString件',
      one: '参照1件',
    );
    return '$_temp0';
  }

  @override
  String get vishnuReferenceUnavailable => '参照されたノートは利用できません';

  @override
  String vishnuNewNotesBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '新しいノート$count件',
      one: '新しいノート1件',
    );
    return '$_temp0';
  }

  @override
  String get homeShivTitle => 'Shiv — AI アシスタント';

  @override
  String get homeShivComingSoon => 'オンデバイス AI も近日登場予定。';

  @override
  String get threadTitle => 'スレッド';

  @override
  String get threadReplies => '返信';

  @override
  String get threadReferences => '参照';

  @override
  String get threadNoReplies => 'まだ返信はありません';

  @override
  String get threadBeFirstToReply => '最初に返信しましょう。';

  @override
  String get threadNoReferences => '参照はありません';

  @override
  String get threadNoReferencesDetail => 'これを参照するノートはまだありません。';

  @override
  String get threadPost => 'ポスト';

  @override
  String get threadReplyToThis => 'このノートに返信…';

  @override
  String threadReplyTo(String name) {
    return '@$nameに返信…';
  }

  @override
  String threadReplyingTo(String name) {
    return '@$nameに返信中';
  }

  @override
  String get threadContinuation => 'スレッドの継続';

  @override
  String threadNReplies(int count) {
    return '$count 返信';
  }

  @override
  String threadUpdated(String time) {
    return '更新: $time';
  }

  @override
  String get followedNoteViewThread => 'スレッドを見る';

  @override
  String get followedNoteFailedToLoad => 'ノートのロードに失敗しました';

  @override
  String get followedNoteResearchNode => 'リサーチノード';

  @override
  String get followedNoteFollowing => 'フォロー中';

  @override
  String get followedNoteReferencedBy => '返信';

  @override
  String get followedNoteReferences => '参照';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsAccount => 'アカウント';

  @override
  String get settingsIdentity => 'アイデンティティ';

  @override
  String get settingsAiShiv => 'AI・Shiv';

  @override
  String get settingsStorage => 'ストレージ';

  @override
  String get settingsAbout => 'アプリについて';

  @override
  String get settingsVersion => 'バージョン';

  @override
  String get settingsLogout => 'ログアウト';

  @override
  String get settingsLogoutTitle => 'ログアウトしますか？';

  @override
  String get settingsLogoutBody =>
      'この端末のノート、チャット、アカウントデータは削除されます。再度ログインするには秘密鍵（nsec）が必要です。秘密鍵をバックアップしていることを確認してください。';

  @override
  String get settingsKeepDownloadedModels => 'ダウンロード済みのAIモデルを次のログイン用に保持する';

  @override
  String get settingsLoggingOut => 'ログアウト中…';

  @override
  String get settingsLogoutConfirm => 'ログアウト';

  @override
  String get settingsAlerts => 'アラート';

  @override
  String get settingsStyle => 'スタイル';

  @override
  String get profileAnonymous => '匿名';

  @override
  String get profileEditProfile => 'プロフィールの編集';

  @override
  String get identityLoginRecovery => 'これがログインと回復方法です。';

  @override
  String get identityKeys => 'キー';

  @override
  String get identityRelays => 'リレー';

  @override
  String get identityPrivacyPolicy => 'プライバシーとポリシー';

  @override
  String get identityYourKeys => 'あなたの鍵';

  @override
  String get identityNeverShare => '秘密キーを誰とも共有しないでください。';

  @override
  String get identityPublicKey => '公開鍵 (npub)';

  @override
  String get identityPublicKeyCopied => '公開鍵がコピーされました';

  @override
  String get identityPrivateKey => '秘密鍵 (nsec)';

  @override
  String get identityRevealPrivateKey => '秘密鍵を表示';

  @override
  String get identityNeverShareKey => 'この秘密鍵を共有しないでください';

  @override
  String get identityTapToCopy => 'タップしてコピー';

  @override
  String get identityHide => '非表示';

  @override
  String get identityPrivateKeyCopied => '秘密鍵をコピーしました。安全に保管してください。';

  @override
  String get identityRelaysSheetTitle => 'リレー';

  @override
  String get identityRelaysSubtitle => 'Nostrクライアントはリレーに接続して通信します。';

  @override
  String get identityRelaysComingSoon => 'カスタムリレー管理は近日公開予定です。';

  @override
  String get alertsDmAlerts => 'DMアラート';

  @override
  String get alertsGroupAlerts => 'グループアラート';

  @override
  String get storageUsage => 'ストレージの使用量';

  @override
  String get storageNoteData => 'ノートデータ';

  @override
  String get storageAiModels => 'AIモデル';

  @override
  String get storageAiModelsSubtitle => 'ダウンロードしたモデルファイル';

  @override
  String get storageTotal => '合計';

  @override
  String storageNotes(int count) {
    return '$count のノート';
  }

  @override
  String get storageRemoveData => 'データの削除';

  @override
  String get storageShowMetrics => 'メトリクスを表示する';

  @override
  String get storageUsed => '使用済み';

  @override
  String storageFree(String size) {
    return '空き容量: $size';
  }

  @override
  String get storageDeleteDialogTitle => 'フィードノートの削除';

  @override
  String storageDeleteDialogBody(int count) {
    return 'これにより、ローカル ストレージから $count フィード ノートが削除されます。\n\n自分のノート、保存したノート、フォローしたノートには影響しません。';
  }

  @override
  String get storageDeleteConfirm => '削除';

  @override
  String storageDeleteSuccess(int count) {
    return '$count のノートを削除しました';
  }

  @override
  String get storageNothingToDelete => '削除するフィードノートはありません';

  @override
  String get storageChatHistory => 'チャット履歴';

  @override
  String get storageOther => 'その他';

  @override
  String get storageDeleteFeedNotes => 'フィードノートの削除';

  @override
  String storageDeleteFeedNotesSubtitle(int count) {
    return '$count フィード ノート · 自分のノート、保存したノート、フォローしているノートは影響を受けません';
  }

  @override
  String get storageDeleteChatHistory => 'チャット履歴を削除する';

  @override
  String get storageDeleteChatHistorySubtitle => 'Shiv のすべての会話とメッセージ';

  @override
  String get storageDeleteChatHistorySuccess => 'チャット履歴が削除されました';

  @override
  String get storageDeleteChatHistoryDialogBody =>
      'これにより、Shiv のすべての会話とメッセージが完全に削除されます。これを元に戻すことはできません。';

  @override
  String get styleTheme => 'テーマ';

  @override
  String get styleThemeLight => 'ライト';

  @override
  String get styleThemeDark => 'ダーク';

  @override
  String get styleThemeSystem => 'システム';

  @override
  String get styleAccent => 'アクセント';

  @override
  String get aiSelectModel => 'モデルの選択';

  @override
  String get settingsDeviceAiModel => 'デバイスAIモデル';

  @override
  String get aiModelNoneSelected => 'モデルがダウンロードされていません';

  @override
  String get aiClearCache => 'AI キャッシュのクリア';

  @override
  String get aiModelSelectionTitle => 'AIモデルの選択';

  @override
  String get aiModelSelectionSubtitle => '端末の性能に合ったAIモデルを選んでください。';

  @override
  String get aiModelAvailableHeader => '利用可能なモデル';

  @override
  String get aiModelCloudTitle => 'UNIUNクラウド';

  @override
  String get aiModelCloudSubtitle =>
      'ダウンロードは必要ありません。Shiv はあなたの ID を使用して UNIUN のサーバー上で実行されます。';

  @override
  String get aiModelCloudBadge => 'ダウンロードなし';

  @override
  String get aiModelRecommendedBadge => 'おすすめ';

  @override
  String get aiModelUseThisButton => 'このモデルを使用する';

  @override
  String get aiModelDownloadInfoText =>
      'モデルの切り替えには一度だけダウンロードが必要です。通信料を抑えるため、Wi-Fiへの接続をおすすめします。チャット履歴は保持されます。';

  @override
  String aiModelOrphanedFilesText(String size) {
    return '残ったモデル ファイルの $size をクリーンアップできます。';
  }

  @override
  String get aiModelCleanUpAction => 'クリーンアップ';

  @override
  String aiModelCleanUpSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ファイル$count件を削除しました',
      one: 'ファイル1件を削除しました',
    );
    return '$_temp0。';
  }

  @override
  String get aiModelCleanUpFailed => '残ったファイルをクリーンアップできませんでした。';

  @override
  String get aiModelOptimizedCpu => 'CPUに最適化';

  @override
  String get aiModelOptimizedGpuCpu => 'GPU/CPU向けに最適化';

  @override
  String get aiModelOptimizedGpu => 'GPU用に最適化';

  @override
  String aiModelDownloadingProgress(int percent) {
    return 'ダウンロード中…$percent%';
  }

  @override
  String get aiModelAlreadyActive => 'アクティブ';

  @override
  String get aiModelDownloaded => 'ダウンロード済み';

  @override
  String get aiModelSetActive => 'アクティブとして設定';

  @override
  String get aiModelDownloadError => 'ダウンロードに失敗しました。もう一度試してください。';

  @override
  String get aiModelQwen25Name => 'Qwen3 0.6B';

  @override
  String get aiModelQwen25Desc =>
      '関数呼び出しを備えたコンパクトな多言語チャット。 3 GB 以上の RAM を搭載したデバイスで動作します。';

  @override
  String get aiModelDeepSeekR1Name => 'DeepSeek R1';

  @override
  String get aiModelDeepSeekR1Desc => '高性能の推論とコード生成。 4 GB 以上の RAM が必要です。';

  @override
  String get aiModelGemma4E2bName => 'Gemma 4 E2B';

  @override
  String get aiModelGemma4E2bDesc =>
      '次世代のマルチモーダル チャット - テキスト、画像、音声。 6 GB 以上の RAM が必要です。';

  @override
  String get aiModelGemma4E4bName => 'Gemma 4 E4B';

  @override
  String get aiModelGemma4E4bDesc =>
      '次世代のマルチモーダル チャット - テキスト、画像、音声。 8 GB 以上の RAM を搭載したフラッグシップ デバイスで最適です。';

  @override
  String get aiEmbeddingSetupInProgress => 'AI 機能をセットアップしています…';

  @override
  String get editProfileTitle => 'プロフィールの編集';

  @override
  String get editProfileSaved => 'プロフィールを保存しました';

  @override
  String get editProfileDisplayName => '表示名';

  @override
  String get editProfileUsername => 'ユーザー名';

  @override
  String get editProfileAbout => '自己紹介';

  @override
  String get editProfileAvatarUrl => 'アバターURL';

  @override
  String get editProfileNip05 => 'NIP-05 識別子';

  @override
  String get editProfileDisplayNameHint => '例：サトシ';

  @override
  String get editProfileUsernameHint => '例：サトシ';

  @override
  String get editProfileAboutHint => 'あなたが誰であるかを世界に伝えてください…';

  @override
  String get editProfileAvatarUrlHint => 'https://…';

  @override
  String get editProfileNip05Hint => 'you@yourdomain.com';

  @override
  String get editProfileSaveButton => 'プロフィールを保存';

  @override
  String get editProfileEyebrow => '公開プロフィール';

  @override
  String get editProfileSubtitle => 'UNIUN 全体で他の人があなたをどのように見ているかを更新します。';

  @override
  String get editProfileEncrypted => 'あなたの公開情報のみが共有されます。';

  @override
  String get welcomeTagline => '*創る* · *共有する*\n*振り返る* · *変える*';

  @override
  String get welcomeCreateIdentity => 'アバターを作成する';

  @override
  String get welcomeImportKey => 'アバターを復元する';

  @override
  String get welcomeLearnHow => 'UNIUN の仕組みを学ぶ';

  @override
  String get welcomeSubtitleLead => 'あなたの分散型';

  @override
  String get welcomeSubtitleEmphasis => '第二の脳';

  @override
  String get welcomePillarBrahma => 'Brahma';

  @override
  String get welcomePillarVishnu => 'Vishnu';

  @override
  String get welcomePillarShiv => 'Shiv';

  @override
  String get welcomeRoleCreate => '作成';

  @override
  String get welcomeRoleReflect => '振り返る';

  @override
  String get welcomeRoleTransform => '変える';

  @override
  String get howItWorksSkip => 'スキップ';

  @override
  String get howItWorksNext => '次へ';

  @override
  String get howItWorksGetStarted => '始めましょう';

  @override
  String get howItWorksIntroTitle => '第二の脳をポケットに';

  @override
  String get howItWorksIntroBody =>
      'UNIUNは、考えを記録し、アイデアをつなぎ、振り返るための落ち着いた場所です。すべてが一つのアプリにあり、あなた自身のものです。';

  @override
  String get howItWorksBrahmaTitle => 'Brahma — キャプチャして接続する';

  @override
  String get howItWorksBrahmaBody => 'アイデアを捉え、それを形にして永続的なものにするためのスペース。';

  @override
  String get howItWorksVishnuTitle => 'Vishnu — 仲間とコミュニティ';

  @override
  String get howItWorksVishnuBody => '自分のやり方で人々やコミュニティとつながりましょう。';

  @override
  String get howItWorksShivTitle => 'Shiv — デバイス上の AI';

  @override
  String get howItWorksShivBody => 'ノートを使って一緒に考える、端末上のAIです。';

  @override
  String get howItWorksTileNote => 'ノート';

  @override
  String get howItWorksDescNote => 'テキスト、画像、リンクを書く';

  @override
  String get howItWorksTileManas => 'Manas';

  @override
  String get howItWorksDescManas => 'ノートをグループ化して独自のコレクションにまとめる';

  @override
  String get howItWorksTileGraph => 'グラフ';

  @override
  String get howItWorksDescGraph => 'リンクされたノートがナレッジグラフになります';

  @override
  String get howItWorksTilePeople => '人々';

  @override
  String get howItWorksDescPeople => '人々をフォローしてフィードを形作る';

  @override
  String get howItWorksTileGroups => 'グループ';

  @override
  String get howItWorksDescGroups => 'トピックについて集まるための公開ルーム';

  @override
  String get howItWorksTilePrivate => 'プライベート';

  @override
  String get howItWorksDescPrivate => '暗号化された招待専用グループ';

  @override
  String get howItWorksTileDms => 'ダイレクトメッセージ';

  @override
  String get howItWorksDescDms => '1対1のプライベートチャット';

  @override
  String get howItWorksTileAdiyogi => 'Adiyogi';

  @override
  String get howItWorksDescAdiyogi => 'ノートについて何でも質問してください';

  @override
  String get howItWorksTileNataraj => 'Nataraj';

  @override
  String get howItWorksDescNataraj => 'スワイプしてノートを新鮮なアイデアに変える';

  @override
  String get howItWorksTileGana => 'Gana';

  @override
  String get howItWorksDescGana => 'バックグラウンドで動作するエージェント';

  @override
  String get howItWorksKeysTitle => 'あなたは自分のアイデンティティを所有しています';

  @override
  String get howItWorksKeysBody =>
      'メールアドレスもパスワードも不要です。UNIUNが作成する秘密鍵はあなたの端末だけに保存されます。それがあなたのIDであり、管理できるのはあなただけです。';

  @override
  String get howItWorksPrivateTitle => 'プライベートでいつでもあなたのもの';

  @override
  String get howItWorksPrivateBody =>
      'UNIUN はオフラインで動作し、その AI はデバイス上で直接実行されます。クラウドには何も行きません。ノートは常に手元に残り、自分のものとして保管しておくことができます。';

  @override
  String get howItWorksReadyTitle => '始める準備はできていますか?';

  @override
  String get howItWorksReadyBody => 'アバターを作成して、第二の脳を育てましょう。すぐに始められます。';

  @override
  String get aboutYouEyebrow => 'アバターを作成する';

  @override
  String get aboutYouTitle => 'あなたについて';

  @override
  String get aboutYouSubtitle => 'アバターを設定します。表示名とユーザー名は必須です。';

  @override
  String get aboutYouAvatarCaption => '自動生成';

  @override
  String get aboutYouDisplayNameLabel => '表示名 *';

  @override
  String get aboutYouDisplayNameHint => 'あなたを何と呼べばいいでしょうか？';

  @override
  String get aboutYouUsernameLabel => 'ユーザー名 *';

  @override
  String get aboutYouUsernameHint => 'ユーザー名';

  @override
  String get aboutYouUsernameHelper => 'メンションや検索に使う固有のユーザー名です。';

  @override
  String get aboutYouBioLabel => '略歴 (オプション)';

  @override
  String get aboutYouBioHint => 'あなた自身について少し世界に伝えてください…';

  @override
  String get aboutYouEncrypted => 'あなたのデータは暗号化されており、プライベートです。';

  @override
  String get aboutYouDisplayNameRequired => '表示名は必須です';

  @override
  String get aboutYouUsernameRequired => 'ユーザー名は必須です';

  @override
  String get importTitle => 'おかえりなさい';

  @override
  String get importSubtitle => '秘密キーを貼り付けて、既存のアバターを復元します。';

  @override
  String get importPrivateKeyLabel => '秘密鍵';

  @override
  String get importPasteFromClipboard => 'クリップボードから貼り付け';

  @override
  String get importKeyHint => 'nsec1... または 64 文字の 16 進数キー';

  @override
  String get importSecurityNote => '秘密キーはローカルで処理され、サーバーに送信されることはありません。';

  @override
  String get importContinue => 'インポートして続行';

  @override
  String get importPasteFirst => '最初に秘密キーを貼り付けてください。';

  @override
  String get importFailed => 'キーのインポートに失敗しました。もう一度試してください。';

  @override
  String get importInvalidKey => '無効なキーです。確認してもう一度お試しください。';

  @override
  String get importEyebrow => 'アバターを復元する';

  @override
  String get importScanQrButton => '代わりに QR をスキャンしてください';

  @override
  String get importScanTitle => 'キーの QR をスキャンします';

  @override
  String get importScanHint => '秘密キーを含む QR にカメラを向けます';

  @override
  String get keysTitle => 'あなたのアバターキー';

  @override
  String get keysSubtitle => '一つは共有用。もう一つは、あなた以外には見せないでください。';

  @override
  String get keysEyebrow => 'あなたのアバターキー';

  @override
  String get keysHeadline => 'あなたのキーはあなたのアバターです。';

  @override
  String get keysPublicKeyTitle => '公開鍵';

  @override
  String get keysPublicKeySubtitle => '他の人と共有してメッセージを受け取ります。';

  @override
  String get keysPrivateKeyTitle => '秘密鍵';

  @override
  String get keysPrivateKeySubtitle => '絶対に共有しないでください。この鍵であなたのIDに完全にアクセスできます。';

  @override
  String get keysPrivateKeyWarning => 'この鍵を失うと、アカウントに二度とアクセスできません。';

  @override
  String get keysSaveAndContinue => '保存して続行';

  @override
  String get keysE2eEncrypted => 'E2E暗号化';

  @override
  String get keysAgreePrefix => '以下に同意します: ';

  @override
  String get keysAgreeTerms => '利用規約';

  @override
  String get keysAgreeConjunction => ' および ';

  @override
  String get keysAgreePrivacy => 'プライバシーポリシー';

  @override
  String get keysPublicCopied => '公開鍵をコピーしました。続けて秘密鍵を表示できます。';

  @override
  String get keysPrivateCopied => '秘密鍵をコピーしました。安全な場所に保管してください。';

  @override
  String keysFailedToSave(String error) {
    return 'キーの保存に失敗しました: $error';
  }

  @override
  String get keysCopyPublicAbove => '上記の公開キーをコピーして、秘密キーを表示します。';

  @override
  String get privacyPageTitle => 'プライバシーとポリシー';

  @override
  String get privacyIntroTitle => 'プライバシーとポリシー';

  @override
  String get privacyIntroBody =>
      'UNIUNは透明性を大切にしています。データは端末に保存されます。知っておきたいことを、わかりやすく説明します。';

  @override
  String get privacyExpandPrivacy => 'プライバシーポリシー';

  @override
  String get privacyExpandTerms => '利用規約';

  @override
  String get privacyLastUpdated => '最終更新日: 2026 年 6 月';

  @override
  String get privacyContactEmail => 'info@uniun.in';

  @override
  String get privacyStoredLocallyTitle => 'ローカルで保管するもの';

  @override
  String get privacyStoredLocallyBody =>
      'UNIUN は、ノート、プロフィール、保存済みアイテム、グループ メッセージ、設定をデバイスに直接保存します。このデータは、UNIUN によって管理されるサーバーには送信されません。';

  @override
  String get privacySharedPubliclyTitle => 'パブリックに共有されるもの';

  @override
  String get privacySharedPubliclyBody =>
      'ノートを公開したり、公開グループでメッセージを送信したりすると、そのコンテンツは Nostr リレーにブロードキャストされます。 Nostr はオープンなパブリック プロトコルです。公開されると、ノートはリレーに接続しているすべての人に表示される可能性があります。 UNIUN はサードパーティのリレーを管理しません。';

  @override
  String get privacyIdentityKeysTitle => 'あなたのアイデンティティと鍵';

  @override
  String get privacyIdentityKeysBody =>
      'あなたの ID は暗号化キーのペアです。あなたの公開キーは、Nostr ネットワーク上の他のユーザーに表示されます。秘密キー (nsec) は、デバイスの安全なシステム キーチェーン (iOS キーチェーン / Android キーストア) にのみ保存されます。 UNIUN が秘密キーをサーバーに送信することはありません。';

  @override
  String get privacyLocalAiTitle => 'ローカルAI（Shiv）';

  @override
  String get privacyLocalAiBody =>
      'Shiv AI アシスタントは完全にデバイス上で実行されます。ローカルに保存されたノートのみにアクセスします。ノートのコンテンツは外部の AI サービスや API に送信されません。';

  @override
  String get privacyMediaTitle => 'メディアおよびブロッサムサーバー';

  @override
  String get privacyMediaBody =>
      '画像やメディアを添付すると、選択した Blossom コンテンツ サーバーにアップロードされる場合があります。 UNIUN は Blossom サーバーを運営していません。そこにアップロードされたコンテンツは、プロトコルの設計により公的にアクセスできる場合があります。';

  @override
  String get privacyDmsTitle => 'ダイレクトメッセージ';

  @override
  String get privacyDmsBody =>
      'DM は、Nostr NIP-17 標準を使用してエンドツーエンドで暗号化されます。意図された受信者のみがメッセージの内容を読むことができます。メッセージ ルーティング メタデータはリレーに表示される場合があります。';

  @override
  String get privacyControlTitle => 'あなたのコントロール';

  @override
  String get privacyControlBody =>
      'ローカル データは、[設定] からいつでも削除できます。 Nostr はパブリック プロトコルであるため、リレーに既に公開されたノートを撤回することはできません。これはネットワークの意図的な特性であり、アプリの制限ではありません。';

  @override
  String get privacyContactTitle => 'お問い合わせ';

  @override
  String get privacyContactBody => 'プライバシーに関する質問: info@uniun.in';

  @override
  String get termsResponsibilityTitle => 'あなたの責任';

  @override
  String get termsResponsibilityBody =>
      'UNIUNで公開する内容は、あなた自身の責任です。違法な内容、虐待、嫌がらせ、性的に露骨な内容、他者の権利を侵害する内容を投稿しないでください。UNIUNは不快な内容や虐待行為を認めません。';

  @override
  String get termsNoAbuseTitle => '悪用やスパムの禁止';

  @override
  String get termsNoAbuseBody =>
      'UNIUN を使用して、スパム、嫌がらせ、他人になりすます、または Nostr ネットワークを混乱させる自動化されたアクティビティを実行しないでください。 UNIUN は分散型です。どのノート メニューにもレポート オプション (カテゴリ: ヌード、マルウェア、冒涜、違法、スパム、なりすまし、その他) が含まれており、任意のユーザーは [設定] → [ブロックされたユーザー] からブロックできます。報告されたノートはフィードからすぐに非表示になり、ブロックされたユーザーのコンテンツが届くことはありません。レポートは Nostr ネットワークにも公開されるため、他のクライアントやリレー オペレーターがレポートに基づいて操作できます。';

  @override
  String get termsPrivateKeyTitle => '秘密鍵を安全に保管する';

  @override
  String get termsPrivateKeyBody =>
      '秘密キー (nsec) があなたの ID であり、ログインです。紛失した場合、アカウントを回復することはできません。UNIUN には秘密キーをリセットまたは回復する方法がありません。安全な場所にバックアップします。';

  @override
  String get termsPublicContentTitle => 'リレー上の公開コンテンツ';

  @override
  String get termsPublicContentBody =>
      '公開したノートとグループ メッセージは Nostr リレーに送信され、ネットワーク上の誰でも閲覧できる可能性があります。機密の個人情報を公開ノートで共有しないでください。';

  @override
  String get termsAppMayChangeTitle => 'アプリは変更される可能性があります';

  @override
  String get termsAppMayChangeBody =>
      'UNIUN は積極的に開発中です。機能、リレーの動作、ポリシーは時間の経過とともに変更される可能性があります。重要なアップデートはアプリ内でお知らせします。';

  @override
  String get termsNoWarrantyTitle => '保証なし';

  @override
  String get termsNoWarrantyBody =>
      'UNIUN は現状のまま提供されます。当社は、リレーの稼働時間、サードパーティのサーバーの可用性、または外部リレー上のコンテンツの永続性については保証しません。';

  @override
  String get shivName => 'Shiv';

  @override
  String get shivTagline => 'スレッドで考える';

  @override
  String get shivLandingBody => '端末上で動くAI。\nノートを使って一緒に考えます。';

  @override
  String get shivNoModelBody =>
      'AI モデルをダウンロードして、Shiv とのチャットを開始します。すべてがデバイス上で動作します。セットアップ後にインターネットは必要ありません。';

  @override
  String get shivSetUpAi => 'AIをセットアップする';

  @override
  String get shivNewConversation => '新しい会話';

  @override
  String shivViewConversations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '会話$count件を表示',
      one: '会話1件を表示',
    );
    return '$_temp0';
  }

  @override
  String get shivConversations => '会話';

  @override
  String get shivNewConversationTooltip => '新しい会話';

  @override
  String get shivConversationsTooltip => '会話';

  @override
  String get shivBranchTreeTooltip => '分岐ツリー';

  @override
  String get shivBranchTreeComingSoon => 'ブランチ ツリー — フェーズ 4 で登場';

  @override
  String get shivConversationTree => '会話ツリー';

  @override
  String get shivNodeOpenBranch => '分岐を開く';

  @override
  String get shivNodeContinueFromHere => 'ここから続ける';

  @override
  String get shivNodeNewBranch => '新しい分岐';

  @override
  String get shivActiveBranch => 'アクティブなブランチ';

  @override
  String shivNodeMessages(int count) {
    return '$count メッセージ';
  }

  @override
  String get shivDefaultConversationTitle => '新しい会話';

  @override
  String get shivEmptyTitle => '会話を始める';

  @override
  String get shivEmptyBody =>
      'Shivに何でも聞いてください。保存したノートを使って、あなたが知っていることを踏まえて答えます。';

  @override
  String get shivEmptyTreeTitle => 'まだメッセージはありません';

  @override
  String get shivEmptyTreeBody => '会話を始めると、ここに分岐ツリーが表示されます。';

  @override
  String get shivThinking => '考え中…';

  @override
  String get shivThinkingLabel => '推論';

  @override
  String shivSourcesChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '出典 · $count件',
      one: '出典 · 1件',
    );
    return '$_temp0';
  }

  @override
  String get shivSourcesSheetTitle => '情報源';

  @override
  String shivSourcesDocumentPage(String label) {
    return 'ページ $label';
  }

  @override
  String get shivSourcesDocumentUntitled => 'PDFドキュメント';

  @override
  String get shivSourcesDocumentOpen => 'PDFを開く';

  @override
  String shivSourcesDocumentSection(String label) {
    return 'セクション: $label';
  }

  @override
  String get shivSourcesDocxUntitled => 'Word文書';

  @override
  String get shivSourcesDocxOpen => '文書を開く';

  @override
  String get documentViewerOpenExternal => '別のアプリで開く';

  @override
  String get documentViewerFileGone => 'このドキュメントはこのデバイス上に存在しません';

  @override
  String get documentViewerReadError => 'このドキュメントはここでは開けませんでした';

  @override
  String get documentViewerTextOnly => 'テキスト、表、大きな画像 - 別のアプリで開いて完全なレイアウトを表示';

  @override
  String get shivSourcesImageFound => '画像で見つかりました';

  @override
  String get shivSourcesImageUntitled => '画像';

  @override
  String get shivSourcesImageOpen => '画像を開く';

  @override
  String get shivSourcesImageGone => 'この画像はこのデバイスにはもうありません';

  @override
  String get shivSourcesEmpty => 'この返信には参照元がありません';

  @override
  String get shivInputHint => 'Shivに何でも聞いてください…';

  @override
  String get shivHomeHeadline => 'どうすればお手伝いできますか?';

  @override
  String get shivHomeHistoryTooltip => '履歴';

  @override
  String get shivHomeGana => 'Gana';

  @override
  String get shivHomeNataraj => 'Nataraj';

  @override
  String get shivHomeSuggestSummarize => '私の一週間を要約する';

  @override
  String get shivHomeSuggestConnect => '2 つのアイデアを結び付ける';

  @override
  String get shivHomeSuggestDraft => 'ノートからの下書き';

  @override
  String composerAskScope(String scope) {
    return '$scopeに質問する';
  }

  @override
  String get shivNoConversations => 'まだ会話はありません';

  @override
  String get shivActiveLabel => 'アクティブ';

  @override
  String get shivTimeJustNow => 'たった今';

  @override
  String shivTimeMinutesAgo(int count) {
    return '$count分前';
  }

  @override
  String shivTimeHoursAgo(int count) {
    return '$count時間前';
  }

  @override
  String shivTimeDaysAgo(int count) {
    return '$count日前';
  }

  @override
  String get savedNotesTitle => '保存されたノート';

  @override
  String get savedNotesSearch => '保存されたノートを検索…';

  @override
  String get savedNotesEmpty => 'まだ何も保存されていません';

  @override
  String get savedNotesEmptySub => 'フィードのノートをブックマークして、後で読むことができます。';

  @override
  String get graphLegendSaved => '保存済み';

  @override
  String get graphLegendOwn => '自分のノート';

  @override
  String get graphLegendDraft => '下書き';

  @override
  String get graphFabTextNote => 'テキストノート';

  @override
  String get graphFabReferenceNote => '参照ノート';

  @override
  String get graphDraftEdit => '編集';

  @override
  String get graphDraftDelete => '削除';

  @override
  String get graphScopeAllNotes => 'すべてのノート';

  @override
  String get graphSearchHint => 'グラフを検索…';

  @override
  String get graphSearchTooltip => 'グラフを検索';

  @override
  String get graphMenuTooltip => 'Manasメニューを開く';

  @override
  String get graphSearchClear => '検索をクリア';

  @override
  String graphStepPosition(int current, int total) {
    return '$current/$total';
  }

  @override
  String get graphSearchPrevMatch => '前の一致項目';

  @override
  String get graphSearchNextMatch => '次の一致項目';

  @override
  String get graphPrevConnection => '前の接続';

  @override
  String get graphNextConnection => '次の接続';

  @override
  String get groupEntryTitle => 'グループ';

  @override
  String get groupEntrySubtitle =>
      'ID または QR を使用して既存のパブリック グループに参加するか、新しいパブリック グループを開始します。';

  @override
  String get groupEntryJoin => 'グループに参加する';

  @override
  String get groupEntryCreate => 'グループを作成する';

  @override
  String get privateGroupEntryTitle => 'プライベートグループ';

  @override
  String get privateGroupEntrySubtitle =>
      '既存のプライベート グループへの参加をリクエストするか、独自のグループを作成します。';

  @override
  String get privateGroupEntryJoin => 'プライベートグループに参加する';

  @override
  String get privateGroupEntryCreate => 'プライベートグループを作成する';

  @override
  String get createGroupTitle => 'グループ';

  @override
  String get createGroupHeaderTitle => 'グループの作成';

  @override
  String get createGroupDetailsHeading => 'グループ詳細';

  @override
  String get createGroupNameLabel => 'グループ名';

  @override
  String get createGroupNamePlaceholder => '例：デザイン';

  @override
  String get createGroupAboutLabel => '概要（テーマ・ルール）';

  @override
  String get createGroupDescriptionLabel => '説明';

  @override
  String get createGroupAboutPlaceholder => 'このグループは何についてですか?';

  @override
  String get createGroupPictureLabel => '画像の URL (オプション)';

  @override
  String get createGroupPermanenceNote =>
      'グループの最初のイベントは永続的な ID となり、削除することはできません。';

  @override
  String get createGroupAdvancedRelays => '詳細設定: リレー';

  @override
  String get createGroupPublishRelays => '公開先のリレー';

  @override
  String get createGroupPublishRelaysBody => 'このグループをブロードキャストするリレーを選択します。';

  @override
  String get createGroupAction => 'グループの作成';

  @override
  String get createGroupSuccess => 'グループを作成しました';

  @override
  String get createPrivateGroupTitle => 'プライベートグループを作成する';

  @override
  String get createPrivateGroupEncrypted => '暗号化済み';

  @override
  String get createPrivateGroupNameHint => '例：コアチーム';

  @override
  String get createPrivateGroupDescHint => 'このグループは何についてですか?';

  @override
  String get createPrivateGroupAdminNote => 'あなたは管理者であり、誰が参加するかを制御します。';

  @override
  String get createPrivateGroupHeading => '新しいプライベートグループを開始する';

  @override
  String get createPrivateGroupDescription =>
      'プライベート グループはエンドツーエンドで暗号化されます。メンバーは参加をリクエストする必要があり、管理者はそれを承認する必要があります。';

  @override
  String get createPrivateGroupNameLabel => 'グループ名';

  @override
  String get createPrivateGroupDescLabel => '説明';

  @override
  String get createPrivateGroupAction => 'グループの作成';

  @override
  String get createPrivateGroupSuccess => '非公開グループを作成しました。';

  @override
  String get createDmTitle => '新しいメッセージ';

  @override
  String get createDmRecipientLabel => '送信先';

  @override
  String get createDmRecipientHint => 'UNIUN コードを貼り付けるか、QR をスキャンしてください';

  @override
  String get createDmRelaysNote => 'このメッセージが送信されるリレーを選択します。';

  @override
  String get createDmEncryptedNote =>
      'ダイレクト メッセージはエンドツーエンドで暗号化されます。受信者のみがそれらを読むことができます。';

  @override
  String get createDmScanQr => 'QRコードをスキャン';

  @override
  String get createDmAction => 'チャットを開始する';

  @override
  String get joinPrivateGroupTitle => 'プライベートグループに参加する';

  @override
  String get joinPrivateGroupEncrypted => '暗号化済み';

  @override
  String get joinPrivateGroupHeading => '参加リクエスト';

  @override
  String get joinPrivateGroupSubtitle =>
      'グループ ID を入力してプライベート グループへのアクセスを要求します。';

  @override
  String get joinPrivateGroupGroupIdLabel => 'グループID';

  @override
  String get joinPrivateGroupGroupIdHint => 'グループIDを貼り付け…';

  @override
  String get joinPrivateGroupGroupIdHelper => 'グループ管理者にグループ ID を問い合わせます。';

  @override
  String get joinPrivateGroupScanQr => 'QRをスキャン';

  @override
  String get joinPrivateGroupScanCardTitle => '非公開グループのQRコードをスキャン';

  @override
  String get joinPrivateGroupScanCardSubtitle => '管理者が共有したコードにカメラを向けます';

  @override
  String get joinPrivateGroupApprovalInfo =>
      'メッセージを読む前に、リクエストは管理者に送信されて承認が求められます。';

  @override
  String get joinPrivateGroupAction => '参加リクエストを送信する';

  @override
  String get joinPrivateGroupSuccess => '参加リクエストを送信しました。管理者の承認をお待ちください。';

  @override
  String get commonOr => 'または';

  @override
  String get commonAdvanced => '詳細設定';

  @override
  String get relaySelectorPlaceholder => 'リレーの選択';

  @override
  String relaySelectorSelected(int count) {
    return '選択したリレー: $count件';
  }

  @override
  String get relaySelectorPickerTitle => 'リレーの選択';

  @override
  String get relaySelectorEmpty => '利用可能なリレーはありません。 + をタップして追加します。';

  @override
  String get relaySelectorAddTooltip => 'リレーを追加する';

  @override
  String get relayAddDialogTitle => 'リレーの追加';

  @override
  String get relayAddDialogHint => 'wss://relay.example.com';

  @override
  String get relayAddDialogAction => '追加';

  @override
  String relayAddDialogError(String error) {
    return 'リレーを追加できませんでした: $error';
  }

  @override
  String get relayRemoveDialogTitle => 'リレーを削除';

  @override
  String relayRemoveDialogBody(String url) {
    return '$urlの利用をやめますか？';
  }

  @override
  String get relayRemoveDialogAction => '削除する';

  @override
  String get relayManageEmpty => 'リレーが見つかりませんでした。';

  @override
  String get relayManageRemoveTooltip => '削除する';

  @override
  String get pendingRequestsTitle => '保留中の参加リクエスト';

  @override
  String get pendingRequestsSubtitle => 'ユーザーを承認して、メッセージを読んだり送信したりできるようにします。';

  @override
  String get pendingRequestsEmpty => '保留中のリクエストはありません。';

  @override
  String get pendingRequestsNewMember => '新メンバー';

  @override
  String get pendingRequestsApprove => '承認する';

  @override
  String get settingsCloudProvider => 'クラウドAI';

  @override
  String get cloudProviderTitle => 'UNIUNクラウド';

  @override
  String get cloudProviderEmptyCta => 'サインイン';

  @override
  String get cloudProviderEmptySubtitle =>
      'ShivをClaudeで利用します。UNIUNのIDでサインインしてください。';

  @override
  String get cloudProviderConnectedSubtitle => '接続済み · タップして管理';

  @override
  String get cloudProviderDisconnect => '切断する';

  @override
  String get cloudProviderLastKeyTitle => 'これが唯一のアクティブなキーです';

  @override
  String get cloudProviderLastKeyMessage =>
      '切断すると、UNIUN クラウド上の最後のアクティブなキーが取り消されます。後でいつでも再接続できます。これは、このデバイスをサインアウトするだけです。';

  @override
  String get cloudProviderConnecting => 'サインイン中…';

  @override
  String get cloudProviderConnectFailed =>
      'UNIUNクラウドにサインインできませんでした。接続を確認して、もう一度試してください。';

  @override
  String get qrLoginNotConnected => 'まず設定で UNIUN クラウドにサインインし、このコードを再度スキャンします。';

  @override
  String get qrLoginApproved => 'このデバイスは現在 Web 上にサインインしています。';

  @override
  String qrLoginFailed(String error) {
    return 'サインインを承認できませんでした: $error';
  }

  @override
  String get cloudProviderModelsHeader => 'クラウドモデル';

  @override
  String get cloudProviderOnDevice => 'オンデバイス';

  @override
  String get cloudProviderOnDeviceNotSet => 'ダウンロードされていない';

  @override
  String get cloudProviderNoCloudModels =>
      'プランにはまだクラウド モデルがありません。ロックを解除するには、uniun.in でプランをアップグレードしてください。';

  @override
  String get cloudProviderPlanLabel => 'プラン';

  @override
  String get cloudProviderCreditsLabel => 'クレジット';

  @override
  String get cloudProviderUpgrade => 'プランのアップグレード / クレジットの追加';

  @override
  String get cloudProviderUpgradeHint =>
      '支払いは uniun.in で行われます。同じ ID でサインインし、戻ってこのシートを再度開くと、新しいプランが表示されます。';

  @override
  String get modelPickerTitle => 'モデルを選択してください';

  @override
  String get modelPickerSearchHint => 'モデルを検索…';

  @override
  String get modelPickerLocalSection => 'オンデバイス';

  @override
  String get modelPickerCloudSection => 'クラウド';

  @override
  String get modelPickerManageLocalCta => 'オンデバイスモデルを管理する';

  @override
  String get modelPickerConnectCloudCta => 'クラウドプロバイダーに接続する';

  @override
  String get modelPickerNoModels => '利用可能なモデルはありません。';

  @override
  String get chatInputAttachImageTooltip => '画像を添付する';

  @override
  String get chatInputRemoveImageTooltip => '画像を削除';

  @override
  String get chatInputPickModelTooltip => 'モデルを選択してください';

  @override
  String get followActionSuccess => 'フォローしました。';

  @override
  String get drawerFollowingSectionTitle => 'フォロー中';

  @override
  String get drawerFollowingEmpty => 'まだ誰もフォローしていません';

  @override
  String get vishnuFeedEmptyTitle => 'あなたのフィードは静かです';

  @override
  String get vishnuFeedEmptySubtitle =>
      '誰かの UNIUN QR をスキャンしてフォローすると、ここでノートが表示されます。';

  @override
  String get vishnuFeedEmptyCta => 'QR をスキャンする';

  @override
  String get vishnuFeedEmptyRefresh => 'リフレッシュ';

  @override
  String get drawerPrivateGroups => 'プライベートグループ';

  @override
  String get drawerNoPrivateGroups => 'プライベートグループは参加していません';

  @override
  String get followActionInvalidKey => '無効な公開キー';

  @override
  String get userProfileFollow => 'フォローする';

  @override
  String get userProfileFollowing => 'フォロー中';

  @override
  String get userProfileNoNotes => 'まだノートはありません';

  @override
  String get userProfileMessage => 'メッセージ';

  @override
  String get userProfileNotesLabel => 'ノート';

  @override
  String get userProfileCopyNpub => 'npubをコピーする';

  @override
  String get qrShareAction => 'シェアする';

  @override
  String get qrShareFailed => 'QRコードを共有できませんでした';

  @override
  String get qrCaptionUser => 'これをスキャンして UNIUN に追加してください。';

  @override
  String get qrCaptionPublicGroup => 'スキャンしてこのグループに参加してください。';

  @override
  String get qrCaptionPrivateGroup => 'スキャンしてこのプライベート グループに参加します。';

  @override
  String get qrCaptionDm => 'スキャンしてUNIUNでチャットを開始します。';

  @override
  String get shareSheetTitle => 'ノートを共有する';

  @override
  String get shareQuotingLabel => '引用';

  @override
  String get shareToLabel => '共有先';

  @override
  String get shareActionShare => 'シェアする';

  @override
  String get shareSheetCommentHint => 'コメントを追加します (オプション)';

  @override
  String get shareDestFeed => '自分のフィードに投稿する';

  @override
  String get shareDestFeedSubtitle => 'Vishnuで公開されます';

  @override
  String get shareSectionPublicGroups => 'パブリックグループ';

  @override
  String get shareSectionPrivateGroups => 'プライベートグループ';

  @override
  String get shareSectionDms => 'ダイレクトメッセージ';

  @override
  String get shareSuccess => '共有';

  @override
  String get shareEmbedLoading => 'ノートを読み込んでいます…';

  @override
  String get shareEmbedNotFound => 'ノートは利用できません';

  @override
  String get shareEmbedUnverified => '未検証';

  @override
  String get shareComposeAddReference => '参照を追加';

  @override
  String get shareComposeAddImage => '画像';

  @override
  String get shareNoDmConversations => 'ここでノートを共有するには、まず DM を開始してください。';

  @override
  String get noteCardBlockUser => 'ユーザーをブロックする';

  @override
  String get noteCardDeleteNote => 'ノートを削除する';

  @override
  String get deleteNoteSnackbar => 'ノートを削除しました。';

  @override
  String blockUserSnackbar(String name) {
    return '$name をブロックしました。彼らからの新しい投稿は表示されません。';
  }

  @override
  String get settingsBlockedUsers => 'ブロックされたユーザー';

  @override
  String get blockedUsersTitle => 'ブロックされたユーザー';

  @override
  String get blockedUsersDescription =>
      'ブロックされたユーザーはあなたにメッセージを送信できず、そのノートはフィードから非表示のままになります。ノートは削除されることはありません。ブロックを解除するとノートが元に戻ります。';

  @override
  String blockedUsersSectionCount(int count) {
    return 'ブロックされました · $count';
  }

  @override
  String blockedUsersBlockedAgo(String time) {
    return '$time 前にブロックされました';
  }

  @override
  String get blockedUsersBlockedJustNow => 'たった今ブロックされました';

  @override
  String get blockedUsersEmpty => 'あなたは誰もブロックしていません';

  @override
  String get blockedUsersEmptyHint => 'ブロックした人はここに表示されるので、いつでもブロックを解除できます。';

  @override
  String get actionUnblock => 'ブロックを解除する';

  @override
  String get noteCardReport => 'ノートを報告';

  @override
  String get reportSheetTitle => 'この内容を報告する';

  @override
  String get reportSheetReasonHint => '任意: 詳細を入力（最大280文字）';

  @override
  String get reportSheetSubmit => '報告を送信';

  @override
  String get reportSheetOutcomeHint => 'このノートはフィードから非表示になり、報告がネットワークに送信されます。';

  @override
  String get reportSheetAlsoBlock => 'このユーザーもブロックします (投稿は表示されなくなります)';

  @override
  String get reportSentSnackbar => '報告を送信しました。UNIUNを安全に保つためのご協力ありがとうございます。';

  @override
  String get reportTypeNudity => 'ヌード';

  @override
  String get reportTypeNudityDescription => '性的に露骨な内容またはヌード';

  @override
  String get reportTypeMalware => 'マルウェア';

  @override
  String get reportTypeMalwareDescription => 'デバイスに損害を与える可能性のあるリンクまたはファイル';

  @override
  String get reportTypeProfanity => '暴言';

  @override
  String get reportTypeProfanityDescription => '憎しみに満ちた、または非常に下品な言葉遣い';

  @override
  String get reportTypeIllegal => '違法';

  @override
  String get reportTypeIllegalDescription => '報告者の居住地域で違法な内容';

  @override
  String get reportTypeSpam => 'スパム';

  @override
  String get reportTypeSpamDescription => '望ましくない、または反復的なプロモーション';

  @override
  String get reportTypeImpersonation => 'なりすまし';

  @override
  String get reportTypeImpersonationDescription => '自分ではない誰かのふりをする';

  @override
  String get reportTypeOther => 'その他';

  @override
  String get reportTypeOtherDescription => 'その他コミュニティの基準に違反するもの';

  @override
  String get actionReadMore => '続きを読む';

  @override
  String get actionReadLess => '閉じる';

  @override
  String get mediaGalleryTitle => 'メディア';

  @override
  String get mediaTabAll => 'すべて';

  @override
  String get mediaTabImages => '画像';

  @override
  String get mediaTabVideos => '動画';

  @override
  String get mediaTabAudio => 'オーディオ';

  @override
  String get mediaTabFiles => 'ファイル';

  @override
  String get mediaTabPinned => '固定済み';

  @override
  String get mediaActionDownload => 'ダウンロード';

  @override
  String get mediaActionOpen => '開く';

  @override
  String get mediaActionPin => '固定する';

  @override
  String get mediaActionUnpin => '固定を解除する';

  @override
  String get mediaActionRemoveLocal => 'デバイスから削除する';

  @override
  String get mediaActionCopySha => 'SHA-256をコピー';

  @override
  String get mediaActionSaveToDevice => 'デバイスに保存';

  @override
  String mediaSavedTo(String destination) {
    return '$destinationに保存しました';
  }

  @override
  String get mediaSaveSuccess => '保存されました';

  @override
  String get mediaSaveFailed => 'ファイルを保存できませんでした';

  @override
  String get mediaEmptyState => 'まだメディアがありません。添付ファイル付きで受信したノートがここに表示されます。';

  @override
  String get mediaDetailReferencedBy => '参照元';

  @override
  String get mediaDetailLabelSha => 'SHA-256';

  @override
  String get mediaDetailLabelMime => 'MIME形式';

  @override
  String get mediaDetailLabelSize => 'サイズ';

  @override
  String get mediaDetailLabelDim => '寸法';

  @override
  String get mediaDetailLabelCached => 'キャッシュ済み';

  @override
  String get mediaDetailLabelServer => 'サーバー';

  @override
  String get mediaPickerTitle => 'ライブラリから添付する';

  @override
  String get mediaPickerEmpty => '利用可能なメディアはまだありません。';

  @override
  String get composerAttachPhoto => '写真';

  @override
  String get composerAttachVideo => 'ビデオ';

  @override
  String get composerAttachFile => 'ファイル';

  @override
  String mediaTooLarge(String size, String cap) {
    return 'ファイルが大きすぎます（$size）。上限は$capです。圧縮してから再試行してください。';
  }

  @override
  String get mediaTooLargeAfterCompress =>
      'アップロードできるほど小さい画像を圧縮できませんでした。別の写真を試してください。';

  @override
  String get storageMediaRow => 'メディア';

  @override
  String get storageMediaRowSubtitle => 'ノートの写真、ビデオ、ファイル';

  @override
  String get noteCardDownloadMedia => 'ダウンロード';

  @override
  String get noteCardFileFallbackName => '添付ファイル';

  @override
  String get noteCardFileTapToOpen => 'タップして開きます';

  @override
  String get noteCardFileTapToDownload => 'タップしてダウンロード';

  @override
  String mediaSelectionCount(int count) {
    return '$count件を選択中';
  }

  @override
  String get mediaSelectionExit => '選択を終了する';

  @override
  String get mediaSelectionRemoveDialogTitle => 'デバイスから削除しますか?';

  @override
  String mediaSelectionRemoveDialogBody(int count) {
    return 'このデバイスから $count キャッシュ ファイルを削除して、スペースを解放します。サーバーのコピーは残ります。いつでも再ダウンロードできます。';
  }

  @override
  String get storageMedia => 'メディア';

  @override
  String get storageRetentionTitle => '古いノートを自動削除';

  @override
  String get storageRetentionSubtitle =>
      '公開フィードとグループノートのみ。保存、フォロー、自分のグループ、DM、プライベート グループは永久に残ります。ノートを削除すると、その写真/ファイルもこのデバイスから削除されます。';

  @override
  String get storageRetentionOff => 'オフ';

  @override
  String storageRetentionDays(int days) {
    return '$days 日';
  }

  @override
  String get syncWindowTitle => '同期ウィンドウ';

  @override
  String get syncWindowSubtitle =>
      'フィードとグループ メッセージを同期するまでの期間。フォローしたノートと DM は常に完全に同期されます。次回のアプリ起動時に適用されます。';

  @override
  String syncWindowDays(int days) {
    return '$days 日';
  }

  @override
  String get noteCardMediaDownloading => 'ダウンロード中…';

  @override
  String get noteCardMediaFailed => 'ダウンロードに失敗しました';

  @override
  String get manasDrawerHeaderTitle => 'Brahma';

  @override
  String get manasDrawerHeaderSubtitle => 'あなたのナレッジグラフ';

  @override
  String get manasDrawerBrahmaEntryTitle => 'Brahma';

  @override
  String get manasDrawerBrahmaEntrySubtitle => 'あなたが保存、執筆、下書きしたものすべて';

  @override
  String get manasDrawerSectionTitle => 'Manas';

  @override
  String get manasDrawerNewManasButton => '新しい';

  @override
  String get manasDrawerEmptyStateTitle => 'Manasはまだありません';

  @override
  String get manasDrawerEmptyStateBody =>
      'Manasを作成して、グラフの対象を絞りましょう。ノートの一部を使って専門的に考えられます。';

  @override
  String get manasDrawerEmptyStateCta => '最初のManasを作成';

  @override
  String manasDrawerTileNoteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ノート$count件',
      one: 'ノート1件',
    );
    return '$_temp0';
  }

  @override
  String get manasTileEmptyHint => 'ノート0件 · タップして開く';

  @override
  String get manasTileActionEdit => 'Manasを編集する';

  @override
  String get manasTileActionDelete => 'Manasの削除';

  @override
  String get manasDeleteConfirmTitle => 'Manasを削除しますか？';

  @override
  String manasDeleteConfirmBody(String name) {
    return '「$name」を削除します。ノート自体は残り、このManasへの所属だけが解除されます。';
  }

  @override
  String get manasDeleteConfirmConfirm => '削除';

  @override
  String get manasDeleteConfirmCancel => 'キャンセル';

  @override
  String get manasFormCreateTitle => '新しいManas';

  @override
  String manasFormEditTitle(String name) {
    return '編集 · $name';
  }

  @override
  String get manasFormEditTitleFallback => 'Manasを編集する';

  @override
  String get manasFormSaveAction => '保存';

  @override
  String get manasFormDeleteAction => 'Manasの削除';

  @override
  String get manasFormNameLabel => '名前';

  @override
  String get manasFormNameHint => '例: Rustのエキスパート';

  @override
  String get manasFormDescriptionLabel => '説明';

  @override
  String get manasFormDescriptionHint => 'オプション。このManasは何のためにあるのでしょうか？';

  @override
  String manasFormMembershipSectionTitle(int count) {
    return 'このManasのノート ($count)';
  }

  @override
  String get manasFormMembershipEmpty => 'まだノートはありません。以下を検索して追加してください。';

  @override
  String get manasFormAddNotesSectionTitle => 'ノートを追加する';

  @override
  String get manasFormSearchHint => '保存済みノート、所有ノート、または下書きノートを検索する';

  @override
  String get manasFormSearchEmpty => '一致はありません。';

  @override
  String get manasFormNoteUnavailable => '(ノートは利用できません)';

  @override
  String get manasFormKindSaved => '保存済み';

  @override
  String get manasFormKindOwn => '自分のノート';

  @override
  String get manasFormKindDraft => '下書き';

  @override
  String get manasFormDeleteConfirmTitle => 'このManasを削除しますか?';

  @override
  String get manasFormDeleteConfirmBody =>
      'これにより、Manasとそのすべてのメンバーが削除されます。ノート自体はBrahmaに残ります。';

  @override
  String get manasFormDeleteConfirmConfirm => '削除';

  @override
  String get manasFormDeleteConfirmCancel => 'キャンセル';

  @override
  String get graphHeaderManasEditTooltip => 'Manasを編集する';

  @override
  String get graphHeaderUnnamedManas => 'Manas';

  @override
  String get noteCardAddToManas => 'Manasに追加';

  @override
  String get noteCardManasSaveFailed => 'ノートを保存できませんでした。もう一度やり直してください。';

  @override
  String get unsaveManasDialogTitle => 'ノートの保存を解除しますか?';

  @override
  String get unsaveManasDialogBody => 'このノートの保存を解除すると、次の場所からも削除されます。';

  @override
  String get unsaveManasDialogConfirm => '保存しない';

  @override
  String get unsaveManasDialogCancel => 'キャンセル';

  @override
  String get manasMembershipSheetTitle => 'Manasに追加';

  @override
  String get manasMembershipSheetCreate => '新しいManasを作成する';

  @override
  String get manasMembershipSheetEmptyTitle => 'Manasはまだありません';

  @override
  String get manasMembershipSheetEmptyBody => '最初のManasを作成し、関連するノートをまとめましょう。';

  @override
  String get manasMembershipSheetEmptyCta => 'Manasを作成する';

  @override
  String get manasIconPickerTitle => 'アイコンを選択してください';

  @override
  String get ganaListTitle => 'Gana';

  @override
  String get ganaListNew => '新しい';

  @override
  String get ganaListSubtitle => '情報源を監視し、Manasを使って考え、あなたに代わって公開する自律型エージェントです。';

  @override
  String get ganaListPaused => '一時停止中';

  @override
  String get ganaListScopeAll => 'すべてのノート';

  @override
  String ganaListScopeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Manas $count件',
      one: 'Manas 1件',
    );
    return '$_temp0';
  }

  @override
  String get ganaDashboardTitle => 'ダッシュボード';

  @override
  String get ganaDashboardActive => 'アクティブ';

  @override
  String get ganaDashboardDone => '完了';

  @override
  String get ganaDashboardFailed => '失敗';

  @override
  String get ganaDashboardSkipped => 'スキップ';

  @override
  String get ganaDashboardAttentionTitle => '注意が必要です';

  @override
  String get ganaDashboardGanasTitle => 'あなたのGana';

  @override
  String get ganaDashboardActivityTitle => '最近のアクティビティ';

  @override
  String get ganaDashboardActivityEmpty => '実行履歴はまだありません。Ganaが動くと、ここに表示されます。';

  @override
  String ganaDashboardRate(int percent) {
    return '$percent%成功';
  }

  @override
  String ganaStatsCounts(int done, int failed, int skipped) {
    return '$done 完了 · $failed 失敗 · $skipped スキップ';
  }

  @override
  String get ganaDashboardFootnote =>
      'このバージョン以降の実行回数です。最近のアクティビティには、Ganaごとに最新10件の実行が残ります。';

  @override
  String get ganaErrNoIdentityTitle => '有効なIDがありません';

  @override
  String get ganaErrNoIdentityHint => 'ログインすると、Ganaがノートに署名して公開できるようになります。';

  @override
  String get ganaErrPublishTitle => 'ノートを公開できませんでした';

  @override
  String get ganaErrPublishHint => 'Ganaはノートを作成しましたが、送信できませんでした。次の起動時に再試行します。';

  @override
  String get ganaErrNetworkTitle => 'ネットワークの問題';

  @override
  String get ganaErrNetworkHint =>
      '接続が切れたか、タイムアウトしました。インターネット接続を確認してください。次の起動時に再試行します。';

  @override
  String get ganaErrModelTitle => 'AIモデルに問題がありました';

  @override
  String get ganaErrModelHint => 'モデルの出力中にエラーが発生しました。Shivでモデルを確認してから再試行してください。';

  @override
  String get ganaErrOtherTitle => '何か問題が発生しました';

  @override
  String get ganaErrOtherHint => '予期しないエラーにより実行が停止しました。';

  @override
  String get ganaRunTechnicalDetail => '技術的な詳細';

  @override
  String get ganaRunOutputLabel => '公開されたノート';

  @override
  String get ganaRunOutputMissing => 'このノートはこのデバイスにはもうありません。';

  @override
  String get ganaRunOpenNote => 'ノートを開く';

  @override
  String ganaRunInputCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'メッセージ$count件を読む',
      one: 'メッセージ1件を読む',
    );
    return '$_temp0';
  }

  @override
  String get ganaSkipNoActiveModel => '有効なAIモデルがありません。Shivで選択してください。';

  @override
  String get ganaSkipModelMismatch => '有効なモデルが、このGanaに固定されたモデルと異なります。';

  @override
  String get ganaSkipNoNewInput => '新しく読む内容はありません。';

  @override
  String get ganaSkipModelSwapped => '実行中にモデルが変更されたため、この実行を中止しました。';

  @override
  String get ganaSkipNoopReturned => 'モデルが何も公開しないと判断しました。';

  @override
  String get ganaSkipMaxOutputs => 'ノートの上限に達したため、自動的に無効になりました。';

  @override
  String get ganaSkipCloudUnavailable =>
      'UNIUNクラウドが接続されていないか、クラウドモデルが設定されていません。';

  @override
  String get ganaDrawerEmptyTitle => 'Ganaはまだありません';

  @override
  String get ganaDrawerEmptyBody => '情報源を監視し、ノートを公開するAIエージェントを作成しましょう。';

  @override
  String get ganaTileDisabled => 'オフ';

  @override
  String get ganaTileTriggerReactive => '新しい入力に反応';

  @override
  String ganaTileTriggerInterval(int n) {
    return '$n分ごと';
  }

  @override
  String ganaTileTriggerBoth(int n) {
    return '新しい入力または$n分ごと';
  }

  @override
  String get ganaTileTriggerOnceOnEnable => '有効化時に1回';

  @override
  String get ganaTileTriggerOnceOnInput => '最初の入力時に1回';

  @override
  String get ganaTileLastRunNever => '実行履歴なし';

  @override
  String ganaTileLastRunSucceeded(String when) {
    return '前回成功 · $when';
  }

  @override
  String ganaTileLastRunSkipped(String when) {
    return '前回スキップ · $when';
  }

  @override
  String ganaTileLastRunFailed(String when) {
    return '前回失敗 · $when';
  }

  @override
  String get ganaRelativeJustNow => 'たった今';

  @override
  String ganaRelativeMinutes(int count) {
    return '$count分前';
  }

  @override
  String ganaRelativeHours(int count) {
    return '$count時間前';
  }

  @override
  String ganaRelativeDays(int count) {
    return '$count日前';
  }

  @override
  String get ganaFormCreateTitle => '新しいGana';

  @override
  String ganaFormEditTitle(String name) {
    return '編集 · $name';
  }

  @override
  String get ganaFormEditTitleFallback => 'Ganaを編集';

  @override
  String get ganaFormSaveAction => '保存';

  @override
  String get ganaFormDeleteAction => 'Ganaを削除';

  @override
  String get ganaFormNameLabel => '名前';

  @override
  String get ganaFormNameHint => '例: 質問への返信役';

  @override
  String get ganaFormManasSectionTitle => '知識';

  @override
  String get ganaFormManasSectionSubtitle => 'このGanaが考えるために使うManasです。';

  @override
  String get ganaFormManasEmpty =>
      'Manasがまだありません。Ganaが考えるには知識ベースが必要です。先にManasを作成してください。';

  @override
  String get ganaFormManasCreateNew => 'Manasを作成';

  @override
  String get ganaFormModeRecurring => '繰り返し';

  @override
  String get ganaFormModeOneShot => '1回だけ';

  @override
  String get ganaFormModeRecurringHelp => '無効にするまで、条件に一致するたびに実行します。';

  @override
  String get ganaFormModeOneShotHelp =>
      '1回実行すると自動的に無効になります。再度有効にすると、もう一度実行できます。';

  @override
  String get ganaFormBlockerName => '続行するには名前を追加してください。';

  @override
  String get ganaFormBlockerManas => 'Manasを1つ以上選択してください。Ganaが考えるには知識が必要です。';

  @override
  String get ganaFormBlockerTask => 'Ganaが何をするか分かるように、指示を入力してください。';

  @override
  String get ganaFormBlockerInputRef => '入力元としてグループ、DM、ユーザー、ノートのいずれかを選択してください。';

  @override
  String get ganaFormBlockerOutputRef => 'Ganaの公開先を選択してください。';

  @override
  String get ganaFormBlockerOneShotReactive =>
      '入力元のある1回限りのGanaでは、「新しい入力に反応」を有効にしてください。';

  @override
  String get ganaFormBlockerInterval => '単独で繰り返し実行するGanaには、5分以上の間隔が必要です。';

  @override
  String get ganaFormBlockerTrigger => '「新しい入力に反応」を有効にするか、5分以上の間隔を設定してください。';

  @override
  String get ganaFormBlockerMaxOutputs => '最大ノート数の上限を 1 ～ 1000 の範囲で設定します。';

  @override
  String get ganaFormMaxOutputsLabel => '生成できる最大ノート数';

  @override
  String get ganaFormMaxOutputsHelp =>
      'この数のノートを公開すると、繰り返し実行するGanaは自動的に無効になります。1〜1000の範囲で指定してください。';

  @override
  String get ganaFormOneShotStandaloneNote =>
      'このGanaを有効にすると1回実行し、その後自動的に無効になります。';

  @override
  String get ganaFormReactiveRequiredNote => '入力元がある1回限りのGanaでは必須です。';

  @override
  String get ganaFormTaskPromptLabel => 'タスクプロンプト';

  @override
  String get ganaFormTaskPromptHint =>
      'Ganaにしてほしいことを入力してください。例:「ここに質問が投稿されたら、Manasから関連するノートを探し、1行のコメントを添えて返信する」';

  @override
  String get ganaFormInputSectionTitle => '入力';

  @override
  String get ganaFormInputStandalone => '単独で実行（入力なし）';

  @override
  String get ganaFormInputGroup => 'パブリックグループ';

  @override
  String get ganaFormInputPrivateGroup => 'プライベートグループ';

  @override
  String get ganaFormInputDm => 'DM';

  @override
  String get ganaFormInputUser => 'ユーザーのノート';

  @override
  String get ganaFormInputFollowedNote => 'フォロー中のノートのスレッド';

  @override
  String get ganaFormInputPickHint => 'ソースを選択してください';

  @override
  String get ganaFormInputUserHint => '公開キー (16 進数または npub) を貼り付けます';

  @override
  String get ganaFormOutputSectionTitle => '出力';

  @override
  String get ganaFormOutputFeed => 'メインフィード（kind 1）';

  @override
  String get ganaFormOutputGroup => 'パブリックグループ';

  @override
  String get ganaFormOutputPrivateGroup => 'プライベートグループ';

  @override
  String get ganaFormOutputDm => 'DM';

  @override
  String get ganaFormOutputPickHint => '公開先を選択';

  @override
  String get ganaFormModelSectionTitle => 'モデル';

  @override
  String get ganaFormModelUseActive => '有効なモデルを使用';

  @override
  String get ganaFormTriggersSectionTitle => 'トリガー';

  @override
  String get ganaFormTriggerQuestion => 'いつ実行しますか？';

  @override
  String get ganaFormPresetOnceOnEnable => '有効化時に1回';

  @override
  String get ganaFormPresetOnceOnFirstMessage => '最初の新しいメッセージで1回';

  @override
  String get ganaFormPresetEveryMessage => '新しいメッセージごと';

  @override
  String get ganaFormPresetOnSchedule => '定期的に実行（N分ごと）';

  @override
  String get ganaFormPresetMessageOrSchedule => '新しいメッセージごと、または定期的に実行';

  @override
  String get ganaFormReactiveLabel => '新しい入力に反応する';

  @override
  String get ganaFormReactiveHelp => '入力元に新しいメッセージが届くと、数秒以内に実行します。';

  @override
  String get ganaFormIntervalLabel => '一定間隔で実行';

  @override
  String get ganaFormIntervalUnit => '分（5分以上）';

  @override
  String get ganaFormEnabledLabel => '有効';

  @override
  String get ganaFormEnabledHelp => 'デフォルトではオフです。設定を確認したらオンにします。';

  @override
  String get ganaFormRunsSectionTitle => '最近の実行';

  @override
  String get ganaFormRunsEmpty => 'このGanaの実行履歴はまだありません。';

  @override
  String get ganaFormDeleteConfirmTitle => 'このGanaを削除しますか？';

  @override
  String get ganaFormDeleteConfirmBody =>
      'エージェントを停止し、実行履歴を削除します。参照しているManasとノートは残ります。';

  @override
  String get ganaFormDeleteConfirmConfirm => '削除';

  @override
  String get ganaFormDeleteConfirmCancel => 'キャンセル';

  @override
  String get ganaRunStatusSucceeded => '成功しました';

  @override
  String get ganaRunStatusSkipped => 'スキップされました';

  @override
  String get ganaRunStatusFailed => '失敗しました';

  @override
  String get ganaRunStatusRunning => '実行中';

  @override
  String get natarajTileAction => 'アイデアを刺激する';

  @override
  String get natarajDrawerTitle => 'Nataraj';

  @override
  String get natarajScopeSheetTitle => 'Manasを選択';

  @override
  String get natarajScopeAllNotes => 'Brahma';

  @override
  String natarajScopeManasCount(int count) {
    return 'Manas $count件';
  }

  @override
  String get natarajNewChatTooltip => '新しいチャット';

  @override
  String get natarajEdgePublish => '公開';

  @override
  String get natarajEdgeDraft => '下書き';

  @override
  String get natarajEdgeDiscard => '破棄';

  @override
  String get natarajEdgeDiscuss => '話し合う';

  @override
  String get natarajReferencesLabel => '参照';

  @override
  String get natarajReferencesView => '参照を表示';

  @override
  String get natarajReferencesAttach => '公開すると、選択したノートが参照として添付されます。';

  @override
  String get natarajCoachTitle => 'スワイプしてアイデアを検討する';

  @override
  String get natarajCoachDismiss => 'わかりました';

  @override
  String get natarajGenerating => 'つながりを探しています…';

  @override
  String get natarajRevisitingHint => '過去のアイデアを見直し、新しい発想のためにノートを追加しましょう';

  @override
  String get natarajEmptyNeedsMoreTitle => 'まだノートが足りません';

  @override
  String get natarajEmptyNeedsMoreBody =>
      'このスコープでは、接続を開始するには少なくとも 2 つのノートが必要です。';

  @override
  String get natarajExhaustedTitle => 'すべての組み合わせを見終えました';

  @override
  String get natarajExhaustedBody => 'ノートを追加して新しいアイデアを生み出します。';

  @override
  String get natarajModelErrorTitle => 'アイデアを生み出すことができませんでした';

  @override
  String get natarajModelErrorBody =>
      'AI モデルはこのデバイスでは実行できませんでした。別の (小さい) モデルを試すか、[再試行] をタップします。';

  @override
  String get natarajNoIdeaTitle => '今回はアイデアが見つかりませんでした';

  @override
  String get natarajNoIdeaBody => 'このノートの組み合わせからは新しい発想が生まれませんでした。また試してみてください。';

  @override
  String get natarajPublishedSnack => 'ノートとして公開しました';

  @override
  String get natarajDraftSavedSnack => '下書きとして保存されました';

  @override
  String get natarajGenerateErrorSnack => '現在生成できませんでした';

  @override
  String get natarajYouName => 'あなた';

  @override
  String get natarajYouHandle => '@you · 今';

  @override
  String get natarajDraftLabel => '下書き';

  @override
  String natarajRefsCount(int count) {
    return '$count 参照';
  }

  @override
  String get natarajRetry => '再試行';

  @override
  String get receiveShareTitle => 'UNIUNに追加';

  @override
  String get receiveShareCommentHint => '何か言ってください… (オプション)';

  @override
  String get receiveShareSaveDraft => '下書きに保存';

  @override
  String get receiveShareDraftSaved => '下書きに保存しました';

  @override
  String get receiveShareIngesting => '添付ファイルを準備しています…';

  @override
  String get receiveShareDraftNeedsText => 'テキストを追加して下書きを保存します';

  @override
  String get receiveShareNothingToShare => '最初にテキストまたはメディアを追加します';

  @override
  String get threadNewNote => '新しい';

  @override
  String get threadNewReplyInside => '新しい返信があります';

  @override
  String get unreadBadgeOverflow => '99+';

  @override
  String get newNotesDivider => '新しいノート';

  @override
  String get jumpToLatest => '最新にジャンプ';

  @override
  String get interestsEyebrow => 'フィードを構築する';

  @override
  String get interestsTitle => '興味のあるものを選んでください';

  @override
  String get interestsSubtitle =>
      '少なくとも 3 つ選択してください。それぞれが毎日投稿されるため、最初のスクロールからフィードが有効になります。';

  @override
  String get interestsSearchHint => '興味のあることを検索…';

  @override
  String get interestsNoResults => '一致する興味はありません。';

  @override
  String get interestsContinue => 'フィードを見る';

  @override
  String interestsPickMore(int count) {
    return '続行するには、さらに $count を選択してください';
  }

  @override
  String get interestsSkip => '今のところスキップしてください';

  @override
  String get interestsFollowFailed => '全員をフォローできませんでした。もう一度お試しください。';

  @override
  String get interestsLoadFailed => '興味のあるものを読み込めませんでした。接続を確認してください。';

  @override
  String get interestsRetry => '再試行';

  @override
  String get welcomeMoreLanguages => 'さらに多くの言語';

  @override
  String get languageSelectTitle => '言語を選択してください';

  @override
  String get languageComingSoon => '近日公開予定';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsAppLanguage => 'アプリ言語';

  @override
  String get graphEmptyHint =>
      'ノートを保存してナレッジ グラフを構築します。\n\nエッジは、あるノートが別のノートを参照するときに表示されます。';

  @override
  String get ganaDetailManasesLabel => 'マナセス';

  @override
  String get settingsAppearance => '外観';

  @override
  String get settingsTheme => 'テーマ';

  @override
  String get settingsThemeSheetTitle => 'テーマの選択';

  @override
  String get settingsThemeSystem => 'システム設定に合わせる';

  @override
  String get settingsThemeLight => 'ライト';

  @override
  String get settingsThemeDark => 'ダーク';

  @override
  String get settingsNearbySync => '近くの同期';

  @override
  String get meshTitle => '近くのデバイスと同期する';

  @override
  String get meshSubtitle =>
      'ベータ · 同じ Wi-Fi 上の他のデバイスとノートを同期します。インターネットは必要ありません。';

  @override
  String meshConnected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ピア$count件',
      one: 'ピア1件',
      zero: 'ピアなし',
    );
    return '$_temp0';
  }

  @override
  String get drawerSurrounding => '周囲';

  @override
  String get surroundingTitle => '周囲';

  @override
  String get surroundingEmpty => '近くにはまだ何もありません';

  @override
  String get surroundingEmptySub =>
      'メッシュ上の近くのデバイスによってブロードキャストされるノートがここに表示されます。それらは毎日クリアされます。';

  @override
  String get surroundingSave => '保存';

  @override
  String get surroundingSaved => '保存されました';

  @override
  String get surroundingSourceLabel => '📍近く';

  @override
  String get noteCardTranslate => '翻訳する';

  @override
  String get translateSheetTitle => '翻訳先の言語';

  @override
  String get translateSheetAction => '翻訳する';

  @override
  String get translateSheetSettingsHint => 'アプリの言語を使用';

  @override
  String get translatingLabel => '翻訳中…';

  @override
  String translatedToLabel(String language) {
    return '$language に翻訳';
  }

  @override
  String get translationShowOriginal => 'オリジナルを表示';

  @override
  String get translationShowTranslation => '翻訳を表示';

  @override
  String get translationChangeLanguage => '変更';

  @override
  String get translationFailed => 'このノートを翻訳できませんでした。もう一度やり直してください。';

  @override
  String get translationNotProduced =>
      'AI モデルはこのノートを翻訳できませんでした。より大きなモデルまたはUNIUNクラウドをお試しください。';

  @override
  String get brahmaPublishConfirmTitle => 'このノートを公開しますか?';

  @override
  String get brahmaPublishConfirmBody =>
      '公開したノートは残り続けます。リレーに送信され、編集や削除はできません。まだ作業中なら、下書きとして保存してください。';

  @override
  String get errorUnexpected => '問題が発生しました。';

  @override
  String get savedNoSearchResults => '検索に一致するノートはありません。';

  @override
  String qrScannerInvalidCode(String error) {
    return '無効なQRコード: $error';
  }

  @override
  String get qrScannerInstruction =>
      'UNIUNのQRコードをスキャンしてください（ユーザー、公開グループ、非公開グループ）';

  @override
  String qrCopiedToClipboard(String label) {
    return '$label • クリップボードにコピーしました';
  }

  @override
  String get privateGroupShareQrTooltip => 'QRコードを共有';

  @override
  String get privateGroupLeaveAction => 'グループから退出';

  @override
  String get privateGroupPendingApprovalTitle => '承認待ち';

  @override
  String get privateGroupPendingApprovalBody =>
      '参加リクエストを送信しました。グループ管理者に承認されると、メッセージの閲覧と送信ができるようになります。';

  @override
  String get dmShareKeysTooltip => '鍵を共有';

  @override
  String get groupFeedNoMessages => 'メッセージはまだありません。最初に投稿しましょう！';

  @override
  String threadShowMoreReferences(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'さらに参照$count件を表示',
      one: 'さらに参照1件を表示',
    );
    return '$_temp0';
  }
}
