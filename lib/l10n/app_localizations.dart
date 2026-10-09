import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// App version string shown in settings / footer
  ///
  /// In en, this message translates to:
  /// **'UNIUN v1.0.0-beta'**
  String get appVersion;

  /// Hero tagline on the welcome screen
  ///
  /// In en, this message translates to:
  /// **'Your notes, your\nnetwork, your identity.'**
  String get appTagline;

  /// Floating nav label for the feed tab
  ///
  /// In en, this message translates to:
  /// **'VISHNU'**
  String get navVishnu;

  /// Floating nav label for the create-note tab
  ///
  /// In en, this message translates to:
  /// **'BRAHMA'**
  String get navBrahma;

  /// Floating nav label for the AI assistant tab
  ///
  /// In en, this message translates to:
  /// **'SHIV'**
  String get navShiv;

  /// Copy button label
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get actionCopy;

  /// Feedback after copying
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get actionCopied;

  /// Retry button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// Continue button in onboarding
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// Delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// Save / bookmark action
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// Tooltip for the shared back-arrow atom
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// Done button
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// State when note is bookmarked
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get actionSaved;

  /// Follow a note
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get actionFollow;

  /// State when following a note
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get actionFollowing;

  /// Drawer nav item — home
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get drawerHome;

  /// Drawer nav item — saved notes
  ///
  /// In en, this message translates to:
  /// **'Saved Notes'**
  String get drawerSavedNotes;

  /// Drawer section header — groups
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get drawerGroups;

  /// Drawer section header — DMs
  ///
  /// In en, this message translates to:
  /// **'Direct Messages'**
  String get drawerDirectMessages;

  /// Drawer section header — apps
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get drawerApps;

  /// Drawer apps item — AI
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get drawerAiAssistant;

  /// Drawer footer — settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get drawerSettings;

  /// Drawer section header — watched notes (uppercase)
  ///
  /// In en, this message translates to:
  /// **'NOTE WATCH'**
  String get drawerFollowingNotes;

  /// Empty state for watched notes in drawer
  ///
  /// In en, this message translates to:
  /// **'Not watching any notes yet'**
  String get drawerNoFollowedNotes;

  /// Empty state for groups in drawer
  ///
  /// In en, this message translates to:
  /// **'No groups yet'**
  String get drawerNoGroups;

  /// Drawer header button — open my QR code
  ///
  /// In en, this message translates to:
  /// **'My QR code'**
  String get drawerMyQrCode;

  /// Drawer header button — open QR scanner
  ///
  /// In en, this message translates to:
  /// **'Scan code'**
  String get drawerScanCode;

  /// Drawer private-group row subtitle
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get drawerPrivateLabel;

  /// Drawer search result subtitle — DM
  ///
  /// In en, this message translates to:
  /// **'Direct message'**
  String get drawerSearchKindDm;

  /// Drawer search result subtitle — followed user
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get drawerSearchKindUser;

  /// App bar title for the join group page
  ///
  /// In en, this message translates to:
  /// **'Join Group'**
  String get joinGroupTitle;

  /// Heading on the join group page
  ///
  /// In en, this message translates to:
  /// **'Join Existing Group'**
  String get joinGroupHeading;

  /// Primary join group button label
  ///
  /// In en, this message translates to:
  /// **'Join Group'**
  String get joinGroupAction;

  /// Field label for group id input
  ///
  /// In en, this message translates to:
  /// **'Group ID (Hex)'**
  String get joinGroupIdLabel;

  /// Section title for relay selection on join group page
  ///
  /// In en, this message translates to:
  /// **'Group Relays'**
  String get joinGroupRelaysTitle;

  /// Helper text under the relay selector on join group page
  ///
  /// In en, this message translates to:
  /// **'Select the relays this group operates on to start syncing.'**
  String get joinGroupRelaysBody;

  /// Placeholder / dialog title for relay selection
  ///
  /// In en, this message translates to:
  /// **'Select Relays'**
  String get joinGroupSelectRelays;

  /// Label showing how many relays are selected on join group page
  ///
  /// In en, this message translates to:
  /// **'{count} Relays Selected'**
  String joinGroupSelectedRelays(int count);

  /// Title and tooltip for adding a relay from the join group flow
  ///
  /// In en, this message translates to:
  /// **'Add Relay'**
  String get joinGroupAddRelay;

  /// Confirm button for adding a relay
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get joinGroupAddRelayAction;

  /// Hint text when adding a relay URL
  ///
  /// In en, this message translates to:
  /// **'wss://relay.example.com'**
  String get joinGroupRelayHint;

  /// Secondary CTA to scan a QR code and join a group
  ///
  /// In en, this message translates to:
  /// **'Join by QR'**
  String get joinGroupByQr;

  /// Title on the scan-QR card at the top of the join group page
  ///
  /// In en, this message translates to:
  /// **'Scan a group QR'**
  String get joinGroupScanCardTitle;

  /// Subtitle on the scan-QR card on the join group page
  ///
  /// In en, this message translates to:
  /// **'Point your camera at a UNIUN group code'**
  String get joinGroupScanCardSubtitle;

  /// Divider label between scan-QR and paste-id on the join group page
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get joinGroupOr;

  /// Placeholder for the group id input on the join group page
  ///
  /// In en, this message translates to:
  /// **'Paste group ID'**
  String get joinGroupIdHint;

  /// App bar title for the QR scanner page
  ///
  /// In en, this message translates to:
  /// **'Scan Group QR'**
  String get joinGroupQrTitle;

  /// Hint text on the join group QR scanner page
  ///
  /// In en, this message translates to:
  /// **'Scan a QR code containing a group id and relay list.'**
  String get joinGroupQrHint;

  /// Tooltip for choosing a QR image from the gallery on the join group scanner page
  ///
  /// In en, this message translates to:
  /// **'Pick QR from gallery'**
  String get joinGroupQrFromGallery;

  /// Snackbar shown when the chosen gallery image does not contain a decodable QR code
  ///
  /// In en, this message translates to:
  /// **'No valid QR code found in the selected image.'**
  String get joinGroupQrGalleryError;

  /// Snackbar after successfully joining a group
  ///
  /// In en, this message translates to:
  /// **'Group joined successfully.'**
  String get joinGroupSuccess;

  /// Validation error when the group id is not 64 hex characters
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like a valid group ID. Check it and try again.'**
  String get joinGroupErrorInvalidId;

  /// Validation error when no relay is selected
  ///
  /// In en, this message translates to:
  /// **'Please select at least one relay.'**
  String get joinGroupErrorNoRelay;

  /// Error when a relay could not be saved to the local database
  ///
  /// In en, this message translates to:
  /// **'Failed to save relay locally.'**
  String get joinGroupErrorRelaySaveFailed;

  /// Error when saving the joined group fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t join the group. Please try again.'**
  String get joinGroupErrorSaveFailed;

  /// Placeholder text in the group message composer input
  ///
  /// In en, this message translates to:
  /// **'Message group…'**
  String get groupMessageHint;

  /// Placeholder text in the DM and private group composer input
  ///
  /// In en, this message translates to:
  /// **'Message…'**
  String get chatMessageHint;

  /// Pill shown at the top of a DM conversation reassuring that messages are E2E encrypted (NIP-17)
  ///
  /// In en, this message translates to:
  /// **'Messages are end-to-end encrypted'**
  String get dmEncryptedNotice;

  /// Title for the share-group QR bottom sheet and tooltip
  ///
  /// In en, this message translates to:
  /// **'Share Group QR'**
  String get groupShareQrTitle;

  /// Helper text under the share-group QR title
  ///
  /// In en, this message translates to:
  /// **'Let someone scan this QR to join the group with the right relays.'**
  String get groupShareQrBody;

  /// Empty state for DMs in drawer
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get drawerNoMessages;

  /// Placeholder for the drawer search field
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get drawerSearchHint;

  /// Shown in the drawer when a search query has no matching items
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get drawerSearchNoResults;

  /// QR sheet action button
  ///
  /// In en, this message translates to:
  /// **'Copy npub'**
  String get drawerCopyNpub;

  /// Snackbar after copying npub
  ///
  /// In en, this message translates to:
  /// **'npub copied'**
  String get drawerNpubCopied;

  /// Snackbar for unimplemented features
  ///
  /// In en, this message translates to:
  /// **'{feature} — coming soon'**
  String drawerComingSoon(String feature);

  /// Title of the create-note screen
  ///
  /// In en, this message translates to:
  /// **'Brahma'**
  String get brahmaTitle;

  /// Brahma header tagline shown below the title
  ///
  /// In en, this message translates to:
  /// **'Write & publish to Nostr'**
  String get brahmaTagline;

  /// Placeholder in the note compose field
  ///
  /// In en, this message translates to:
  /// **'Write a new note...'**
  String get brahmaHintText;

  /// Placeholder in the note subject field
  ///
  /// In en, this message translates to:
  /// **'Subject (optional)'**
  String get brahmaSubjectHintText;

  /// Tooltip for attach-image button
  ///
  /// In en, this message translates to:
  /// **'Add Image'**
  String get brahmaAddImage;

  /// Tooltip for tag-people button
  ///
  /// In en, this message translates to:
  /// **'Tag People'**
  String get brahmaTagPeople;

  /// Tooltip for the mention icon in the compose bar
  ///
  /// In en, this message translates to:
  /// **'Mention a Note'**
  String get brahmaReferenceNote;

  /// Title of the mention-search bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Mention a Note'**
  String get brahmaMentionSheetTitle;

  /// Hint text in the mention search field
  ///
  /// In en, this message translates to:
  /// **'Search notes…'**
  String get brahmaMentionSearchHint;

  /// Empty state in mention search results
  ///
  /// In en, this message translates to:
  /// **'No notes found'**
  String get brahmaMentionEmpty;

  /// Badge shown on an already-selected note in the search sheet
  ///
  /// In en, this message translates to:
  /// **'Mentioned'**
  String get brahmaMentionSelected;

  /// Title of the full-screen reference picker
  ///
  /// In en, this message translates to:
  /// **'Add reference'**
  String get composerReferenceTitle;

  /// Hint text in the reference picker search field
  ///
  /// In en, this message translates to:
  /// **'Search…'**
  String get composerReferenceSearchHint;

  /// Empty state in the reference picker
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get composerReferenceEmpty;

  /// Reference picker tab showing all candidate notes
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get composerReferenceTabAll;

  /// Reference picker tab showing only saved notes
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get composerReferenceTabSaved;

  /// Reference picker tab showing only the user's own notes
  ///
  /// In en, this message translates to:
  /// **'My notes'**
  String get composerReferenceTabOwn;

  /// Reference picker tab showing only local drafts
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get composerReferenceTabDrafts;

  /// Reference picker confirm button; shows the selected count when non-zero
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get composerReferenceAdd;

  /// Title of the Manas picker bottom sheet that grounds the inline Shiv chat
  ///
  /// In en, this message translates to:
  /// **'Chat with your notes'**
  String get composerChatPickerTitle;

  /// Subtitle under the Manas picker title
  ///
  /// In en, this message translates to:
  /// **'Scope to a Manas'**
  String get composerChatPickerSubtitle;

  /// Brand title shown in the in-composer AI chat header
  ///
  /// In en, this message translates to:
  /// **'Shiv'**
  String get composerChatBrand;

  /// Manas picker row that scopes Shiv to the user's whole library
  ///
  /// In en, this message translates to:
  /// **'All notes'**
  String get composerChatAllNotes;

  /// Subtitle of the All notes row in the Manas picker
  ///
  /// In en, this message translates to:
  /// **'Ask Brahma'**
  String get composerChatAllNotesSubtitle;

  /// Note count shown under each Manas row in the picker
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 note} other{{count} notes}}'**
  String composerChatManasNotes(int count);

  /// Eyebrow under the 'Shiv' title in the inline composer-chat header; shows the grounding scope (a Manas name or 'All notes'). Rendered uppercase.
  ///
  /// In en, this message translates to:
  /// **'{scope} · on-device'**
  String composerChatScopeEyebrow(String scope);

  /// Empty-state hint pill in the inline composer-chat, shown before the first question. {scope} is a Manas name or 'All notes'.
  ///
  /// In en, this message translates to:
  /// **'Grounded in {scope}'**
  String composerChatGroundedHint(String scope);

  /// Placeholder shown in the AI answer bubble while the first tokens are still streaming
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get composerChatThinking;

  /// Button that stops the in-flight inline composer-chat answer
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get composerChatStop;

  /// Shown in the inline composer-chat when no on-device model is installed
  ///
  /// In en, this message translates to:
  /// **'No AI model is active. Download one from the Shiv tab.'**
  String get composerChatNoModel;

  /// Fallback error text in the inline composer-chat
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get composerChatError;

  /// Action under an AI answer that moves its text into the composer as an editable reply draft
  ///
  /// In en, this message translates to:
  /// **'Use as reply'**
  String get composerChatUseAsReply;

  /// Header above the notes a thread note references (mentions)
  ///
  /// In en, this message translates to:
  /// **'REFERENCES'**
  String get threadReferencesLabel;

  /// Header above the parent note a thread note is replying to
  ///
  /// In en, this message translates to:
  /// **'REPLYING TO'**
  String get threadReplyingToLabel;

  /// Submit button in the compose card
  ///
  /// In en, this message translates to:
  /// **'Create Note'**
  String get brahmaCreateNote;

  /// Fallback error message when publishing fails
  ///
  /// In en, this message translates to:
  /// **'Failed to publish'**
  String get brahmaFailedToPublish;

  /// Section header above the graph preview canvas
  ///
  /// In en, this message translates to:
  /// **'REFERENCE GRAPH PREVIEW'**
  String get brahmaGraphPreviewLabel;

  /// Badge on the graph preview canvas
  ///
  /// In en, this message translates to:
  /// **'Interactive Preview'**
  String get brahmaInteractivePreview;

  /// Save as draft button label
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get brahmaDraft;

  /// Tooltip for the heading button (cycles H1/H2/H3)
  ///
  /// In en, this message translates to:
  /// **'Heading'**
  String get markdownToolbarHeading;

  /// Tooltip for the bold formatting button in the composer
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get markdownToolbarBold;

  /// Tooltip for the italic formatting button
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get markdownToolbarItalic;

  /// Tooltip for the inline-code formatting button
  ///
  /// In en, this message translates to:
  /// **'Inline code'**
  String get markdownToolbarCode;

  /// Tooltip for the bullet-list formatting button
  ///
  /// In en, this message translates to:
  /// **'Bullet list'**
  String get markdownToolbarBulletList;

  /// Tooltip for the numbered-list formatting button
  ///
  /// In en, this message translates to:
  /// **'Numbered list'**
  String get markdownToolbarNumberList;

  /// Tooltip for the blockquote formatting button
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get markdownToolbarQuote;

  /// Tooltip for the link formatting button
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get markdownToolbarLink;

  /// Feedback after saving a draft
  ///
  /// In en, this message translates to:
  /// **'Draft saved'**
  String get brahmaDraftSaved;

  /// Section header for drafts list
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get brahmaDrafts;

  /// Publish draft button in draft list
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get brahmaPublish;

  /// Snackbar confirmation after a draft is published from the graph
  ///
  /// In en, this message translates to:
  /// **'Published as a note'**
  String get brahmaDraftPublished;

  /// Tag count display in draft item
  ///
  /// In en, this message translates to:
  /// **'tags'**
  String get brahmaTags;

  /// Title of the bottom sheet asking how to handle draft → draft references at publish time
  ///
  /// In en, this message translates to:
  /// **'This note links to other drafts'**
  String get brahmaPublishChainTitle;

  /// Sub-line on the publish-chain sheet — explains the Nostr immutability constraint
  ///
  /// In en, this message translates to:
  /// **'Nostr notes are immutable once published — references to {count, plural, =1{1 unpublished draft} other{{count} unpublished drafts}} can only be added now, not later.'**
  String brahmaPublishChainSubtitle(int count);

  /// Sheet option: publish dependencies first, then this draft, with links restored
  ///
  /// In en, this message translates to:
  /// **'Publish the whole chain'**
  String get brahmaPublishChain;

  /// Body for the 'publish chain' sheet option
  ///
  /// In en, this message translates to:
  /// **'Publishes {count, plural, =1{1 linked draft} other{{count} linked drafts}} first, then this note with the links in its tags.'**
  String brahmaPublishChainBody(int count);

  /// Sheet option: publish just this draft, dropping the unpublished draft references
  ///
  /// In en, this message translates to:
  /// **'Publish only this'**
  String get brahmaPublishOnlyThis;

  /// Body for the 'publish only this' sheet option
  ///
  /// In en, this message translates to:
  /// **'Drop the draft references from this note. The other drafts stay where they are.'**
  String get brahmaPublishOnlyThisSubtitle;

  /// Empty-feed heading
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get vishnuNoNotes;

  /// Empty-feed body text
  ///
  /// In en, this message translates to:
  /// **'Create your first note in Brahma\nor wait for the relay to sync.'**
  String get vishnuCreateFirst;

  /// Thread indicator badge on note cards
  ///
  /// In en, this message translates to:
  /// **'THREAD'**
  String get vishnuThread;

  /// Reference count badge on note cards
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 REFERENCE} other{{count} REFERENCES}}'**
  String vishnuReferences(num count);

  /// Shown when a referenced note is not in local Isar
  ///
  /// In en, this message translates to:
  /// **'Referenced note not available'**
  String get vishnuReferenceUnavailable;

  /// Sticky banner shown when new feed items arrived since the page was loaded
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 new note} other{{count} new notes}}'**
  String vishnuNewNotesBanner(int count);

  /// Placeholder title for the Shiv tab
  ///
  /// In en, this message translates to:
  /// **'Shiv — AI Assistant'**
  String get homeShivTitle;

  /// Placeholder body for the Shiv tab
  ///
  /// In en, this message translates to:
  /// **'On-device AI coming soon.'**
  String get homeShivComingSoon;

  /// Thread screen app-bar title
  ///
  /// In en, this message translates to:
  /// **'Thread'**
  String get threadTitle;

  /// Segmented toggle tab — replies
  ///
  /// In en, this message translates to:
  /// **'Replies'**
  String get threadReplies;

  /// Segmented toggle tab — references
  ///
  /// In en, this message translates to:
  /// **'References'**
  String get threadReferences;

  /// Empty state heading for replies tab
  ///
  /// In en, this message translates to:
  /// **'No replies yet'**
  String get threadNoReplies;

  /// Empty state body for replies tab
  ///
  /// In en, this message translates to:
  /// **'Be the first to reply.'**
  String get threadBeFirstToReply;

  /// Empty state heading for references tab
  ///
  /// In en, this message translates to:
  /// **'No references'**
  String get threadNoReferences;

  /// Empty state body for references tab
  ///
  /// In en, this message translates to:
  /// **'No notes reference this one yet.'**
  String get threadNoReferencesDetail;

  /// Send button in the reply composer
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get threadPost;

  /// Reply composer hint when no specific target
  ///
  /// In en, this message translates to:
  /// **'Reply to this note…'**
  String get threadReplyToThis;

  /// Reply composer hint when replying to a specific user
  ///
  /// In en, this message translates to:
  /// **'Reply to @{name}…'**
  String threadReplyTo(String name);

  /// Pill label showing who the reply targets
  ///
  /// In en, this message translates to:
  /// **'Replying to @{name}'**
  String threadReplyingTo(String name);

  /// Section header in followed-note detail
  ///
  /// In en, this message translates to:
  /// **'THREAD CONTINUATION'**
  String get threadContinuation;

  /// Reply count label in thread continuation card
  ///
  /// In en, this message translates to:
  /// **'{count} Replies'**
  String threadNReplies(int count);

  /// Last-updated label in thread continuation card
  ///
  /// In en, this message translates to:
  /// **'Updated: {time}'**
  String threadUpdated(String time);

  /// Primary CTA on followed-note detail
  ///
  /// In en, this message translates to:
  /// **'View Thread'**
  String get followedNoteViewThread;

  /// Error state on followed-note detail
  ///
  /// In en, this message translates to:
  /// **'Failed to load note'**
  String get followedNoteFailedToLoad;

  /// Node-type label on note header card
  ///
  /// In en, this message translates to:
  /// **'Research Node'**
  String get followedNoteResearchNode;

  /// Following badge on note header card
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get followedNoteFollowing;

  /// Section header for the replies list on followed-note detail
  ///
  /// In en, this message translates to:
  /// **'Replies'**
  String get followedNoteReferencedBy;

  /// Section header for the references list
  ///
  /// In en, this message translates to:
  /// **'References'**
  String get followedNoteReferences;

  /// Settings screen app-bar title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings section label — account
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// Settings section label — identity
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get settingsIdentity;

  /// Settings section label — AI
  ///
  /// In en, this message translates to:
  /// **'AI · Shiv'**
  String get settingsAiShiv;

  /// Settings section label — storage
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get settingsStorage;

  /// Settings section label — about
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// Settings About row label — app version
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// Settings log out button label
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get settingsLogout;

  /// Log out confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get settingsLogoutTitle;

  /// Log out confirmation dialog body
  ///
  /// In en, this message translates to:
  /// **'You\'ll need your private key (nsec) to sign back in. Make sure it\'s backed up before logging out.'**
  String get settingsLogoutBody;

  /// Log out confirmation dialog confirm action
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get settingsLogoutConfirm;

  /// Settings section label — alerts
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get settingsAlerts;

  /// Settings section label — style
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get settingsStyle;

  /// Fallback display name when profile has no name
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get profileAnonymous;

  /// Edit profile button on settings
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEditProfile;

  /// Subtitle on the identity card
  ///
  /// In en, this message translates to:
  /// **'This is your login & recovery method.'**
  String get identityLoginRecovery;

  /// Identity card row — keys
  ///
  /// In en, this message translates to:
  /// **'Keys'**
  String get identityKeys;

  /// Identity card row — relays
  ///
  /// In en, this message translates to:
  /// **'Relays'**
  String get identityRelays;

  /// Identity card row — privacy policy
  ///
  /// In en, this message translates to:
  /// **'Privacy & Policy'**
  String get identityPrivacyPolicy;

  /// Keys sheet title
  ///
  /// In en, this message translates to:
  /// **'Your Keys'**
  String get identityYourKeys;

  /// Warning subtitle in the keys sheet
  ///
  /// In en, this message translates to:
  /// **'Never share your private key with anyone.'**
  String get identityNeverShare;

  /// Section label for public key in keys sheet
  ///
  /// In en, this message translates to:
  /// **'Public Key (npub)'**
  String get identityPublicKey;

  /// Snackbar after copying public key from keys sheet
  ///
  /// In en, this message translates to:
  /// **'Public key copied'**
  String get identityPublicKeyCopied;

  /// Section label for private key in keys sheet
  ///
  /// In en, this message translates to:
  /// **'Private Key (nsec)'**
  String get identityPrivateKey;

  /// Button to reveal nsec in keys sheet
  ///
  /// In en, this message translates to:
  /// **'Reveal Private Key'**
  String get identityRevealPrivateKey;

  /// Warning label inside revealed nsec box
  ///
  /// In en, this message translates to:
  /// **'Never share this key'**
  String get identityNeverShareKey;

  /// Inline copy prompt for nsec
  ///
  /// In en, this message translates to:
  /// **'Tap to copy'**
  String get identityTapToCopy;

  /// Hide nsec inline button
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get identityHide;

  /// Snackbar after copying nsec from keys sheet
  ///
  /// In en, this message translates to:
  /// **'Private key copied — keep it safe!'**
  String get identityPrivateKeyCopied;

  /// Relays bottom sheet title
  ///
  /// In en, this message translates to:
  /// **'Relays'**
  String get identityRelaysSheetTitle;

  /// Relays sheet subtitle
  ///
  /// In en, this message translates to:
  /// **'Nostr relays your client connects to.'**
  String get identityRelaysSubtitle;

  /// Info note in relays sheet
  ///
  /// In en, this message translates to:
  /// **'Custom relay management coming soon.'**
  String get identityRelaysComingSoon;

  /// Toggle label for DM notifications
  ///
  /// In en, this message translates to:
  /// **'DM Alerts'**
  String get alertsDmAlerts;

  /// Toggle label for group notifications
  ///
  /// In en, this message translates to:
  /// **'Group Alerts'**
  String get alertsGroupAlerts;

  /// Storage card section heading
  ///
  /// In en, this message translates to:
  /// **'Storage Usage'**
  String get storageUsage;

  /// Storage bar chart row — notes stored in local DB
  ///
  /// In en, this message translates to:
  /// **'Note Data'**
  String get storageNoteData;

  /// Storage bar chart row — downloaded AI model files
  ///
  /// In en, this message translates to:
  /// **'AI Models'**
  String get storageAiModels;

  /// Subtitle for AI models storage row
  ///
  /// In en, this message translates to:
  /// **'Downloaded model files'**
  String get storageAiModelsSubtitle;

  /// Storage total row label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get storageTotal;

  /// Note count label
  ///
  /// In en, this message translates to:
  /// **'{count} notes'**
  String storageNotes(int count);

  /// Storage card button — opens removal dialog
  ///
  /// In en, this message translates to:
  /// **'Remove Data'**
  String get storageRemoveData;

  /// Settings → Storage row that opens the storage-breakdown bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Show metrics'**
  String get storageShowMetrics;

  /// Header label above the total used figure in the storage metrics sheet.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get storageUsed;

  /// Free-disk label in the storage metrics sheet.
  ///
  /// In en, this message translates to:
  /// **'{size} free'**
  String storageFree(String size);

  /// Title of the delete feed notes confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Feed Notes'**
  String get storageDeleteDialogTitle;

  /// Body of the delete feed notes dialog
  ///
  /// In en, this message translates to:
  /// **'This will delete {count} feed notes from local storage.\n\nYour own notes, saved notes, and followed notes will NOT be affected.'**
  String storageDeleteDialogBody(int count);

  /// Confirm button in delete dialog
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get storageDeleteConfirm;

  /// Snackbar shown after successful deletion
  ///
  /// In en, this message translates to:
  /// **'Deleted {count} notes'**
  String storageDeleteSuccess(int count);

  /// Shown when there are 0 deletable notes
  ///
  /// In en, this message translates to:
  /// **'No feed notes to delete'**
  String get storageNothingToDelete;

  /// Legend label for chat history storage
  ///
  /// In en, this message translates to:
  /// **'Chat History'**
  String get storageChatHistory;

  /// Legend label for miscellaneous app files (caches, config, assets)
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get storageOther;

  /// Bottom sheet option to delete feed notes
  ///
  /// In en, this message translates to:
  /// **'Delete Feed Notes'**
  String get storageDeleteFeedNotes;

  /// Subtitle for delete feed notes option
  ///
  /// In en, this message translates to:
  /// **'{count} feed notes · your own, saved, and followed notes are not affected'**
  String storageDeleteFeedNotesSubtitle(int count);

  /// Bottom sheet option to delete chat history
  ///
  /// In en, this message translates to:
  /// **'Delete Chat History'**
  String get storageDeleteChatHistory;

  /// Subtitle for delete chat history option
  ///
  /// In en, this message translates to:
  /// **'All Shiv conversations and messages'**
  String get storageDeleteChatHistorySubtitle;

  /// Snackbar shown after deleting chat history
  ///
  /// In en, this message translates to:
  /// **'Chat history deleted'**
  String get storageDeleteChatHistorySuccess;

  /// Confirmation dialog body for chat history deletion
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all Shiv conversations and messages. This cannot be undone.'**
  String get storageDeleteChatHistoryDialogBody;

  /// Style card row — theme
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get styleTheme;

  /// Light theme option label
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get styleThemeLight;

  /// Dark theme option label
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get styleThemeDark;

  /// System default theme option label
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get styleThemeSystem;

  /// Style card row — accent color
  ///
  /// In en, this message translates to:
  /// **'Accent'**
  String get styleAccent;

  /// AI card row — model selector
  ///
  /// In en, this message translates to:
  /// **'Select Model'**
  String get aiSelectModel;

  /// Settings → AI · Shiv row label for the on-device (local) model selector.
  ///
  /// In en, this message translates to:
  /// **'Device AI model'**
  String get settingsDeviceAiModel;

  /// Subtitle in AI card when no model is active
  ///
  /// In en, this message translates to:
  /// **'No model downloaded'**
  String get aiModelNoneSelected;

  /// AI card destructive action
  ///
  /// In en, this message translates to:
  /// **'Clear AI Cache'**
  String get aiClearCache;

  /// App bar title on the model selection screen
  ///
  /// In en, this message translates to:
  /// **'AI Model Selection'**
  String get aiModelSelectionTitle;

  /// Subtitle under available models header
  ///
  /// In en, this message translates to:
  /// **'Choose the intelligence level that fits your device\'s capabilities.'**
  String get aiModelSelectionSubtitle;

  /// Section header on model selection screen
  ///
  /// In en, this message translates to:
  /// **'Available Models'**
  String get aiModelAvailableHeader;

  /// Cloud option card title on model selection screen
  ///
  /// In en, this message translates to:
  /// **'UNIUN Cloud'**
  String get aiModelCloudTitle;

  /// Cloud option card subtitle on model selection screen
  ///
  /// In en, this message translates to:
  /// **'No download needed — Shiv runs on UNIUN\'s servers with your identity.'**
  String get aiModelCloudSubtitle;

  /// Badge chip on the cloud option card
  ///
  /// In en, this message translates to:
  /// **'No download'**
  String get aiModelCloudBadge;

  /// Badge shown on the recommended model card
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get aiModelRecommendedBadge;

  /// Primary CTA button on model selection screen
  ///
  /// In en, this message translates to:
  /// **'Use This Model'**
  String get aiModelUseThisButton;

  /// Info banner text on model selection screen
  ///
  /// In en, this message translates to:
  /// **'Switching models requires a one-time download. Connect to Wi-Fi to avoid data charges. Your chat history is preserved.'**
  String get aiModelDownloadInfoText;

  /// Banner shown when flutter_gemma reports leftover/orphaned model files on disk
  ///
  /// In en, this message translates to:
  /// **'{size} of leftover model files can be cleaned up.'**
  String aiModelOrphanedFilesText(String size);

  /// Button to delete leftover/orphaned model files
  ///
  /// In en, this message translates to:
  /// **'Clean up'**
  String get aiModelCleanUpAction;

  /// Snackbar shown after successfully cleaning up leftover model files
  ///
  /// In en, this message translates to:
  /// **'Cleaned up {count, plural, =1{1 file} other{{count} files}}.'**
  String aiModelCleanUpSuccess(int count);

  /// Snackbar shown when cleaning up leftover model files fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t clean up leftover files.'**
  String get aiModelCleanUpFailed;

  /// Capability chip — CPU optimized model
  ///
  /// In en, this message translates to:
  /// **'Optimized for CPU'**
  String get aiModelOptimizedCpu;

  /// Capability chip — GPU+CPU model
  ///
  /// In en, this message translates to:
  /// **'Optimized for GPU / CPU'**
  String get aiModelOptimizedGpuCpu;

  /// Capability chip — GPU-only model
  ///
  /// In en, this message translates to:
  /// **'Optimized for GPU'**
  String get aiModelOptimizedGpu;

  /// Download progress label shown in footer while downloading
  ///
  /// In en, this message translates to:
  /// **'Downloading… {percent}%'**
  String aiModelDownloadingProgress(int percent);

  /// Badge shown on already-downloaded active model card
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get aiModelAlreadyActive;

  /// Badge shown on downloaded but inactive model card
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get aiModelDownloaded;

  /// Footer button when selected model is downloaded but not active
  ///
  /// In en, this message translates to:
  /// **'Set as Active'**
  String get aiModelSetActive;

  /// Snackbar when model download fails
  ///
  /// In en, this message translates to:
  /// **'Download failed. Please try again.'**
  String get aiModelDownloadError;

  /// Display name for Qwen3 0.6B model
  ///
  /// In en, this message translates to:
  /// **'Qwen3 0.6B'**
  String get aiModelQwen25Name;

  /// Description for Qwen3 0.6B model
  ///
  /// In en, this message translates to:
  /// **'Compact multilingual chat with function calling. Works on any device with 3 GB+ RAM.'**
  String get aiModelQwen25Desc;

  /// Display name for DeepSeek R1 model
  ///
  /// In en, this message translates to:
  /// **'DeepSeek R1'**
  String get aiModelDeepSeekR1Name;

  /// Description for DeepSeek R1 model
  ///
  /// In en, this message translates to:
  /// **'High-performance reasoning and code generation. Requires 4 GB+ RAM.'**
  String get aiModelDeepSeekR1Desc;

  /// Display name for Gemma 4 E2B model
  ///
  /// In en, this message translates to:
  /// **'Gemma 4 E2B'**
  String get aiModelGemma4E2bName;

  /// Description for Gemma 4 E2B model
  ///
  /// In en, this message translates to:
  /// **'Next-gen multimodal chat — text, image, audio. Requires 6 GB+ RAM.'**
  String get aiModelGemma4E2bDesc;

  /// Display name for Gemma 4 E4B model
  ///
  /// In en, this message translates to:
  /// **'Gemma 4 E4B'**
  String get aiModelGemma4E4bName;

  /// Description for Gemma 4 E4B model
  ///
  /// In en, this message translates to:
  /// **'Next-gen multimodal chat — text, image, audio. Best on flagship devices with 8 GB+ RAM.'**
  String get aiModelGemma4E4bDesc;

  /// Progress label shown while the embedding model is downloading after first LLM install
  ///
  /// In en, this message translates to:
  /// **'Setting up AI features…'**
  String get aiEmbeddingSetupInProgress;

  /// Edit profile screen app-bar title
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// Snackbar after saving profile
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get editProfileSaved;

  /// Field label — display name
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get editProfileDisplayName;

  /// Field label — username
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get editProfileUsername;

  /// Field label — about / bio
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get editProfileAbout;

  /// Field label — avatar URL
  ///
  /// In en, this message translates to:
  /// **'Avatar URL'**
  String get editProfileAvatarUrl;

  /// Field label — NIP-05
  ///
  /// In en, this message translates to:
  /// **'NIP-05 Identifier'**
  String get editProfileNip05;

  /// Hint for display name field
  ///
  /// In en, this message translates to:
  /// **'e.g. Satoshi'**
  String get editProfileDisplayNameHint;

  /// Hint for username field
  ///
  /// In en, this message translates to:
  /// **'e.g. satoshi'**
  String get editProfileUsernameHint;

  /// Hint for about field
  ///
  /// In en, this message translates to:
  /// **'Tell the world who you are…'**
  String get editProfileAboutHint;

  /// Hint for avatar URL field
  ///
  /// In en, this message translates to:
  /// **'https://…'**
  String get editProfileAvatarUrlHint;

  /// Hint for NIP-05 field
  ///
  /// In en, this message translates to:
  /// **'you@yourdomain.com'**
  String get editProfileNip05Hint;

  /// Save profile button
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get editProfileSaveButton;

  /// Uppercase eyebrow label above the edit-profile headline
  ///
  /// In en, this message translates to:
  /// **'Public profile'**
  String get editProfileEyebrow;

  /// Body subtitle on the edit-profile screen
  ///
  /// In en, this message translates to:
  /// **'Update how others see you across UNIUN.'**
  String get editProfileSubtitle;

  /// Privacy reassurance chip on the edit-profile screen
  ///
  /// In en, this message translates to:
  /// **'Only your public details are shared.'**
  String get editProfileEncrypted;

  /// Hero tagline on welcome screen. Words wrapped in *asterisks* are rendered in the brand accent color; everything else is muted.
  ///
  /// In en, this message translates to:
  /// **'*Create* · *Share*\n*Reflect* · *Transform*'**
  String get welcomeTagline;

  /// Primary CTA on welcome screen — generate a new Nostr keypair (a new avatar/incarnation in the network)
  ///
  /// In en, this message translates to:
  /// **'Create Your Avatar'**
  String get welcomeCreateIdentity;

  /// Secondary CTA on welcome screen — import an existing nsec key (restore the same avatar onto this device)
  ///
  /// In en, this message translates to:
  /// **'Restore Your Avatar'**
  String get welcomeImportKey;

  /// Learn more link on welcome screen
  ///
  /// In en, this message translates to:
  /// **'Learn how UNIUN works'**
  String get welcomeLearnHow;

  /// Muted lead-in of the welcome subtitle, immediately followed by welcomeSubtitleEmphasis. Trailing space is intentional.
  ///
  /// In en, this message translates to:
  /// **'Your decentralized '**
  String get welcomeSubtitleLead;

  /// Emphasized (bold, brand-blue) tail of the welcome subtitle, follows welcomeSubtitleLead.
  ///
  /// In en, this message translates to:
  /// **'second brain'**
  String get welcomeSubtitleEmphasis;

  /// First Trimurti pillar name on the welcome screen (the create surface).
  ///
  /// In en, this message translates to:
  /// **'Brahma'**
  String get welcomePillarBrahma;

  /// Second Trimurti pillar name on the welcome screen (the reflect/feed surface).
  ///
  /// In en, this message translates to:
  /// **'Vishnu'**
  String get welcomePillarVishnu;

  /// Third Trimurti pillar name on the welcome screen (the transform/AI surface).
  ///
  /// In en, this message translates to:
  /// **'Shiv'**
  String get welcomePillarShiv;

  /// Role label under the Brahma pillar on the welcome screen.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get welcomeRoleCreate;

  /// Role label under the Vishnu pillar on the welcome screen.
  ///
  /// In en, this message translates to:
  /// **'Reflect'**
  String get welcomeRoleReflect;

  /// Role label under the Shiv pillar on the welcome screen.
  ///
  /// In en, this message translates to:
  /// **'Transform'**
  String get welcomeRoleTransform;

  /// Top-right control that closes the 'how it works' intro carousel and returns to the welcome screen.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get howItWorksSkip;

  /// Bottom button on the intro carousel that advances to the next slide.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get howItWorksNext;

  /// Bottom button on the final intro carousel slide; closes the carousel and returns to the welcome screen.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get howItWorksGetStarted;

  /// Title of the first intro carousel slide introducing UNIUN.
  ///
  /// In en, this message translates to:
  /// **'Your second brain, in your pocket'**
  String get howItWorksIntroTitle;

  /// Body of the first intro carousel slide introducing UNIUN.
  ///
  /// In en, this message translates to:
  /// **'UNIUN is a calm space to capture what you think, connect your ideas, and reflect on them — all in one app that\'s truly yours.'**
  String get howItWorksIntroBody;

  /// Title of the Brahma (create) slide in the intro carousel.
  ///
  /// In en, this message translates to:
  /// **'Brahma — capture & connect'**
  String get howItWorksBrahmaTitle;

  /// Short lead under the Brahma slide title, above the feature sections.
  ///
  /// In en, this message translates to:
  /// **'Your space to capture ideas and shape them into something lasting.'**
  String get howItWorksBrahmaBody;

  /// Title of the Vishnu (feed/social) slide in the intro carousel.
  ///
  /// In en, this message translates to:
  /// **'Vishnu — your people & spaces'**
  String get howItWorksVishnuTitle;

  /// Short lead under the Vishnu slide title, above the feature sections.
  ///
  /// In en, this message translates to:
  /// **'Connect with people and communities, your way.'**
  String get howItWorksVishnuBody;

  /// Title of the Shiv (AI) slide in the intro carousel.
  ///
  /// In en, this message translates to:
  /// **'Shiv — AI on your device'**
  String get howItWorksShivTitle;

  /// Short lead under the Shiv slide title, above the feature sections.
  ///
  /// In en, this message translates to:
  /// **'On-device AI that thinks alongside your notes.'**
  String get howItWorksShivBody;

  /// Feature-section name on the Brahma slide: a single note you write.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get howItWorksTileNote;

  /// Feature-section description on the Brahma slide for Note.
  ///
  /// In en, this message translates to:
  /// **'Write text, images and links'**
  String get howItWorksDescNote;

  /// Feature-section name on the Brahma slide: a Manas (personal note collection).
  ///
  /// In en, this message translates to:
  /// **'Manas'**
  String get howItWorksTileManas;

  /// Feature-section description on the Brahma slide for Manas.
  ///
  /// In en, this message translates to:
  /// **'Group notes into your own collections'**
  String get howItWorksDescManas;

  /// Feature-section name on the Brahma slide: the knowledge graph of linked notes.
  ///
  /// In en, this message translates to:
  /// **'Graph'**
  String get howItWorksTileGraph;

  /// Feature-section description on the Brahma slide for Graph.
  ///
  /// In en, this message translates to:
  /// **'Linked notes become your knowledge graph'**
  String get howItWorksDescGraph;

  /// Feature-section name on the Vishnu slide: people you follow.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get howItWorksTilePeople;

  /// Feature-section description on the Vishnu slide for People.
  ///
  /// In en, this message translates to:
  /// **'Follow people to shape your feed'**
  String get howItWorksDescPeople;

  /// Feature-section name on the Vishnu slide: public groups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get howItWorksTileGroups;

  /// Feature-section description on the Vishnu slide for Groups.
  ///
  /// In en, this message translates to:
  /// **'Public rooms to gather around topics'**
  String get howItWorksDescGroups;

  /// Feature-section name on the Vishnu slide: private encrypted groups.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get howItWorksTilePrivate;

  /// Feature-section description on the Vishnu slide for Private groups.
  ///
  /// In en, this message translates to:
  /// **'Encrypted, invite-only groups'**
  String get howItWorksDescPrivate;

  /// Feature-section name on the Vishnu slide: direct messages.
  ///
  /// In en, this message translates to:
  /// **'Direct messages'**
  String get howItWorksTileDms;

  /// Feature-section description on the Vishnu slide for Direct messages.
  ///
  /// In en, this message translates to:
  /// **'Private one-to-one chats'**
  String get howItWorksDescDms;

  /// Feature-section name on the Shiv slide: Adiyogi, the chat assistant.
  ///
  /// In en, this message translates to:
  /// **'Adiyogi'**
  String get howItWorksTileAdiyogi;

  /// Feature-section description on the Shiv slide for Adiyogi.
  ///
  /// In en, this message translates to:
  /// **'Ask anything about your notes'**
  String get howItWorksDescAdiyogi;

  /// Feature-section name on the Shiv slide: Nataraj, the idea-synthesis deck.
  ///
  /// In en, this message translates to:
  /// **'Nataraj'**
  String get howItWorksTileNataraj;

  /// Feature-section description on the Shiv slide for Nataraj.
  ///
  /// In en, this message translates to:
  /// **'Swipe to turn notes into fresh ideas'**
  String get howItWorksDescNataraj;

  /// Feature-section name on the Shiv slide: Gana, the autonomous agents.
  ///
  /// In en, this message translates to:
  /// **'Gana'**
  String get howItWorksTileGana;

  /// Feature-section description on the Shiv slide for Gana.
  ///
  /// In en, this message translates to:
  /// **'Agents that work in the background'**
  String get howItWorksDescGana;

  /// Title of the intro carousel slide about owning your identity via a private key.
  ///
  /// In en, this message translates to:
  /// **'You own your identity'**
  String get howItWorksKeysTitle;

  /// Body of the intro carousel slide about owning your identity via a private key.
  ///
  /// In en, this message translates to:
  /// **'No email, no password, no account. UNIUN gives you a private key that lives only on your device — it is your identity, and only you hold it.'**
  String get howItWorksKeysBody;

  /// Title of the intro carousel slide about offline-first, on-device privacy.
  ///
  /// In en, this message translates to:
  /// **'Private and always yours'**
  String get howItWorksPrivateTitle;

  /// Body of the intro carousel slide about offline-first, on-device privacy.
  ///
  /// In en, this message translates to:
  /// **'UNIUN works offline and its AI runs right on your device — nothing goes to the cloud. Your notes stay with you, and they\'re yours to keep.'**
  String get howItWorksPrivateBody;

  /// Title of the final intro carousel slide inviting the user to start.
  ///
  /// In en, this message translates to:
  /// **'Ready to begin?'**
  String get howItWorksReadyTitle;

  /// Body of the final intro carousel slide inviting the user to start.
  ///
  /// In en, this message translates to:
  /// **'Create your avatar and start building your second brain. It only takes a moment.'**
  String get howItWorksReadyBody;

  /// Uppercase eyebrow label above the headline on the about-you onboarding page
  ///
  /// In en, this message translates to:
  /// **'Create your avatar'**
  String get aboutYouEyebrow;

  /// Heading on the about-you onboarding page
  ///
  /// In en, this message translates to:
  /// **'About You'**
  String get aboutYouTitle;

  /// Body subtitle on about-you page
  ///
  /// In en, this message translates to:
  /// **'Set up your avatar. Display Name and Username are required.'**
  String get aboutYouSubtitle;

  /// Caption under the avatar on about-you page
  ///
  /// In en, this message translates to:
  /// **'Auto-generated'**
  String get aboutYouAvatarCaption;

  /// Field label for display name on about-you page
  ///
  /// In en, this message translates to:
  /// **'Display Name *'**
  String get aboutYouDisplayNameLabel;

  /// Hint for display name on about-you page
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get aboutYouDisplayNameHint;

  /// Field label for username on about-you page
  ///
  /// In en, this message translates to:
  /// **'Username *'**
  String get aboutYouUsernameLabel;

  /// Hint for username on about-you page
  ///
  /// In en, this message translates to:
  /// **'username'**
  String get aboutYouUsernameHint;

  /// Helper text under username on about-you page
  ///
  /// In en, this message translates to:
  /// **'Unique handle for mentions and search.'**
  String get aboutYouUsernameHelper;

  /// Field label for bio on about-you page
  ///
  /// In en, this message translates to:
  /// **'Bio  (optional)'**
  String get aboutYouBioLabel;

  /// Hint for bio on about-you page
  ///
  /// In en, this message translates to:
  /// **'Tell the world a bit about yourself…'**
  String get aboutYouBioHint;

  /// Privacy reassurance chip on about-you page
  ///
  /// In en, this message translates to:
  /// **'Your data is encrypted and private.'**
  String get aboutYouEncrypted;

  /// Validation error for display name
  ///
  /// In en, this message translates to:
  /// **'Display name is required'**
  String get aboutYouDisplayNameRequired;

  /// Validation error for username
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get aboutYouUsernameRequired;

  /// Heading on the import-identity page
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get importTitle;

  /// Body subtitle on the import-identity page
  ///
  /// In en, this message translates to:
  /// **'Paste your private key to restore your existing avatar.'**
  String get importSubtitle;

  /// Field section label on import page
  ///
  /// In en, this message translates to:
  /// **'PRIVATE KEY'**
  String get importPrivateKeyLabel;

  /// Paste action on import page
  ///
  /// In en, this message translates to:
  /// **'Paste from Clipboard'**
  String get importPasteFromClipboard;

  /// Hint for key input on import page
  ///
  /// In en, this message translates to:
  /// **'nsec1... or 64-character hex key'**
  String get importKeyHint;

  /// Security reassurance note on import page
  ///
  /// In en, this message translates to:
  /// **'Your private key is processed locally and never sent to any server.'**
  String get importSecurityNote;

  /// Submit button on import page
  ///
  /// In en, this message translates to:
  /// **'Import & Continue'**
  String get importContinue;

  /// Validation error when field is empty on import page
  ///
  /// In en, this message translates to:
  /// **'Please paste your private key first.'**
  String get importPasteFirst;

  /// Error snackbar on import page
  ///
  /// In en, this message translates to:
  /// **'Failed to import key. Please try again.'**
  String get importFailed;

  /// Error snackbar for unrecognised key format
  ///
  /// In en, this message translates to:
  /// **'Invalid key. Please check and try again.'**
  String get importInvalidKey;

  /// Uppercase eyebrow above the import-page title
  ///
  /// In en, this message translates to:
  /// **'Restore your avatar'**
  String get importEyebrow;

  /// Secondary action on import page to scan a key QR
  ///
  /// In en, this message translates to:
  /// **'Scan a QR instead'**
  String get importScanQrButton;

  /// App bar title on the key QR scanner page
  ///
  /// In en, this message translates to:
  /// **'Scan your key QR'**
  String get importScanTitle;

  /// Helper text on the key QR scanner page
  ///
  /// In en, this message translates to:
  /// **'Point your camera at a QR that contains your private key'**
  String get importScanHint;

  /// Heading on the identity-keys onboarding page
  ///
  /// In en, this message translates to:
  /// **'Your Avatar Keys'**
  String get keysTitle;

  /// Subtitle on the identity-keys onboarding page
  ///
  /// In en, this message translates to:
  /// **'One is for sharing. One is for your eyes only.'**
  String get keysSubtitle;

  /// Uppercase eyebrow label above the headline on the identity-keys onboarding page
  ///
  /// In en, this message translates to:
  /// **'Your avatar keys'**
  String get keysEyebrow;

  /// Serif display headline on the identity-keys onboarding page
  ///
  /// In en, this message translates to:
  /// **'Your keys are your avatar.'**
  String get keysHeadline;

  /// KeyCard title for npub
  ///
  /// In en, this message translates to:
  /// **'Public Key'**
  String get keysPublicKeyTitle;

  /// KeyCard subtitle for npub
  ///
  /// In en, this message translates to:
  /// **'Share with others to receive messages.'**
  String get keysPublicKeySubtitle;

  /// KeyCard title for nsec
  ///
  /// In en, this message translates to:
  /// **'Private Key'**
  String get keysPrivateKeyTitle;

  /// KeyCard subtitle for nsec
  ///
  /// In en, this message translates to:
  /// **'Never share this. Total access to your identity.'**
  String get keysPrivateKeySubtitle;

  /// KeyCard warning for nsec
  ///
  /// In en, this message translates to:
  /// **'Lose this key = lose your account forever.'**
  String get keysPrivateKeyWarning;

  /// CTA button on identity-keys page
  ///
  /// In en, this message translates to:
  /// **'Save & Continue'**
  String get keysSaveAndContinue;

  /// Badge on identity-keys page footer
  ///
  /// In en, this message translates to:
  /// **'E2E ENCRYPTED'**
  String get keysE2eEncrypted;

  /// Leading text of the terms-acceptance checkbox on identity-keys page
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get keysAgreePrefix;

  /// Tappable Terms & Conditions link in the acceptance checkbox
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get keysAgreeTerms;

  /// Conjunction between the two links in the acceptance checkbox
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get keysAgreeConjunction;

  /// Tappable Privacy Policy link in the acceptance checkbox
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get keysAgreePrivacy;

  /// Snackbar after copying npub on identity-keys page
  ///
  /// In en, this message translates to:
  /// **'Public key copied — now reveal your private key'**
  String get keysPublicCopied;

  /// Snackbar after copying nsec on identity-keys page
  ///
  /// In en, this message translates to:
  /// **'Private key copied — store it somewhere safe!'**
  String get keysPrivateCopied;

  /// Error snackbar when key save fails
  ///
  /// In en, this message translates to:
  /// **'Failed to save keys: {error}'**
  String keysFailedToSave(String error);

  /// Hint shown in place of private key card until npub is copied
  ///
  /// In en, this message translates to:
  /// **'Copy your public key above to reveal your private key.'**
  String get keysCopyPublicAbove;

  /// App-bar title for privacy policy page
  ///
  /// In en, this message translates to:
  /// **'Privacy & Policy'**
  String get privacyPageTitle;

  /// Section heading inside privacy policy page
  ///
  /// In en, this message translates to:
  /// **'Privacy & Policy'**
  String get privacyIntroTitle;

  /// Intro paragraph on privacy policy page
  ///
  /// In en, this message translates to:
  /// **'UNIUN is built on transparency. Your data stays on your device. Below is everything you need to know — no legal jargon.'**
  String get privacyIntroBody;

  /// Expandable section title — privacy policy
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyExpandPrivacy;

  /// Expandable section title — terms of use
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get privacyExpandTerms;

  /// Footer date on privacy policy page
  ///
  /// In en, this message translates to:
  /// **'Last updated: June 2026'**
  String get privacyLastUpdated;

  /// Contact email shown on privacy policy page
  ///
  /// In en, this message translates to:
  /// **'info@uniun.in'**
  String get privacyContactEmail;

  /// No description provided for @privacyStoredLocallyTitle.
  ///
  /// In en, this message translates to:
  /// **'What We Store Locally'**
  String get privacyStoredLocallyTitle;

  /// No description provided for @privacyStoredLocallyBody.
  ///
  /// In en, this message translates to:
  /// **'UNIUN stores your notes, profile, saved items, group messages, and settings directly on your device. This data is not sent to any server controlled by UNIUN.'**
  String get privacyStoredLocallyBody;

  /// No description provided for @privacySharedPubliclyTitle.
  ///
  /// In en, this message translates to:
  /// **'What Gets Shared Publicly'**
  String get privacySharedPubliclyTitle;

  /// No description provided for @privacySharedPubliclyBody.
  ///
  /// In en, this message translates to:
  /// **'When you publish a note or send a message in a public group, that content is broadcast to Nostr relays. Nostr is an open public protocol — once published, your notes may be visible to anyone connected to those relays. UNIUN does not control third-party relays.'**
  String get privacySharedPubliclyBody;

  /// No description provided for @privacyIdentityKeysTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Identity & Keys'**
  String get privacyIdentityKeysTitle;

  /// No description provided for @privacyIdentityKeysBody.
  ///
  /// In en, this message translates to:
  /// **'Your identity is a cryptographic key pair. Your public key is visible to others on the Nostr network. Your private key (nsec) is stored exclusively in your device\'s secure system keychain (iOS Keychain / Android Keystore). UNIUN never transmits your private key to any server.'**
  String get privacyIdentityKeysBody;

  /// No description provided for @privacyLocalAiTitle.
  ///
  /// In en, this message translates to:
  /// **'Local AI (Shiv)'**
  String get privacyLocalAiTitle;

  /// No description provided for @privacyLocalAiBody.
  ///
  /// In en, this message translates to:
  /// **'The Shiv AI assistant runs entirely on your device. It accesses only your locally saved notes. No note content is sent to any external AI service or API.'**
  String get privacyLocalAiBody;

  /// No description provided for @privacyMediaTitle.
  ///
  /// In en, this message translates to:
  /// **'Media & Blossom Servers'**
  String get privacyMediaTitle;

  /// No description provided for @privacyMediaBody.
  ///
  /// In en, this message translates to:
  /// **'If you attach images or media, they may be uploaded to a Blossom content server of your choice. UNIUN does not operate Blossom servers. Content uploaded there may be publicly accessible by design of the protocol.'**
  String get privacyMediaBody;

  /// No description provided for @privacyDmsTitle.
  ///
  /// In en, this message translates to:
  /// **'Direct Messages'**
  String get privacyDmsTitle;

  /// No description provided for @privacyDmsBody.
  ///
  /// In en, this message translates to:
  /// **'DMs are end-to-end encrypted using the Nostr NIP-17 standard. Only the intended recipient can read the message content. Message routing metadata may be visible to relays.'**
  String get privacyDmsBody;

  /// No description provided for @privacyControlTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Control'**
  String get privacyControlTitle;

  /// No description provided for @privacyControlBody.
  ///
  /// In en, this message translates to:
  /// **'You can delete your local data at any time from Settings. Because Nostr is a public protocol, notes already published to relays cannot be retracted — this is an intentional property of the network, not a limitation of the app.'**
  String get privacyControlBody;

  /// No description provided for @privacyContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get privacyContactTitle;

  /// No description provided for @privacyContactBody.
  ///
  /// In en, this message translates to:
  /// **'For privacy questions: info@uniun.in'**
  String get privacyContactBody;

  /// No description provided for @termsResponsibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Responsibility'**
  String get termsResponsibilityTitle;

  /// No description provided for @termsResponsibilityBody.
  ///
  /// In en, this message translates to:
  /// **'You are solely responsible for all content you publish on UNIUN. By using the app, you agree not to post content that is illegal, abusive, harassing, hateful, sexually explicit, or that violates others\' rights. Objectionable content and abusive behavior are not welcome on UNIUN.'**
  String get termsResponsibilityBody;

  /// No description provided for @termsNoAbuseTitle.
  ///
  /// In en, this message translates to:
  /// **'No Abuse or Spam'**
  String get termsNoAbuseTitle;

  /// No description provided for @termsNoAbuseBody.
  ///
  /// In en, this message translates to:
  /// **'Do not use UNIUN to spam, harass, impersonate others, or conduct automated activity that disrupts the Nostr network. UNIUN is decentralized: any note menu includes a Report option (categories: nudity, malware, profanity, illegal, spam, impersonation, other) and any user can be blocked from Settings → Blocked Users. Reported notes are immediately hidden from your feed and blocked users\' content never reaches you. Reports are also published on the Nostr network so other clients and relay operators can act on them.'**
  String get termsNoAbuseBody;

  /// No description provided for @termsPrivateKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep Your Private Key Safe'**
  String get termsPrivateKeyTitle;

  /// No description provided for @termsPrivateKeyBody.
  ///
  /// In en, this message translates to:
  /// **'Your private key (nsec) is your identity and login. If you lose it, your account cannot be recovered — UNIUN has no way to reset or recover private keys. Back it up in a secure location.'**
  String get termsPrivateKeyBody;

  /// No description provided for @termsPublicContentTitle.
  ///
  /// In en, this message translates to:
  /// **'Public Content on Relays'**
  String get termsPublicContentTitle;

  /// No description provided for @termsPublicContentBody.
  ///
  /// In en, this message translates to:
  /// **'Notes and group messages you publish are sent to Nostr relays and may be visible to anyone on the network. Do not share sensitive personal information in public notes.'**
  String get termsPublicContentBody;

  /// No description provided for @termsAppMayChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'App May Change'**
  String get termsAppMayChangeTitle;

  /// No description provided for @termsAppMayChangeBody.
  ///
  /// In en, this message translates to:
  /// **'UNIUN is in active development. Features, relay behavior, and policies may change over time. We will communicate significant updates within the app.'**
  String get termsAppMayChangeBody;

  /// No description provided for @termsNoWarrantyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Warranty'**
  String get termsNoWarrantyTitle;

  /// No description provided for @termsNoWarrantyBody.
  ///
  /// In en, this message translates to:
  /// **'UNIUN is provided as-is. We make no guarantees about relay uptime, third-party server availability, or persistence of content on external relays.'**
  String get termsNoWarrantyBody;

  /// Shiv AI assistant name label (uppercase)
  ///
  /// In en, this message translates to:
  /// **'SHIV'**
  String get shivName;

  /// Shiv landing header tagline
  ///
  /// In en, this message translates to:
  /// **'Think in threads'**
  String get shivTagline;

  /// Shiv landing screen body subtitle
  ///
  /// In en, this message translates to:
  /// **'Your on-device AI.\nThink in threads.'**
  String get shivLandingBody;

  /// Shiv no-model placeholder body text
  ///
  /// In en, this message translates to:
  /// **'Download an AI model to start chatting with Shiv. Everything runs on your device — no internet needed after setup.'**
  String get shivNoModelBody;

  /// Button to open AI model selection
  ///
  /// In en, this message translates to:
  /// **'Set up AI'**
  String get shivSetUpAi;

  /// Button label to create a new Shiv conversation
  ///
  /// In en, this message translates to:
  /// **'New Conversation'**
  String get shivNewConversation;

  /// Link to view existing conversations on Shiv landing
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{View 1 conversation} other{View {count} conversations}}'**
  String shivViewConversations(int count);

  /// Title of the conversations history sheet
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get shivConversations;

  /// Tooltip on new conversation icon button
  ///
  /// In en, this message translates to:
  /// **'New conversation'**
  String get shivNewConversationTooltip;

  /// Tooltip on the history icon in chat header
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get shivConversationsTooltip;

  /// Tooltip on the branch tree icon in chat header
  ///
  /// In en, this message translates to:
  /// **'Branch tree'**
  String get shivBranchTreeTooltip;

  /// Snackbar shown when tapping the branch tree button
  ///
  /// In en, this message translates to:
  /// **'Branch tree — coming in Phase 4'**
  String get shivBranchTreeComingSoon;

  /// Title of the branch tree page
  ///
  /// In en, this message translates to:
  /// **'Conversation Tree'**
  String get shivConversationTree;

  /// Button to open the selected branch in chat
  ///
  /// In en, this message translates to:
  /// **'Open Branch'**
  String get shivNodeOpenBranch;

  /// Button to set selected node as active branch point
  ///
  /// In en, this message translates to:
  /// **'Continue From Here'**
  String get shivNodeContinueFromHere;

  /// Button to fork a new branch from selected node
  ///
  /// In en, this message translates to:
  /// **'New Branch'**
  String get shivNodeNewBranch;

  /// Badge label on the active branch node panel
  ///
  /// In en, this message translates to:
  /// **'Active Branch'**
  String get shivActiveBranch;

  /// Message count shown in node panel
  ///
  /// In en, this message translates to:
  /// **'{count} msgs'**
  String shivNodeMessages(int count);

  /// Default title for a newly created conversation
  ///
  /// In en, this message translates to:
  /// **'New conversation'**
  String get shivDefaultConversationTitle;

  /// Empty chat state heading
  ///
  /// In en, this message translates to:
  /// **'Start a conversation'**
  String get shivEmptyTitle;

  /// Empty chat state body text
  ///
  /// In en, this message translates to:
  /// **'Ask Shiv anything — your saved notes\ngive it context about what you know.'**
  String get shivEmptyBody;

  /// Tree view empty state heading
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get shivEmptyTreeTitle;

  /// Tree view empty state body text
  ///
  /// In en, this message translates to:
  /// **'Start a conversation to see the\nbranch tree here.'**
  String get shivEmptyTreeBody;

  /// Label shown while the model is in a thinking/reasoning block
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get shivThinking;

  /// Collapsed section header for the model's internal thinking
  ///
  /// In en, this message translates to:
  /// **'Reasoning'**
  String get shivThinkingLabel;

  /// Chip below the last Shiv reply that opens the source-notes sheet
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Sources · 1} other{Sources · {count}}}'**
  String shivSourcesChip(int count);

  /// Title of the Shiv RAG source-notes bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get shivSourcesSheetTitle;

  /// Page reference on a PDF source tile in Shiv's Sources sheet, e.g. 'Page 4'
  ///
  /// In en, this message translates to:
  /// **'Page {label}'**
  String shivSourcesDocumentPage(String label);

  /// Title of a PDF source tile when the note that attached the file is no longer on this device
  ///
  /// In en, this message translates to:
  /// **'PDF document'**
  String get shivSourcesDocumentUntitled;

  /// Tooltip on a PDF source tile in Shiv's Sources sheet
  ///
  /// In en, this message translates to:
  /// **'Open PDF'**
  String get shivSourcesDocumentOpen;

  /// Heading reference on a Word (.docx) source tile in Shiv's Sources sheet, e.g. 'Section: Annual Leave'. A Word file has no fixed pages, so it is located by the heading above the passage.
  ///
  /// In en, this message translates to:
  /// **'Section: {label}'**
  String shivSourcesDocumentSection(String label);

  /// Title of a Word (.docx) source tile when the note that attached the file is no longer on this device
  ///
  /// In en, this message translates to:
  /// **'Word document'**
  String get shivSourcesDocxUntitled;

  /// Tooltip on a Word (.docx) source tile in Shiv's Sources sheet
  ///
  /// In en, this message translates to:
  /// **'Open document'**
  String get shivSourcesDocxOpen;

  /// Action in the in-app document viewer that hands the file to the OS viewer, for reading rather than checking a citation
  ///
  /// In en, this message translates to:
  /// **'Open in another app'**
  String get documentViewerOpenExternal;

  /// Shown when a cited document's cached file has been removed since the answer
  ///
  /// In en, this message translates to:
  /// **'This document is no longer on this device'**
  String get documentViewerFileGone;

  /// Shown when the in-app viewer cannot read a cited Word or PDF file
  ///
  /// In en, this message translates to:
  /// **'This document could not be opened here'**
  String get documentViewerReadError;

  /// Note above the in-app view of a Word document, which shows its text, tables and large pictures but not styling or page layout
  ///
  /// In en, this message translates to:
  /// **'Text, tables and large pictures — open in another app for the full layout'**
  String get documentViewerTextOnly;

  /// Location line on an image source tile in Shiv's Sources sheet: the answer drew on the picture — its text (read by OCR) or what it shows (on-device labels)
  ///
  /// In en, this message translates to:
  /// **'Found in image'**
  String get shivSourcesImageFound;

  /// Title of an image source tile when the attaching note gave the image no file name
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get shivSourcesImageUntitled;

  /// Tooltip on an image source tile in Shiv's Sources sheet
  ///
  /// In en, this message translates to:
  /// **'Open image'**
  String get shivSourcesImageOpen;

  /// Shown when the user taps an image source whose cached file was removed since the answer was given
  ///
  /// In en, this message translates to:
  /// **'This image is no longer on this device'**
  String get shivSourcesImageGone;

  /// Empty state when the source notes for a Shiv reply can't be resolved
  ///
  /// In en, this message translates to:
  /// **'No sources for this reply'**
  String get shivSourcesEmpty;

  /// Hint text inside the Shiv chat input field
  ///
  /// In en, this message translates to:
  /// **'Ask Shiv anything…'**
  String get shivInputHint;

  /// Hero headline on the Shiv home landing screen
  ///
  /// In en, this message translates to:
  /// **'How can I help you?'**
  String get shivHomeHeadline;

  /// Tooltip for the history button on the Shiv home app bar
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get shivHomeHistoryTooltip;

  /// Label for the Gana action button on the Shiv home screen
  ///
  /// In en, this message translates to:
  /// **'Gana'**
  String get shivHomeGana;

  /// Label for the Nataraj action button on the Shiv home screen
  ///
  /// In en, this message translates to:
  /// **'Nataraj'**
  String get shivHomeNataraj;

  /// Suggested prompt chip on the Shiv home screen
  ///
  /// In en, this message translates to:
  /// **'Summarize my week'**
  String get shivHomeSuggestSummarize;

  /// Suggested prompt chip on the Shiv home screen
  ///
  /// In en, this message translates to:
  /// **'Connect two ideas'**
  String get shivHomeSuggestConnect;

  /// Suggested prompt chip on the Shiv home screen
  ///
  /// In en, this message translates to:
  /// **'Draft from a note'**
  String get shivHomeSuggestDraft;

  /// Composer-chat input hint reflecting the grounding scope, e.g. 'Ask Brahma' (all notes) or 'Ask <manas name>'
  ///
  /// In en, this message translates to:
  /// **'Ask {scope}'**
  String composerAskScope(String scope);

  /// Empty state in the conversations history sheet
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get shivNoConversations;

  /// Badge on the currently active conversation in history
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get shivActiveLabel;

  /// Relative time: less than 1 minute ago
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get shivTimeJustNow;

  /// Relative time in minutes
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String shivTimeMinutesAgo(int count);

  /// Relative time in hours
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String shivTimeHoursAgo(int count);

  /// Relative time in days
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String shivTimeDaysAgo(int count);

  /// Page title for the saved notes list
  ///
  /// In en, this message translates to:
  /// **'Saved Notes'**
  String get savedNotesTitle;

  /// Placeholder for saved notes search bar
  ///
  /// In en, this message translates to:
  /// **'Search saved notes…'**
  String get savedNotesSearch;

  /// Empty state headline on saved notes page
  ///
  /// In en, this message translates to:
  /// **'Nothing saved yet'**
  String get savedNotesEmpty;

  /// Empty state sub-text on saved notes page
  ///
  /// In en, this message translates to:
  /// **'Bookmark notes from your feed to read them later.'**
  String get savedNotesEmptySub;

  /// Graph legend label for saved notes (blue nodes)
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get graphLegendSaved;

  /// Graph legend label for own published notes (blue-300 nodes)
  ///
  /// In en, this message translates to:
  /// **'Own'**
  String get graphLegendOwn;

  /// Graph legend label for draft notes (blue-800 nodes)
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get graphLegendDraft;

  /// FAB option to create a plain text note from the graph
  ///
  /// In en, this message translates to:
  /// **'Text note'**
  String get graphFabTextNote;

  /// FAB option to create a reference/mention note from the graph
  ///
  /// In en, this message translates to:
  /// **'Reference note'**
  String get graphFabReferenceNote;

  /// Edit action on a draft node panel
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get graphDraftEdit;

  /// Delete action on a draft node panel
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get graphDraftDelete;

  /// Scope chip label when the graph shows the whole library (no Manas scope)
  ///
  /// In en, this message translates to:
  /// **'All notes'**
  String get graphScopeAllNotes;

  /// Placeholder in the graph search field
  ///
  /// In en, this message translates to:
  /// **'Search graph…'**
  String get graphSearchHint;

  /// Tooltip on the graph search icon button
  ///
  /// In en, this message translates to:
  /// **'Search graph'**
  String get graphSearchTooltip;

  /// Tooltip on the graph header menu button
  ///
  /// In en, this message translates to:
  /// **'Open Manas drawer'**
  String get graphMenuTooltip;

  /// Tooltip on the button that closes/clears graph search
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get graphSearchClear;

  /// Position of the focused item in a graph stepper (search matches, node connections), e.g. 2/7. 0 means nothing is focused yet
  ///
  /// In en, this message translates to:
  /// **'{current}/{total}'**
  String graphStepPosition(int current, int total);

  /// Tooltip on the button that moves the graph camera to the previous search match
  ///
  /// In en, this message translates to:
  /// **'Previous match'**
  String get graphSearchPrevMatch;

  /// Tooltip on the button that moves the graph camera to the next search match
  ///
  /// In en, this message translates to:
  /// **'Next match'**
  String get graphSearchNextMatch;

  /// Tooltip on the button that moves the graph camera to the selected node's previous connection
  ///
  /// In en, this message translates to:
  /// **'Previous connection'**
  String get graphPrevConnection;

  /// Tooltip on the button that moves the graph camera to the selected node's next connection
  ///
  /// In en, this message translates to:
  /// **'Next connection'**
  String get graphNextConnection;

  /// Title of the public group entry/chooser screen
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groupEntryTitle;

  /// Subtitle on the public group entry chooser
  ///
  /// In en, this message translates to:
  /// **'Join an existing public group using its ID or QR, or start a new one.'**
  String get groupEntrySubtitle;

  /// Join option on the public group entry chooser
  ///
  /// In en, this message translates to:
  /// **'Join a group'**
  String get groupEntryJoin;

  /// Create option on the public group entry chooser
  ///
  /// In en, this message translates to:
  /// **'Create a group'**
  String get groupEntryCreate;

  /// Title of the private group entry/chooser screen
  ///
  /// In en, this message translates to:
  /// **'Private groups'**
  String get privateGroupEntryTitle;

  /// Subtitle on the private group entry chooser
  ///
  /// In en, this message translates to:
  /// **'Request to join an existing private group, or create your own.'**
  String get privateGroupEntrySubtitle;

  /// Join option on the private group entry chooser
  ///
  /// In en, this message translates to:
  /// **'Join a private group'**
  String get privateGroupEntryJoin;

  /// Create option on the private group entry chooser
  ///
  /// In en, this message translates to:
  /// **'Create a private group'**
  String get privateGroupEntryCreate;

  /// App bar title on the create group page
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get createGroupTitle;

  /// App bar title on the create group page (redesign)
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get createGroupHeaderTitle;

  /// Section heading for group details on create group page
  ///
  /// In en, this message translates to:
  /// **'Group Details'**
  String get createGroupDetailsHeading;

  /// Section label for group name field
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get createGroupNameLabel;

  /// Placeholder in the group name field
  ///
  /// In en, this message translates to:
  /// **'e.g. design'**
  String get createGroupNamePlaceholder;

  /// Text field label for group about/description
  ///
  /// In en, this message translates to:
  /// **'About (Theme/Rules)'**
  String get createGroupAboutLabel;

  /// Section label for the group description field
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get createGroupDescriptionLabel;

  /// Placeholder in the group description field
  ///
  /// In en, this message translates to:
  /// **'What\'s this group about?'**
  String get createGroupAboutPlaceholder;

  /// Text field label for optional group picture url
  ///
  /// In en, this message translates to:
  /// **'Picture URL (Optional)'**
  String get createGroupPictureLabel;

  /// Info note explaining group permanence on create
  ///
  /// In en, this message translates to:
  /// **'The group\'s first event becomes its permanent ID — it can never be deleted.'**
  String get createGroupPermanenceNote;

  /// Collapsible advanced relays section header on create group
  ///
  /// In en, this message translates to:
  /// **'Advanced · relays'**
  String get createGroupAdvancedRelays;

  /// Section heading for publish relays on create group page
  ///
  /// In en, this message translates to:
  /// **'Publish Relays'**
  String get createGroupPublishRelays;

  /// Helper text under publish relays section on create group page
  ///
  /// In en, this message translates to:
  /// **'Select the relays this group should be broadcasted on.'**
  String get createGroupPublishRelaysBody;

  /// Primary create group button label
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get createGroupAction;

  /// Snackbar shown after a group is created
  ///
  /// In en, this message translates to:
  /// **'Group created successfully'**
  String get createGroupSuccess;

  /// App bar title on the create private group page
  ///
  /// In en, this message translates to:
  /// **'Create private group'**
  String get createPrivateGroupTitle;

  /// Eyebrow label above the encrypted private-group form
  ///
  /// In en, this message translates to:
  /// **'Encrypted'**
  String get createPrivateGroupEncrypted;

  /// Placeholder for the private group name field
  ///
  /// In en, this message translates to:
  /// **'e.g. core team'**
  String get createPrivateGroupNameHint;

  /// Placeholder for the private group description field
  ///
  /// In en, this message translates to:
  /// **'What\'s this group about?'**
  String get createPrivateGroupDescHint;

  /// Muted footer note explaining the creator becomes the admin
  ///
  /// In en, this message translates to:
  /// **'You\'re the admin — you control who joins.'**
  String get createPrivateGroupAdminNote;

  /// Heading on the create private group page
  ///
  /// In en, this message translates to:
  /// **'Start a new Private Group'**
  String get createPrivateGroupHeading;

  /// Explanation of how private groups work
  ///
  /// In en, this message translates to:
  /// **'Private groups are end-to-end encrypted. Members must request to join, and admins must approve them.'**
  String get createPrivateGroupDescription;

  /// Text field label for private group name
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get createPrivateGroupNameLabel;

  /// Text field label for private group description
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get createPrivateGroupDescLabel;

  /// Primary create private group button label
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get createPrivateGroupAction;

  /// Snackbar shown after a private group is created
  ///
  /// In en, this message translates to:
  /// **'Private group created successfully!'**
  String get createPrivateGroupSuccess;

  /// App bar title on the new direct message page
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get createDmTitle;

  /// Section label above the DM recipient field
  ///
  /// In en, this message translates to:
  /// **'Send to'**
  String get createDmRecipientLabel;

  /// Placeholder for the DM recipient field
  ///
  /// In en, this message translates to:
  /// **'Paste their UNIUN code, or scan their QR'**
  String get createDmRecipientHint;

  /// Helper text under the DM relays section
  ///
  /// In en, this message translates to:
  /// **'Select the relays this message is sent through.'**
  String get createDmRelaysNote;

  /// Info card explaining DM encryption on the new message page
  ///
  /// In en, this message translates to:
  /// **'Direct messages are end-to-end encrypted. Only the recipient can read them.'**
  String get createDmEncryptedNote;

  /// Secondary button to scan a user QR on the new message page
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get createDmScanQr;

  /// Primary button to start a direct message chat
  ///
  /// In en, this message translates to:
  /// **'Start chat'**
  String get createDmAction;

  /// App bar title on the join private group page
  ///
  /// In en, this message translates to:
  /// **'Join private group'**
  String get joinPrivateGroupTitle;

  /// Eyebrow label signalling the group is end-to-end encrypted
  ///
  /// In en, this message translates to:
  /// **'Encrypted'**
  String get joinPrivateGroupEncrypted;

  /// Heading on the join private group page
  ///
  /// In en, this message translates to:
  /// **'Request to Join'**
  String get joinPrivateGroupHeading;

  /// Helper text under heading on join private group page
  ///
  /// In en, this message translates to:
  /// **'Enter the Group ID to request access to a private group.'**
  String get joinPrivateGroupSubtitle;

  /// Text field label for private group group id
  ///
  /// In en, this message translates to:
  /// **'Group ID'**
  String get joinPrivateGroupGroupIdLabel;

  /// Hint text in the group id input
  ///
  /// In en, this message translates to:
  /// **'Paste group ID…'**
  String get joinPrivateGroupGroupIdHint;

  /// Helper text under the group id input
  ///
  /// In en, this message translates to:
  /// **'Ask the group admin for the group ID.'**
  String get joinPrivateGroupGroupIdHelper;

  /// Secondary button to open the QR scanner
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get joinPrivateGroupScanQr;

  /// Title of the prominent scan-QR card
  ///
  /// In en, this message translates to:
  /// **'Scan a private group QR'**
  String get joinPrivateGroupScanCardTitle;

  /// Subtitle of the prominent scan-QR card
  ///
  /// In en, this message translates to:
  /// **'Point your camera at a code shared by the admin'**
  String get joinPrivateGroupScanCardSubtitle;

  /// Info card explaining admin approval is required
  ///
  /// In en, this message translates to:
  /// **'Your request goes to the admin for approval before you can read messages.'**
  String get joinPrivateGroupApprovalInfo;

  /// Primary submit button on join private group page
  ///
  /// In en, this message translates to:
  /// **'Send join request'**
  String get joinPrivateGroupAction;

  /// Snackbar after submitting a join request to a private group
  ///
  /// In en, this message translates to:
  /// **'Join request sent! Wait for admin approval.'**
  String get joinPrivateGroupSuccess;

  /// Lowercase divider word between two alternative actions
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get commonOr;

  /// Header for a collapsible section hiding advanced/optional settings (e.g. relays)
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get commonAdvanced;

  /// Empty-state label inside the relay selector field
  ///
  /// In en, this message translates to:
  /// **'Select Relays'**
  String get relaySelectorPlaceholder;

  /// Label showing how many relays are currently selected
  ///
  /// In en, this message translates to:
  /// **'{count} Relays Selected'**
  String relaySelectorSelected(int count);

  /// Title of the relay multi-select dialog
  ///
  /// In en, this message translates to:
  /// **'Select Relays'**
  String get relaySelectorPickerTitle;

  /// Empty-state copy inside the relay picker dialog
  ///
  /// In en, this message translates to:
  /// **'No relays available. Tap + to add one.'**
  String get relaySelectorEmpty;

  /// Tooltip for the + icon that opens the add-relay dialog
  ///
  /// In en, this message translates to:
  /// **'Add relay'**
  String get relaySelectorAddTooltip;

  /// Title of the add-relay dialog
  ///
  /// In en, this message translates to:
  /// **'Add Relay'**
  String get relayAddDialogTitle;

  /// Hint text in the add-relay url input
  ///
  /// In en, this message translates to:
  /// **'wss://relay.example.com'**
  String get relayAddDialogHint;

  /// Confirm button label on the add-relay dialog
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get relayAddDialogAction;

  /// Error snackbar when a relay could not be added
  ///
  /// In en, this message translates to:
  /// **'Could not add relay: {error}'**
  String relayAddDialogError(String error);

  /// Title of the remove-relay confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Remove Relay'**
  String get relayRemoveDialogTitle;

  /// Body of the remove-relay confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Stop using {url}?'**
  String relayRemoveDialogBody(String url);

  /// Confirm button label on the remove-relay dialog
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get relayRemoveDialogAction;

  /// Empty state when the user has no relays in the settings sheet
  ///
  /// In en, this message translates to:
  /// **'No relays found.'**
  String get relayManageEmpty;

  /// Tooltip for the per-relay delete icon in the settings sheet
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get relayManageRemoveTooltip;

  /// Title of the pending join requests bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Pending join requests'**
  String get pendingRequestsTitle;

  /// Subtitle of the pending join requests bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Approve users so they can read and send messages.'**
  String get pendingRequestsSubtitle;

  /// Empty state of the pending join requests bottom sheet
  ///
  /// In en, this message translates to:
  /// **'No pending requests.'**
  String get pendingRequestsEmpty;

  /// Fallback name shown for a join request with no profile name
  ///
  /// In en, this message translates to:
  /// **'New member'**
  String get pendingRequestsNewMember;

  /// Approve button label on a pending join request
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get pendingRequestsApprove;

  /// Section label for cloud LLM provider settings
  ///
  /// In en, this message translates to:
  /// **'Cloud AI'**
  String get settingsCloudProvider;

  /// Title of the cloud provider settings card
  ///
  /// In en, this message translates to:
  /// **'UNIUN Cloud'**
  String get cloudProviderTitle;

  /// CTA in cloud provider card when no API key is configured
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get cloudProviderEmptyCta;

  /// Subtitle in cloud provider card when no API key is configured
  ///
  /// In en, this message translates to:
  /// **'Run Shiv on Claude — sign in with your UNIUN identity.'**
  String get cloudProviderEmptySubtitle;

  /// Subtitle in cloud provider card when an API key is configured
  ///
  /// In en, this message translates to:
  /// **'Connected · Tap to manage'**
  String get cloudProviderConnectedSubtitle;

  /// Action that removes the saved API key
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get cloudProviderDisconnect;

  /// Dialog title warning that disconnecting revokes the account's last active gateway key
  ///
  /// In en, this message translates to:
  /// **'This is your only active key'**
  String get cloudProviderLastKeyTitle;

  /// Dialog body explaining the consequence of revoking the last active key
  ///
  /// In en, this message translates to:
  /// **'Disconnecting will revoke your last active key on UNIUN Cloud. You can always reconnect later — this just signs this device out.'**
  String get cloudProviderLastKeyMessage;

  /// Shown while the silent keypair login to the UNIUN gateway runs
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get cloudProviderConnecting;

  /// Error shown when the silent keypair login fails
  ///
  /// In en, this message translates to:
  /// **'Could not sign in to UNIUN Cloud. Check your connection and try again.'**
  String get cloudProviderConnectFailed;

  /// Snackbar shown when scanning a web QR-login code while not connected to UNIUN Cloud
  ///
  /// In en, this message translates to:
  /// **'Sign in to UNIUN Cloud in Settings first, then scan this code again.'**
  String get qrLoginNotConnected;

  /// Snackbar shown after successfully approving a web QR-login session
  ///
  /// In en, this message translates to:
  /// **'This device is now signed in on the web.'**
  String get qrLoginApproved;

  /// Snackbar shown when approving a web QR-login session fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t approve sign-in: {error}'**
  String qrLoginFailed(String error);

  /// Section header above the cloud model rows in the manage sheet
  ///
  /// In en, this message translates to:
  /// **'CLOUD MODELS'**
  String get cloudProviderModelsHeader;

  /// Label of the on-device model row in the manage sheet
  ///
  /// In en, this message translates to:
  /// **'On-device'**
  String get cloudProviderOnDevice;

  /// Shown after On-device when no local model is installed
  ///
  /// In en, this message translates to:
  /// **'not downloaded'**
  String get cloudProviderOnDeviceNotSet;

  /// Shown in the manage sheet when the plan allows no cloud-served models
  ///
  /// In en, this message translates to:
  /// **'No cloud models on your plan yet. Upgrade your plan at uniun.in to unlock them.'**
  String get cloudProviderNoCloudModels;

  /// Label for the account plan in the cloud manage sheet
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get cloudProviderPlanLabel;

  /// Label for the credit balance in the cloud manage sheet
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get cloudProviderCreditsLabel;

  /// Button in the cloud manage sheet that opens the website pricing page for checkout
  ///
  /// In en, this message translates to:
  /// **'Upgrade plan / add credits'**
  String get cloudProviderUpgrade;

  /// Explains why upgrading opens a browser instead of paying in-app
  ///
  /// In en, this message translates to:
  /// **'Payment happens on uniun.in — sign in there with the same identity, then come back and reopen this sheet to see your new plan.'**
  String get cloudProviderUpgradeHint;

  /// Title of the chat input model picker bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Pick a model'**
  String get modelPickerTitle;

  /// Placeholder of the search field in the model picker
  ///
  /// In en, this message translates to:
  /// **'Search models…'**
  String get modelPickerSearchHint;

  /// Section header in model picker for locally-downloaded models
  ///
  /// In en, this message translates to:
  /// **'On-device'**
  String get modelPickerLocalSection;

  /// Section header in model picker for cloud OpenRouter models
  ///
  /// In en, this message translates to:
  /// **'Cloud'**
  String get modelPickerCloudSection;

  /// Footer CTA in the model picker that opens the local model download page
  ///
  /// In en, this message translates to:
  /// **'Manage on-device models'**
  String get modelPickerManageLocalCta;

  /// Footer CTA in the model picker shown when no API key is configured
  ///
  /// In en, this message translates to:
  /// **'Connect a cloud provider'**
  String get modelPickerConnectCloudCta;

  /// Empty state shown in the model picker
  ///
  /// In en, this message translates to:
  /// **'No models available.'**
  String get modelPickerNoModels;

  /// Tooltip on the button in Shiv's chat input that attaches a photo to the message; shown only when the active AI model can read images
  ///
  /// In en, this message translates to:
  /// **'Attach an image'**
  String get chatInputAttachImageTooltip;

  /// Tooltip on the button that removes the photo attached to the chat message being written
  ///
  /// In en, this message translates to:
  /// **'Remove image'**
  String get chatInputRemoveImageTooltip;

  /// Tooltip on the + icon in the chat input that opens the model picker
  ///
  /// In en, this message translates to:
  /// **'Pick model'**
  String get chatInputPickModelTooltip;

  /// Snackbar shown after a successful follow
  ///
  /// In en, this message translates to:
  /// **'Now following.'**
  String get followActionSuccess;

  /// Drawer section header listing users the active identity follows
  ///
  /// In en, this message translates to:
  /// **'FOLLOWING'**
  String get drawerFollowingSectionTitle;

  /// Empty hint shown in the drawer when the follow list is empty
  ///
  /// In en, this message translates to:
  /// **'Not following anyone yet'**
  String get drawerFollowingEmpty;

  /// Vishnu feed empty-state title shown when the user follows nobody and has no own notes
  ///
  /// In en, this message translates to:
  /// **'Your feed is quiet'**
  String get vishnuFeedEmptyTitle;

  /// Vishnu feed empty-state subtitle below the title
  ///
  /// In en, this message translates to:
  /// **'Scan someone\'s UNIUN QR to follow them and see their notes here.'**
  String get vishnuFeedEmptySubtitle;

  /// Vishnu feed empty-state CTA opening the QR scanner
  ///
  /// In en, this message translates to:
  /// **'Scan a QR'**
  String get vishnuFeedEmptyCta;

  /// Vishnu feed empty-state button that re-reads the feed (after the gateway syncs followed accounts' notes)
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get vishnuFeedEmptyRefresh;

  /// Drawer section header for private groups (uppercase)
  ///
  /// In en, this message translates to:
  /// **'PRIVATE GROUPS'**
  String get drawerPrivateGroups;

  /// Empty hint shown in the drawer when no private groups are joined
  ///
  /// In en, this message translates to:
  /// **'No private groups joined'**
  String get drawerNoPrivateGroups;

  /// Error snackbar when the scanned user QR has an unparseable public key
  ///
  /// In en, this message translates to:
  /// **'Invalid public key'**
  String get followActionInvalidKey;

  /// Follow button on the user profile page
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get userProfileFollow;

  /// Toggle label on the user profile page when already following the user
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get userProfileFollowing;

  /// Empty state shown on the user profile page when the user has no notes locally
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get userProfileNoNotes;

  /// Message button on the user profile page that opens a direct message with the user
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get userProfileMessage;

  /// Section label above the user's recent notes on the user profile page
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get userProfileNotesLabel;

  /// Tooltip on the copy button next to the npub on the user profile page
  ///
  /// In en, this message translates to:
  /// **'Copy npub'**
  String get userProfileCopyNpub;

  /// Button in the QR card that opens the native share sheet with the QR image and deep link
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get qrShareAction;

  /// Snackbar shown when sharing the QR image fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t share QR code'**
  String get qrShareFailed;

  /// Caption under the QR code on a user identity card
  ///
  /// In en, this message translates to:
  /// **'Scan this to add you on UNIUN.'**
  String get qrCaptionUser;

  /// Caption under the QR code on a public group card
  ///
  /// In en, this message translates to:
  /// **'Scan to join this group.'**
  String get qrCaptionPublicGroup;

  /// Caption under the QR code on a private group card
  ///
  /// In en, this message translates to:
  /// **'Scan to join this private group.'**
  String get qrCaptionPrivateGroup;

  /// Caption under the QR code on a direct-message card
  ///
  /// In en, this message translates to:
  /// **'Scan to start a chat on UNIUN.'**
  String get qrCaptionDm;

  /// Title of the in-app share bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Share note'**
  String get shareSheetTitle;

  /// Eyebrow label above the quoted-note preview card at the top of the share sheet
  ///
  /// In en, this message translates to:
  /// **'Quoting'**
  String get shareQuotingLabel;

  /// Eyebrow label above the destination list in the share sheet
  ///
  /// In en, this message translates to:
  /// **'Share to'**
  String get shareToLabel;

  /// Label of the primary button that publishes the share to the selected destination
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareActionShare;

  /// Placeholder for the optional caption above the embedded shared note
  ///
  /// In en, this message translates to:
  /// **'Add a comment (optional)'**
  String get shareSheetCommentHint;

  /// Share destination — re-post on the user's own Vishnu feed
  ///
  /// In en, this message translates to:
  /// **'Post to my feed'**
  String get shareDestFeed;

  /// Subtitle under the 'Post to my feed' share destination
  ///
  /// In en, this message translates to:
  /// **'Visible on Vishnu'**
  String get shareDestFeedSubtitle;

  /// Section header in the share sheet listing public groups
  ///
  /// In en, this message translates to:
  /// **'PUBLIC GROUPS'**
  String get shareSectionPublicGroups;

  /// Section header in the share sheet listing private groups
  ///
  /// In en, this message translates to:
  /// **'PRIVATE GROUPS'**
  String get shareSectionPrivateGroups;

  /// Section header in the share sheet listing DM conversations
  ///
  /// In en, this message translates to:
  /// **'DIRECT MESSAGES'**
  String get shareSectionDms;

  /// Snackbar confirmation after the note has been shared into the chosen destination
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get shareSuccess;

  /// Placeholder shown inside an embedded shared-note card while the original is being resolved
  ///
  /// In en, this message translates to:
  /// **'Loading note…'**
  String get shareEmbedLoading;

  /// Placeholder shown when an embedded shared-note cannot be resolved (e.g. private-group note shared to a public surface)
  ///
  /// In en, this message translates to:
  /// **'Note not available'**
  String get shareEmbedNotFound;

  /// Badge shown over an embedded shared-note whose snapshot signature failed verification
  ///
  /// In en, this message translates to:
  /// **'Unverified'**
  String get shareEmbedUnverified;

  /// Button in the share composer to attach a referenced note
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get shareComposeAddReference;

  /// Button in the share composer to attach an image
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get shareComposeAddImage;

  /// Hint shown in the share sheet's DM section when the user has no DM conversations yet
  ///
  /// In en, this message translates to:
  /// **'Start a DM first to share notes here.'**
  String get shareNoDmConversations;

  /// Action in the note card overflow menu that blocks the note's author
  ///
  /// In en, this message translates to:
  /// **'Block user'**
  String get noteCardBlockUser;

  /// Action in the note card overflow menu that deletes the note locally
  ///
  /// In en, this message translates to:
  /// **'Delete note'**
  String get noteCardDeleteNote;

  /// Confirmation snackbar shown after deleting a note from a note card
  ///
  /// In en, this message translates to:
  /// **'Note deleted.'**
  String get deleteNoteSnackbar;

  /// Confirmation snackbar shown after blocking a user from a note card
  ///
  /// In en, this message translates to:
  /// **'Blocked {name}. New posts from them won\'t appear.'**
  String blockUserSnackbar(String name);

  /// Settings row that opens the blocked users management screen
  ///
  /// In en, this message translates to:
  /// **'Blocked Users'**
  String get settingsBlockedUsers;

  /// App bar title of the blocked users management screen
  ///
  /// In en, this message translates to:
  /// **'Blocked users'**
  String get blockedUsersTitle;

  /// Explainer paragraph at the top of the blocked users screen
  ///
  /// In en, this message translates to:
  /// **'Blocked people can\'t message you and their notes stay hidden from your feed. Notes are never deleted — unblocking brings them back.'**
  String get blockedUsersDescription;

  /// Section label above the blocked users list, with the number of blocked users
  ///
  /// In en, this message translates to:
  /// **'Blocked · {count}'**
  String blockedUsersSectionCount(int count);

  /// Per-row meta line showing how long ago a user was blocked
  ///
  /// In en, this message translates to:
  /// **'Blocked {time} ago'**
  String blockedUsersBlockedAgo(String time);

  /// Per-row meta line when a user was blocked less than a minute ago
  ///
  /// In en, this message translates to:
  /// **'Blocked just now'**
  String get blockedUsersBlockedJustNow;

  /// Empty state on the blocked users screen when no users are blocked
  ///
  /// In en, this message translates to:
  /// **'You haven\'t blocked anyone'**
  String get blockedUsersEmpty;

  /// Helper subtitle below the empty-state title on the blocked users screen
  ///
  /// In en, this message translates to:
  /// **'People you block will appear here, so you can unblock them anytime.'**
  String get blockedUsersEmptyHint;

  /// Button that unblocks a user on the blocked users screen
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get actionUnblock;

  /// Action in the note card overflow menu that opens the NIP-56 report sheet
  ///
  /// In en, this message translates to:
  /// **'Report note'**
  String get noteCardReport;

  /// Title shown at the top of the NIP-56 report bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Report this content'**
  String get reportSheetTitle;

  /// Placeholder for the optional reason text field in the report sheet
  ///
  /// In en, this message translates to:
  /// **'Optional — add any context (max 280 chars)'**
  String get reportSheetReasonHint;

  /// Primary button on the report sheet that publishes the Kind-1984 event
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get reportSheetSubmit;

  /// Inline explainer under the report form telling the user what the unconditional outcome of submitting will be
  ///
  /// In en, this message translates to:
  /// **'This note will be hidden from your feed. Your report is sent to the network.'**
  String get reportSheetOutcomeHint;

  /// Optional checkbox on the report sheet that additionally adds the author to the blocked-users list
  ///
  /// In en, this message translates to:
  /// **'Also block this user (you won\'t see any of their posts)'**
  String get reportSheetAlsoBlock;

  /// Confirmation snackbar shown after a report is successfully published
  ///
  /// In en, this message translates to:
  /// **'Report sent. Thanks for keeping UNIUN safe.'**
  String get reportSentSnackbar;

  /// Label for the NIP-56 'nudity' report category
  ///
  /// In en, this message translates to:
  /// **'Nudity'**
  String get reportTypeNudity;

  /// One-line description shown under the 'nudity' report option
  ///
  /// In en, this message translates to:
  /// **'Sexually explicit material or nudity'**
  String get reportTypeNudityDescription;

  /// Label for the NIP-56 'malware' report category
  ///
  /// In en, this message translates to:
  /// **'Malware'**
  String get reportTypeMalware;

  /// One-line description shown under the 'malware' report option
  ///
  /// In en, this message translates to:
  /// **'Links or files that could harm devices'**
  String get reportTypeMalwareDescription;

  /// Label for the NIP-56 'profanity' report category
  ///
  /// In en, this message translates to:
  /// **'Profanity'**
  String get reportTypeProfanity;

  /// One-line description shown under the 'profanity' report option
  ///
  /// In en, this message translates to:
  /// **'Hateful or extremely vulgar language'**
  String get reportTypeProfanityDescription;

  /// Label for the NIP-56 'illegal' report category
  ///
  /// In en, this message translates to:
  /// **'Illegal'**
  String get reportTypeIllegal;

  /// One-line description shown under the 'illegal' report option
  ///
  /// In en, this message translates to:
  /// **'Content that is illegal in the reporter\'s jurisdiction'**
  String get reportTypeIllegalDescription;

  /// Label for the NIP-56 'spam' report category
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get reportTypeSpam;

  /// One-line description shown under the 'spam' report option
  ///
  /// In en, this message translates to:
  /// **'Unwanted or repetitive promotion'**
  String get reportTypeSpamDescription;

  /// Label for the NIP-56 'impersonation' report category
  ///
  /// In en, this message translates to:
  /// **'Impersonation'**
  String get reportTypeImpersonation;

  /// One-line description shown under the 'impersonation' report option
  ///
  /// In en, this message translates to:
  /// **'Pretending to be someone they are not'**
  String get reportTypeImpersonationDescription;

  /// Label for the NIP-56 'other' report category
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reportTypeOther;

  /// One-line description shown under the 'other' report option
  ///
  /// In en, this message translates to:
  /// **'Something else that violates community standards'**
  String get reportTypeOtherDescription;

  /// Button that expands a note's text when it is longer than the collapsed line limit
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get actionReadMore;

  /// Button that collapses a previously expanded note's text
  ///
  /// In en, this message translates to:
  /// **'Read less'**
  String get actionReadLess;

  /// App bar title of the media gallery / file manager
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get mediaGalleryTitle;

  /// Filter chip in the media gallery showing every blob
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get mediaTabAll;

  /// Filter chip restricting the media gallery to image blobs
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get mediaTabImages;

  /// Filter chip restricting the media gallery to video blobs
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get mediaTabVideos;

  /// Filter chip restricting the media gallery to audio blobs
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get mediaTabAudio;

  /// Filter chip showing non-media file blobs (PDFs, etc.)
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get mediaTabFiles;

  /// Filter chip restricting the media gallery to blobs the user pinned
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get mediaTabPinned;

  /// Action in the media action sheet that downloads the blob bytes from the server
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get mediaActionDownload;

  /// Action in the media detail page that hands the cached file to the OS for viewing (PDF reader, video player, etc.)
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get mediaActionOpen;

  /// Action that pins the blob so cleanup never evicts it
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get mediaActionPin;

  /// Action that unpins the blob, restoring normal retention
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get mediaActionUnpin;

  /// Action that deletes the local copy of the blob (server copy stays)
  ///
  /// In en, this message translates to:
  /// **'Remove from device'**
  String get mediaActionRemoveLocal;

  /// Action that copies the blob's sha256 hash to the clipboard
  ///
  /// In en, this message translates to:
  /// **'Copy sha256'**
  String get mediaActionCopySha;

  /// Action that saves the cached blob to the device's gallery (images / videos via `gal`) or Downloads folder (files on desktop) or share sheet (non-media on mobile).
  ///
  /// In en, this message translates to:
  /// **'Save to device'**
  String get mediaActionSaveToDevice;

  /// Snackbar shown after a successful Save to device; placeholder is the destination (e.g. 'Photos', '/Users/...').
  ///
  /// In en, this message translates to:
  /// **'Saved to {destination}'**
  String mediaSavedTo(String destination);

  /// Generic success snackbar when the destination isn't a known string (mobile share-sheet path).
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get mediaSaveSuccess;

  /// Snackbar shown when the Save to device action fails (permission denied / disk error).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the file'**
  String get mediaSaveFailed;

  /// Empty state shown in the media gallery when there are no known blobs
  ///
  /// In en, this message translates to:
  /// **'No media yet. Notes you receive with attachments will appear here.'**
  String get mediaEmptyState;

  /// Metadata row label showing how many notes reference this blob
  ///
  /// In en, this message translates to:
  /// **'Referenced by'**
  String get mediaDetailReferencedBy;

  /// Metadata row label for the blob's sha256 hash on the media detail page
  ///
  /// In en, this message translates to:
  /// **'sha256'**
  String get mediaDetailLabelSha;

  /// Metadata row label for the blob's MIME type on the media detail page
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get mediaDetailLabelMime;

  /// Metadata row label for the blob's byte size on the media detail page
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get mediaDetailLabelSize;

  /// Metadata row label for the blob's width × height on the media detail page
  ///
  /// In en, this message translates to:
  /// **'Dimensions'**
  String get mediaDetailLabelDim;

  /// Metadata row label for when the blob was downloaded locally
  ///
  /// In en, this message translates to:
  /// **'Cached'**
  String get mediaDetailLabelCached;

  /// Metadata row label for each Blossom server URL hosting the blob
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get mediaDetailLabelServer;

  /// Title of the media picker bottom sheet shown from the composer
  ///
  /// In en, this message translates to:
  /// **'Attach from library'**
  String get mediaPickerTitle;

  /// Empty state shown in the media picker when there are no known blobs
  ///
  /// In en, this message translates to:
  /// **'No media available yet.'**
  String get mediaPickerEmpty;

  /// Bottom-sheet row that opens the device gallery to attach an image
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get composerAttachPhoto;

  /// Bottom-sheet row that opens the device gallery to attach a video
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get composerAttachVideo;

  /// Bottom-sheet row that opens the device file picker to attach any file
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get composerAttachFile;

  /// Snackbar shown when the user picks a binary (video / PDF / doc / archive) bigger than the upload cap, AND on-device compression — when applicable, e.g. video — couldn't shrink it enough. Both placeholders are pre-formatted human strings (e.g. '72.4 MB', '50 MB').
  ///
  /// In en, this message translates to:
  /// **'File too large ({size}). Max {cap}. Please compress it and try again.'**
  String mediaTooLarge(String size, String cap);

  /// Snackbar shown when even maximum compression can't get the picked image under the relay's body-size limit
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t compress image small enough to upload. Try a different photo.'**
  String get mediaTooLargeAfterCompress;

  /// Settings row that opens the media gallery / file manager
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get storageMediaRow;

  /// Subtitle under the Storage→Media settings row
  ///
  /// In en, this message translates to:
  /// **'Photos, videos and files from your notes'**
  String get storageMediaRowSubtitle;

  /// Label on the download button overlay on an attached-media tile in a note card
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get noteCardDownloadMedia;

  /// Filename label shown on a file attachment tile when the publisher did not include an imeta `name` field.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get noteCardFileFallbackName;

  /// Subtitle hint shown on a cached file attachment tile telling the user the tap action hands the file to the OS.
  ///
  /// In en, this message translates to:
  /// **'Tap to open'**
  String get noteCardFileTapToOpen;

  /// Subtitle hint shown on a not-yet-cached file attachment tile telling the user the tap action triggers a Blossom download.
  ///
  /// In en, this message translates to:
  /// **'Tap to download'**
  String get noteCardFileTapToDownload;

  /// Media gallery contextual app-bar title when the user has long-pressed one or more tiles to multi-select. {count} is the number of selected blobs.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String mediaSelectionCount(int count);

  /// Tooltip on the close (X) button that clears multi-select mode in the media gallery.
  ///
  /// In en, this message translates to:
  /// **'Exit selection'**
  String get mediaSelectionExit;

  /// Confirmation dialog title before bulk-removing local copies of the selected media.
  ///
  /// In en, this message translates to:
  /// **'Remove from device?'**
  String get mediaSelectionRemoveDialogTitle;

  /// Confirmation dialog body. Explains that only the local cache is wiped; remote bytes survive.
  ///
  /// In en, this message translates to:
  /// **'Free up space by deleting {count} cached file(s) from this device. The server copies remain — you can re-download anytime.'**
  String mediaSelectionRemoveDialogBody(int count);

  /// Legend label in the Settings → Storage chart for the cached media bucket (photos / videos / files under getApplicationSupportDirectory()/media/).
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get storageMedia;

  /// Row title for the auto-cleanup retention dropdown in Settings → Storage. Affects only public feed / group notes the user hasn't saved or followed.
  ///
  /// In en, this message translates to:
  /// **'Auto-delete old notes'**
  String get storageRetentionTitle;

  /// Subtitle/explanation under the auto-delete retention row — clarifies which notes are affected and that their local media is removed along with them.
  ///
  /// In en, this message translates to:
  /// **'Public feed and group notes only. Saved, followed, your own, DMs, and private groups stay forever. Deleting a note also removes its photos/files from this device.'**
  String get storageRetentionSubtitle;

  /// Dropdown value for disabling auto-deletion (the default — nothing is removed).
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get storageRetentionOff;

  /// Dropdown value for the auto-delete retention window in days.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String storageRetentionDays(int days);

  /// Row title for the sync-window dropdown in Settings → Storage. Controls how many days of history feed/groups/groups pull.
  ///
  /// In en, this message translates to:
  /// **'Sync window'**
  String get syncWindowTitle;

  /// Subtitle under the sync-window row; explains scope and that it applies on next launch.
  ///
  /// In en, this message translates to:
  /// **'How far back to sync feed and group messages. Followed notes and DMs always sync in full. Applies on next app launch.'**
  String get syncWindowSubtitle;

  /// Dropdown value for the sync-window length in days.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String syncWindowDays(int days);

  /// Status text shown on a note-card media tile while bytes are downloading
  ///
  /// In en, this message translates to:
  /// **'Downloading…'**
  String get noteCardMediaDownloading;

  /// Status text shown on a note-card media tile when the download fails
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get noteCardMediaFailed;

  /// Title of the Brahma side drawer
  ///
  /// In en, this message translates to:
  /// **'BRAHMA'**
  String get manasDrawerHeaderTitle;

  /// Subtitle in the Brahma drawer header
  ///
  /// In en, this message translates to:
  /// **'Your knowledge graphs'**
  String get manasDrawerHeaderSubtitle;

  /// Name of the full unscoped graph entry in the Brahma drawer
  ///
  /// In en, this message translates to:
  /// **'Brahma'**
  String get manasDrawerBrahmaEntryTitle;

  /// Subtitle under the full Brahma entry in the drawer
  ///
  /// In en, this message translates to:
  /// **'Everything you\'ve saved, written, and drafted'**
  String get manasDrawerBrahmaEntrySubtitle;

  /// Section label for the list of Manases
  ///
  /// In en, this message translates to:
  /// **'MANAS'**
  String get manasDrawerSectionTitle;

  /// Inline action that opens the new-Manas form
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get manasDrawerNewManasButton;

  /// Headline when the Manas list is empty
  ///
  /// In en, this message translates to:
  /// **'No Manases yet'**
  String get manasDrawerEmptyStateTitle;

  /// Empty-state body copy in the Manas drawer
  ///
  /// In en, this message translates to:
  /// **'Create a Manas to focus the graph on a topic — a sub-expert mind built from a subset of your notes.'**
  String get manasDrawerEmptyStateBody;

  /// CTA button for the empty Manas list
  ///
  /// In en, this message translates to:
  /// **'Create your first Manas'**
  String get manasDrawerEmptyStateCta;

  /// Note-count subtitle on a Manas tile
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 note} other{{count} notes}}'**
  String manasDrawerTileNoteCount(int count);

  /// Subtitle of a Manas tile with no notes yet
  ///
  /// In en, this message translates to:
  /// **'0 notes · Tap to open'**
  String get manasTileEmptyHint;

  /// Bottom-sheet action — edit the long-pressed Manas
  ///
  /// In en, this message translates to:
  /// **'Edit Manas'**
  String get manasTileActionEdit;

  /// Bottom-sheet action — delete the long-pressed Manas
  ///
  /// In en, this message translates to:
  /// **'Delete Manas'**
  String get manasTileActionDelete;

  /// Confirmation dialog title for deleting a Manas
  ///
  /// In en, this message translates to:
  /// **'Delete Manas?'**
  String get manasDeleteConfirmTitle;

  /// Body of the Manas delete confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'“{name}” will be removed. The notes themselves are kept — only the Manas membership is deleted.'**
  String manasDeleteConfirmBody(String name);

  /// Destructive confirm button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get manasDeleteConfirmConfirm;

  /// Cancel button on the delete confirmation
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get manasDeleteConfirmCancel;

  /// App-bar title in create mode
  ///
  /// In en, this message translates to:
  /// **'New Manas'**
  String get manasFormCreateTitle;

  /// App-bar title in edit mode
  ///
  /// In en, this message translates to:
  /// **'Edit · {name}'**
  String manasFormEditTitle(String name);

  /// App-bar title in edit mode when the name is empty
  ///
  /// In en, this message translates to:
  /// **'Edit Manas'**
  String get manasFormEditTitleFallback;

  /// Save action on the Manas form app bar
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get manasFormSaveAction;

  /// Delete button at the bottom of the Manas form (edit mode)
  ///
  /// In en, this message translates to:
  /// **'Delete Manas'**
  String get manasFormDeleteAction;

  /// Label for the Manas name field
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get manasFormNameLabel;

  /// Placeholder for the Manas name field
  ///
  /// In en, this message translates to:
  /// **'e.g. Rust Expert'**
  String get manasFormNameHint;

  /// Label for the description field
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get manasFormDescriptionLabel;

  /// Placeholder for the description field
  ///
  /// In en, this message translates to:
  /// **'Optional. What is this Manas for?'**
  String get manasFormDescriptionHint;

  /// Section title listing the included notes
  ///
  /// In en, this message translates to:
  /// **'NOTES IN THIS MANAS ({count})'**
  String manasFormMembershipSectionTitle(int count);

  /// Hint when the membership list is empty
  ///
  /// In en, this message translates to:
  /// **'No notes yet. Search below to add some.'**
  String get manasFormMembershipEmpty;

  /// Section title for the search/add area
  ///
  /// In en, this message translates to:
  /// **'ADD NOTES'**
  String get manasFormAddNotesSectionTitle;

  /// Placeholder in the note-search field
  ///
  /// In en, this message translates to:
  /// **'Search saved, own, or draft notes'**
  String get manasFormSearchHint;

  /// Hint when search returns no results
  ///
  /// In en, this message translates to:
  /// **'No matches.'**
  String get manasFormSearchEmpty;

  /// Chip label when a referenced note is not in local cache
  ///
  /// In en, this message translates to:
  /// **'(note unavailable)'**
  String get manasFormNoteUnavailable;

  /// Provenance badge on search-result rows for saved notes
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get manasFormKindSaved;

  /// Provenance badge on search-result rows for own (authored) notes
  ///
  /// In en, this message translates to:
  /// **'Own'**
  String get manasFormKindOwn;

  /// Provenance badge on search-result rows for local drafts
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get manasFormKindDraft;

  /// Title of the form's delete confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete this Manas?'**
  String get manasFormDeleteConfirmTitle;

  /// Body of the form's delete confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'This removes the Manas and all its memberships. The notes themselves remain in Brahma.'**
  String get manasFormDeleteConfirmBody;

  /// Destructive confirm action in the form
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get manasFormDeleteConfirmConfirm;

  /// Cancel action in the form's delete dialog
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get manasFormDeleteConfirmCancel;

  /// Tooltip for the edit-Manas pencil in the graph header
  ///
  /// In en, this message translates to:
  /// **'Edit Manas'**
  String get graphHeaderManasEditTooltip;

  /// Fallback label for the scoped Manas chip when the name is not loaded yet
  ///
  /// In en, this message translates to:
  /// **'Manas'**
  String get graphHeaderUnnamedManas;

  /// Note-card overflow menu — open the Manas membership sheet for this note
  ///
  /// In en, this message translates to:
  /// **'Add to Manas'**
  String get noteCardAddToManas;

  /// Snackbar shown when saving a note before adding it to a Manas fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the note. Try again.'**
  String get noteCardManasSaveFailed;

  /// Title of the confirmation dialog shown when unsaving a note that belongs to one or more Manases
  ///
  /// In en, this message translates to:
  /// **'Unsave note?'**
  String get unsaveManasDialogTitle;

  /// Lead-in line of the unsave confirmation dialog, above the list of Manas cards the note will be removed from
  ///
  /// In en, this message translates to:
  /// **'Unsaving this note will also remove it from:'**
  String get unsaveManasDialogBody;

  /// Destructive confirm button on the unsave-from-Manas dialog
  ///
  /// In en, this message translates to:
  /// **'Unsave'**
  String get unsaveManasDialogConfirm;

  /// Cancel button on the unsave-from-Manas dialog
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get unsaveManasDialogCancel;

  /// Title of the bottom sheet that toggles a note's Manas memberships
  ///
  /// In en, this message translates to:
  /// **'Add to Manas'**
  String get manasMembershipSheetTitle;

  /// Trailing button in the membership sheet that opens the create form
  ///
  /// In en, this message translates to:
  /// **'Create new Manas'**
  String get manasMembershipSheetCreate;

  /// Headline shown when the user has no Manases
  ///
  /// In en, this message translates to:
  /// **'No Manases yet'**
  String get manasMembershipSheetEmptyTitle;

  /// Body copy in the empty-state of the membership sheet
  ///
  /// In en, this message translates to:
  /// **'Create your first Manas to start grouping notes into focused sub-experts.'**
  String get manasMembershipSheetEmptyBody;

  /// Primary CTA in the empty-state of the membership sheet
  ///
  /// In en, this message translates to:
  /// **'Create Manas'**
  String get manasMembershipSheetEmptyCta;

  /// Title of the bottom sheet that picks a Manas icon
  ///
  /// In en, this message translates to:
  /// **'Pick an icon'**
  String get manasIconPickerTitle;

  /// App bar title on the Gana agents list page
  ///
  /// In en, this message translates to:
  /// **'Gana'**
  String get ganaListTitle;

  /// Label for the create-new-Gana button on the Gana list page
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get ganaListNew;

  /// Intro line below the app bar on the Gana list page
  ///
  /// In en, this message translates to:
  /// **'Autonomous agents that watch a surface, reason over a Manas, and publish for you.'**
  String get ganaListSubtitle;

  /// Status line on a Gana card when the agent is disabled
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get ganaListPaused;

  /// Gana card scope label when no Manas is selected (whole library)
  ///
  /// In en, this message translates to:
  /// **'All notes'**
  String get ganaListScopeAll;

  /// Gana card scope label showing how many Manas the agent reasons over
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Manas} other{{count} Manas}}'**
  String ganaListScopeCount(int count);

  /// Title of the Gana dashboard page
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get ganaDashboardTitle;

  /// Dashboard tile label: Ganas currently switched on
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get ganaDashboardActive;

  /// Dashboard tile label: total successful runs
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get ganaDashboardDone;

  /// Dashboard tile label: total failed runs
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get ganaDashboardFailed;

  /// Dashboard tile label: total skipped runs
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get ganaDashboardSkipped;

  /// Section title listing Ganas whose last run failed
  ///
  /// In en, this message translates to:
  /// **'NEEDS ATTENTION'**
  String get ganaDashboardAttentionTitle;

  /// Section title listing every Gana with its numbers
  ///
  /// In en, this message translates to:
  /// **'YOUR GANAS'**
  String get ganaDashboardGanasTitle;

  /// Section title for the latest runs across all Ganas
  ///
  /// In en, this message translates to:
  /// **'RECENT ACTIVITY'**
  String get ganaDashboardActivityTitle;

  /// Empty text of the recent activity section
  ///
  /// In en, this message translates to:
  /// **'No runs yet. They show up here as your Ganas work.'**
  String get ganaDashboardActivityEmpty;

  /// Success rate of a Gana; {percent} is a whole number
  ///
  /// In en, this message translates to:
  /// **'{percent}% succeeded'**
  String ganaDashboardRate(int percent);

  /// Lifetime run counts of one Gana
  ///
  /// In en, this message translates to:
  /// **'{done} done · {failed} failed · {skipped} skipped'**
  String ganaStatsCounts(int done, int failed, int skipped);

  /// Footnote explaining what the dashboard numbers cover
  ///
  /// In en, this message translates to:
  /// **'Totals count runs since this version. Recent activity keeps the latest 10 runs per Gana.'**
  String get ganaDashboardFootnote;

  /// Failed-run title: no signed-in identity
  ///
  /// In en, this message translates to:
  /// **'No active identity'**
  String get ganaErrNoIdentityTitle;

  /// Failed-run hint: no signed-in identity
  ///
  /// In en, this message translates to:
  /// **'Sign in so the Gana can sign and publish its note.'**
  String get ganaErrNoIdentityHint;

  /// Failed-run title: publishing failed
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t publish the note'**
  String get ganaErrPublishTitle;

  /// Failed-run hint: publishing failed
  ///
  /// In en, this message translates to:
  /// **'The Gana wrote a note but sending it failed. It tries again on the next trigger.'**
  String get ganaErrPublishHint;

  /// Failed-run title: connection or timeout error
  ///
  /// In en, this message translates to:
  /// **'Network problem'**
  String get ganaErrNetworkTitle;

  /// Failed-run hint: connection or timeout error
  ///
  /// In en, this message translates to:
  /// **'The connection dropped or timed out. Check your internet; it retries on the next trigger.'**
  String get ganaErrNetworkHint;

  /// Failed-run title: model or engine error
  ///
  /// In en, this message translates to:
  /// **'The AI model had a problem'**
  String get ganaErrModelTitle;

  /// Failed-run hint: model or engine error
  ///
  /// In en, this message translates to:
  /// **'The model failed while writing. Check the model in Shiv, then try again.'**
  String get ganaErrModelHint;

  /// Failed-run title: unrecognised error
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get ganaErrOtherTitle;

  /// Failed-run hint: unrecognised error
  ///
  /// In en, this message translates to:
  /// **'The run stopped with an unexpected error.'**
  String get ganaErrOtherHint;

  /// Label above the raw error text of a failed run
  ///
  /// In en, this message translates to:
  /// **'Technical detail'**
  String get ganaRunTechnicalDetail;

  /// Label above the note a run published
  ///
  /// In en, this message translates to:
  /// **'NOTE IT PUBLISHED'**
  String get ganaRunOutputLabel;

  /// Shown when a run's published note was cleaned up
  ///
  /// In en, this message translates to:
  /// **'This note is no longer on this device.'**
  String get ganaRunOutputMissing;

  /// Button that opens the note a run published
  ///
  /// In en, this message translates to:
  /// **'Open note'**
  String get ganaRunOpenNote;

  /// How many input messages a run read
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Read 1 message} other{Read {count} messages}}'**
  String ganaRunInputCount(int count);

  /// Skip reason explanation
  ///
  /// In en, this message translates to:
  /// **'No AI model is active. Pick one in Shiv.'**
  String get ganaSkipNoActiveModel;

  /// Skip reason explanation
  ///
  /// In en, this message translates to:
  /// **'The active model isn\'t the one this Gana is pinned to.'**
  String get ganaSkipModelMismatch;

  /// Skip reason explanation
  ///
  /// In en, this message translates to:
  /// **'Nothing new to read.'**
  String get ganaSkipNoNewInput;

  /// Skip reason explanation
  ///
  /// In en, this message translates to:
  /// **'The model changed mid-run, so this run was cancelled.'**
  String get ganaSkipModelSwapped;

  /// Skip reason explanation
  ///
  /// In en, this message translates to:
  /// **'The model chose to stay silent.'**
  String get ganaSkipNoopReturned;

  /// Skip reason explanation
  ///
  /// In en, this message translates to:
  /// **'It reached its max notes and switched itself off.'**
  String get ganaSkipMaxOutputs;

  /// Skip reason explanation
  ///
  /// In en, this message translates to:
  /// **'UNIUN Cloud isn\'t connected, or no cloud model is set.'**
  String get ganaSkipCloudUnavailable;

  /// Empty-state title in the Ganas section
  ///
  /// In en, this message translates to:
  /// **'No Ganas yet'**
  String get ganaDrawerEmptyTitle;

  /// Empty-state body in the Ganas section
  ///
  /// In en, this message translates to:
  /// **'Create an AI worker that watches a surface and publishes for you.'**
  String get ganaDrawerEmptyBody;

  /// Status pill on a Gana tile when it is disabled
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get ganaTileDisabled;

  /// Subtitle fragment shown when a Gana fires on new input
  ///
  /// In en, this message translates to:
  /// **'Reactive'**
  String get ganaTileTriggerReactive;

  /// Subtitle fragment for an interval Gana; {n} is the minute count
  ///
  /// In en, this message translates to:
  /// **'Every {n}m'**
  String ganaTileTriggerInterval(int n);

  /// Subtitle when a Gana has both triggers
  ///
  /// In en, this message translates to:
  /// **'Reactive + every {n}m'**
  String ganaTileTriggerBoth(int n);

  /// Subtitle for a one-shot standalone Gana
  ///
  /// In en, this message translates to:
  /// **'Once on enable'**
  String get ganaTileTriggerOnceOnEnable;

  /// Subtitle for a one-shot Gana with an input source
  ///
  /// In en, this message translates to:
  /// **'Once on first input'**
  String get ganaTileTriggerOnceOnInput;

  /// Last-run label when the Gana has never run
  ///
  /// In en, this message translates to:
  /// **'No runs yet'**
  String get ganaTileLastRunNever;

  /// Last-run label on success; {when} is a relative time
  ///
  /// In en, this message translates to:
  /// **'Last run · {when}'**
  String ganaTileLastRunSucceeded(String when);

  /// Last-run label when the most recent run was skipped
  ///
  /// In en, this message translates to:
  /// **'Skipped · {when}'**
  String ganaTileLastRunSkipped(String when);

  /// Last-run label when the most recent run failed
  ///
  /// In en, this message translates to:
  /// **'Failed · {when}'**
  String ganaTileLastRunFailed(String when);

  /// Relative time for an event less than a minute ago
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get ganaRelativeJustNow;

  /// Relative time in minutes
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String ganaRelativeMinutes(int count);

  /// Relative time in hours
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String ganaRelativeHours(int count);

  /// Relative time in days
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String ganaRelativeDays(int count);

  /// AppBar title in create mode
  ///
  /// In en, this message translates to:
  /// **'New Gana'**
  String get ganaFormCreateTitle;

  /// AppBar title in edit mode
  ///
  /// In en, this message translates to:
  /// **'Edit · {name}'**
  String ganaFormEditTitle(String name);

  /// Edit-mode title when the name is empty
  ///
  /// In en, this message translates to:
  /// **'Edit Gana'**
  String get ganaFormEditTitleFallback;

  /// AppBar action — save the Gana
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get ganaFormSaveAction;

  /// Edit-mode delete button label
  ///
  /// In en, this message translates to:
  /// **'Delete Gana'**
  String get ganaFormDeleteAction;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get ganaFormNameLabel;

  /// Name field placeholder
  ///
  /// In en, this message translates to:
  /// **'e.g. Life Lessons Replier'**
  String get ganaFormNameHint;

  /// Section title above the Manas picker
  ///
  /// In en, this message translates to:
  /// **'KNOWLEDGE'**
  String get ganaFormManasSectionTitle;

  /// Helper text under the section title
  ///
  /// In en, this message translates to:
  /// **'The Manas this Gana reasons over.'**
  String get ganaFormManasSectionSubtitle;

  /// Empty-state when the user has no Manases
  ///
  /// In en, this message translates to:
  /// **'No Manases yet. A Gana needs a knowledge base to reason over — create one to continue.'**
  String get ganaFormManasEmpty;

  /// Inline CTA to open the Manas form from the Gana form
  ///
  /// In en, this message translates to:
  /// **'Create Manas'**
  String get ganaFormManasCreateNew;

  /// Cron-job mode label
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get ganaFormModeRecurring;

  /// Fire once then auto-disable label
  ///
  /// In en, this message translates to:
  /// **'One-shot'**
  String get ganaFormModeOneShot;

  /// Recurring mode helper
  ///
  /// In en, this message translates to:
  /// **'Keeps firing on every matching trigger until you disable it.'**
  String get ganaFormModeRecurringHelp;

  /// One-shot mode helper
  ///
  /// In en, this message translates to:
  /// **'Fires once, then auto-disables itself. Re-enable to run again.'**
  String get ganaFormModeOneShotHelp;

  /// Save-blocker hint: missing name
  ///
  /// In en, this message translates to:
  /// **'Add a name to continue.'**
  String get ganaFormBlockerName;

  /// Save-blocker hint: no Manas selected
  ///
  /// In en, this message translates to:
  /// **'Pick at least one Manas — a Gana needs knowledge to reason over.'**
  String get ganaFormBlockerManas;

  /// Save-blocker hint: empty task prompt
  ///
  /// In en, this message translates to:
  /// **'Write a task prompt so the Gana knows what to do.'**
  String get ganaFormBlockerTask;

  /// Save-blocker hint: input type set but ref empty
  ///
  /// In en, this message translates to:
  /// **'Pick the input source — group, DM, user, or note.'**
  String get ganaFormBlockerInputRef;

  /// Save-blocker hint: output type set but ref empty
  ///
  /// In en, this message translates to:
  /// **'Pick the output destination so the Gana knows where to publish.'**
  String get ganaFormBlockerOutputRef;

  /// Save-blocker hint: one-shot + input but reactive off
  ///
  /// In en, this message translates to:
  /// **'One-shot Ganas with an input source need React to new input turned on.'**
  String get ganaFormBlockerOneShotReactive;

  /// Save-blocker hint: recurring + standalone but no interval
  ///
  /// In en, this message translates to:
  /// **'Standalone recurring Ganas need an interval (≥ 5 min).'**
  String get ganaFormBlockerInterval;

  /// Save-blocker hint: recurring + input but no trigger picked
  ///
  /// In en, this message translates to:
  /// **'Turn on React to new input, or set an interval (≥ 5 min).'**
  String get ganaFormBlockerTrigger;

  /// Save-blocker hint: recurring without a maxOutputs cap
  ///
  /// In en, this message translates to:
  /// **'Set a max-notes cap between 1 and 1000.'**
  String get ganaFormBlockerMaxOutputs;

  /// Label for the recurring safety cap input
  ///
  /// In en, this message translates to:
  /// **'Max notes to produce'**
  String get ganaFormMaxOutputsLabel;

  /// Helper text for the max-outputs cap
  ///
  /// In en, this message translates to:
  /// **'Recurring Ganas auto-disable after publishing this many notes. 1–1000.'**
  String get ganaFormMaxOutputsHelp;

  /// Help text for one-shot + standalone (no trigger UI needed)
  ///
  /// In en, this message translates to:
  /// **'Will fire once when you enable this Gana, then auto-disable.'**
  String get ganaFormOneShotStandaloneNote;

  /// Help text under reactive switch when it's required
  ///
  /// In en, this message translates to:
  /// **'Required for one-shot Ganas with an input source.'**
  String get ganaFormReactiveRequiredNote;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Task prompt'**
  String get ganaFormTaskPromptLabel;

  /// Placeholder for the task prompt
  ///
  /// In en, this message translates to:
  /// **'Tell the Gana what to do. e.g. \"When someone posts a question here, reply with the most relevant note from my Manas and add one line of commentary.\"'**
  String get ganaFormTaskPromptHint;

  /// Section title for the input source
  ///
  /// In en, this message translates to:
  /// **'INPUT'**
  String get ganaFormInputSectionTitle;

  /// Input-type option meaning no input surface
  ///
  /// In en, this message translates to:
  /// **'Standalone (no input)'**
  String get ganaFormInputStandalone;

  /// Input-type option
  ///
  /// In en, this message translates to:
  /// **'Public group'**
  String get ganaFormInputGroup;

  /// Input-type option
  ///
  /// In en, this message translates to:
  /// **'Private group'**
  String get ganaFormInputPrivateGroup;

  /// Input-type option
  ///
  /// In en, this message translates to:
  /// **'DM'**
  String get ganaFormInputDm;

  /// Input-type option
  ///
  /// In en, this message translates to:
  /// **'A user\'s notes'**
  String get ganaFormInputUser;

  /// Input-type option
  ///
  /// In en, this message translates to:
  /// **'Followed note thread'**
  String get ganaFormInputFollowedNote;

  /// Hint in the input-ref picker
  ///
  /// In en, this message translates to:
  /// **'Pick a source'**
  String get ganaFormInputPickHint;

  /// Hint when picking the user input ref
  ///
  /// In en, this message translates to:
  /// **'Paste a pubkey (hex or npub)'**
  String get ganaFormInputUserHint;

  /// Section title for the output destination
  ///
  /// In en, this message translates to:
  /// **'OUTPUT'**
  String get ganaFormOutputSectionTitle;

  /// Output destination
  ///
  /// In en, this message translates to:
  /// **'Main feed (Kind 1)'**
  String get ganaFormOutputFeed;

  /// Output destination
  ///
  /// In en, this message translates to:
  /// **'Public group'**
  String get ganaFormOutputGroup;

  /// Output destination
  ///
  /// In en, this message translates to:
  /// **'Private group'**
  String get ganaFormOutputPrivateGroup;

  /// Output destination
  ///
  /// In en, this message translates to:
  /// **'DM'**
  String get ganaFormOutputDm;

  /// Hint in the output-ref picker
  ///
  /// In en, this message translates to:
  /// **'Pick a destination'**
  String get ganaFormOutputPickHint;

  /// Section title for model selection
  ///
  /// In en, this message translates to:
  /// **'MODEL'**
  String get ganaFormModelSectionTitle;

  /// Default option when no specific model is pinned
  ///
  /// In en, this message translates to:
  /// **'Use whichever model is active'**
  String get ganaFormModelUseActive;

  /// Section title for trigger config
  ///
  /// In en, this message translates to:
  /// **'TRIGGERS'**
  String get ganaFormTriggersSectionTitle;

  /// Header above the trigger preset radio group
  ///
  /// In en, this message translates to:
  /// **'When should this run?'**
  String get ganaFormTriggerQuestion;

  /// Preset: standalone one-shot — fires on enable
  ///
  /// In en, this message translates to:
  /// **'Once, when I enable it'**
  String get ganaFormPresetOnceOnEnable;

  /// Preset: one-shot + reactive
  ///
  /// In en, this message translates to:
  /// **'Once, on the first new message'**
  String get ganaFormPresetOnceOnFirstMessage;

  /// Preset: recurring + reactive (no interval)
  ///
  /// In en, this message translates to:
  /// **'On every new message'**
  String get ganaFormPresetEveryMessage;

  /// Preset: recurring + interval only
  ///
  /// In en, this message translates to:
  /// **'On a schedule (every N minutes)'**
  String get ganaFormPresetOnSchedule;

  /// Preset: recurring + reactive + interval
  ///
  /// In en, this message translates to:
  /// **'On every new message AND on a timer'**
  String get ganaFormPresetMessageOrSchedule;

  /// Reactive trigger toggle label
  ///
  /// In en, this message translates to:
  /// **'React to new input'**
  String get ganaFormReactiveLabel;

  /// Reactive trigger helper text
  ///
  /// In en, this message translates to:
  /// **'Fires within a few seconds of a new message on the input surface.'**
  String get ganaFormReactiveHelp;

  /// Interval trigger label
  ///
  /// In en, this message translates to:
  /// **'Run every'**
  String get ganaFormIntervalLabel;

  /// Interval trigger unit hint
  ///
  /// In en, this message translates to:
  /// **'minutes (min 5)'**
  String get ganaFormIntervalUnit;

  /// Master switch label
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get ganaFormEnabledLabel;

  /// Master switch helper text
  ///
  /// In en, this message translates to:
  /// **'Off by default. Turn on once you\'ve reviewed the config.'**
  String get ganaFormEnabledHelp;

  /// Section header for the run log in edit mode
  ///
  /// In en, this message translates to:
  /// **'RECENT RUNS'**
  String get ganaFormRunsSectionTitle;

  /// Empty state for the run log
  ///
  /// In en, this message translates to:
  /// **'This Gana hasn\'t run yet.'**
  String get ganaFormRunsEmpty;

  /// Delete confirmation title
  ///
  /// In en, this message translates to:
  /// **'Delete this Gana?'**
  String get ganaFormDeleteConfirmTitle;

  /// Delete confirmation body
  ///
  /// In en, this message translates to:
  /// **'This stops the worker and removes its run log. The Manases and notes it referenced are not affected.'**
  String get ganaFormDeleteConfirmBody;

  /// Destructive confirm
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get ganaFormDeleteConfirmConfirm;

  /// Cancel action
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get ganaFormDeleteConfirmCancel;

  /// Run-status label
  ///
  /// In en, this message translates to:
  /// **'Succeeded'**
  String get ganaRunStatusSucceeded;

  /// Run-status label
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get ganaRunStatusSkipped;

  /// Run-status label
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get ganaRunStatusFailed;

  /// Run-status label
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get ganaRunStatusRunning;

  /// Nataraj tile action button label
  ///
  /// In en, this message translates to:
  /// **'Spark ideas'**
  String get natarajTileAction;

  /// Title of the Nataraj deck side drawer
  ///
  /// In en, this message translates to:
  /// **'Nataraj'**
  String get natarajDrawerTitle;

  /// Nataraj scope sheet title
  ///
  /// In en, this message translates to:
  /// **'Select Manas'**
  String get natarajScopeSheetTitle;

  /// Nataraj scope option — all notes (Brahma)
  ///
  /// In en, this message translates to:
  /// **'Brahma'**
  String get natarajScopeAllNotes;

  /// Nataraj scope pill label when multiple manas are selected
  ///
  /// In en, this message translates to:
  /// **'{count} manas'**
  String natarajScopeManasCount(int count);

  /// Tooltip for new nataraj chat button
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get natarajNewChatTooltip;

  /// Nataraj edge action — publish
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get natarajEdgePublish;

  /// Nataraj edge action — save as draft
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get natarajEdgeDraft;

  /// Nataraj edge action — discard
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get natarajEdgeDiscard;

  /// Nataraj edge action — discuss
  ///
  /// In en, this message translates to:
  /// **'Discuss'**
  String get natarajEdgeDiscuss;

  /// Nataraj references section label
  ///
  /// In en, this message translates to:
  /// **'References'**
  String get natarajReferencesLabel;

  /// Nataraj references action — view
  ///
  /// In en, this message translates to:
  /// **'View references'**
  String get natarajReferencesView;

  /// Nataraj references helper text
  ///
  /// In en, this message translates to:
  /// **'Publishing attaches the checked notes as references.'**
  String get natarajReferencesAttach;

  /// Nataraj coach/onboarding title
  ///
  /// In en, this message translates to:
  /// **'Swipe to explore ideas'**
  String get natarajCoachTitle;

  /// Nataraj coach dismiss button
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get natarajCoachDismiss;

  /// Nataraj generating state label
  ///
  /// In en, this message translates to:
  /// **'Finding connections…'**
  String get natarajGenerating;

  /// Nataraj hint when revisiting older generated ideas
  ///
  /// In en, this message translates to:
  /// **'Revisiting older sparks — add notes for fresh ideas'**
  String get natarajRevisitingHint;

  /// Nataraj empty state title when scope lacks notes
  ///
  /// In en, this message translates to:
  /// **'Not enough notes yet'**
  String get natarajEmptyNeedsMoreTitle;

  /// Nataraj empty state body when scope lacks notes
  ///
  /// In en, this message translates to:
  /// **'This scope needs at least 2 notes to spark connections.'**
  String get natarajEmptyNeedsMoreBody;

  /// Nataraj exhausted state title
  ///
  /// In en, this message translates to:
  /// **'You\'ve seen them all'**
  String get natarajExhaustedTitle;

  /// Nataraj exhausted state body
  ///
  /// In en, this message translates to:
  /// **'Add more notes to spark new ideas.'**
  String get natarajExhaustedBody;

  /// Nataraj error state title when the AI model fails to run
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t generate ideas'**
  String get natarajModelErrorTitle;

  /// Nataraj error state body when the AI model fails to run
  ///
  /// In en, this message translates to:
  /// **'The AI model couldn\'t run on this device. Try a different (smaller) model, or tap retry.'**
  String get natarajModelErrorBody;

  /// Nataraj state title when generation succeeded but produced nothing usable (not a model/device failure)
  ///
  /// In en, this message translates to:
  /// **'No idea this time'**
  String get natarajNoIdeaTitle;

  /// Nataraj state body when generation succeeded but produced nothing usable (not a model/device failure)
  ///
  /// In en, this message translates to:
  /// **'That combination of notes didn\'t spark anything. Nothing\'s wrong — just try again.'**
  String get natarajNoIdeaBody;

  /// Snackbar after publishing a nataraj idea
  ///
  /// In en, this message translates to:
  /// **'Published as a note'**
  String get natarajPublishedSnack;

  /// Snackbar after saving a nataraj idea as draft
  ///
  /// In en, this message translates to:
  /// **'Saved as a draft'**
  String get natarajDraftSavedSnack;

  /// Snackbar when nataraj generation fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t generate right now'**
  String get natarajGenerateErrorSnack;

  /// Author name shown on the synthesized root card in Nataraj refs page
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get natarajYouName;

  /// Handle/timestamp shown on the synthesized root card in Nataraj refs page
  ///
  /// In en, this message translates to:
  /// **'@you · now'**
  String get natarajYouHandle;

  /// Display name for unknown or resolved draft references in Nataraj refs page
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get natarajDraftLabel;

  /// Refs badge label on the synthesized root card action row in Nataraj refs page
  ///
  /// In en, this message translates to:
  /// **'{count} refs'**
  String natarajRefsCount(int count);

  /// Retry button label on the Nataraj error state
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get natarajRetry;

  /// Title of the sheet shown when content is shared into UNIUN from another app
  ///
  /// In en, this message translates to:
  /// **'Add to UNIUN'**
  String get receiveShareTitle;

  /// Composer hint on the receive-share sheet
  ///
  /// In en, this message translates to:
  /// **'Say something… (optional)'**
  String get receiveShareCommentHint;

  /// Draft button label on the receive-share sheet
  ///
  /// In en, this message translates to:
  /// **'Save to draft'**
  String get receiveShareSaveDraft;

  /// Snackbar after saving shared content as a draft
  ///
  /// In en, this message translates to:
  /// **'Saved to drafts'**
  String get receiveShareDraftSaved;

  /// Shown while shared images/videos/files are being uploaded
  ///
  /// In en, this message translates to:
  /// **'Preparing attachments…'**
  String get receiveShareIngesting;

  /// Error when trying to save a draft with no text (drafts are text-only)
  ///
  /// In en, this message translates to:
  /// **'Add some text to save a draft'**
  String get receiveShareDraftNeedsText;

  /// Error when trying to publish with no text and no attachments
  ///
  /// In en, this message translates to:
  /// **'Add text or media first'**
  String get receiveShareNothingToShare;

  /// Marker above a note in a followed note's thread that has not been opened yet
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get threadNewNote;

  /// Marker above a note in a followed note's thread when an unopened reply sits further down
  ///
  /// In en, this message translates to:
  /// **'New reply inside'**
  String get threadNewReplyInside;

  /// Shown on the jump-to-latest badge when more than 99 notes are unread
  ///
  /// In en, this message translates to:
  /// **'99+'**
  String get unreadBadgeOverflow;

  /// Line shown above the first unread note when a chat opens
  ///
  /// In en, this message translates to:
  /// **'New notes'**
  String get newNotesDivider;

  /// Tooltip on the floating button that scrolls a chat to the newest message and marks the surface read
  ///
  /// In en, this message translates to:
  /// **'Jump to latest'**
  String get jumpToLatest;

  /// Eyebrow label on the onboarding interest picker
  ///
  /// In en, this message translates to:
  /// **'Build your feed'**
  String get interestsEyebrow;

  /// Title on the onboarding interest picker
  ///
  /// In en, this message translates to:
  /// **'Tap what you love'**
  String get interestsTitle;

  /// Subtitle explaining the onboarding interest picker
  ///
  /// In en, this message translates to:
  /// **'Pick at least 3. Each one posts daily, so your feed is alive from the very first scroll.'**
  String get interestsSubtitle;

  /// Placeholder in the interest picker search box
  ///
  /// In en, this message translates to:
  /// **'Search interests…'**
  String get interestsSearchHint;

  /// Shown when an interest search matches nothing
  ///
  /// In en, this message translates to:
  /// **'No interests match that.'**
  String get interestsNoResults;

  /// Primary button on the interest picker, enabled once enough interests are chosen
  ///
  /// In en, this message translates to:
  /// **'Show me my feed'**
  String get interestsContinue;

  /// Disabled-state label on the interest picker button, shows how many more interests are needed
  ///
  /// In en, this message translates to:
  /// **'Pick {count} more to continue'**
  String interestsPickMore(int count);

  /// Secondary action to skip the interest picker
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get interestsSkip;

  /// Snackbar when following the chosen interests fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t follow everyone — please try again.'**
  String get interestsFollowFailed;

  /// Shown when fetching the onboarding interest roster from the gateway fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load interests. Check your connection.'**
  String get interestsLoadFailed;

  /// Button to retry loading the onboarding interest roster
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get interestsRetry;

  /// Link on the welcome screen that opens the full language picker
  ///
  /// In en, this message translates to:
  /// **'More languages'**
  String get welcomeMoreLanguages;

  /// App bar title of the language selection page
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get languageSelectTitle;

  /// Badge on languages that don't have translations yet
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get languageComingSoon;

  /// Settings section label for the app language
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Settings row label that opens the language picker
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get settingsAppLanguage;

  /// Empty-state message shown on the knowledge graph canvas when there are no notes yet
  ///
  /// In en, this message translates to:
  /// **'Save notes to build your knowledge graph.\n\nEdges appear when one note references another.'**
  String get graphEmptyHint;

  /// Label on the Gana detail card for the number of Manases the agent draws from
  ///
  /// In en, this message translates to:
  /// **'Manases'**
  String get ganaDetailManasesLabel;

  /// Settings section label for appearance-related options (theme mode)
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// Settings row label that opens the theme mode picker
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// Title of the bottom sheet that picks between system/light/dark theme
  ///
  /// In en, this message translates to:
  /// **'Choose theme'**
  String get settingsThemeSheetTitle;

  /// Theme option that follows the device's system theme
  ///
  /// In en, this message translates to:
  /// **'Match system'**
  String get settingsThemeSystem;

  /// Theme option that forces light mode
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// Theme option that forces dark mode
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// Settings section label for nearby-device sync
  ///
  /// In en, this message translates to:
  /// **'Nearby Sync'**
  String get settingsNearbySync;

  /// Title of the nearby-device sync toggle in settings
  ///
  /// In en, this message translates to:
  /// **'Sync with nearby devices'**
  String get meshTitle;

  /// Subtitle explaining the nearby-device sync toggle
  ///
  /// In en, this message translates to:
  /// **'Beta · Sync your notes with your other devices on the same Wi-Fi — no internet needed.'**
  String get meshSubtitle;

  /// Status line under the mesh toggle: how many peers are currently connected
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No peers} =1{1 peer} other{{count} peers}}'**
  String meshConnected(int count);

  /// Drawer entry opening the Surrounding (nearby) feed
  ///
  /// In en, this message translates to:
  /// **'Surrounding'**
  String get drawerSurrounding;

  /// App bar title of the Surrounding feed
  ///
  /// In en, this message translates to:
  /// **'Surrounding'**
  String get surroundingTitle;

  /// Empty state title for the Surrounding feed
  ///
  /// In en, this message translates to:
  /// **'Nothing nearby yet'**
  String get surroundingEmpty;

  /// Empty state subtitle for the Surrounding feed
  ///
  /// In en, this message translates to:
  /// **'Notes broadcast by nearby devices on the mesh will appear here. They\'re cleared each day.'**
  String get surroundingEmptySub;

  /// Button that saves a surrounding note before it is evicted
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get surroundingSave;

  /// Snackbar shown after keeping a surrounding note
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get surroundingSaved;

  /// Source tag shown on a note received from a nearby device in the Surrounding feed
  ///
  /// In en, this message translates to:
  /// **'📍 Nearby'**
  String get surroundingSourceLabel;

  /// No description provided for @noteCardTranslate.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get noteCardTranslate;

  /// No description provided for @translateSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Translate to'**
  String get translateSheetTitle;

  /// No description provided for @translateSheetAction.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get translateSheetAction;

  /// No description provided for @translateSheetSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'From your app language'**
  String get translateSheetSettingsHint;

  /// No description provided for @translatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Translating…'**
  String get translatingLabel;

  /// No description provided for @translatedToLabel.
  ///
  /// In en, this message translates to:
  /// **'Translated to {language}'**
  String translatedToLabel(String language);

  /// No description provided for @translationShowOriginal.
  ///
  /// In en, this message translates to:
  /// **'Show original'**
  String get translationShowOriginal;

  /// No description provided for @translationShowTranslation.
  ///
  /// In en, this message translates to:
  /// **'Show translation'**
  String get translationShowTranslation;

  /// No description provided for @translationChangeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get translationChangeLanguage;

  /// No description provided for @translationFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t translate this note. Try again.'**
  String get translationFailed;

  /// No description provided for @translationNotProduced.
  ///
  /// In en, this message translates to:
  /// **'The AI model couldn\'t translate this note. Try a larger model or UNIUN Cloud.'**
  String get translationNotProduced;

  /// No description provided for @brahmaPublishConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Publish this note?'**
  String get brahmaPublishConfirmTitle;

  /// No description provided for @brahmaPublishConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Published notes are permanent. They go out to the relay and cannot be edited or deleted. Keep it as a draft if you\'re still working on it.'**
  String get brahmaPublishConfirmBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
