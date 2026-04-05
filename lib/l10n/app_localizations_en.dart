// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appVersion => 'UNIUN v1.0.0-beta';

  @override
  String get appTagline => 'Your notes, your\nnetwork, your identity.';

  @override
  String get navVishnu => 'VISHNU';

  @override
  String get navBrahma => 'BRAHMA';

  @override
  String get navShiv => 'SHIV';

  @override
  String get actionCopy => 'COPY';

  @override
  String get actionCopied => 'Copied';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionSave => 'Save';

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
  String get drawerChannels => 'Channels';

  @override
  String get drawerDirectMessages => 'Direct Messages';

  @override
  String get drawerApps => 'Apps';

  @override
  String get drawerAiAssistant => 'AI Assistant';

  @override
  String get drawerSettings => 'Settings';

  @override
  String get drawerFollowingNotes => 'FOLLOWING NOTES';

  @override
  String get drawerNoFollowedNotes => 'No followed notes yet';

  @override
  String get drawerNoChannels => 'No channels yet';

  @override
  String get drawerNoMessages => 'No messages yet';

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
  String get brahmaHintText => 'Write a new note...';

  @override
  String get brahmaAddImage => 'Add Image';

  @override
  String get brahmaTagPeople => 'Tag People';

  @override
  String get brahmaReferenceNote => 'Reference Note';

  @override
  String get brahmaCreateNote => 'Create Note';

  @override
  String get brahmaFailedToPublish => 'Failed to publish';

  @override
  String get brahmaGraphPreviewLabel => 'REFERENCE GRAPH PREVIEW';

  @override
  String get brahmaInteractivePreview => 'Interactive Preview';

  @override
  String get vishnuNoNotes => 'No notes yet';

  @override
  String get vishnuCreateFirst =>
      'Create your first note in Brahma\nor wait for the relay to sync.';

  @override
  String get vishnuThread => 'THREAD';

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
  String get followedNoteReferencedBy => 'Referenced By';

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
  String get identityExportBackup => 'Export Backup';

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
  String get alertsChannelAlerts => 'Channel Alerts';

  @override
  String get storageUsage => 'Storage Usage';

  @override
  String get storageOptimizing => 'Optimizing for offline-first experience.';

  @override
  String get storageClearCache => 'Clear Cache';

  @override
  String get storageResetData => 'Reset Local Data';

  @override
  String get styleTheme => 'Theme';

  @override
  String get styleThemeLight => 'Light';

  @override
  String get styleAccent => 'Accent';

  @override
  String get aiSelectModel => 'Select Model';

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
  String get aiModelRecommendedBadge => 'Recommended';

  @override
  String get aiModelUseThisButton => 'Use This Model';

  @override
  String get aiModelDownloadInfoText =>
      'Switching models requires a one-time download. Connect to Wi-Fi to avoid data charges. Your chat history is preserved.';

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
  String get aiModelDownloadError => 'Download failed. Please try again.';

  @override
  String get aiModelQwen25Name => 'Qwen 2.5 0.5B';

  @override
  String get aiModelQwen25Desc =>
      'Ultra-compact and fast. Works on any Android device with 3 GB+ RAM.';

  @override
  String get aiModelDeepSeekR1Name => 'DeepSeek R1';

  @override
  String get aiModelDeepSeekR1Desc =>
      'Best reasoning and code generation for daily use. Requires 4 GB+ RAM.';

  @override
  String get aiModelGemma4E2bName => 'Gemma 4 E2B';

  @override
  String get aiModelGemma4E2bDesc =>
      'Multimodal — handles text and images. Great for high-end devices with 6 GB+ RAM.';

  @override
  String get aiModelGemma4E4bName => 'Gemma 4 E4B';

  @override
  String get aiModelGemma4E4bDesc =>
      'Maximum accuracy multimodal model. Best on flagship devices with 8 GB+ RAM.';

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
  String get welcomeTagline => 'Your notes, your\nnetwork, your identity.';

  @override
  String get welcomeCreateIdentity => 'Create New Identity';

  @override
  String get welcomeImportKey => 'I Already Have a Key';

  @override
  String get welcomeLearnHow => 'Learn how UNIUN works';

  @override
  String get aboutYouTitle => 'About You';

  @override
  String get aboutYouSubtitle =>
      'Set up your profile. Display Name and Username are required.';

  @override
  String get aboutYouAvatarCaption => 'Auto-generated · Photo optional';

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
  String get aboutYouSetUpLater => 'SET UP LATER';

  @override
  String get aboutYouEncrypted => 'Your data is encrypted and private.';

  @override
  String get aboutYouDisplayNameRequired => 'Display name is required';

  @override
  String get aboutYouUsernameRequired => 'Username is required';

  @override
  String get importTitle => 'Import Your Identity';

  @override
  String get importSubtitle =>
      'Paste your private key to recover your existing profile.';

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
  String get keysTitle => 'Your Identity Keys';

  @override
  String get keysSubtitle => 'One is for sharing. One is for your eyes only.';

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
  String get keysDownloadBackup => 'Download Backup';

  @override
  String get keysE2eEncrypted => 'E2E ENCRYPTED';

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
  String keysBackupSaved(String path) {
    return 'Backup saved to $path';
  }

  @override
  String get keysBackupFailed => 'Failed to save backup';

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
  String get privacyLastUpdated => 'Last updated: June 2025';

  @override
  String get privacyContactEmail => 'privacy@uniun.app';

  @override
  String get privacyStoredLocallyTitle => 'What We Store Locally';

  @override
  String get privacyStoredLocallyBody =>
      'UNIUN stores your notes, profile, saved items, channel messages, and settings directly on your device. This data is not sent to any server controlled by UNIUN.';

  @override
  String get privacySharedPubliclyTitle => 'What Gets Shared Publicly';

  @override
  String get privacySharedPubliclyBody =>
      'When you publish a note or send a message in a public channel, that content is broadcast to Nostr relays. Nostr is an open public protocol — once published, your notes may be visible to anyone connected to those relays. UNIUN does not control third-party relays.';

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
  String get privacyContactBody => 'For privacy questions: privacy@uniun.app';

  @override
  String get termsResponsibilityTitle => 'Your Responsibility';

  @override
  String get termsResponsibilityBody =>
      'You are solely responsible for all content you publish on UNIUN. By using the app, you agree not to post content that is illegal, abusive, harassing, or violates others\' rights.';

  @override
  String get termsNoAbuseTitle => 'No Abuse or Spam';

  @override
  String get termsNoAbuseBody =>
      'Do not use UNIUN to spam, harass, impersonate others, or conduct automated activity that disrupts the Nostr network.';

  @override
  String get termsPrivateKeyTitle => 'Keep Your Private Key Safe';

  @override
  String get termsPrivateKeyBody =>
      'Your private key (nsec) is your identity and login. If you lose it, your account cannot be recovered — UNIUN has no way to reset or recover private keys. Back it up in a secure location.';

  @override
  String get termsPublicContentTitle => 'Public Content on Relays';

  @override
  String get termsPublicContentBody =>
      'Notes and channel messages you publish are sent to Nostr relays and may be visible to anyone on the network. Do not share sensitive personal information in public notes.';

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
}
