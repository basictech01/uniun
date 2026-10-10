// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String appVersion(String version) {
    return 'UNIUN v$version';
  }

  @override
  String get appTagline => 'Your notes, your\nnetwork, your identity.';

  @override
  String get navVishnu => 'VISHNU';

  @override
  String get navBrahma => 'BRAHMA';

  @override
  String get navShiv => 'SHIV';

  @override
  String get actionCopy => 'Copy';

  @override
  String get actionCopied => 'Copied';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionBack => 'Back';

  @override
  String get actionDone => 'Done';

  @override
  String get actionSaved => 'Saved';

  @override
  String get actionFollow => 'Follow';

  @override
  String get actionFollowing => 'Following';

  @override
  String get drawerHome => 'Home';

  @override
  String get drawerSavedNotes => 'Saved Notes';

  @override
  String get drawerGroups => 'Groups';

  @override
  String get drawerDirectMessages => 'Direct Messages';

  @override
  String get drawerApps => 'Apps';

  @override
  String get drawerAiAssistant => 'AI Assistant';

  @override
  String get drawerSettings => 'Settings';

  @override
  String get drawerFollowingNotes => 'NOTE WATCH';

  @override
  String get drawerNoFollowedNotes => 'Not watching any notes yet';

  @override
  String get drawerNoGroups => 'No groups yet';

  @override
  String get drawerMyQrCode => 'My QR code';

  @override
  String get drawerScanCode => 'Scan code';

  @override
  String get drawerPrivateLabel => 'Private';

  @override
  String get drawerSearchKindDm => 'Direct message';

  @override
  String get drawerSearchKindUser => 'Following';

  @override
  String get joinGroupTitle => 'Join Group';

  @override
  String get joinGroupHeading => 'Join Existing Group';

  @override
  String get joinGroupAction => 'Join Group';

  @override
  String get joinGroupIdLabel => 'Group ID (Hex)';

  @override
  String get joinGroupRelaysTitle => 'Group Relays';

  @override
  String get joinGroupRelaysBody =>
      'Select the relays this group operates on to start syncing.';

  @override
  String get joinGroupSelectRelays => 'Select Relays';

  @override
  String joinGroupSelectedRelays(int count) {
    return '$count Relays Selected';
  }

  @override
  String get joinGroupAddRelay => 'Add Relay';

  @override
  String get joinGroupAddRelayAction => 'Add';

  @override
  String get joinGroupRelayHint => 'wss://relay.example.com';

  @override
  String get joinGroupByQr => 'Join by QR';

  @override
  String get joinGroupScanCardTitle => 'Scan a group QR';

  @override
  String get joinGroupScanCardSubtitle =>
      'Point your camera at a UNIUN group code';

  @override
  String get joinGroupOr => 'or';

  @override
  String get joinGroupIdHint => 'Paste group ID';

  @override
  String get joinGroupQrTitle => 'Scan Group QR';

  @override
  String get joinGroupQrHint =>
      'Scan a QR code containing a group id and relay list.';

  @override
  String get joinGroupQrFromGallery => 'Pick QR from gallery';

  @override
  String get joinGroupQrGalleryError =>
      'No valid QR code found in the selected image.';

  @override
  String get joinGroupSuccess => 'Group joined successfully.';

  @override
  String get joinGroupErrorInvalidId =>
      'That doesn\'t look like a valid group ID. Check it and try again.';

  @override
  String get joinGroupErrorNoRelay => 'Please select at least one relay.';

  @override
  String get joinGroupErrorRelaySaveFailed => 'Failed to save relay locally.';

  @override
  String get joinGroupErrorSaveFailed =>
      'Couldn\'t join the group. Please try again.';

  @override
  String get groupMessageHint => 'Message group…';

  @override
  String get chatMessageHint => 'Message…';

  @override
  String get dmEncryptedNotice => 'Messages are end-to-end encrypted';

  @override
  String get groupShareQrTitle => 'Share Group QR';

  @override
  String get groupShareQrBody =>
      'Let someone scan this QR to join the group with the right relays.';

  @override
  String get drawerNoMessages => 'No messages yet';

  @override
  String get drawerSearchHint => 'Search';

  @override
  String get drawerSearchNoResults => 'No matches';

  @override
  String get drawerCopyNpub => 'Copy npub';

  @override
  String get drawerNpubCopied => 'npub copied';

  @override
  String drawerComingSoon(String feature) {
    return '$feature — coming soon';
  }

  @override
  String get brahmaTitle => 'Brahma';

  @override
  String get brahmaTagline => 'Write & publish to Nostr';

  @override
  String get brahmaHintText => 'Write a new note...';

  @override
  String get brahmaSubjectHintText => 'Subject (optional)';

  @override
  String get brahmaAddImage => 'Add Image';

  @override
  String get brahmaTagPeople => 'Tag People';

  @override
  String get brahmaReferenceNote => 'Mention a Note';

  @override
  String get brahmaMentionSheetTitle => 'Mention a Note';

  @override
  String get brahmaMentionSearchHint => 'Search notes…';

  @override
  String get brahmaMentionEmpty => 'No notes found';

  @override
  String get brahmaMentionSelected => 'Mentioned';

  @override
  String get composerReferenceTitle => 'Add reference';

  @override
  String get composerReferenceSearchHint => 'Search…';

  @override
  String get composerReferenceEmpty => 'No results';

  @override
  String get composerReferenceTabAll => 'All';

  @override
  String get composerReferenceTabSaved => 'Saved';

  @override
  String get composerReferenceTabOwn => 'My notes';

  @override
  String get composerReferenceTabDrafts => 'Drafts';

  @override
  String get composerReferenceAdd => 'Add';

  @override
  String get composerChatPickerTitle => 'Chat with your notes';

  @override
  String get composerChatPickerSubtitle => 'Scope to a Manas';

  @override
  String get composerChatBrand => 'Shiv';

  @override
  String get composerChatAllNotes => 'All notes';

  @override
  String get composerChatAllNotesSubtitle => 'Ask Brahma';

  @override
  String composerChatManasNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return '$_temp0';
  }

  @override
  String composerChatScopeEyebrow(String scope) {
    return '$scope · on-device';
  }

  @override
  String composerChatGroundedHint(String scope) {
    return 'Grounded in $scope';
  }

  @override
  String get composerChatThinking => 'Thinking…';

  @override
  String get composerChatStop => 'Stop';

  @override
  String get composerChatNoModel =>
      'No AI model is active. Download one from the Shiv tab.';

  @override
  String get composerChatError => 'Something went wrong.';

  @override
  String get composerChatUseAsReply => 'Use as reply';

  @override
  String get threadReferencesLabel => 'REFERENCES';

  @override
  String get threadReplyingToLabel => 'REPLYING TO';

  @override
  String get brahmaCreateNote => 'Create Note';

  @override
  String get brahmaFailedToPublish => 'Failed to publish';

  @override
  String get brahmaGraphPreviewLabel => 'REFERENCE GRAPH PREVIEW';

  @override
  String get brahmaInteractivePreview => 'Interactive Preview';

  @override
  String get brahmaDraft => 'Draft';

  @override
  String get markdownToolbarHeading => 'Heading';

  @override
  String get markdownToolbarBold => 'Bold';

  @override
  String get markdownToolbarItalic => 'Italic';

  @override
  String get markdownToolbarCode => 'Inline code';

  @override
  String get markdownToolbarBulletList => 'Bullet list';

  @override
  String get markdownToolbarNumberList => 'Numbered list';

  @override
  String get markdownToolbarQuote => 'Quote';

  @override
  String get markdownToolbarLink => 'Link';

  @override
  String get brahmaDraftSaved => 'Draft saved';

  @override
  String get brahmaDrafts => 'Drafts';

  @override
  String get brahmaPublish => 'Publish';

  @override
  String get brahmaDraftPublished => 'Published as a note';

  @override
  String get brahmaTags => 'tags';

  @override
  String get brahmaPublishChainTitle => 'This note links to other drafts';

  @override
  String brahmaPublishChainSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unpublished drafts',
      one: '1 unpublished draft',
    );
    return 'Nostr notes are immutable once published — references to $_temp0 can only be added now, not later.';
  }

  @override
  String get brahmaPublishChain => 'Publish the whole chain';

  @override
  String brahmaPublishChainBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count linked drafts',
      one: '1 linked draft',
    );
    return 'Publishes $_temp0 first, then this note with the links in its tags.';
  }

  @override
  String get brahmaPublishOnlyThis => 'Publish only this';

  @override
  String get brahmaPublishOnlyThisSubtitle =>
      'Drop the draft references from this note. The other drafts stay where they are.';

  @override
  String get vishnuNoNotes => 'No notes yet';

  @override
  String get vishnuCreateFirst =>
      'Create your first note in Brahma\nor wait for the relay to sync.';

  @override
  String get vishnuThread => 'THREAD';

  @override
  String vishnuReferences(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString REFERENCES',
      one: '1 REFERENCE',
    );
    return '$_temp0';
  }

  @override
  String get vishnuReferenceUnavailable => 'Referenced note not available';

  @override
  String vishnuNewNotesBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new notes',
      one: '1 new note',
    );
    return '$_temp0';
  }

  @override
  String get homeShivTitle => 'Shiv — AI Assistant';

  @override
  String get homeShivComingSoon => 'On-device AI coming soon.';

  @override
  String get threadTitle => 'Thread';

  @override
  String get threadReplies => 'Replies';

  @override
  String get threadReferences => 'References';

  @override
  String get threadNoReplies => 'No replies yet';

  @override
  String get threadBeFirstToReply => 'Be the first to reply.';

  @override
  String get threadNoReferences => 'No references';

  @override
  String get threadNoReferencesDetail => 'No notes reference this one yet.';

  @override
  String get threadPost => 'Post';

  @override
  String get threadReplyToThis => 'Reply to this note…';

  @override
  String threadReplyTo(String name) {
    return 'Reply to @$name…';
  }

  @override
  String threadReplyingTo(String name) {
    return 'Replying to @$name';
  }

  @override
  String get threadContinuation => 'THREAD CONTINUATION';

  @override
  String threadNReplies(int count) {
    return '$count Replies';
  }

  @override
  String threadUpdated(String time) {
    return 'Updated: $time';
  }

  @override
  String get followedNoteViewThread => 'View Thread';

  @override
  String get followedNoteFailedToLoad => 'Failed to load note';

  @override
  String get followedNoteResearchNode => 'Research Node';

  @override
  String get followedNoteFollowing => 'Following';

  @override
  String get followedNoteReferencedBy => 'Replies';

  @override
  String get followedNoteReferences => 'References';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsIdentity => 'Identity';

  @override
  String get settingsAiShiv => 'AI · Shiv';

  @override
  String get settingsStorage => 'Storage';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsLogout => 'Log out';

  @override
  String get settingsLogoutTitle => 'Log out?';

  @override
  String get settingsLogoutBody =>
      'Your notes, chats, and account data on this device will be removed. You\'ll need your private key (nsec) to sign back in. Make sure it\'s backed up.';

  @override
  String get settingsKeepDownloadedModels =>
      'Keep downloaded AI models for another login';

  @override
  String get settingsLoggingOut => 'Logging out…';

  @override
  String get settingsLogoutConfirm => 'Log out';

  @override
  String get settingsAlerts => 'Alerts';

  @override
  String get settingsStyle => 'Style';

  @override
  String get profileAnonymous => 'Anonymous';

  @override
  String get profileEditProfile => 'Edit Profile';

  @override
  String get identityLoginRecovery => 'This is your login & recovery method.';

  @override
  String get identityKeys => 'Keys';

  @override
  String get identityRelays => 'Relays';

  @override
  String get identityPrivacyPolicy => 'Privacy & Policy';

  @override
  String get identityYourKeys => 'Your Keys';

  @override
  String get identityNeverShare => 'Never share your private key with anyone.';

  @override
  String get identityPublicKey => 'Public Key (npub)';

  @override
  String get identityPublicKeyCopied => 'Public key copied';

  @override
  String get identityPrivateKey => 'Private Key (nsec)';

  @override
  String get identityRevealPrivateKey => 'Reveal Private Key';

  @override
  String get identityNeverShareKey => 'Never share this key';

  @override
  String get identityTapToCopy => 'Tap to copy';

  @override
  String get identityHide => 'Hide';

  @override
  String get identityPrivateKeyCopied => 'Private key copied — keep it safe!';

  @override
  String get identityRelaysSheetTitle => 'Relays';

  @override
  String get identityRelaysSubtitle => 'Nostr relays your client connects to.';

  @override
  String get identityRelaysComingSoon => 'Custom relay management coming soon.';

  @override
  String get alertsDmAlerts => 'DM Alerts';

  @override
  String get alertsGroupAlerts => 'Group Alerts';

  @override
  String get storageUsage => 'Storage Usage';

  @override
  String get storageNoteData => 'Note Data';

  @override
  String get storageAiModels => 'AI Models';

  @override
  String get storageAiModelsSubtitle => 'Downloaded model files';

  @override
  String get storageTotal => 'Total';

  @override
  String storageNotes(int count) {
    return '$count notes';
  }

  @override
  String get storageRemoveData => 'Remove Data';

  @override
  String get storageShowMetrics => 'Show metrics';

  @override
  String get storageUsed => 'Used';

  @override
  String storageFree(String size) {
    return '$size free';
  }

  @override
  String get storageDeleteDialogTitle => 'Delete Feed Notes';

  @override
  String storageDeleteDialogBody(int count) {
    return 'This will delete $count feed notes from local storage.\n\nYour own notes, saved notes, and followed notes will NOT be affected.';
  }

  @override
  String get storageDeleteConfirm => 'Delete';

  @override
  String storageDeleteSuccess(int count) {
    return 'Deleted $count notes';
  }

  @override
  String get storageNothingToDelete => 'No feed notes to delete';

  @override
  String get storageChatHistory => 'Chat History';

  @override
  String get storageOther => 'Other';

  @override
  String get storageDeleteFeedNotes => 'Delete Feed Notes';

  @override
  String storageDeleteFeedNotesSubtitle(int count) {
    return '$count feed notes · your own, saved, and followed notes are not affected';
  }

  @override
  String get storageDeleteChatHistory => 'Delete Chat History';

  @override
  String get storageDeleteChatHistorySubtitle =>
      'All Shiv conversations and messages';

  @override
  String get storageDeleteChatHistorySuccess => 'Chat history deleted';

  @override
  String get storageDeleteChatHistoryDialogBody =>
      'This will permanently delete all Shiv conversations and messages. This cannot be undone.';

  @override
  String get styleTheme => 'Theme';

  @override
  String get styleThemeLight => 'Light';

  @override
  String get styleThemeDark => 'Dark';

  @override
  String get styleThemeSystem => 'System';

  @override
  String get styleAccent => 'Accent';

  @override
  String get aiSelectModel => 'Select Model';

  @override
  String get settingsDeviceAiModel => 'Device AI model';

  @override
  String get aiModelNoneSelected => 'No model downloaded';

  @override
  String get aiClearCache => 'Clear AI Cache';

  @override
  String get aiModelSelectionTitle => 'AI Model Selection';

  @override
  String get aiModelSelectionSubtitle =>
      'Choose the intelligence level that fits your device\'s capabilities.';

  @override
  String get aiModelAvailableHeader => 'Available Models';

  @override
  String get aiModelCloudTitle => 'UNIUN Cloud';

  @override
  String get aiModelCloudSubtitle =>
      'No download needed — Shiv runs on UNIUN\'s servers with your identity.';

  @override
  String get aiModelCloudBadge => 'No download';

  @override
  String get aiModelRecommendedBadge => 'Recommended';

  @override
  String get aiModelUseThisButton => 'Use This Model';

  @override
  String get aiModelDownloadInfoText =>
      'Switching models requires a one-time download. Connect to Wi-Fi to avoid data charges. Your chat history is preserved.';

  @override
  String aiModelOrphanedFilesText(String size) {
    return '$size of leftover model files can be cleaned up.';
  }

  @override
  String get aiModelCleanUpAction => 'Clean up';

  @override
  String aiModelCleanUpSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return 'Cleaned up $_temp0.';
  }

  @override
  String get aiModelCleanUpFailed => 'Couldn\'t clean up leftover files.';

  @override
  String get aiModelOptimizedCpu => 'Optimized for CPU';

  @override
  String get aiModelOptimizedGpuCpu => 'Optimized for GPU / CPU';

  @override
  String get aiModelOptimizedGpu => 'Optimized for GPU';

  @override
  String aiModelDownloadingProgress(int percent) {
    return 'Downloading… $percent%';
  }

  @override
  String get aiModelAlreadyActive => 'Active';

  @override
  String get aiModelDownloaded => 'Downloaded';

  @override
  String get aiModelSetActive => 'Set as Active';

  @override
  String get aiModelDownloadError => 'Download failed. Please try again.';

  @override
  String get aiModelQwen25Name => 'Qwen3 0.6B';

  @override
  String get aiModelQwen25Desc =>
      'Compact multilingual chat with function calling. Works on any device with 3 GB+ RAM.';

  @override
  String get aiModelDeepSeekR1Name => 'DeepSeek R1';

  @override
  String get aiModelDeepSeekR1Desc =>
      'High-performance reasoning and code generation. Requires 4 GB+ RAM.';

  @override
  String get aiModelGemma4E2bName => 'Gemma 4 E2B';

  @override
  String get aiModelGemma4E2bDesc =>
      'Next-gen multimodal chat — text, image, audio. Requires 6 GB+ RAM.';

  @override
  String get aiModelGemma4E4bName => 'Gemma 4 E4B';

  @override
  String get aiModelGemma4E4bDesc =>
      'Next-gen multimodal chat — text, image, audio. Best on flagship devices with 8 GB+ RAM.';

  @override
  String get aiEmbeddingSetupInProgress => 'Setting up AI features…';

  @override
  String get editProfileTitle => 'Edit Profile';

  @override
  String get editProfileSaved => 'Profile saved';

  @override
  String get editProfileDisplayName => 'Display Name';

  @override
  String get editProfileUsername => 'Username';

  @override
  String get editProfileAbout => 'About';

  @override
  String get editProfileAvatarUrl => 'Avatar URL';

  @override
  String get editProfileNip05 => 'NIP-05 Identifier';

  @override
  String get editProfileDisplayNameHint => 'e.g. Satoshi';

  @override
  String get editProfileUsernameHint => 'e.g. satoshi';

  @override
  String get editProfileAboutHint => 'Tell the world who you are…';

  @override
  String get editProfileAvatarUrlHint => 'https://…';

  @override
  String get editProfileNip05Hint => 'you@yourdomain.com';

  @override
  String get editProfileSaveButton => 'Save Profile';

  @override
  String get editProfileEyebrow => 'Public profile';

  @override
  String get editProfileSubtitle => 'Update how others see you across UNIUN.';

  @override
  String get editProfileEncrypted => 'Only your public details are shared.';

  @override
  String get welcomeTagline => '*Create* · *Share*\n*Reflect* · *Transform*';

  @override
  String get welcomeCreateIdentity => 'Create Your Avatar';

  @override
  String get welcomeImportKey => 'Restore Your Avatar';

  @override
  String get welcomeLearnHow => 'Learn how UNIUN works';

  @override
  String get welcomeSubtitleLead => 'Your decentralized ';

  @override
  String get welcomeSubtitleEmphasis => 'second brain';

  @override
  String get welcomePillarBrahma => 'Brahma';

  @override
  String get welcomePillarVishnu => 'Vishnu';

  @override
  String get welcomePillarShiv => 'Shiv';

  @override
  String get welcomeRoleCreate => 'Create';

  @override
  String get welcomeRoleReflect => 'Reflect';

  @override
  String get welcomeRoleTransform => 'Transform';

  @override
  String get howItWorksSkip => 'Skip';

  @override
  String get howItWorksNext => 'Next';

  @override
  String get howItWorksGetStarted => 'Get started';

  @override
  String get howItWorksIntroTitle => 'Your second brain, in your pocket';

  @override
  String get howItWorksIntroBody =>
      'UNIUN is a calm space to capture what you think, connect your ideas, and reflect on them — all in one app that\'s truly yours.';

  @override
  String get howItWorksBrahmaTitle => 'Brahma — capture & connect';

  @override
  String get howItWorksBrahmaBody =>
      'Your space to capture ideas and shape them into something lasting.';

  @override
  String get howItWorksVishnuTitle => 'Vishnu — your people & spaces';

  @override
  String get howItWorksVishnuBody =>
      'Connect with people and communities, your way.';

  @override
  String get howItWorksShivTitle => 'Shiv — AI on your device';

  @override
  String get howItWorksShivBody =>
      'On-device AI that thinks alongside your notes.';

  @override
  String get howItWorksTileNote => 'Note';

  @override
  String get howItWorksDescNote => 'Write text, images and links';

  @override
  String get howItWorksTileManas => 'Manas';

  @override
  String get howItWorksDescManas => 'Group notes into your own collections';

  @override
  String get howItWorksTileGraph => 'Graph';

  @override
  String get howItWorksDescGraph => 'Linked notes become your knowledge graph';

  @override
  String get howItWorksTilePeople => 'People';

  @override
  String get howItWorksDescPeople => 'Follow people to shape your feed';

  @override
  String get howItWorksTileGroups => 'Groups';

  @override
  String get howItWorksDescGroups => 'Public rooms to gather around topics';

  @override
  String get howItWorksTilePrivate => 'Private';

  @override
  String get howItWorksDescPrivate => 'Encrypted, invite-only groups';

  @override
  String get howItWorksTileDms => 'Direct messages';

  @override
  String get howItWorksDescDms => 'Private one-to-one chats';

  @override
  String get howItWorksTileAdiyogi => 'Adiyogi';

  @override
  String get howItWorksDescAdiyogi => 'Ask anything about your notes';

  @override
  String get howItWorksTileNataraj => 'Nataraj';

  @override
  String get howItWorksDescNataraj => 'Swipe to turn notes into fresh ideas';

  @override
  String get howItWorksTileGana => 'Gana';

  @override
  String get howItWorksDescGana => 'Agents that work in the background';

  @override
  String get howItWorksKeysTitle => 'You own your identity';

  @override
  String get howItWorksKeysBody =>
      'No email, no password, no account. UNIUN gives you a private key that lives only on your device — it is your identity, and only you hold it.';

  @override
  String get howItWorksPrivateTitle => 'Private and always yours';

  @override
  String get howItWorksPrivateBody =>
      'UNIUN works offline and its AI runs right on your device — nothing goes to the cloud. Your notes stay with you, and they\'re yours to keep.';

  @override
  String get howItWorksReadyTitle => 'Ready to begin?';

  @override
  String get howItWorksReadyBody =>
      'Create your avatar and start building your second brain. It only takes a moment.';

  @override
  String get aboutYouEyebrow => 'Create your avatar';

  @override
  String get aboutYouTitle => 'About You';

  @override
  String get aboutYouSubtitle =>
      'Set up your avatar. Display Name and Username are required.';

  @override
  String get aboutYouAvatarCaption => 'Auto-generated';

  @override
  String get aboutYouDisplayNameLabel => 'Display Name *';

  @override
  String get aboutYouDisplayNameHint => 'What should we call you?';

  @override
  String get aboutYouUsernameLabel => 'Username *';

  @override
  String get aboutYouUsernameHint => 'username';

  @override
  String get aboutYouUsernameHelper => 'Unique handle for mentions and search.';

  @override
  String get aboutYouBioLabel => 'Bio  (optional)';

  @override
  String get aboutYouBioHint => 'Tell the world a bit about yourself…';

  @override
  String get aboutYouEncrypted => 'Your data is encrypted and private.';

  @override
  String get aboutYouDisplayNameRequired => 'Display name is required';

  @override
  String get aboutYouUsernameRequired => 'Username is required';

  @override
  String get importTitle => 'Welcome Back';

  @override
  String get importSubtitle =>
      'Paste your private key to restore your existing avatar.';

  @override
  String get importPrivateKeyLabel => 'PRIVATE KEY';

  @override
  String get importPasteFromClipboard => 'Paste from Clipboard';

  @override
  String get importKeyHint => 'nsec1... or 64-character hex key';

  @override
  String get importSecurityNote =>
      'Your private key is processed locally and never sent to any server.';

  @override
  String get importContinue => 'Import & Continue';

  @override
  String get importPasteFirst => 'Please paste your private key first.';

  @override
  String get importFailed => 'Failed to import key. Please try again.';

  @override
  String get importInvalidKey => 'Invalid key. Please check and try again.';

  @override
  String get importEyebrow => 'Restore your avatar';

  @override
  String get importScanQrButton => 'Scan a QR instead';

  @override
  String get importScanTitle => 'Scan your key QR';

  @override
  String get importScanHint =>
      'Point your camera at a QR that contains your private key';

  @override
  String get keysTitle => 'Your Avatar Keys';

  @override
  String get keysSubtitle => 'One is for sharing. One is for your eyes only.';

  @override
  String get keysEyebrow => 'Your avatar keys';

  @override
  String get keysHeadline => 'Your keys are your avatar.';

  @override
  String get keysPublicKeyTitle => 'Public Key';

  @override
  String get keysPublicKeySubtitle => 'Share with others to receive messages.';

  @override
  String get keysPrivateKeyTitle => 'Private Key';

  @override
  String get keysPrivateKeySubtitle =>
      'Never share this. Total access to your identity.';

  @override
  String get keysPrivateKeyWarning =>
      'Lose this key = lose your account forever.';

  @override
  String get keysSaveAndContinue => 'Save & Continue';

  @override
  String get keysE2eEncrypted => 'E2E ENCRYPTED';

  @override
  String get keysAgreePrefix => 'I agree to the ';

  @override
  String get keysAgreeTerms => 'Terms & Conditions';

  @override
  String get keysAgreeConjunction => ' and ';

  @override
  String get keysAgreePrivacy => 'Privacy Policy';

  @override
  String get keysPublicCopied =>
      'Public key copied — now reveal your private key';

  @override
  String get keysPrivateCopied =>
      'Private key copied — store it somewhere safe!';

  @override
  String keysFailedToSave(String error) {
    return 'Failed to save keys: $error';
  }

  @override
  String get keysCopyPublicAbove =>
      'Copy your public key above to reveal your private key.';

  @override
  String get privacyPageTitle => 'Privacy & Policy';

  @override
  String get privacyIntroTitle => 'Privacy & Policy';

  @override
  String get privacyIntroBody =>
      'UNIUN is built on transparency. Your data stays on your device. Below is everything you need to know — no legal jargon.';

  @override
  String get privacyExpandPrivacy => 'Privacy Policy';

  @override
  String get privacyExpandTerms => 'Terms of Use';

  @override
  String get privacyLastUpdated => 'Last updated: June 2026';

  @override
  String get privacyContactEmail => 'info@uniun.in';

  @override
  String get privacyStoredLocallyTitle => 'What We Store Locally';

  @override
  String get privacyStoredLocallyBody =>
      'UNIUN stores your notes, profile, saved items, group messages, and settings directly on your device. This data is not sent to any server controlled by UNIUN.';

  @override
  String get privacySharedPubliclyTitle => 'What Gets Shared Publicly';

  @override
  String get privacySharedPubliclyBody =>
      'When you publish a note or send a message in a public group, that content is broadcast to Nostr relays. Nostr is an open public protocol — once published, your notes may be visible to anyone connected to those relays. UNIUN does not control third-party relays.';

  @override
  String get privacyIdentityKeysTitle => 'Your Identity & Keys';

  @override
  String get privacyIdentityKeysBody =>
      'Your identity is a cryptographic key pair. Your public key is visible to others on the Nostr network. Your private key (nsec) is stored exclusively in your device\'s secure system keychain (iOS Keychain / Android Keystore). UNIUN never transmits your private key to any server.';

  @override
  String get privacyLocalAiTitle => 'Local AI (Shiv)';

  @override
  String get privacyLocalAiBody =>
      'The Shiv AI assistant runs entirely on your device. It accesses only your locally saved notes. No note content is sent to any external AI service or API.';

  @override
  String get privacyMediaTitle => 'Media & Blossom Servers';

  @override
  String get privacyMediaBody =>
      'If you attach images or media, they may be uploaded to a Blossom content server of your choice. UNIUN does not operate Blossom servers. Content uploaded there may be publicly accessible by design of the protocol.';

  @override
  String get privacyDmsTitle => 'Direct Messages';

  @override
  String get privacyDmsBody =>
      'DMs are end-to-end encrypted using the Nostr NIP-17 standard. Only the intended recipient can read the message content. Message routing metadata may be visible to relays.';

  @override
  String get privacyControlTitle => 'Your Control';

  @override
  String get privacyControlBody =>
      'You can delete your local data at any time from Settings. Because Nostr is a public protocol, notes already published to relays cannot be retracted — this is an intentional property of the network, not a limitation of the app.';

  @override
  String get privacyContactTitle => 'Contact';

  @override
  String get privacyContactBody => 'For privacy questions: info@uniun.in';

  @override
  String get termsResponsibilityTitle => 'Your Responsibility';

  @override
  String get termsResponsibilityBody =>
      'You are solely responsible for all content you publish on UNIUN. By using the app, you agree not to post content that is illegal, abusive, harassing, hateful, sexually explicit, or that violates others\' rights. Objectionable content and abusive behavior are not welcome on UNIUN.';

  @override
  String get termsNoAbuseTitle => 'No Abuse or Spam';

  @override
  String get termsNoAbuseBody =>
      'Do not use UNIUN to spam, harass, impersonate others, or conduct automated activity that disrupts the Nostr network. UNIUN is decentralized: any note menu includes a Report option (categories: nudity, malware, profanity, illegal, spam, impersonation, other) and any user can be blocked from Settings → Blocked Users. Reported notes are immediately hidden from your feed and blocked users\' content never reaches you. Reports are also published on the Nostr network so other clients and relay operators can act on them.';

  @override
  String get termsPrivateKeyTitle => 'Keep Your Private Key Safe';

  @override
  String get termsPrivateKeyBody =>
      'Your private key (nsec) is your identity and login. If you lose it, your account cannot be recovered — UNIUN has no way to reset or recover private keys. Back it up in a secure location.';

  @override
  String get termsPublicContentTitle => 'Public Content on Relays';

  @override
  String get termsPublicContentBody =>
      'Notes and group messages you publish are sent to Nostr relays and may be visible to anyone on the network. Do not share sensitive personal information in public notes.';

  @override
  String get termsAppMayChangeTitle => 'App May Change';

  @override
  String get termsAppMayChangeBody =>
      'UNIUN is in active development. Features, relay behavior, and policies may change over time. We will communicate significant updates within the app.';

  @override
  String get termsNoWarrantyTitle => 'No Warranty';

  @override
  String get termsNoWarrantyBody =>
      'UNIUN is provided as-is. We make no guarantees about relay uptime, third-party server availability, or persistence of content on external relays.';

  @override
  String get shivName => 'SHIV';

  @override
  String get shivTagline => 'Think in threads';

  @override
  String get shivLandingBody => 'Your on-device AI.\nThink in threads.';

  @override
  String get shivNoModelBody =>
      'Download an AI model to start chatting with Shiv. Everything runs on your device — no internet needed after setup.';

  @override
  String get shivSetUpAi => 'Set up AI';

  @override
  String get shivNewConversation => 'New Conversation';

  @override
  String shivViewConversations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'View $count conversations',
      one: 'View 1 conversation',
    );
    return '$_temp0';
  }

  @override
  String get shivConversations => 'Conversations';

  @override
  String get shivNewConversationTooltip => 'New conversation';

  @override
  String get shivConversationsTooltip => 'Conversations';

  @override
  String get shivBranchTreeTooltip => 'Branch tree';

  @override
  String get shivBranchTreeComingSoon => 'Branch tree — coming in Phase 4';

  @override
  String get shivConversationTree => 'Conversation Tree';

  @override
  String get shivNodeOpenBranch => 'Open Branch';

  @override
  String get shivNodeContinueFromHere => 'Continue From Here';

  @override
  String get shivNodeNewBranch => 'New Branch';

  @override
  String get shivActiveBranch => 'Active Branch';

  @override
  String shivNodeMessages(int count) {
    return '$count msgs';
  }

  @override
  String get shivDefaultConversationTitle => 'New conversation';

  @override
  String get shivEmptyTitle => 'Start a conversation';

  @override
  String get shivEmptyBody =>
      'Ask Shiv anything — your saved notes\ngive it context about what you know.';

  @override
  String get shivEmptyTreeTitle => 'No messages yet';

  @override
  String get shivEmptyTreeBody =>
      'Start a conversation to see the\nbranch tree here.';

  @override
  String get shivThinking => 'Thinking…';

  @override
  String get shivThinkingLabel => 'Reasoning';

  @override
  String shivSourcesChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sources · $count',
      one: 'Sources · 1',
    );
    return '$_temp0';
  }

  @override
  String get shivSourcesSheetTitle => 'Sources';

  @override
  String shivSourcesDocumentPage(String label) {
    return 'Page $label';
  }

  @override
  String get shivSourcesDocumentUntitled => 'PDF document';

  @override
  String get shivSourcesDocumentOpen => 'Open PDF';

  @override
  String shivSourcesDocumentSection(String label) {
    return 'Section: $label';
  }

  @override
  String get shivSourcesDocxUntitled => 'Word document';

  @override
  String get shivSourcesDocxOpen => 'Open document';

  @override
  String get documentViewerOpenExternal => 'Open in another app';

  @override
  String get documentViewerFileGone =>
      'This document is no longer on this device';

  @override
  String get documentViewerReadError =>
      'This document could not be opened here';

  @override
  String get documentViewerTextOnly =>
      'Text, tables and large pictures — open in another app for the full layout';

  @override
  String get shivSourcesImageFound => 'Found in image';

  @override
  String get shivSourcesImageUntitled => 'Image';

  @override
  String get shivSourcesImageOpen => 'Open image';

  @override
  String get shivSourcesImageGone => 'This image is no longer on this device';

  @override
  String get shivSourcesEmpty => 'No sources for this reply';

  @override
  String get shivInputHint => 'Ask Shiv anything…';

  @override
  String get shivHomeHeadline => 'How can I help you?';

  @override
  String get shivHomeHistoryTooltip => 'History';

  @override
  String get shivHomeGana => 'Gana';

  @override
  String get shivHomeNataraj => 'Nataraj';

  @override
  String get shivHomeSuggestSummarize => 'Summarize my week';

  @override
  String get shivHomeSuggestConnect => 'Connect two ideas';

  @override
  String get shivHomeSuggestDraft => 'Draft from a note';

  @override
  String composerAskScope(String scope) {
    return 'Ask $scope';
  }

  @override
  String get shivNoConversations => 'No conversations yet';

  @override
  String get shivActiveLabel => 'Active';

  @override
  String get shivTimeJustNow => 'Just now';

  @override
  String shivTimeMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String shivTimeHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String shivTimeDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get savedNotesTitle => 'Saved Notes';

  @override
  String get savedNotesSearch => 'Search saved notes…';

  @override
  String get savedNotesEmpty => 'Nothing saved yet';

  @override
  String get savedNotesEmptySub =>
      'Bookmark notes from your feed to read them later.';

  @override
  String get graphLegendSaved => 'Saved';

  @override
  String get graphLegendOwn => 'Own';

  @override
  String get graphLegendDraft => 'Draft';

  @override
  String get graphFabTextNote => 'Text note';

  @override
  String get graphFabReferenceNote => 'Reference note';

  @override
  String get graphDraftEdit => 'Edit';

  @override
  String get graphDraftDelete => 'Delete';

  @override
  String get graphScopeAllNotes => 'All notes';

  @override
  String get graphSearchHint => 'Search graph…';

  @override
  String get graphSearchTooltip => 'Search graph';

  @override
  String get graphMenuTooltip => 'Open Manas drawer';

  @override
  String get graphSearchClear => 'Clear search';

  @override
  String graphStepPosition(int current, int total) {
    return '$current/$total';
  }

  @override
  String get graphSearchPrevMatch => 'Previous match';

  @override
  String get graphSearchNextMatch => 'Next match';

  @override
  String get graphPrevConnection => 'Previous connection';

  @override
  String get graphNextConnection => 'Next connection';

  @override
  String get groupEntryTitle => 'Groups';

  @override
  String get groupEntrySubtitle =>
      'Join an existing public group using its ID or QR, or start a new one.';

  @override
  String get groupEntryJoin => 'Join a group';

  @override
  String get groupEntryCreate => 'Create a group';

  @override
  String get privateGroupEntryTitle => 'Private groups';

  @override
  String get privateGroupEntrySubtitle =>
      'Request to join an existing private group, or create your own.';

  @override
  String get privateGroupEntryJoin => 'Join a private group';

  @override
  String get privateGroupEntryCreate => 'Create a private group';

  @override
  String get createGroupTitle => 'Group';

  @override
  String get createGroupHeaderTitle => 'Create group';

  @override
  String get createGroupDetailsHeading => 'Group Details';

  @override
  String get createGroupNameLabel => 'Group name';

  @override
  String get createGroupNamePlaceholder => 'e.g. design';

  @override
  String get createGroupAboutLabel => 'About (Theme/Rules)';

  @override
  String get createGroupDescriptionLabel => 'Description';

  @override
  String get createGroupAboutPlaceholder => 'What\'s this group about?';

  @override
  String get createGroupPictureLabel => 'Picture URL (Optional)';

  @override
  String get createGroupPermanenceNote =>
      'The group\'s first event becomes its permanent ID — it can never be deleted.';

  @override
  String get createGroupAdvancedRelays => 'Advanced · relays';

  @override
  String get createGroupPublishRelays => 'Publish Relays';

  @override
  String get createGroupPublishRelaysBody =>
      'Select the relays this group should be broadcasted on.';

  @override
  String get createGroupAction => 'Create group';

  @override
  String get createGroupSuccess => 'Group created successfully';

  @override
  String get createPrivateGroupTitle => 'Create private group';

  @override
  String get createPrivateGroupEncrypted => 'Encrypted';

  @override
  String get createPrivateGroupNameHint => 'e.g. core team';

  @override
  String get createPrivateGroupDescHint => 'What\'s this group about?';

  @override
  String get createPrivateGroupAdminNote =>
      'You\'re the admin — you control who joins.';

  @override
  String get createPrivateGroupHeading => 'Start a new Private Group';

  @override
  String get createPrivateGroupDescription =>
      'Private groups are end-to-end encrypted. Members must request to join, and admins must approve them.';

  @override
  String get createPrivateGroupNameLabel => 'Group Name';

  @override
  String get createPrivateGroupDescLabel => 'Description';

  @override
  String get createPrivateGroupAction => 'Create Group';

  @override
  String get createPrivateGroupSuccess => 'Private group created successfully!';

  @override
  String get createDmTitle => 'New message';

  @override
  String get createDmRecipientLabel => 'Send to';

  @override
  String get createDmRecipientHint =>
      'Paste their UNIUN code, or scan their QR';

  @override
  String get createDmRelaysNote =>
      'Select the relays this message is sent through.';

  @override
  String get createDmEncryptedNote =>
      'Direct messages are end-to-end encrypted. Only the recipient can read them.';

  @override
  String get createDmScanQr => 'Scan QR code';

  @override
  String get createDmAction => 'Start chat';

  @override
  String get joinPrivateGroupTitle => 'Join private group';

  @override
  String get joinPrivateGroupEncrypted => 'Encrypted';

  @override
  String get joinPrivateGroupHeading => 'Request to Join';

  @override
  String get joinPrivateGroupSubtitle =>
      'Enter the Group ID to request access to a private group.';

  @override
  String get joinPrivateGroupGroupIdLabel => 'Group ID';

  @override
  String get joinPrivateGroupGroupIdHint => 'Paste group ID…';

  @override
  String get joinPrivateGroupGroupIdHelper =>
      'Ask the group admin for the group ID.';

  @override
  String get joinPrivateGroupScanQr => 'Scan QR';

  @override
  String get joinPrivateGroupScanCardTitle => 'Scan a private group QR';

  @override
  String get joinPrivateGroupScanCardSubtitle =>
      'Point your camera at a code shared by the admin';

  @override
  String get joinPrivateGroupApprovalInfo =>
      'Your request goes to the admin for approval before you can read messages.';

  @override
  String get joinPrivateGroupAction => 'Send join request';

  @override
  String get joinPrivateGroupSuccess =>
      'Join request sent! Wait for admin approval.';

  @override
  String get commonOr => 'or';

  @override
  String get commonAdvanced => 'Advanced';

  @override
  String get relaySelectorPlaceholder => 'Select Relays';

  @override
  String relaySelectorSelected(int count) {
    return '$count Relays Selected';
  }

  @override
  String get relaySelectorPickerTitle => 'Select Relays';

  @override
  String get relaySelectorEmpty => 'No relays available. Tap + to add one.';

  @override
  String get relaySelectorAddTooltip => 'Add relay';

  @override
  String get relayAddDialogTitle => 'Add Relay';

  @override
  String get relayAddDialogHint => 'wss://relay.example.com';

  @override
  String get relayAddDialogAction => 'Add';

  @override
  String relayAddDialogError(String error) {
    return 'Could not add relay: $error';
  }

  @override
  String get relayRemoveDialogTitle => 'Remove Relay';

  @override
  String relayRemoveDialogBody(String url) {
    return 'Stop using $url?';
  }

  @override
  String get relayRemoveDialogAction => 'Remove';

  @override
  String get relayManageEmpty => 'No relays found.';

  @override
  String get relayManageRemoveTooltip => 'Remove';

  @override
  String get pendingRequestsTitle => 'Pending join requests';

  @override
  String get pendingRequestsSubtitle =>
      'Approve users so they can read and send messages.';

  @override
  String get pendingRequestsEmpty => 'No pending requests.';

  @override
  String get pendingRequestsNewMember => 'New member';

  @override
  String get pendingRequestsApprove => 'Approve';

  @override
  String get settingsCloudProvider => 'Cloud AI';

  @override
  String get cloudProviderTitle => 'UNIUN Cloud';

  @override
  String get cloudProviderEmptyCta => 'Sign in';

  @override
  String get cloudProviderEmptySubtitle =>
      'Run Shiv on Claude — sign in with your UNIUN identity.';

  @override
  String get cloudProviderConnectedSubtitle => 'Connected · Tap to manage';

  @override
  String get cloudProviderDisconnect => 'Disconnect';

  @override
  String get cloudProviderLastKeyTitle => 'This is your only active key';

  @override
  String get cloudProviderLastKeyMessage =>
      'Disconnecting will revoke your last active key on UNIUN Cloud. You can always reconnect later — this just signs this device out.';

  @override
  String get cloudProviderConnecting => 'Signing in…';

  @override
  String get cloudProviderConnectFailed =>
      'Could not sign in to UNIUN Cloud. Check your connection and try again.';

  @override
  String get qrLoginNotConnected =>
      'Sign in to UNIUN Cloud in Settings first, then scan this code again.';

  @override
  String get qrLoginApproved => 'This device is now signed in on the web.';

  @override
  String qrLoginFailed(String error) {
    return 'Couldn\'t approve sign-in: $error';
  }

  @override
  String get cloudProviderModelsHeader => 'CLOUD MODELS';

  @override
  String get cloudProviderOnDevice => 'On-device';

  @override
  String get cloudProviderOnDeviceNotSet => 'not downloaded';

  @override
  String get cloudProviderNoCloudModels =>
      'No cloud models on your plan yet. Upgrade your plan at uniun.in to unlock them.';

  @override
  String get cloudProviderPlanLabel => 'Plan';

  @override
  String get cloudProviderCreditsLabel => 'Credits';

  @override
  String get cloudProviderUpgrade => 'Upgrade plan / add credits';

  @override
  String get cloudProviderUpgradeHint =>
      'Payment happens on uniun.in — sign in there with the same identity, then come back and reopen this sheet to see your new plan.';

  @override
  String get modelPickerTitle => 'Pick a model';

  @override
  String get modelPickerSearchHint => 'Search models…';

  @override
  String get modelPickerLocalSection => 'On-device';

  @override
  String get modelPickerCloudSection => 'Cloud';

  @override
  String get modelPickerManageLocalCta => 'Manage on-device models';

  @override
  String get modelPickerConnectCloudCta => 'Connect a cloud provider';

  @override
  String get modelPickerNoModels => 'No models available.';

  @override
  String get chatInputAttachImageTooltip => 'Attach an image';

  @override
  String get chatInputRemoveImageTooltip => 'Remove image';

  @override
  String get chatInputPickModelTooltip => 'Pick model';

  @override
  String get followActionSuccess => 'Now following.';

  @override
  String get drawerFollowingSectionTitle => 'FOLLOWING';

  @override
  String get drawerFollowingEmpty => 'Not following anyone yet';

  @override
  String get vishnuFeedEmptyTitle => 'Your feed is quiet';

  @override
  String get vishnuFeedEmptySubtitle =>
      'Scan someone\'s UNIUN QR to follow them and see their notes here.';

  @override
  String get vishnuFeedEmptyCta => 'Scan a QR';

  @override
  String get vishnuFeedEmptyRefresh => 'Refresh';

  @override
  String get drawerPrivateGroups => 'PRIVATE GROUPS';

  @override
  String get drawerNoPrivateGroups => 'No private groups joined';

  @override
  String get followActionInvalidKey => 'Invalid public key';

  @override
  String get userProfileFollow => 'Follow';

  @override
  String get userProfileFollowing => 'Following';

  @override
  String get userProfileNoNotes => 'No notes yet';

  @override
  String get userProfileMessage => 'Message';

  @override
  String get userProfileNotesLabel => 'Notes';

  @override
  String get userProfileCopyNpub => 'Copy npub';

  @override
  String get qrShareAction => 'Share';

  @override
  String get qrShareFailed => 'Couldn\'t share QR code';

  @override
  String get qrCaptionUser => 'Scan this to add you on UNIUN.';

  @override
  String get qrCaptionPublicGroup => 'Scan to join this group.';

  @override
  String get qrCaptionPrivateGroup => 'Scan to join this private group.';

  @override
  String get qrCaptionDm => 'Scan to start a chat on UNIUN.';

  @override
  String get shareSheetTitle => 'Share note';

  @override
  String get shareQuotingLabel => 'Quoting';

  @override
  String get shareToLabel => 'Share to';

  @override
  String get shareActionShare => 'Share';

  @override
  String get shareSheetCommentHint => 'Add a comment (optional)';

  @override
  String get shareDestFeed => 'Post to my feed';

  @override
  String get shareDestFeedSubtitle => 'Visible on Vishnu';

  @override
  String get shareSectionPublicGroups => 'PUBLIC GROUPS';

  @override
  String get shareSectionPrivateGroups => 'PRIVATE GROUPS';

  @override
  String get shareSectionDms => 'DIRECT MESSAGES';

  @override
  String get shareSuccess => 'Shared';

  @override
  String get shareEmbedLoading => 'Loading note…';

  @override
  String get shareEmbedNotFound => 'Note not available';

  @override
  String get shareEmbedUnverified => 'Unverified';

  @override
  String get shareComposeAddReference => 'Reference';

  @override
  String get shareComposeAddImage => 'Image';

  @override
  String get shareNoDmConversations => 'Start a DM first to share notes here.';

  @override
  String get noteCardBlockUser => 'Block user';

  @override
  String get noteCardDeleteNote => 'Delete note';

  @override
  String get deleteNoteSnackbar => 'Note deleted.';

  @override
  String blockUserSnackbar(String name) {
    return 'Blocked $name. New posts from them won\'t appear.';
  }

  @override
  String get settingsBlockedUsers => 'Blocked Users';

  @override
  String get blockedUsersTitle => 'Blocked users';

  @override
  String get blockedUsersDescription =>
      'Blocked people can\'t message you and their notes stay hidden from your feed. Notes are never deleted — unblocking brings them back.';

  @override
  String blockedUsersSectionCount(int count) {
    return 'Blocked · $count';
  }

  @override
  String blockedUsersBlockedAgo(String time) {
    return 'Blocked $time ago';
  }

  @override
  String get blockedUsersBlockedJustNow => 'Blocked just now';

  @override
  String get blockedUsersEmpty => 'You haven\'t blocked anyone';

  @override
  String get blockedUsersEmptyHint =>
      'People you block will appear here, so you can unblock them anytime.';

  @override
  String get actionUnblock => 'Unblock';

  @override
  String get noteCardReport => 'Report note';

  @override
  String get reportSheetTitle => 'Report this content';

  @override
  String get reportSheetReasonHint =>
      'Optional — add any context (max 280 chars)';

  @override
  String get reportSheetSubmit => 'Submit report';

  @override
  String get reportSheetOutcomeHint =>
      'This note will be hidden from your feed. Your report is sent to the network.';

  @override
  String get reportSheetAlsoBlock =>
      'Also block this user (you won\'t see any of their posts)';

  @override
  String get reportSentSnackbar =>
      'Report sent. Thanks for keeping UNIUN safe.';

  @override
  String get reportTypeNudity => 'Nudity';

  @override
  String get reportTypeNudityDescription =>
      'Sexually explicit material or nudity';

  @override
  String get reportTypeMalware => 'Malware';

  @override
  String get reportTypeMalwareDescription =>
      'Links or files that could harm devices';

  @override
  String get reportTypeProfanity => 'Profanity';

  @override
  String get reportTypeProfanityDescription =>
      'Hateful or extremely vulgar language';

  @override
  String get reportTypeIllegal => 'Illegal';

  @override
  String get reportTypeIllegalDescription =>
      'Content that is illegal in the reporter\'s jurisdiction';

  @override
  String get reportTypeSpam => 'Spam';

  @override
  String get reportTypeSpamDescription => 'Unwanted or repetitive promotion';

  @override
  String get reportTypeImpersonation => 'Impersonation';

  @override
  String get reportTypeImpersonationDescription =>
      'Pretending to be someone they are not';

  @override
  String get reportTypeOther => 'Other';

  @override
  String get reportTypeOtherDescription =>
      'Something else that violates community standards';

  @override
  String get actionReadMore => 'Read more';

  @override
  String get actionReadLess => 'Read less';

  @override
  String get mediaGalleryTitle => 'Media';

  @override
  String get mediaTabAll => 'All';

  @override
  String get mediaTabImages => 'Images';

  @override
  String get mediaTabVideos => 'Videos';

  @override
  String get mediaTabAudio => 'Audio';

  @override
  String get mediaTabFiles => 'Files';

  @override
  String get mediaTabPinned => 'Pinned';

  @override
  String get mediaActionDownload => 'Download';

  @override
  String get mediaActionOpen => 'Open';

  @override
  String get mediaActionPin => 'Pin';

  @override
  String get mediaActionUnpin => 'Unpin';

  @override
  String get mediaActionRemoveLocal => 'Remove from device';

  @override
  String get mediaActionCopySha => 'Copy sha256';

  @override
  String get mediaActionSaveToDevice => 'Save to device';

  @override
  String mediaSavedTo(String destination) {
    return 'Saved to $destination';
  }

  @override
  String get mediaSaveSuccess => 'Saved';

  @override
  String get mediaSaveFailed => 'Couldn\'t save the file';

  @override
  String get mediaEmptyState =>
      'No media yet. Notes you receive with attachments will appear here.';

  @override
  String get mediaDetailReferencedBy => 'Referenced by';

  @override
  String get mediaDetailLabelSha => 'sha256';

  @override
  String get mediaDetailLabelMime => 'Type';

  @override
  String get mediaDetailLabelSize => 'Size';

  @override
  String get mediaDetailLabelDim => 'Dimensions';

  @override
  String get mediaDetailLabelCached => 'Cached';

  @override
  String get mediaDetailLabelServer => 'Server';

  @override
  String get mediaPickerTitle => 'Attach from library';

  @override
  String get mediaPickerEmpty => 'No media available yet.';

  @override
  String get composerAttachPhoto => 'Photo';

  @override
  String get composerAttachVideo => 'Video';

  @override
  String get composerAttachFile => 'File';

  @override
  String mediaTooLarge(String size, String cap) {
    return 'File too large ($size). Max $cap. Please compress it and try again.';
  }

  @override
  String get mediaTooLargeAfterCompress =>
      'Couldn\'t compress image small enough to upload. Try a different photo.';

  @override
  String get storageMediaRow => 'Media';

  @override
  String get storageMediaRowSubtitle =>
      'Photos, videos and files from your notes';

  @override
  String get noteCardDownloadMedia => 'Download';

  @override
  String get noteCardFileFallbackName => 'Attachment';

  @override
  String get noteCardFileTapToOpen => 'Tap to open';

  @override
  String get noteCardFileTapToDownload => 'Tap to download';

  @override
  String mediaSelectionCount(int count) {
    return '$count selected';
  }

  @override
  String get mediaSelectionExit => 'Exit selection';

  @override
  String get mediaSelectionRemoveDialogTitle => 'Remove from device?';

  @override
  String mediaSelectionRemoveDialogBody(int count) {
    return 'Free up space by deleting $count cached file(s) from this device. The server copies remain — you can re-download anytime.';
  }

  @override
  String get storageMedia => 'Media';

  @override
  String get storageRetentionTitle => 'Auto-delete old notes';

  @override
  String get storageRetentionSubtitle =>
      'Public feed and group notes only. Saved, followed, your own, DMs, and private groups stay forever. Deleting a note also removes its photos/files from this device.';

  @override
  String get storageRetentionOff => 'Off';

  @override
  String storageRetentionDays(int days) {
    return '$days days';
  }

  @override
  String get syncWindowTitle => 'Sync window';

  @override
  String get syncWindowSubtitle =>
      'How far back to sync feed and group messages. Followed notes and DMs always sync in full. Applies on next app launch.';

  @override
  String syncWindowDays(int days) {
    return '$days days';
  }

  @override
  String get noteCardMediaDownloading => 'Downloading…';

  @override
  String get noteCardMediaFailed => 'Download failed';

  @override
  String get manasDrawerHeaderTitle => 'BRAHMA';

  @override
  String get manasDrawerHeaderSubtitle => 'Your knowledge graphs';

  @override
  String get manasDrawerBrahmaEntryTitle => 'Brahma';

  @override
  String get manasDrawerBrahmaEntrySubtitle =>
      'Everything you\'ve saved, written, and drafted';

  @override
  String get manasDrawerSectionTitle => 'MANAS';

  @override
  String get manasDrawerNewManasButton => 'New';

  @override
  String get manasDrawerEmptyStateTitle => 'No Manases yet';

  @override
  String get manasDrawerEmptyStateBody =>
      'Create a Manas to focus the graph on a topic — a sub-expert mind built from a subset of your notes.';

  @override
  String get manasDrawerEmptyStateCta => 'Create your first Manas';

  @override
  String manasDrawerTileNoteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return '$_temp0';
  }

  @override
  String get manasTileEmptyHint => '0 notes · Tap to open';

  @override
  String get manasTileActionEdit => 'Edit Manas';

  @override
  String get manasTileActionDelete => 'Delete Manas';

  @override
  String get manasDeleteConfirmTitle => 'Delete Manas?';

  @override
  String manasDeleteConfirmBody(String name) {
    return '“$name” will be removed. The notes themselves are kept — only the Manas membership is deleted.';
  }

  @override
  String get manasDeleteConfirmConfirm => 'Delete';

  @override
  String get manasDeleteConfirmCancel => 'Cancel';

  @override
  String get manasFormCreateTitle => 'New Manas';

  @override
  String manasFormEditTitle(String name) {
    return 'Edit · $name';
  }

  @override
  String get manasFormEditTitleFallback => 'Edit Manas';

  @override
  String get manasFormSaveAction => 'Save';

  @override
  String get manasFormDeleteAction => 'Delete Manas';

  @override
  String get manasFormNameLabel => 'Name';

  @override
  String get manasFormNameHint => 'e.g. Rust Expert';

  @override
  String get manasFormDescriptionLabel => 'Description';

  @override
  String get manasFormDescriptionHint => 'Optional. What is this Manas for?';

  @override
  String manasFormMembershipSectionTitle(int count) {
    return 'NOTES IN THIS MANAS ($count)';
  }

  @override
  String get manasFormMembershipEmpty =>
      'No notes yet. Search below to add some.';

  @override
  String get manasFormAddNotesSectionTitle => 'ADD NOTES';

  @override
  String get manasFormSearchHint => 'Search saved, own, or draft notes';

  @override
  String get manasFormSearchEmpty => 'No matches.';

  @override
  String get manasFormNoteUnavailable => '(note unavailable)';

  @override
  String get manasFormKindSaved => 'Saved';

  @override
  String get manasFormKindOwn => 'Own';

  @override
  String get manasFormKindDraft => 'Draft';

  @override
  String get manasFormDeleteConfirmTitle => 'Delete this Manas?';

  @override
  String get manasFormDeleteConfirmBody =>
      'This removes the Manas and all its memberships. The notes themselves remain in Brahma.';

  @override
  String get manasFormDeleteConfirmConfirm => 'Delete';

  @override
  String get manasFormDeleteConfirmCancel => 'Cancel';

  @override
  String get graphHeaderManasEditTooltip => 'Edit Manas';

  @override
  String get graphHeaderUnnamedManas => 'Manas';

  @override
  String get noteCardAddToManas => 'Add to Manas';

  @override
  String get noteCardManasSaveFailed => 'Couldn\'t save the note. Try again.';

  @override
  String get unsaveManasDialogTitle => 'Unsave note?';

  @override
  String get unsaveManasDialogBody =>
      'Unsaving this note will also remove it from:';

  @override
  String get unsaveManasDialogConfirm => 'Unsave';

  @override
  String get unsaveManasDialogCancel => 'Cancel';

  @override
  String get manasMembershipSheetTitle => 'Add to Manas';

  @override
  String get manasMembershipSheetCreate => 'Create new Manas';

  @override
  String get manasMembershipSheetEmptyTitle => 'No Manases yet';

  @override
  String get manasMembershipSheetEmptyBody =>
      'Create your first Manas to start grouping notes into focused sub-experts.';

  @override
  String get manasMembershipSheetEmptyCta => 'Create Manas';

  @override
  String get manasIconPickerTitle => 'Pick an icon';

  @override
  String get ganaListTitle => 'Gana';

  @override
  String get ganaListNew => 'New';

  @override
  String get ganaListSubtitle =>
      'Autonomous agents that watch a surface, reason over a Manas, and publish for you.';

  @override
  String get ganaListPaused => 'Paused';

  @override
  String get ganaListScopeAll => 'All notes';

  @override
  String ganaListScopeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Manas',
      one: '1 Manas',
    );
    return '$_temp0';
  }

  @override
  String get ganaDashboardTitle => 'Dashboard';

  @override
  String get ganaDashboardActive => 'Active';

  @override
  String get ganaDashboardDone => 'Done';

  @override
  String get ganaDashboardFailed => 'Failed';

  @override
  String get ganaDashboardSkipped => 'Skipped';

  @override
  String get ganaDashboardAttentionTitle => 'NEEDS ATTENTION';

  @override
  String get ganaDashboardGanasTitle => 'YOUR GANAS';

  @override
  String get ganaDashboardActivityTitle => 'RECENT ACTIVITY';

  @override
  String get ganaDashboardActivityEmpty =>
      'No runs yet. They show up here as your Ganas work.';

  @override
  String ganaDashboardRate(int percent) {
    return '$percent% succeeded';
  }

  @override
  String ganaStatsCounts(int done, int failed, int skipped) {
    return '$done done · $failed failed · $skipped skipped';
  }

  @override
  String get ganaDashboardFootnote =>
      'Totals count runs since this version. Recent activity keeps the latest 10 runs per Gana.';

  @override
  String get ganaErrNoIdentityTitle => 'No active identity';

  @override
  String get ganaErrNoIdentityHint =>
      'Sign in so the Gana can sign and publish its note.';

  @override
  String get ganaErrPublishTitle => 'Couldn\'t publish the note';

  @override
  String get ganaErrPublishHint =>
      'The Gana wrote a note but sending it failed. It tries again on the next trigger.';

  @override
  String get ganaErrNetworkTitle => 'Network problem';

  @override
  String get ganaErrNetworkHint =>
      'The connection dropped or timed out. Check your internet; it retries on the next trigger.';

  @override
  String get ganaErrModelTitle => 'The AI model had a problem';

  @override
  String get ganaErrModelHint =>
      'The model failed while writing. Check the model in Shiv, then try again.';

  @override
  String get ganaErrOtherTitle => 'Something went wrong';

  @override
  String get ganaErrOtherHint => 'The run stopped with an unexpected error.';

  @override
  String get ganaRunTechnicalDetail => 'Technical detail';

  @override
  String get ganaRunOutputLabel => 'NOTE IT PUBLISHED';

  @override
  String get ganaRunOutputMissing => 'This note is no longer on this device.';

  @override
  String get ganaRunOpenNote => 'Open note';

  @override
  String ganaRunInputCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Read $count messages',
      one: 'Read 1 message',
    );
    return '$_temp0';
  }

  @override
  String get ganaSkipNoActiveModel =>
      'No AI model is active. Pick one in Shiv.';

  @override
  String get ganaSkipModelMismatch =>
      'The active model isn\'t the one this Gana is pinned to.';

  @override
  String get ganaSkipNoNewInput => 'Nothing new to read.';

  @override
  String get ganaSkipModelSwapped =>
      'The model changed mid-run, so this run was cancelled.';

  @override
  String get ganaSkipNoopReturned => 'The model chose to stay silent.';

  @override
  String get ganaSkipMaxOutputs =>
      'It reached its max notes and switched itself off.';

  @override
  String get ganaSkipCloudUnavailable =>
      'UNIUN Cloud isn\'t connected, or no cloud model is set.';

  @override
  String get ganaDrawerEmptyTitle => 'No Ganas yet';

  @override
  String get ganaDrawerEmptyBody =>
      'Create an AI worker that watches a surface and publishes for you.';

  @override
  String get ganaTileDisabled => 'Off';

  @override
  String get ganaTileTriggerReactive => 'Reactive';

  @override
  String ganaTileTriggerInterval(int n) {
    return 'Every ${n}m';
  }

  @override
  String ganaTileTriggerBoth(int n) {
    return 'Reactive + every ${n}m';
  }

  @override
  String get ganaTileTriggerOnceOnEnable => 'Once on enable';

  @override
  String get ganaTileTriggerOnceOnInput => 'Once on first input';

  @override
  String get ganaTileLastRunNever => 'No runs yet';

  @override
  String ganaTileLastRunSucceeded(String when) {
    return 'Last run · $when';
  }

  @override
  String ganaTileLastRunSkipped(String when) {
    return 'Skipped · $when';
  }

  @override
  String ganaTileLastRunFailed(String when) {
    return 'Failed · $when';
  }

  @override
  String get ganaRelativeJustNow => 'just now';

  @override
  String ganaRelativeMinutes(int count) {
    return '${count}m ago';
  }

  @override
  String ganaRelativeHours(int count) {
    return '${count}h ago';
  }

  @override
  String ganaRelativeDays(int count) {
    return '${count}d ago';
  }

  @override
  String get ganaFormCreateTitle => 'New Gana';

  @override
  String ganaFormEditTitle(String name) {
    return 'Edit · $name';
  }

  @override
  String get ganaFormEditTitleFallback => 'Edit Gana';

  @override
  String get ganaFormSaveAction => 'Save';

  @override
  String get ganaFormDeleteAction => 'Delete Gana';

  @override
  String get ganaFormNameLabel => 'Name';

  @override
  String get ganaFormNameHint => 'e.g. Life Lessons Replier';

  @override
  String get ganaFormManasSectionTitle => 'KNOWLEDGE';

  @override
  String get ganaFormManasSectionSubtitle =>
      'The Manas this Gana reasons over.';

  @override
  String get ganaFormManasEmpty =>
      'No Manases yet. A Gana needs a knowledge base to reason over — create one to continue.';

  @override
  String get ganaFormManasCreateNew => 'Create Manas';

  @override
  String get ganaFormModeRecurring => 'Recurring';

  @override
  String get ganaFormModeOneShot => 'One-shot';

  @override
  String get ganaFormModeRecurringHelp =>
      'Keeps firing on every matching trigger until you disable it.';

  @override
  String get ganaFormModeOneShotHelp =>
      'Fires once, then auto-disables itself. Re-enable to run again.';

  @override
  String get ganaFormBlockerName => 'Add a name to continue.';

  @override
  String get ganaFormBlockerManas =>
      'Pick at least one Manas — a Gana needs knowledge to reason over.';

  @override
  String get ganaFormBlockerTask =>
      'Write a task prompt so the Gana knows what to do.';

  @override
  String get ganaFormBlockerInputRef =>
      'Pick the input source — group, DM, user, or note.';

  @override
  String get ganaFormBlockerOutputRef =>
      'Pick the output destination so the Gana knows where to publish.';

  @override
  String get ganaFormBlockerOneShotReactive =>
      'One-shot Ganas with an input source need React to new input turned on.';

  @override
  String get ganaFormBlockerInterval =>
      'Standalone recurring Ganas need an interval (≥ 5 min).';

  @override
  String get ganaFormBlockerTrigger =>
      'Turn on React to new input, or set an interval (≥ 5 min).';

  @override
  String get ganaFormBlockerMaxOutputs =>
      'Set a max-notes cap between 1 and 1000.';

  @override
  String get ganaFormMaxOutputsLabel => 'Max notes to produce';

  @override
  String get ganaFormMaxOutputsHelp =>
      'Recurring Ganas auto-disable after publishing this many notes. 1–1000.';

  @override
  String get ganaFormOneShotStandaloneNote =>
      'Will fire once when you enable this Gana, then auto-disable.';

  @override
  String get ganaFormReactiveRequiredNote =>
      'Required for one-shot Ganas with an input source.';

  @override
  String get ganaFormTaskPromptLabel => 'Task prompt';

  @override
  String get ganaFormTaskPromptHint =>
      'Tell the Gana what to do. e.g. \"When someone posts a question here, reply with the most relevant note from my Manas and add one line of commentary.\"';

  @override
  String get ganaFormInputSectionTitle => 'INPUT';

  @override
  String get ganaFormInputStandalone => 'Standalone (no input)';

  @override
  String get ganaFormInputGroup => 'Public group';

  @override
  String get ganaFormInputPrivateGroup => 'Private group';

  @override
  String get ganaFormInputDm => 'DM';

  @override
  String get ganaFormInputUser => 'A user\'s notes';

  @override
  String get ganaFormInputFollowedNote => 'Followed note thread';

  @override
  String get ganaFormInputPickHint => 'Pick a source';

  @override
  String get ganaFormInputUserHint => 'Paste a pubkey (hex or npub)';

  @override
  String get ganaFormOutputSectionTitle => 'OUTPUT';

  @override
  String get ganaFormOutputFeed => 'Main feed (Kind 1)';

  @override
  String get ganaFormOutputGroup => 'Public group';

  @override
  String get ganaFormOutputPrivateGroup => 'Private group';

  @override
  String get ganaFormOutputDm => 'DM';

  @override
  String get ganaFormOutputPickHint => 'Pick a destination';

  @override
  String get ganaFormModelSectionTitle => 'MODEL';

  @override
  String get ganaFormModelUseActive => 'Use whichever model is active';

  @override
  String get ganaFormTriggersSectionTitle => 'TRIGGERS';

  @override
  String get ganaFormTriggerQuestion => 'When should this run?';

  @override
  String get ganaFormPresetOnceOnEnable => 'Once, when I enable it';

  @override
  String get ganaFormPresetOnceOnFirstMessage =>
      'Once, on the first new message';

  @override
  String get ganaFormPresetEveryMessage => 'On every new message';

  @override
  String get ganaFormPresetOnSchedule => 'On a schedule (every N minutes)';

  @override
  String get ganaFormPresetMessageOrSchedule =>
      'On every new message AND on a timer';

  @override
  String get ganaFormReactiveLabel => 'React to new input';

  @override
  String get ganaFormReactiveHelp =>
      'Fires within a few seconds of a new message on the input surface.';

  @override
  String get ganaFormIntervalLabel => 'Run every';

  @override
  String get ganaFormIntervalUnit => 'minutes (min 5)';

  @override
  String get ganaFormEnabledLabel => 'Enabled';

  @override
  String get ganaFormEnabledHelp =>
      'Off by default. Turn on once you\'ve reviewed the config.';

  @override
  String get ganaFormRunsSectionTitle => 'RECENT RUNS';

  @override
  String get ganaFormRunsEmpty => 'This Gana hasn\'t run yet.';

  @override
  String get ganaFormDeleteConfirmTitle => 'Delete this Gana?';

  @override
  String get ganaFormDeleteConfirmBody =>
      'This stops the worker and removes its run log. The Manases and notes it referenced are not affected.';

  @override
  String get ganaFormDeleteConfirmConfirm => 'Delete';

  @override
  String get ganaFormDeleteConfirmCancel => 'Cancel';

  @override
  String get ganaRunStatusSucceeded => 'Succeeded';

  @override
  String get ganaRunStatusSkipped => 'Skipped';

  @override
  String get ganaRunStatusFailed => 'Failed';

  @override
  String get ganaRunStatusRunning => 'Running';

  @override
  String get natarajTileAction => 'Spark ideas';

  @override
  String get natarajDrawerTitle => 'Nataraj';

  @override
  String get natarajScopeSheetTitle => 'Select Manas';

  @override
  String get natarajScopeAllNotes => 'Brahma';

  @override
  String natarajScopeManasCount(int count) {
    return '$count manas';
  }

  @override
  String get natarajNewChatTooltip => 'New chat';

  @override
  String get natarajEdgePublish => 'Publish';

  @override
  String get natarajEdgeDraft => 'Draft';

  @override
  String get natarajEdgeDiscard => 'Discard';

  @override
  String get natarajEdgeDiscuss => 'Discuss';

  @override
  String get natarajReferencesLabel => 'References';

  @override
  String get natarajReferencesView => 'View references';

  @override
  String get natarajReferencesAttach =>
      'Publishing attaches the checked notes as references.';

  @override
  String get natarajCoachTitle => 'Swipe to explore ideas';

  @override
  String get natarajCoachDismiss => 'Got it';

  @override
  String get natarajGenerating => 'Finding connections…';

  @override
  String get natarajRevisitingHint =>
      'Revisiting older sparks — add notes for fresh ideas';

  @override
  String get natarajEmptyNeedsMoreTitle => 'Not enough notes yet';

  @override
  String get natarajEmptyNeedsMoreBody =>
      'This scope needs at least 2 notes to spark connections.';

  @override
  String get natarajExhaustedTitle => 'You\'ve seen them all';

  @override
  String get natarajExhaustedBody => 'Add more notes to spark new ideas.';

  @override
  String get natarajModelErrorTitle => 'Couldn\'t generate ideas';

  @override
  String get natarajModelErrorBody =>
      'The AI model couldn\'t run on this device. Try a different (smaller) model, or tap retry.';

  @override
  String get natarajNoIdeaTitle => 'No idea this time';

  @override
  String get natarajNoIdeaBody =>
      'That combination of notes didn\'t spark anything. Nothing\'s wrong — just try again.';

  @override
  String get natarajPublishedSnack => 'Published as a note';

  @override
  String get natarajDraftSavedSnack => 'Saved as a draft';

  @override
  String get natarajGenerateErrorSnack => 'Couldn\'t generate right now';

  @override
  String get natarajYouName => 'You';

  @override
  String get natarajYouHandle => '@you · now';

  @override
  String get natarajDraftLabel => 'Draft';

  @override
  String natarajRefsCount(int count) {
    return '$count refs';
  }

  @override
  String get natarajRetry => 'Try again';

  @override
  String get receiveShareTitle => 'Add to UNIUN';

  @override
  String get receiveShareCommentHint => 'Say something… (optional)';

  @override
  String get receiveShareSaveDraft => 'Save to draft';

  @override
  String get receiveShareDraftSaved => 'Saved to drafts';

  @override
  String get receiveShareIngesting => 'Preparing attachments…';

  @override
  String get receiveShareDraftNeedsText => 'Add some text to save a draft';

  @override
  String get receiveShareNothingToShare => 'Add text or media first';

  @override
  String get threadNewNote => 'New';

  @override
  String get threadNewReplyInside => 'New reply inside';

  @override
  String get unreadBadgeOverflow => '99+';

  @override
  String get newNotesDivider => 'New notes';

  @override
  String get jumpToLatest => 'Jump to latest';

  @override
  String get interestsEyebrow => 'Build your feed';

  @override
  String get interestsTitle => 'Tap what you love';

  @override
  String get interestsSubtitle =>
      'Pick at least 3. Each one posts daily, so your feed is alive from the very first scroll.';

  @override
  String get interestsSearchHint => 'Search interests…';

  @override
  String get interestsNoResults => 'No interests match that.';

  @override
  String get interestsContinue => 'Show me my feed';

  @override
  String interestsPickMore(int count) {
    return 'Pick $count more to continue';
  }

  @override
  String get interestsSkip => 'Skip for now';

  @override
  String get interestsFollowFailed =>
      'Couldn\'t follow everyone — please try again.';

  @override
  String get interestsLoadFailed =>
      'Couldn\'t load interests. Check your connection.';

  @override
  String get interestsRetry => 'Retry';

  @override
  String get welcomeMoreLanguages => 'More languages';

  @override
  String get languageSelectTitle => 'Choose language';

  @override
  String get languageComingSoon => 'Coming soon';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsAppLanguage => 'App language';

  @override
  String get graphEmptyHint =>
      'Save notes to build your knowledge graph.\n\nEdges appear when one note references another.';

  @override
  String get ganaDetailManasesLabel => 'Manases';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSheetTitle => 'Choose theme';

  @override
  String get settingsThemeSystem => 'Match system';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsNearbySync => 'Nearby Sync';

  @override
  String get meshTitle => 'Sync with nearby devices';

  @override
  String get meshSubtitle =>
      'Beta · Sync your notes with your other devices on the same Wi-Fi — no internet needed.';

  @override
  String meshConnected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count peers',
      one: '1 peer',
      zero: 'No peers',
    );
    return '$_temp0';
  }

  @override
  String get drawerSurrounding => 'Surrounding';

  @override
  String get surroundingTitle => 'Surrounding';

  @override
  String get surroundingEmpty => 'Nothing nearby yet';

  @override
  String get surroundingEmptySub =>
      'Notes broadcast by nearby devices on the mesh will appear here. They\'re cleared each day.';

  @override
  String get surroundingSave => 'Keep';

  @override
  String get surroundingSaved => 'Saved';

  @override
  String get surroundingSourceLabel => '📍 Nearby';

  @override
  String get noteCardTranslate => 'Translate';

  @override
  String get translateSheetTitle => 'Translate to';

  @override
  String get translateSheetAction => 'Translate';

  @override
  String get translateSheetSettingsHint => 'From your app language';

  @override
  String get translatingLabel => 'Translating…';

  @override
  String translatedToLabel(String language) {
    return 'Translated to $language';
  }

  @override
  String get translationShowOriginal => 'Show original';

  @override
  String get translationShowTranslation => 'Show translation';

  @override
  String get translationChangeLanguage => 'Change';

  @override
  String get translationFailed => 'Couldn\'t translate this note. Try again.';

  @override
  String get translationNotProduced =>
      'The AI model couldn\'t translate this note. Try a larger model or UNIUN Cloud.';

  @override
  String get brahmaPublishConfirmTitle => 'Publish this note?';

  @override
  String get brahmaPublishConfirmBody =>
      'Published notes are permanent. They go out to the relay and cannot be edited or deleted. Keep it as a draft if you\'re still working on it.';

  @override
  String get errorUnexpected => 'Something went wrong.';

  @override
  String get savedNoSearchResults => 'No notes match your search.';

  @override
  String qrScannerInvalidCode(String error) {
    return 'Invalid QR: $error';
  }

  @override
  String get qrScannerInstruction =>
      'Scan a UNIUN QR — user, public group, or private group';

  @override
  String qrCopiedToClipboard(String label) {
    return '$label • copied to clipboard';
  }

  @override
  String get privateGroupShareQrTooltip => 'Share QR';

  @override
  String get privateGroupLeaveAction => 'Leave Group';

  @override
  String get privateGroupPendingApprovalTitle => 'Pending approval';

  @override
  String get privateGroupPendingApprovalBody =>
      'Your request to join has been sent. You\'ll be able to read and send messages once the group admin approves you.';

  @override
  String get dmShareKeysTooltip => 'Share keys';

  @override
  String get groupFeedNoMessages => 'No messages yet. Be the first!';

  @override
  String threadShowMoreReferences(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show $count more references',
      one: 'Show 1 more reference',
    );
    return '$_temp0';
  }
}
