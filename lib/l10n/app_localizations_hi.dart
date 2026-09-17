// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appVersion => 'UNIUN v1.0.0-beta';

  @override
  String get appTagline => 'आपके नोट्स, आपका\nनेटवर्क, आपकी पहचान।';

  @override
  String get navVishnu => 'विष्णु';

  @override
  String get navBrahma => 'ब्रह्मा';

  @override
  String get navShiv => 'शिव';

  @override
  String get actionCopy => 'कॉपी करें';

  @override
  String get actionCopied => 'कॉपी हो गया';

  @override
  String get actionRetry => 'पुनः प्रयास करें';

  @override
  String get actionContinue => 'जारी रखें';

  @override
  String get actionDelete => 'हटाएं';

  @override
  String get actionSave => 'सहेजें';

  @override
  String get actionCancel => 'रद्द करें';

  @override
  String get actionBack => 'वापस';

  @override
  String get actionDone => 'पूर्ण';

  @override
  String get actionSaved => 'सहेजा गया';

  @override
  String get actionFollow => 'फ़ॉलो करें';

  @override
  String get actionFollowing => 'फ़ॉलो किया जा रहा है';

  @override
  String get drawerHome => 'होम';

  @override
  String get drawerSavedNotes => 'सहेजे गए नोट्स';

  @override
  String get drawerGroups => 'दल';

  @override
  String get drawerDirectMessages => 'डायरेक्ट मैसेज';

  @override
  String get drawerApps => 'ऐप्स';

  @override
  String get drawerAiAssistant => 'AI सहायक';

  @override
  String get drawerSettings => 'सेटिंग्स';

  @override
  String get drawerFollowingNotes => 'नोट वॉच';

  @override
  String get drawerNoFollowedNotes => 'अभी तक किसी नोट को नहीं देख रहे';

  @override
  String get drawerNoGroups => 'अभी तक कोई दल नहीं';

  @override
  String get drawerMyQrCode => 'मेरा QR कोड';

  @override
  String get drawerScanCode => 'कोड स्कैन करें';

  @override
  String get drawerPrivateLabel => 'निजी';

  @override
  String get drawerSearchKindDm => 'डायरेक्ट मैसेज';

  @override
  String get drawerSearchKindUser => 'फ़ॉलो किया जा रहा है';

  @override
  String get joinGroupTitle => 'दल में शामिल हों';

  @override
  String get joinGroupHeading => 'मौजूदा दल में शामिल हों';

  @override
  String get joinGroupAction => 'दल में शामिल हों';

  @override
  String get joinGroupIdLabel => 'दल ID (Hex)';

  @override
  String get joinGroupRelaysTitle => 'दल रिले';

  @override
  String get joinGroupRelaysBody =>
      'सिंक शुरू करने के लिए वे रिले चुनें जिन पर यह दल चलता है।';

  @override
  String get joinGroupSelectRelays => 'रिले चुनें';

  @override
  String joinGroupSelectedRelays(int count) {
    return '$count रिले चुने गए';
  }

  @override
  String get joinGroupAddRelay => 'रिले जोड़ें';

  @override
  String get joinGroupAddRelayAction => 'जोड़ें';

  @override
  String get joinGroupRelayHint => 'wss://relay.example.com';

  @override
  String get joinGroupByQr => 'QR से शामिल हों';

  @override
  String get joinGroupScanCardTitle => 'दल QR स्कैन करें';

  @override
  String get joinGroupScanCardSubtitle =>
      'अपने कैमरे को UNIUN दल कोड की ओर रखें';

  @override
  String get joinGroupOr => 'या';

  @override
  String get joinGroupIdHint => 'दल ID पेस्ट करें';

  @override
  String get joinGroupQrTitle => 'दल QR स्कैन करें';

  @override
  String get joinGroupQrHint => 'दल ID और रिले सूची वाला QR कोड स्कैन करें।';

  @override
  String get joinGroupQrFromGallery => 'गैलरी से QR चुनें';

  @override
  String get joinGroupQrGalleryError =>
      'चुनी गई इमेज में कोई वैध QR कोड नहीं मिला।';

  @override
  String get joinGroupSuccess => 'दल में सफलतापूर्वक शामिल हो गए।';

  @override
  String get joinGroupErrorInvalidId =>
      'यह एक वैध दल ID जैसा नहीं लगता। इसे जाँचें और फिर से प्रयास करें।';

  @override
  String get joinGroupErrorNoRelay => 'कृपया कम से कम एक रिले चुनें।';

  @override
  String get joinGroupErrorRelaySaveFailed =>
      'रिले को स्थानीय रूप से सहेजने में विफल।';

  @override
  String get joinGroupErrorSaveFailed =>
      'दल में शामिल नहीं हो सके। कृपया फिर से प्रयास करें।';

  @override
  String get groupMessageHint => 'दल में संदेश भेजें…';

  @override
  String get chatMessageHint => 'संदेश…';

  @override
  String get dmEncryptedNotice => 'संदेश एंड-टू-एंड एन्क्रिप्टेड हैं';

  @override
  String get groupShareQrTitle => 'दल QR साझा करें';

  @override
  String get groupShareQrBody =>
      'किसी को सही रिले के साथ दल में शामिल होने के लिए यह QR स्कैन करने दें।';

  @override
  String get drawerNoMessages => 'अभी तक कोई संदेश नहीं';

  @override
  String get drawerSearchHint => 'खोजें';

  @override
  String get drawerSearchNoResults => 'कोई मेल नहीं';

  @override
  String get drawerCopyNpub => 'npub कॉपी करें';

  @override
  String get drawerNpubCopied => 'npub कॉपी हो गया';

  @override
  String drawerComingSoon(String feature) {
    return '$feature — जल्द आ रहा है';
  }

  @override
  String get brahmaTitle => 'ब्रह्मा';

  @override
  String get brahmaTagline => 'Nostr पर लिखें और प्रकाशित करें';

  @override
  String get brahmaHintText => 'नया नोट लिखें...';

  @override
  String get brahmaSubjectHintText => 'विषय (वैकल्पिक)';

  @override
  String get brahmaAddImage => 'इमेज जोड़ें';

  @override
  String get brahmaTagPeople => 'लोगों को टैग करें';

  @override
  String get brahmaReferenceNote => 'किसी नोट का उल्लेख करें';

  @override
  String get brahmaMentionSheetTitle => 'किसी नोट का उल्लेख करें';

  @override
  String get brahmaMentionSearchHint => 'नोट्स खोजें…';

  @override
  String get brahmaMentionEmpty => 'कोई नोट नहीं मिला';

  @override
  String get brahmaMentionSelected => 'उल्लेख किया गया';

  @override
  String get composerReferenceTitle => 'संदर्भ जोड़ें';

  @override
  String get composerReferenceSearchHint => 'खोजें…';

  @override
  String get composerReferenceEmpty => 'कोई परिणाम नहीं';

  @override
  String get composerReferenceTabAll => 'सभी';

  @override
  String get composerReferenceTabSaved => 'सहेजे गए';

  @override
  String get composerReferenceTabOwn => 'मेरे नोट्स';

  @override
  String get composerReferenceTabDrafts => 'ड्राफ़्ट';

  @override
  String get composerReferenceAdd => 'जोड़ें';

  @override
  String get composerChatPickerTitle => 'अपने नोट्स से बात करें';

  @override
  String get composerChatPickerSubtitle => 'किसी मानस तक सीमित करें';

  @override
  String get composerChatBrand => 'शिव';

  @override
  String get composerChatAllNotes => 'सभी नोट्स';

  @override
  String get composerChatAllNotesSubtitle => 'ब्रह्मा से पूछें';

  @override
  String composerChatManasNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count नोट्स',
      one: '1 नोट',
    );
    return '$_temp0';
  }

  @override
  String composerChatScopeEyebrow(String scope) {
    return '$scope · डिवाइस पर';
  }

  @override
  String composerChatGroundedHint(String scope) {
    return '$scope पर आधारित';
  }

  @override
  String get composerChatThinking => 'सोच रहा है…';

  @override
  String get composerChatStop => 'रोकें';

  @override
  String get composerChatNoModel =>
      'कोई AI मॉडल सक्रिय नहीं है। शिव टैब से कोई एक डाउनलोड करें।';

  @override
  String get composerChatError => 'कुछ गड़बड़ हो गई।';

  @override
  String get composerChatUseAsReply => 'उत्तर के रूप में उपयोग करें';

  @override
  String get threadReferencesLabel => 'संदर्भ';

  @override
  String get threadReplyingToLabel => 'इसका उत्तर दे रहे हैं';

  @override
  String get brahmaCreateNote => 'नोट बनाएं';

  @override
  String get brahmaFailedToPublish => 'प्रकाशित करने में विफल';

  @override
  String get brahmaGraphPreviewLabel => 'संदर्भ ग्राफ़ पूर्वावलोकन';

  @override
  String get brahmaInteractivePreview => 'इंटरैक्टिव पूर्वावलोकन';

  @override
  String get brahmaDraft => 'ड्राफ़्ट';

  @override
  String get markdownToolbarHeading => 'शीर्षक';

  @override
  String get markdownToolbarBold => 'बोल्ड';

  @override
  String get markdownToolbarItalic => 'इटैलिक';

  @override
  String get markdownToolbarCode => 'इनलाइन कोड';

  @override
  String get markdownToolbarBulletList => 'बुलेट सूची';

  @override
  String get markdownToolbarNumberList => 'क्रमांकित सूची';

  @override
  String get markdownToolbarQuote => 'उद्धरण';

  @override
  String get markdownToolbarLink => 'लिंक';

  @override
  String get brahmaDraftSaved => 'ड्राफ़्ट सहेजा गया';

  @override
  String get brahmaDrafts => 'ड्राफ़्ट';

  @override
  String get brahmaPublish => 'प्रकाशित करें';

  @override
  String get brahmaDraftPublished => 'नोट के रूप में प्रकाशित किया गया';

  @override
  String get brahmaTags => 'टैग';

  @override
  String get brahmaPublishChainTitle => 'यह नोट अन्य ड्राफ़्ट से जुड़ता है';

  @override
  String brahmaPublishChainSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count अप्रकाशित ड्राफ़्ट',
      one: '1 अप्रकाशित ड्राफ़्ट',
    );
    return 'Nostr नोट्स प्रकाशित होने के बाद अपरिवर्तनीय होते हैं — $_temp0 के संदर्भ केवल अभी जोड़े जा सकते हैं, बाद में नहीं।';
  }

  @override
  String get brahmaPublishChain => 'पूरी श्रृंखला प्रकाशित करें';

  @override
  String brahmaPublishChainBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count जुड़े ड्राफ़्ट',
      one: '1 जुड़े ड्राफ़्ट',
    );
    return 'पहले $_temp0 प्रकाशित करता है, फिर यह नोट उसके टैग में लिंक के साथ।';
  }

  @override
  String get brahmaPublishOnlyThis => 'केवल यही प्रकाशित करें';

  @override
  String get brahmaPublishOnlyThisSubtitle =>
      'इस नोट से ड्राफ़्ट संदर्भ हटा दें। बाकी ड्राफ़्ट जहाँ हैं वहीं रहेंगे।';

  @override
  String get vishnuNoNotes => 'अभी तक कोई नोट नहीं';

  @override
  String get vishnuCreateFirst =>
      'ब्रह्मा में अपना पहला नोट बनाएं\nया रिले के सिंक होने की प्रतीक्षा करें।';

  @override
  String get vishnuThread => 'थ्रेड';

  @override
  String vishnuReferences(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString संदर्भ',
      one: '1 संदर्भ',
    );
    return '$_temp0';
  }

  @override
  String get vishnuReferenceUnavailable => 'संदर्भित नोट उपलब्ध नहीं है';

  @override
  String vishnuNewNotesBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count नए नोट',
      one: '1 नया नोट',
    );
    return '$_temp0';
  }

  @override
  String get homeShivTitle => 'शिव — AI सहायक';

  @override
  String get homeShivComingSoon => 'डिवाइस पर AI जल्द आ रहा है।';

  @override
  String get threadTitle => 'थ्रेड';

  @override
  String get threadReplies => 'उत्तर';

  @override
  String get threadReferences => 'संदर्भ';

  @override
  String get threadNoReplies => 'अभी तक कोई उत्तर नहीं';

  @override
  String get threadBeFirstToReply => 'उत्तर देने वाले पहले व्यक्ति बनें।';

  @override
  String get threadNoReferences => 'कोई संदर्भ नहीं';

  @override
  String get threadNoReferencesDetail =>
      'अभी तक किसी नोट ने इसका संदर्भ नहीं दिया है।';

  @override
  String get threadPost => 'पोस्ट करें';

  @override
  String get threadReplyToThis => 'इस नोट का उत्तर दें…';

  @override
  String threadReplyTo(String name) {
    return '@$name को उत्तर दें…';
  }

  @override
  String threadReplyingTo(String name) {
    return '@$name को उत्तर दे रहे हैं';
  }

  @override
  String get threadContinuation => 'थ्रेड निरंतरता';

  @override
  String threadNReplies(int count) {
    return '$count उत्तर';
  }

  @override
  String threadUpdated(String time) {
    return 'अपडेट किया गया: $time';
  }

  @override
  String get followedNoteViewThread => 'थ्रेड देखें';

  @override
  String get followedNoteFailedToLoad => 'नोट लोड करने में विफल';

  @override
  String get followedNoteResearchNode => 'शोध नोड';

  @override
  String get followedNoteFollowing => 'फ़ॉलो किया जा रहा है';

  @override
  String get followedNoteReferencedBy => 'उत्तर';

  @override
  String get followedNoteReferences => 'संदर्भ';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get settingsAccount => 'खाता';

  @override
  String get settingsIdentity => 'पहचान';

  @override
  String get settingsAiShiv => 'AI · शिव';

  @override
  String get settingsStorage => 'स्टोरेज';

  @override
  String get settingsAbout => 'के बारे में';

  @override
  String get settingsVersion => 'संस्करण';

  @override
  String get settingsLogout => 'लॉग आउट';

  @override
  String get settingsLogoutTitle => 'लॉग आउट करें?';

  @override
  String get settingsLogoutBody =>
      'वापस साइन इन करने के लिए आपको अपनी प्राइवेट की (nsec) की आवश्यकता होगी। लॉग आउट करने से पहले सुनिश्चित करें कि इसका बैकअप ले लिया गया है।';

  @override
  String get settingsLogoutConfirm => 'लॉग आउट';

  @override
  String get settingsAlerts => 'अलर्ट';

  @override
  String get settingsStyle => 'स्टाइल';

  @override
  String get profileAnonymous => 'गुमनाम';

  @override
  String get profileEditProfile => 'प्रोफ़ाइल संपादित करें';

  @override
  String get identityLoginRecovery => 'यह आपका लॉगिन और रिकवरी तरीका है।';

  @override
  String get identityKeys => 'कुंजियाँ';

  @override
  String get identityRelays => 'रिले';

  @override
  String get identityPrivacyPolicy => 'गोपनीयता और नीति';

  @override
  String get identityYourKeys => 'आपकी कुंजियाँ';

  @override
  String get identityNeverShare =>
      'अपनी प्राइवेट की किसी के साथ कभी साझा न करें।';

  @override
  String get identityPublicKey => 'पब्लिक की (npub)';

  @override
  String get identityPublicKeyCopied => 'पब्लिक की कॉपी हो गई';

  @override
  String get identityPrivateKey => 'प्राइवेट की (nsec)';

  @override
  String get identityRevealPrivateKey => 'प्राइवेट की दिखाएं';

  @override
  String get identityNeverShareKey => 'यह कुंजी कभी साझा न करें';

  @override
  String get identityTapToCopy => 'कॉपी करने के लिए टैप करें';

  @override
  String get identityHide => 'छिपाएं';

  @override
  String get identityPrivateKeyCopied =>
      'प्राइवेट की कॉपी हो गई — इसे सुरक्षित रखें!';

  @override
  String get identityRelaysSheetTitle => 'रिले';

  @override
  String get identityRelaysSubtitle =>
      'Nostr रिले जिनसे आपका क्लाइंट जुड़ता है।';

  @override
  String get identityRelaysComingSoon => 'कस्टम रिले प्रबंधन जल्द आ रहा है।';

  @override
  String get alertsDmAlerts => 'DM अलर्ट';

  @override
  String get alertsGroupAlerts => 'दल अलर्ट';

  @override
  String get storageUsage => 'स्टोरेज उपयोग';

  @override
  String get storageNoteData => 'नोट डेटा';

  @override
  String get storageAiModels => 'AI मॉडल';

  @override
  String get storageAiModelsSubtitle => 'डाउनलोड की गई मॉडल फ़ाइलें';

  @override
  String get storageTotal => 'कुल';

  @override
  String storageNotes(int count) {
    return '$count नोट्स';
  }

  @override
  String get storageRemoveData => 'डेटा हटाएं';

  @override
  String get storageShowMetrics => 'मेट्रिक्स दिखाएं';

  @override
  String get storageUsed => 'उपयोग किया गया';

  @override
  String storageFree(String size) {
    return '$size खाली';
  }

  @override
  String get storageDeleteDialogTitle => 'फ़ीड नोट्स हटाएं';

  @override
  String storageDeleteDialogBody(int count) {
    return 'इससे स्थानीय स्टोरेज से $count फ़ीड नोट्स हट जाएंगे।\n\nआपके अपने नोट्स, सहेजे गए नोट्स और देखे जा रहे नोट्स प्रभावित नहीं होंगे।';
  }

  @override
  String get storageDeleteConfirm => 'हटाएं';

  @override
  String storageDeleteSuccess(int count) {
    return '$count नोट्स हटाए गए';
  }

  @override
  String get storageNothingToDelete => 'हटाने के लिए कोई फ़ीड नोट नहीं';

  @override
  String get storageChatHistory => 'चैट इतिहास';

  @override
  String get storageOther => 'अन्य';

  @override
  String get storageDeleteFeedNotes => 'फ़ीड नोट्स हटाएं';

  @override
  String storageDeleteFeedNotesSubtitle(int count) {
    return '$count फ़ीड नोट्स · आपके अपने, सहेजे गए और देखे जा रहे नोट्स प्रभावित नहीं होते';
  }

  @override
  String get storageDeleteChatHistory => 'चैट इतिहास हटाएं';

  @override
  String get storageDeleteChatHistorySubtitle => 'सभी शिव बातचीत और संदेश';

  @override
  String get storageDeleteChatHistorySuccess => 'चैट इतिहास हटा दिया गया';

  @override
  String get storageDeleteChatHistoryDialogBody =>
      'इससे सभी शिव बातचीत और संदेश स्थायी रूप से हट जाएंगे। इसे पूर्ववत नहीं किया जा सकता।';

  @override
  String get styleTheme => 'थीम';

  @override
  String get styleThemeLight => 'लाइट';

  @override
  String get styleThemeDark => 'डार्क';

  @override
  String get styleThemeSystem => 'सिस्टम';

  @override
  String get styleAccent => 'एक्सेंट';

  @override
  String get aiSelectModel => 'मॉडल चुनें';

  @override
  String get settingsDeviceAiModel => 'डिवाइस AI मॉडल';

  @override
  String get aiModelNoneSelected => 'कोई मॉडल डाउनलोड नहीं किया गया';

  @override
  String get aiClearCache => 'AI कैश साफ़ करें';

  @override
  String get aiModelSelectionTitle => 'AI मॉडल चयन';

  @override
  String get aiModelSelectionSubtitle =>
      'अपने डिवाइस की क्षमताओं के अनुकूल बुद्धिमत्ता स्तर चुनें।';

  @override
  String get aiModelAvailableHeader => 'उपलब्ध मॉडल';

  @override
  String get aiModelCloudTitle => 'UNIUN क्लाउड';

  @override
  String get aiModelCloudSubtitle =>
      'डाउनलोड की ज़रूरत नहीं — शिव आपकी पहचान के साथ UNIUN के सर्वर पर चलता है।';

  @override
  String get aiModelCloudBadge => 'बिना डाउनलोड';

  @override
  String get aiModelRecommendedBadge => 'अनुशंसित';

  @override
  String get aiModelUseThisButton => 'यह मॉडल उपयोग करें';

  @override
  String get aiModelDownloadInfoText =>
      'मॉडल बदलने के लिए एक बार डाउनलोड करना होगा। डेटा शुल्क से बचने के लिए Wi-Fi से कनेक्ट करें। आपका चैट इतिहास सुरक्षित रहता है।';

  @override
  String aiModelOrphanedFilesText(String size) {
    return '$size बची हुई मॉडल फ़ाइलें साफ़ की जा सकती हैं।';
  }

  @override
  String get aiModelCleanUpAction => 'साफ़ करें';

  @override
  String aiModelCleanUpSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count फ़ाइलें',
      one: '1 फ़ाइल',
    );
    return '$_temp0 साफ़ की गईं।';
  }

  @override
  String get aiModelCleanUpFailed => 'बची हुई फ़ाइलें साफ़ नहीं की जा सकीं।';

  @override
  String get aiModelOptimizedCpu => 'CPU के लिए अनुकूलित';

  @override
  String get aiModelOptimizedGpuCpu => 'GPU / CPU के लिए अनुकूलित';

  @override
  String get aiModelOptimizedGpu => 'GPU के लिए अनुकूलित';

  @override
  String aiModelDownloadingProgress(int percent) {
    return 'डाउनलोड हो रहा है… $percent%';
  }

  @override
  String get aiModelAlreadyActive => 'सक्रिय';

  @override
  String get aiModelDownloaded => 'डाउनलोड किया गया';

  @override
  String get aiModelSetActive => 'सक्रिय के रूप में सेट करें';

  @override
  String get aiModelDownloadError => 'डाउनलोड विफल। कृपया फिर से प्रयास करें।';

  @override
  String get aiModelQwen25Name => 'Qwen3 0.6B';

  @override
  String get aiModelQwen25Desc =>
      'फ़ंक्शन कॉलिंग के साथ कॉम्पैक्ट बहुभाषी चैट। 3 GB+ RAM वाले किसी भी डिवाइस पर काम करता है।';

  @override
  String get aiModelDeepSeekR1Name => 'DeepSeek R1';

  @override
  String get aiModelDeepSeekR1Desc =>
      'उच्च-प्रदर्शन तर्क और कोड जनरेशन। 4 GB+ RAM की आवश्यकता है।';

  @override
  String get aiModelGemma4E2bName => 'Gemma 4 E2B';

  @override
  String get aiModelGemma4E2bDesc =>
      'अगली पीढ़ी की मल्टीमॉडल चैट — टेक्स्ट, इमेज, ऑडियो। 6 GB+ RAM की आवश्यकता है।';

  @override
  String get aiModelGemma4E4bName => 'Gemma 4 E4B';

  @override
  String get aiModelGemma4E4bDesc =>
      'अगली पीढ़ी की मल्टीमॉडल चैट — टेक्स्ट, इमेज, ऑडियो। 8 GB+ RAM वाले फ्लैगशिप डिवाइस पर सर्वोत्तम।';

  @override
  String get aiEmbeddingSetupInProgress => 'AI सुविधाएँ सेट की जा रही हैं…';

  @override
  String get editProfileTitle => 'प्रोफ़ाइल संपादित करें';

  @override
  String get editProfileSaved => 'प्रोफ़ाइल सहेजी गई';

  @override
  String get editProfileDisplayName => 'प्रदर्शित नाम';

  @override
  String get editProfileUsername => 'उपयोगकर्ता नाम';

  @override
  String get editProfileAbout => 'के बारे में';

  @override
  String get editProfileAvatarUrl => 'अवतार URL';

  @override
  String get editProfileNip05 => 'NIP-05 पहचानकर्ता';

  @override
  String get editProfileDisplayNameHint => 'जैसे Satoshi';

  @override
  String get editProfileUsernameHint => 'जैसे satoshi';

  @override
  String get editProfileAboutHint => 'दुनिया को बताएं कि आप कौन हैं…';

  @override
  String get editProfileAvatarUrlHint => 'https://…';

  @override
  String get editProfileNip05Hint => 'you@yourdomain.com';

  @override
  String get editProfileSaveButton => 'प्रोफ़ाइल सहेजें';

  @override
  String get editProfileEyebrow => 'सार्वजनिक प्रोफ़ाइल';

  @override
  String get editProfileSubtitle =>
      'अपडेट करें कि UNIUN पर दूसरे आपको कैसे देखते हैं।';

  @override
  String get editProfileEncrypted =>
      'केवल आपके सार्वजनिक विवरण साझा किए जाते हैं।';

  @override
  String get welcomeTagline =>
      '*बनाएं* · *साझा करें*\n*चिंतन करें* · *रूपांतरित करें*';

  @override
  String get welcomeCreateIdentity => 'अपना अवतार बनाएं';

  @override
  String get welcomeImportKey => 'अपना अवतार पुनर्स्थापित करें';

  @override
  String get welcomeLearnHow => 'जानें UNIUN कैसे काम करता है';

  @override
  String get welcomeSubtitleLead => 'आपका विकेंद्रीकृत ';

  @override
  String get welcomeSubtitleEmphasis => 'दूसरा दिमाग';

  @override
  String get welcomePillarBrahma => 'ब्रह्मा';

  @override
  String get welcomePillarVishnu => 'विष्णु';

  @override
  String get welcomePillarShiv => 'शिव';

  @override
  String get welcomeRoleCreate => 'बनाएं';

  @override
  String get welcomeRoleReflect => 'चिंतन करें';

  @override
  String get welcomeRoleTransform => 'रूपांतरित करें';

  @override
  String get howItWorksSkip => 'छोड़ें';

  @override
  String get howItWorksNext => 'आगे';

  @override
  String get howItWorksGetStarted => 'शुरू करें';

  @override
  String get howItWorksIntroTitle => 'आपका दूसरा दिमाग, आपकी जेब में';

  @override
  String get howItWorksIntroBody =>
      'UNIUN एक शांत जगह है जहाँ आप अपने विचारों को संजो सकते हैं, अपने आइडिया जोड़ सकते हैं और उन पर चिंतन कर सकते हैं — सब कुछ एक ऐप में जो सचमुच आपका है।';

  @override
  String get howItWorksBrahmaTitle => 'ब्रह्मा — संजोएं और जोड़ें';

  @override
  String get howItWorksBrahmaBody =>
      'विचारों को संजोने और उन्हें कुछ स्थायी रूप में ढालने की आपकी जगह।';

  @override
  String get howItWorksVishnuTitle => 'विष्णु — आपके लोग और स्थान';

  @override
  String get howItWorksVishnuBody =>
      'लोगों और समुदायों से अपने तरीके से जुड़ें।';

  @override
  String get howItWorksShivTitle => 'शिव — आपके डिवाइस पर AI';

  @override
  String get howItWorksShivBody =>
      'डिवाइस पर मौजूद AI जो आपके नोट्स के साथ सोचता है।';

  @override
  String get howItWorksTileNote => 'नोट';

  @override
  String get howItWorksDescNote => 'टेक्स्ट, इमेज और लिंक लिखें';

  @override
  String get howItWorksTileManas => 'मानस';

  @override
  String get howItWorksDescManas => 'नोट्स को अपने संग्रहों में समूहित करें';

  @override
  String get howItWorksTileGraph => 'ग्राफ़';

  @override
  String get howItWorksDescGraph =>
      'जुड़े हुए नोट्स आपका नॉलेज ग्राफ़ बन जाते हैं';

  @override
  String get howItWorksTilePeople => 'लोग';

  @override
  String get howItWorksDescPeople =>
      'अपनी फ़ीड को आकार देने के लिए लोगों को फ़ॉलो करें';

  @override
  String get howItWorksTileGroups => 'दल';

  @override
  String get howItWorksDescGroups =>
      'विषयों के इर्द-गिर्द जुड़ने के लिए सार्वजनिक कक्ष';

  @override
  String get howItWorksTilePrivate => 'निजी';

  @override
  String get howItWorksDescPrivate => 'एन्क्रिप्टेड, केवल-आमंत्रण वाले दल';

  @override
  String get howItWorksTileDms => 'डायरेक्ट मैसेज';

  @override
  String get howItWorksDescDms => 'निजी आमने-सामने की बातचीत';

  @override
  String get howItWorksTileAdiyogi => 'आदियोगी';

  @override
  String get howItWorksDescAdiyogi => 'अपने नोट्स के बारे में कुछ भी पूछें';

  @override
  String get howItWorksTileNataraj => 'नटराज';

  @override
  String get howItWorksDescNataraj =>
      'नोट्स को नए विचारों में बदलने के लिए स्वाइप करें';

  @override
  String get howItWorksTileGana => 'गण';

  @override
  String get howItWorksDescGana => 'एजेंट जो पृष्ठभूमि में काम करते हैं';

  @override
  String get howItWorksKeysTitle => 'आपकी पहचान आपकी अपनी है';

  @override
  String get howItWorksKeysBody =>
      'कोई ईमेल नहीं, कोई पासवर्ड नहीं, कोई खाता नहीं। UNIUN आपको एक प्राइवेट की देता है जो केवल आपके डिवाइस पर रहती है — यही आपकी पहचान है, और केवल आपके पास है।';

  @override
  String get howItWorksPrivateTitle => 'निजी और हमेशा आपकी';

  @override
  String get howItWorksPrivateBody =>
      'UNIUN ऑफ़लाइन काम करता है और इसका AI सीधे आपके डिवाइस पर चलता है — कुछ भी क्लाउड पर नहीं जाता। आपके नोट्स आपके पास रहते हैं, और वे आपके रखने के लिए हैं।';

  @override
  String get howItWorksReadyTitle => 'शुरू करने के लिए तैयार हैं?';

  @override
  String get howItWorksReadyBody =>
      'अपना अवतार बनाएं और अपना दूसरा दिमाग बनाना शुरू करें। इसमें बस एक पल लगता है।';

  @override
  String get aboutYouEyebrow => 'अपना अवतार बनाएं';

  @override
  String get aboutYouTitle => 'आपके बारे में';

  @override
  String get aboutYouSubtitle =>
      'अपना अवतार सेट करें। प्रदर्शित नाम और उपयोगकर्ता नाम आवश्यक हैं।';

  @override
  String get aboutYouAvatarCaption => 'स्वतः-जनित';

  @override
  String get aboutYouDisplayNameLabel => 'प्रदर्शित नाम *';

  @override
  String get aboutYouDisplayNameHint => 'हम आपको क्या कहकर बुलाएं?';

  @override
  String get aboutYouUsernameLabel => 'उपयोगकर्ता नाम *';

  @override
  String get aboutYouUsernameHint => 'उपयोगकर्ता नाम';

  @override
  String get aboutYouUsernameHelper => 'उल्लेख और खोज के लिए अनोखा हैंडल।';

  @override
  String get aboutYouBioLabel => 'बायो  (वैकल्पिक)';

  @override
  String get aboutYouBioHint => 'दुनिया को अपने बारे में थोड़ा बताएं…';

  @override
  String get aboutYouEncrypted => 'आपका डेटा एन्क्रिप्टेड और निजी है।';

  @override
  String get aboutYouDisplayNameRequired => 'प्रदर्शित नाम आवश्यक है';

  @override
  String get aboutYouUsernameRequired => 'उपयोगकर्ता नाम आवश्यक है';

  @override
  String get importTitle => 'वापसी पर स्वागत है';

  @override
  String get importSubtitle =>
      'अपने मौजूदा अवतार को पुनर्स्थापित करने के लिए अपनी प्राइवेट की पेस्ट करें।';

  @override
  String get importPrivateKeyLabel => 'प्राइवेट की';

  @override
  String get importPasteFromClipboard => 'क्लिपबोर्ड से पेस्ट करें';

  @override
  String get importKeyHint => 'nsec1... या 64-वर्ण की hex कुंजी';

  @override
  String get importSecurityNote =>
      'आपकी प्राइवेट की स्थानीय रूप से संसाधित होती है और कभी किसी सर्वर पर नहीं भेजी जाती।';

  @override
  String get importContinue => 'इम्पोर्ट करें और जारी रखें';

  @override
  String get importPasteFirst => 'कृपया पहले अपनी प्राइवेट की पेस्ट करें।';

  @override
  String get importFailed =>
      'कुंजी इम्पोर्ट करने में विफल। कृपया फिर से प्रयास करें।';

  @override
  String get importInvalidKey =>
      'अमान्य कुंजी। कृपया जाँचें और फिर से प्रयास करें।';

  @override
  String get importEyebrow => 'अपना अवतार पुनर्स्थापित करें';

  @override
  String get importScanQrButton => 'इसके बजाय QR स्कैन करें';

  @override
  String get importScanTitle => 'अपनी कुंजी का QR स्कैन करें';

  @override
  String get importScanHint =>
      'अपने कैमरे को उस QR की ओर रखें जिसमें आपकी प्राइवेट की हो';

  @override
  String get keysTitle => 'आपकी अवतार कुंजियाँ';

  @override
  String get keysSubtitle =>
      'एक साझा करने के लिए है। एक केवल आपकी नज़रों के लिए है।';

  @override
  String get keysEyebrow => 'आपकी अवतार कुंजियाँ';

  @override
  String get keysHeadline => 'आपकी कुंजियाँ ही आपका अवतार हैं।';

  @override
  String get keysPublicKeyTitle => 'पब्लिक की';

  @override
  String get keysPublicKeySubtitle =>
      'संदेश पाने के लिए दूसरों के साथ साझा करें।';

  @override
  String get keysPrivateKeyTitle => 'प्राइवेट की';

  @override
  String get keysPrivateKeySubtitle =>
      'इसे कभी साझा न करें। यह आपकी पहचान तक पूरी पहुँच देती है।';

  @override
  String get keysPrivateKeyWarning =>
      'यह कुंजी खोना = अपना खाता हमेशा के लिए खोना।';

  @override
  String get keysSaveAndContinue => 'सहेजें और जारी रखें';

  @override
  String get keysE2eEncrypted => 'E2E एन्क्रिप्टेड';

  @override
  String get keysAgreePrefix => 'मैं सहमत हूँ ';

  @override
  String get keysAgreeTerms => 'नियम और शर्तें';

  @override
  String get keysAgreeConjunction => ' और ';

  @override
  String get keysAgreePrivacy => 'गोपनीयता नीति';

  @override
  String get keysPublicCopied =>
      'पब्लिक की कॉपी हो गई — अब अपनी प्राइवेट की दिखाएं';

  @override
  String get keysPrivateCopied =>
      'प्राइवेट की कॉपी हो गई — इसे कहीं सुरक्षित रखें!';

  @override
  String keysFailedToSave(String error) {
    return 'कुंजियाँ सहेजने में विफल: $error';
  }

  @override
  String get keysCopyPublicAbove =>
      'अपनी प्राइवेट की दिखाने के लिए ऊपर अपनी पब्लिक की कॉपी करें।';

  @override
  String get privacyPageTitle => 'गोपनीयता और नीति';

  @override
  String get privacyIntroTitle => 'गोपनीयता और नीति';

  @override
  String get privacyIntroBody =>
      'UNIUN पारदर्शिता पर बना है। आपका डेटा आपके डिवाइस पर रहता है। नीचे वह सब कुछ है जो आपको जानना चाहिए — कोई कानूनी शब्दजाल नहीं।';

  @override
  String get privacyExpandPrivacy => 'गोपनीयता नीति';

  @override
  String get privacyExpandTerms => 'उपयोग की शर्तें';

  @override
  String get privacyLastUpdated => 'अंतिम अपडेट: जून 2026';

  @override
  String get privacyContactEmail => 'info@uniun.in';

  @override
  String get privacyStoredLocallyTitle =>
      'हम स्थानीय रूप से क्या संग्रहीत करते हैं';

  @override
  String get privacyStoredLocallyBody =>
      'UNIUN आपके नोट्स, प्रोफ़ाइल, सहेजे गए आइटम, दल संदेश और सेटिंग्स सीधे आपके डिवाइस पर संग्रहीत करता है। यह डेटा UNIUN द्वारा नियंत्रित किसी सर्वर पर नहीं भेजा जाता।';

  @override
  String get privacySharedPubliclyTitle => 'सार्वजनिक रूप से क्या साझा होता है';

  @override
  String get privacySharedPubliclyBody =>
      'जब आप कोई नोट प्रकाशित करते हैं या किसी सार्वजनिक दल में संदेश भेजते हैं, तो वह सामग्री Nostr रिले पर प्रसारित होती है। Nostr एक खुला सार्वजनिक प्रोटोकॉल है — एक बार प्रकाशित होने के बाद, आपके नोट्स उन रिले से जुड़े किसी भी व्यक्ति को दिख सकते हैं। UNIUN तीसरे-पक्ष के रिले को नियंत्रित नहीं करता।';

  @override
  String get privacyIdentityKeysTitle => 'आपकी पहचान और कुंजियाँ';

  @override
  String get privacyIdentityKeysBody =>
      'आपकी पहचान एक क्रिप्टोग्राफ़िक कुंजी जोड़ी है। आपकी पब्लिक की Nostr नेटवर्क पर दूसरों को दिखाई देती है। आपकी प्राइवेट की (nsec) विशेष रूप से आपके डिवाइस के सुरक्षित सिस्टम कीचेन (iOS Keychain / Android Keystore) में संग्रहीत होती है। UNIUN आपकी प्राइवेट की कभी किसी सर्वर पर नहीं भेजता।';

  @override
  String get privacyLocalAiTitle => 'स्थानीय AI (शिव)';

  @override
  String get privacyLocalAiBody =>
      'शिव AI सहायक पूरी तरह आपके डिवाइस पर चलता है। यह केवल आपके स्थानीय रूप से सहेजे गए नोट्स तक पहुँचता है। कोई भी नोट सामग्री किसी बाहरी AI सेवा या API को नहीं भेजी जाती।';

  @override
  String get privacyMediaTitle => 'मीडिया और Blossom सर्वर';

  @override
  String get privacyMediaBody =>
      'यदि आप इमेज या मीडिया संलग्न करते हैं, तो उन्हें आपकी पसंद के किसी Blossom कंटेंट सर्वर पर अपलोड किया जा सकता है। UNIUN Blossom सर्वर संचालित नहीं करता। वहाँ अपलोड की गई सामग्री प्रोटोकॉल के डिज़ाइन के अनुसार सार्वजनिक रूप से सुलभ हो सकती है।';

  @override
  String get privacyDmsTitle => 'डायरेक्ट मैसेज';

  @override
  String get privacyDmsBody =>
      'DM, Nostr NIP-17 मानक का उपयोग करके एंड-टू-एंड एन्क्रिप्टेड हैं। केवल इच्छित प्राप्तकर्ता ही संदेश की सामग्री पढ़ सकता है। संदेश रूटिंग मेटाडेटा रिले को दिखाई दे सकता है।';

  @override
  String get privacyControlTitle => 'आपका नियंत्रण';

  @override
  String get privacyControlBody =>
      'आप सेटिंग्स से किसी भी समय अपना स्थानीय डेटा हटा सकते हैं। चूँकि Nostr एक सार्वजनिक प्रोटोकॉल है, रिले पर पहले से प्रकाशित नोट्स वापस नहीं लिए जा सकते — यह नेटवर्क का एक जानबूझकर रखा गया गुण है, ऐप की सीमा नहीं।';

  @override
  String get privacyContactTitle => 'संपर्क';

  @override
  String get privacyContactBody =>
      'गोपनीयता संबंधी प्रश्नों के लिए: info@uniun.in';

  @override
  String get termsResponsibilityTitle => 'आपकी ज़िम्मेदारी';

  @override
  String get termsResponsibilityBody =>
      'UNIUN पर आपके द्वारा प्रकाशित सभी सामग्री के लिए आप पूरी तरह ज़िम्मेदार हैं। ऐप का उपयोग करके, आप ऐसी सामग्री पोस्ट न करने के लिए सहमत होते हैं जो अवैध, अपमानजनक, उत्पीड़क, घृणास्पद, यौन रूप से स्पष्ट हो, या दूसरों के अधिकारों का उल्लंघन करती हो। आपत्तिजनक सामग्री और अपमानजनक व्यवहार UNIUN पर स्वीकार्य नहीं हैं।';

  @override
  String get termsNoAbuseTitle => 'कोई दुरुपयोग या स्पैम नहीं';

  @override
  String get termsNoAbuseBody =>
      'UNIUN का उपयोग स्पैम करने, उत्पीड़न करने, दूसरों का प्रतिरूपण करने, या Nostr नेटवर्क को बाधित करने वाली स्वचालित गतिविधि के लिए न करें। UNIUN विकेंद्रीकृत है: किसी भी नोट के मेन्यू में एक रिपोर्ट विकल्प शामिल है (श्रेणियाँ: नग्नता, मैलवेयर, अपशब्द, अवैध, स्पैम, प्रतिरूपण, अन्य) और किसी भी उपयोगकर्ता को सेटिंग्स → ब्लॉक किए गए उपयोगकर्ता से ब्लॉक किया जा सकता है। रिपोर्ट किए गए नोट्स तुरंत आपकी फ़ीड से छिप जाते हैं और ब्लॉक किए गए उपयोगकर्ताओं की सामग्री कभी आप तक नहीं पहुँचती। रिपोर्ट Nostr नेटवर्क पर भी प्रकाशित होती हैं ताकि अन्य क्लाइंट और रिले संचालक उन पर कार्रवाई कर सकें।';

  @override
  String get termsPrivateKeyTitle => 'अपनी प्राइवेट की सुरक्षित रखें';

  @override
  String get termsPrivateKeyBody =>
      'आपकी प्राइवेट की (nsec) आपकी पहचान और लॉगिन है। यदि आप इसे खो देते हैं, तो आपका खाता पुनर्प्राप्त नहीं किया जा सकता — UNIUN के पास प्राइवेट की को रीसेट या पुनर्प्राप्त करने का कोई तरीका नहीं है। इसे किसी सुरक्षित स्थान पर बैकअप करें।';

  @override
  String get termsPublicContentTitle => 'रिले पर सार्वजनिक सामग्री';

  @override
  String get termsPublicContentBody =>
      'आपके द्वारा प्रकाशित नोट्स और दल संदेश Nostr रिले पर भेजे जाते हैं और नेटवर्क पर किसी को भी दिख सकते हैं। सार्वजनिक नोट्स में संवेदनशील व्यक्तिगत जानकारी साझा न करें।';

  @override
  String get termsAppMayChangeTitle => 'ऐप बदल सकता है';

  @override
  String get termsAppMayChangeBody =>
      'UNIUN सक्रिय विकास के अधीन है। सुविधाएँ, रिले व्यवहार और नीतियाँ समय के साथ बदल सकती हैं। हम ऐप के भीतर महत्वपूर्ण अपडेट के बारे में सूचित करेंगे।';

  @override
  String get termsNoWarrantyTitle => 'कोई वारंटी नहीं';

  @override
  String get termsNoWarrantyBody =>
      'UNIUN जैसा है वैसा ही प्रदान किया जाता है। हम रिले अपटाइम, तीसरे-पक्ष सर्वर उपलब्धता, या बाहरी रिले पर सामग्री के बने रहने की कोई गारंटी नहीं देते।';

  @override
  String get shivName => 'शिव';

  @override
  String get shivTagline => 'थ्रेड्स में सोचें';

  @override
  String get shivLandingBody => 'आपका डिवाइस पर मौजूद AI.\nथ्रेड्स में सोचें।';

  @override
  String get shivNoModelBody =>
      'शिव से चैट करना शुरू करने के लिए एक AI मॉडल डाउनलोड करें। सेटअप के बाद सब कुछ आपके डिवाइस पर चलता है — इंटरनेट की ज़रूरत नहीं।';

  @override
  String get shivSetUpAi => 'AI सेट करें';

  @override
  String get shivNewConversation => 'नई बातचीत';

  @override
  String shivViewConversations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बातचीत देखें',
      one: '1 बातचीत देखें',
    );
    return '$_temp0';
  }

  @override
  String get shivConversations => 'बातचीत';

  @override
  String get shivNewConversationTooltip => 'नई बातचीत';

  @override
  String get shivConversationsTooltip => 'बातचीत';

  @override
  String get shivBranchTreeTooltip => 'ब्रांच ट्री';

  @override
  String get shivBranchTreeComingSoon => 'ब्रांच ट्री — चरण 4 में आ रहा है';

  @override
  String get shivConversationTree => 'बातचीत ट्री';

  @override
  String get shivNodeOpenBranch => 'ब्रांच खोलें';

  @override
  String get shivNodeContinueFromHere => 'यहाँ से जारी रखें';

  @override
  String get shivNodeNewBranch => 'नई ब्रांच';

  @override
  String get shivActiveBranch => 'सक्रिय ब्रांच';

  @override
  String shivNodeMessages(int count) {
    return '$count संदेश';
  }

  @override
  String get shivDefaultConversationTitle => 'नई बातचीत';

  @override
  String get shivEmptyTitle => 'एक बातचीत शुरू करें';

  @override
  String get shivEmptyBody =>
      'शिव से कुछ भी पूछें — आपके सहेजे गए नोट्स\nइसे संदर्भ देते हैं कि आप क्या जानते हैं।';

  @override
  String get shivEmptyTreeTitle => 'अभी तक कोई संदेश नहीं';

  @override
  String get shivEmptyTreeBody =>
      'ब्रांच ट्री यहाँ देखने के लिए\nएक बातचीत शुरू करें।';

  @override
  String get shivThinking => 'सोच रहा है…';

  @override
  String get shivThinkingLabel => 'तर्क';

  @override
  String shivSourcesChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'स्रोत · $count',
      one: 'स्रोत · 1',
    );
    return '$_temp0';
  }

  @override
  String get shivSourcesSheetTitle => 'स्रोत';

  @override
  String get shivSourcesEmpty => 'इस उत्तर के लिए कोई स्रोत नोट नहीं';

  @override
  String get shivInputHint => 'शिव से कुछ भी पूछें…';

  @override
  String get shivHomeHeadline => 'मैं आपकी कैसे मदद कर सकता हूँ?';

  @override
  String get shivHomeHistoryTooltip => 'इतिहास';

  @override
  String get shivHomeGana => 'गण';

  @override
  String get shivHomeNataraj => 'नटराज';

  @override
  String get shivHomeSuggestSummarize => 'मेरे सप्ताह का सारांश दें';

  @override
  String get shivHomeSuggestConnect => 'दो विचारों को जोड़ें';

  @override
  String get shivHomeSuggestDraft => 'किसी नोट से ड्राफ़्ट बनाएं';

  @override
  String composerAskScope(String scope) {
    return '$scope से पूछें';
  }

  @override
  String get shivNoConversations => 'अभी तक कोई बातचीत नहीं';

  @override
  String get shivActiveLabel => 'सक्रिय';

  @override
  String get shivTimeJustNow => 'अभी-अभी';

  @override
  String shivTimeMinutesAgo(int count) {
    return '$count मिनट पहले';
  }

  @override
  String shivTimeHoursAgo(int count) {
    return '$count घंटे पहले';
  }

  @override
  String shivTimeDaysAgo(int count) {
    return '$count दिन पहले';
  }

  @override
  String get savedNotesTitle => 'सहेजे गए नोट्स';

  @override
  String get savedNotesSearch => 'सहेजे गए नोट्स खोजें…';

  @override
  String get savedNotesEmpty => 'अभी तक कुछ सहेजा नहीं गया';

  @override
  String get savedNotesEmptySub =>
      'बाद में पढ़ने के लिए अपनी फ़ीड से नोट्स बुकमार्क करें।';

  @override
  String get graphLegendSaved => 'सहेजे गए';

  @override
  String get graphLegendOwn => 'अपने';

  @override
  String get graphLegendDraft => 'ड्राफ़्ट';

  @override
  String get graphFabTextNote => 'टेक्स्ट नोट';

  @override
  String get graphFabReferenceNote => 'संदर्भ नोट';

  @override
  String get graphDraftEdit => 'संपादित करें';

  @override
  String get graphDraftDelete => 'हटाएं';

  @override
  String get graphScopeAllNotes => 'सभी नोट्स';

  @override
  String get graphSearchHint => 'ग्राफ़ खोजें…';

  @override
  String get graphSearchTooltip => 'ग्राफ़ खोजें';

  @override
  String get graphMenuTooltip => 'मानस ड्रॉअर खोलें';

  @override
  String get graphSearchClear => 'खोज साफ़ करें';

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
  String get groupEntryTitle => 'दल';

  @override
  String get groupEntrySubtitle =>
      'किसी मौजूदा सार्वजनिक दल में उसकी ID या QR का उपयोग करके शामिल हों, या नया शुरू करें।';

  @override
  String get groupEntryJoin => 'किसी दल में शामिल हों';

  @override
  String get groupEntryCreate => 'एक दल बनाएं';

  @override
  String get privateGroupEntryTitle => 'निजी दल';

  @override
  String get privateGroupEntrySubtitle =>
      'किसी मौजूदा निजी दल में शामिल होने का अनुरोध करें, या अपना खुद का बनाएं।';

  @override
  String get privateGroupEntryJoin => 'किसी निजी दल में शामिल हों';

  @override
  String get privateGroupEntryCreate => 'एक निजी दल बनाएं';

  @override
  String get createGroupTitle => 'दल';

  @override
  String get createGroupHeaderTitle => 'दल बनाएं';

  @override
  String get createGroupDetailsHeading => 'दल विवरण';

  @override
  String get createGroupNameLabel => 'दल का नाम';

  @override
  String get createGroupNamePlaceholder => 'जैसे design';

  @override
  String get createGroupAboutLabel => 'के बारे में (थीम/नियम)';

  @override
  String get createGroupDescriptionLabel => 'विवरण';

  @override
  String get createGroupAboutPlaceholder => 'यह दल किस बारे में है?';

  @override
  String get createGroupPictureLabel => 'तस्वीर URL (वैकल्पिक)';

  @override
  String get createGroupPermanenceNote =>
      'दल की पहली घटना उसकी स्थायी ID बन जाती है — इसे कभी हटाया नहीं जा सकता।';

  @override
  String get createGroupAdvancedRelays => 'उन्नत · रिले';

  @override
  String get createGroupPublishRelays => 'प्रकाशन रिले';

  @override
  String get createGroupPublishRelaysBody =>
      'वे रिले चुनें जिन पर यह दल प्रसारित होना चाहिए।';

  @override
  String get createGroupAction => 'दल बनाएं';

  @override
  String get createGroupSuccess => 'दल सफलतापूर्वक बनाया गया';

  @override
  String get createPrivateGroupTitle => 'निजी दल बनाएं';

  @override
  String get createPrivateGroupEncrypted => 'एन्क्रिप्टेड';

  @override
  String get createPrivateGroupNameHint => 'जैसे core team';

  @override
  String get createPrivateGroupDescHint => 'यह दल किस बारे में है?';

  @override
  String get createPrivateGroupAdminNote =>
      'आप एडमिन हैं — आप तय करते हैं कौन शामिल होगा।';

  @override
  String get createPrivateGroupHeading => 'एक नया निजी दल शुरू करें';

  @override
  String get createPrivateGroupDescription =>
      'निजी दल एंड-टू-एंड एन्क्रिप्टेड होते हैं। सदस्यों को शामिल होने का अनुरोध करना होता है, और एडमिन को उन्हें स्वीकृत करना होता है।';

  @override
  String get createPrivateGroupNameLabel => 'दल का नाम';

  @override
  String get createPrivateGroupDescLabel => 'विवरण';

  @override
  String get createPrivateGroupAction => 'दल बनाएं';

  @override
  String get createPrivateGroupSuccess => 'निजी दल सफलतापूर्वक बनाया गया!';

  @override
  String get createDmTitle => 'नया संदेश';

  @override
  String get createDmRecipientLabel => 'इन्हें भेजें';

  @override
  String get createDmRecipientHint =>
      'उनका UNIUN कोड पेस्ट करें, या उनका QR स्कैन करें';

  @override
  String get createDmRelaysNote =>
      'वे रिले चुनें जिनके माध्यम से यह संदेश भेजा जाता है।';

  @override
  String get createDmEncryptedNote =>
      'डायरेक्ट मैसेज एंड-टू-एंड एन्क्रिप्टेड हैं। केवल प्राप्तकर्ता ही उन्हें पढ़ सकता है।';

  @override
  String get createDmScanQr => 'QR कोड स्कैन करें';

  @override
  String get createDmAction => 'चैट शुरू करें';

  @override
  String get joinPrivateGroupTitle => 'निजी दल में शामिल हों';

  @override
  String get joinPrivateGroupEncrypted => 'एन्क्रिप्टेड';

  @override
  String get joinPrivateGroupHeading => 'शामिल होने का अनुरोध करें';

  @override
  String get joinPrivateGroupSubtitle =>
      'किसी निजी दल तक पहुँच का अनुरोध करने के लिए दल ID दर्ज करें।';

  @override
  String get joinPrivateGroupGroupIdLabel => 'दल ID';

  @override
  String get joinPrivateGroupGroupIdHint => 'दल ID पेस्ट करें…';

  @override
  String get joinPrivateGroupGroupIdHelper => 'दल ID के लिए दल एडमिन से पूछें।';

  @override
  String get joinPrivateGroupScanQr => 'QR स्कैन करें';

  @override
  String get joinPrivateGroupScanCardTitle => 'एक निजी दल QR स्कैन करें';

  @override
  String get joinPrivateGroupScanCardSubtitle =>
      'अपने कैमरे को एडमिन द्वारा साझा किए गए कोड की ओर रखें';

  @override
  String get joinPrivateGroupApprovalInfo =>
      'संदेश पढ़ने से पहले आपका अनुरोध स्वीकृति के लिए एडमिन के पास जाता है।';

  @override
  String get joinPrivateGroupAction => 'शामिल होने का अनुरोध भेजें';

  @override
  String get joinPrivateGroupSuccess =>
      'शामिल होने का अनुरोध भेजा गया! एडमिन की स्वीकृति की प्रतीक्षा करें।';

  @override
  String get commonOr => 'या';

  @override
  String get commonAdvanced => 'उन्नत';

  @override
  String get relaySelectorPlaceholder => 'रिले चुनें';

  @override
  String relaySelectorSelected(int count) {
    return '$count रिले चुने गए';
  }

  @override
  String get relaySelectorPickerTitle => 'रिले चुनें';

  @override
  String get relaySelectorEmpty =>
      'कोई रिले उपलब्ध नहीं। जोड़ने के लिए + पर टैप करें।';

  @override
  String get relaySelectorAddTooltip => 'रिले जोड़ें';

  @override
  String get relayAddDialogTitle => 'रिले जोड़ें';

  @override
  String get relayAddDialogHint => 'wss://relay.example.com';

  @override
  String get relayAddDialogAction => 'जोड़ें';

  @override
  String relayAddDialogError(String error) {
    return 'रिले नहीं जोड़ सका: $error';
  }

  @override
  String get relayRemoveDialogTitle => 'रिले हटाएं';

  @override
  String relayRemoveDialogBody(String url) {
    return '$url का उपयोग बंद करें?';
  }

  @override
  String get relayRemoveDialogAction => 'हटाएं';

  @override
  String get relayManageEmpty => 'कोई रिले नहीं मिला।';

  @override
  String get relayManageRemoveTooltip => 'हटाएं';

  @override
  String get pendingRequestsTitle => 'लंबित शामिल होने के अनुरोध';

  @override
  String get pendingRequestsSubtitle =>
      'उपयोगकर्ताओं को स्वीकृत करें ताकि वे संदेश पढ़ और भेज सकें।';

  @override
  String get pendingRequestsEmpty => 'कोई लंबित अनुरोध नहीं।';

  @override
  String get pendingRequestsNewMember => 'नया सदस्य';

  @override
  String get pendingRequestsApprove => 'स्वीकृत करें';

  @override
  String get settingsCloudProvider => 'Cloud AI';

  @override
  String get cloudProviderTitle => 'UNIUN Cloud';

  @override
  String get cloudProviderEmptyCta => 'साइन इन करें';

  @override
  String get cloudProviderEmptySubtitle =>
      'शिव को Claude पर चलाएं — अपनी UNIUN पहचान से साइन इन करें।';

  @override
  String get cloudProviderConnectedSubtitle =>
      'कनेक्ट किया गया · प्रबंधित करने के लिए टैप करें';

  @override
  String get cloudProviderDisconnect => 'डिस्कनेक्ट करें';

  @override
  String get cloudProviderLastKeyTitle => 'यह आपकी एकमात्र सक्रिय कुंजी है';

  @override
  String get cloudProviderLastKeyMessage =>
      'डिस्कनेक्ट करने से UNIUN Cloud पर आपकी अंतिम सक्रिय कुंजी रद्द हो जाएगी। आप बाद में फिर से कनेक्ट कर सकते हैं — इससे केवल यह डिवाइस साइन आउट होगा।';

  @override
  String get cloudProviderConnecting => 'साइन इन हो रहा है…';

  @override
  String get cloudProviderConnectFailed =>
      'UNIUN Cloud में साइन इन नहीं हो सका। कनेक्शन जांचें और फिर से प्रयास करें।';

  @override
  String get qrLoginNotConnected =>
      'पहले सेटिंग्स में UNIUN Cloud में साइन इन करें, फिर इस कोड को फिर से स्कैन करें।';

  @override
  String get qrLoginApproved => 'यह डिवाइस अब वेब पर साइन इन है।';

  @override
  String qrLoginFailed(String error) {
    return 'साइन-इन स्वीकृत नहीं हो सका: $error';
  }

  @override
  String get cloudProviderModelsHeader => 'क्लाउड मॉडल';

  @override
  String get cloudProviderOnDevice => 'ऑन-डिवाइस';

  @override
  String get cloudProviderOnDeviceNotSet => 'डाउनलोड नहीं हुआ';

  @override
  String get cloudProviderNoCloudModels =>
      'आपके प्लान में अभी कोई क्लाउड मॉडल नहीं है। इन्हें अनलॉक करने के लिए uniun.in पर अपना प्लान अपग्रेड करें।';

  @override
  String get cloudProviderPlanLabel => 'प्लान';

  @override
  String get cloudProviderCreditsLabel => 'क्रेडिट';

  @override
  String get cloudProviderUpgrade => 'प्लान अपग्रेड करें / क्रेडिट जोड़ें';

  @override
  String get cloudProviderUpgradeHint =>
      'पेमेंट uniun.in पर होता है — वहां अपनी उसी पहचान से साइन इन करें, फिर वापस आकर इस शीट को फिर से खोलें ताकि नया प्लान दिखे।';

  @override
  String get modelPickerTitle => 'एक मॉडल चुनें';

  @override
  String get modelPickerSearchHint => 'मॉडल खोजें…';

  @override
  String get modelPickerLocalSection => 'डिवाइस पर';

  @override
  String get modelPickerCloudSection => 'क्लाउड';

  @override
  String get modelPickerManageLocalCta => 'डिवाइस पर मॉडल प्रबंधित करें';

  @override
  String get modelPickerConnectCloudCta => 'एक क्लाउड प्रदाता कनेक्ट करें';

  @override
  String get modelPickerNoModels => 'कोई मॉडल उपलब्ध नहीं।';

  @override
  String get chatInputPickModelTooltip => 'मॉडल चुनें';

  @override
  String get followActionSuccess => 'अब फ़ॉलो कर रहे हैं।';

  @override
  String get drawerFollowingSectionTitle => 'फ़ॉलो किए जा रहे';

  @override
  String get drawerFollowingEmpty => 'अभी तक किसी को फ़ॉलो नहीं कर रहे';

  @override
  String get vishnuFeedEmptyTitle => 'आपकी फ़ीड शांत है';

  @override
  String get vishnuFeedEmptySubtitle =>
      'किसी का UNIUN QR स्कैन करके उन्हें फ़ॉलो करें और उनके नोट्स यहाँ देखें।';

  @override
  String get vishnuFeedEmptyCta => 'एक QR स्कैन करें';

  @override
  String get vishnuFeedEmptyRefresh => 'रिफ़्रेश करें';

  @override
  String get drawerPrivateGroups => 'निजी दल';

  @override
  String get drawerNoPrivateGroups => 'कोई निजी दल नहीं जुड़ा';

  @override
  String get followActionInvalidKey => 'अमान्य पब्लिक की';

  @override
  String get userProfileFollow => 'फ़ॉलो करें';

  @override
  String get userProfileFollowing => 'फ़ॉलो किया जा रहा है';

  @override
  String get userProfileNoNotes => 'अभी तक कोई नोट नहीं';

  @override
  String get userProfileMessage => 'संदेश';

  @override
  String get userProfileNotesLabel => 'नोट्स';

  @override
  String get userProfileCopyNpub => 'npub कॉपी करें';

  @override
  String get qrShareAction => 'साझा करें';

  @override
  String get qrShareFailed => 'QR कोड साझा नहीं कर सके';

  @override
  String get qrCaptionUser => 'UNIUN पर आपको जोड़ने के लिए इसे स्कैन करें।';

  @override
  String get qrCaptionPublicGroup => 'इस दल में शामिल होने के लिए स्कैन करें।';

  @override
  String get qrCaptionPrivateGroup =>
      'इस निजी दल में शामिल होने के लिए स्कैन करें।';

  @override
  String get qrCaptionDm => 'UNIUN पर चैट शुरू करने के लिए स्कैन करें।';

  @override
  String get shareSheetTitle => 'नोट साझा करें';

  @override
  String get shareQuotingLabel => 'उद्धृत कर रहे हैं';

  @override
  String get shareToLabel => 'इन्हें साझा करें';

  @override
  String get shareActionShare => 'साझा करें';

  @override
  String get shareSheetCommentHint => 'एक टिप्पणी जोड़ें (वैकल्पिक)';

  @override
  String get shareDestFeed => 'मेरी फ़ीड पर पोस्ट करें';

  @override
  String get shareDestFeedSubtitle => 'विष्णु पर दृश्यमान';

  @override
  String get shareSectionPublicGroups => 'सार्वजनिक दल';

  @override
  String get shareSectionPrivateGroups => 'निजी दल';

  @override
  String get shareSectionDms => 'डायरेक्ट मैसेज';

  @override
  String get shareSuccess => 'साझा किया गया';

  @override
  String get shareEmbedLoading => 'नोट लोड हो रहा है…';

  @override
  String get shareEmbedNotFound => 'नोट उपलब्ध नहीं';

  @override
  String get shareEmbedUnverified => 'असत्यापित';

  @override
  String get shareComposeAddReference => 'संदर्भ';

  @override
  String get shareComposeAddImage => 'इमेज';

  @override
  String get shareNoDmConversations =>
      'नोट्स यहाँ साझा करने के लिए पहले एक DM शुरू करें।';

  @override
  String get noteCardBlockUser => 'उपयोगकर्ता को ब्लॉक करें';

  @override
  String get noteCardDeleteNote => 'नोट हटाएं';

  @override
  String get deleteNoteSnackbar => 'नोट हटा दिया गया।';

  @override
  String blockUserSnackbar(String name) {
    return '$name को ब्लॉक कर दिया। उनकी नई पोस्ट दिखाई नहीं देंगी।';
  }

  @override
  String get settingsBlockedUsers => 'ब्लॉक किए गए उपयोगकर्ता';

  @override
  String get blockedUsersTitle => 'ब्लॉक किए गए उपयोगकर्ता';

  @override
  String get blockedUsersDescription =>
      'ब्लॉक किए गए लोग आपको संदेश नहीं भेज सकते और उनके नोट्स आपकी फ़ीड से छिपे रहते हैं। नोट्स कभी हटाए नहीं जाते — अनब्लॉक करने से वे वापस आ जाते हैं।';

  @override
  String blockedUsersSectionCount(int count) {
    return 'ब्लॉक किए गए · $count';
  }

  @override
  String blockedUsersBlockedAgo(String time) {
    return '$time पहले ब्लॉक किया गया';
  }

  @override
  String get blockedUsersBlockedJustNow => 'अभी-अभी ब्लॉक किया गया';

  @override
  String get blockedUsersEmpty => 'आपने किसी को ब्लॉक नहीं किया है';

  @override
  String get blockedUsersEmptyHint =>
      'आपके द्वारा ब्लॉक किए गए लोग यहाँ दिखेंगे, ताकि आप उन्हें कभी भी अनब्लॉक कर सकें।';

  @override
  String get actionUnblock => 'अनब्लॉक करें';

  @override
  String get noteCardReport => 'नोट की रिपोर्ट करें';

  @override
  String get reportSheetTitle => 'इस सामग्री की रिपोर्ट करें';

  @override
  String get reportSheetReasonHint =>
      'वैकल्पिक — कोई संदर्भ जोड़ें (अधिकतम 280 अक्षर)';

  @override
  String get reportSheetSubmit => 'रिपोर्ट सबमिट करें';

  @override
  String get reportSheetOutcomeHint =>
      'यह नोट आपकी फ़ीड से छिप जाएगा। आपकी रिपोर्ट नेटवर्क पर भेजी जाती है।';

  @override
  String get reportSheetAlsoBlock =>
      'इस उपयोगकर्ता को भी ब्लॉक करें (आप उनकी कोई भी पोस्ट नहीं देखेंगे)';

  @override
  String get reportSentSnackbar =>
      'रिपोर्ट भेजी गई। UNIUN को सुरक्षित रखने के लिए धन्यवाद।';

  @override
  String get reportTypeNudity => 'नग्नता';

  @override
  String get reportTypeNudityDescription =>
      'यौन रूप से स्पष्ट सामग्री या नग्नता';

  @override
  String get reportTypeMalware => 'मैलवेयर';

  @override
  String get reportTypeMalwareDescription =>
      'ऐसे लिंक या फ़ाइलें जो डिवाइस को नुकसान पहुँचा सकती हैं';

  @override
  String get reportTypeProfanity => 'अपशब्द';

  @override
  String get reportTypeProfanityDescription =>
      'घृणास्पद या अत्यधिक अश्लील भाषा';

  @override
  String get reportTypeIllegal => 'अवैध';

  @override
  String get reportTypeIllegalDescription =>
      'ऐसी सामग्री जो रिपोर्टकर्ता के क्षेत्राधिकार में अवैध है';

  @override
  String get reportTypeSpam => 'स्पैम';

  @override
  String get reportTypeSpamDescription => 'अवांछित या बार-बार होने वाला प्रचार';

  @override
  String get reportTypeImpersonation => 'प्रतिरूपण';

  @override
  String get reportTypeImpersonationDescription =>
      'किसी और होने का दिखावा करना';

  @override
  String get reportTypeOther => 'अन्य';

  @override
  String get reportTypeOtherDescription =>
      'कुछ और जो सामुदायिक मानकों का उल्लंघन करता है';

  @override
  String get actionReadMore => 'और पढ़ें';

  @override
  String get actionReadLess => 'कम पढ़ें';

  @override
  String get mediaGalleryTitle => 'मीडिया';

  @override
  String get mediaTabAll => 'सभी';

  @override
  String get mediaTabImages => 'इमेज';

  @override
  String get mediaTabVideos => 'वीडियो';

  @override
  String get mediaTabAudio => 'ऑडियो';

  @override
  String get mediaTabFiles => 'फ़ाइलें';

  @override
  String get mediaTabPinned => 'पिन किए गए';

  @override
  String get mediaActionDownload => 'डाउनलोड करें';

  @override
  String get mediaActionOpen => 'खोलें';

  @override
  String get mediaActionPin => 'पिन करें';

  @override
  String get mediaActionUnpin => 'अनपिन करें';

  @override
  String get mediaActionRemoveLocal => 'डिवाइस से हटाएं';

  @override
  String get mediaActionCopySha => 'sha256 कॉपी करें';

  @override
  String get mediaActionSaveToDevice => 'डिवाइस में सहेजें';

  @override
  String mediaSavedTo(String destination) {
    return '$destination में सहेजा गया';
  }

  @override
  String get mediaSaveSuccess => 'सहेजा गया';

  @override
  String get mediaSaveFailed => 'फ़ाइल सहेज नहीं सके';

  @override
  String get mediaEmptyState =>
      'अभी तक कोई मीडिया नहीं। अटैचमेंट के साथ मिलने वाले नोट्स यहाँ दिखेंगे।';

  @override
  String get mediaDetailReferencedBy => 'इनके द्वारा संदर्भित';

  @override
  String get mediaDetailLabelSha => 'sha256';

  @override
  String get mediaDetailLabelMime => 'प्रकार';

  @override
  String get mediaDetailLabelSize => 'आकार';

  @override
  String get mediaDetailLabelDim => 'आयाम';

  @override
  String get mediaDetailLabelCached => 'कैश किया गया';

  @override
  String get mediaDetailLabelServer => 'सर्वर';

  @override
  String get mediaPickerTitle => 'लाइब्रेरी से संलग्न करें';

  @override
  String get mediaPickerEmpty => 'अभी तक कोई मीडिया उपलब्ध नहीं।';

  @override
  String get composerAttachPhoto => 'फ़ोटो';

  @override
  String get composerAttachVideo => 'वीडियो';

  @override
  String get composerAttachFile => 'फ़ाइल';

  @override
  String mediaTooLarge(String size, String cap) {
    return 'फ़ाइल बहुत बड़ी है ($size)। अधिकतम $cap। कृपया इसे कंप्रेस करके फिर से प्रयास करें।';
  }

  @override
  String get mediaTooLargeAfterCompress =>
      'इमेज को अपलोड करने लायक छोटा नहीं कर सके। कोई दूसरी फ़ोटो आज़माएं।';

  @override
  String get storageMediaRow => 'मीडिया';

  @override
  String get storageMediaRowSubtitle =>
      'आपके नोट्स की फ़ोटो, वीडियो और फ़ाइलें';

  @override
  String get noteCardDownloadMedia => 'डाउनलोड करें';

  @override
  String get noteCardFileFallbackName => 'अटैचमेंट';

  @override
  String get noteCardFileTapToOpen => 'खोलने के लिए टैप करें';

  @override
  String get noteCardFileTapToDownload => 'डाउनलोड करने के लिए टैप करें';

  @override
  String mediaSelectionCount(int count) {
    return '$count चयनित';
  }

  @override
  String get mediaSelectionExit => 'चयन से बाहर निकलें';

  @override
  String get mediaSelectionRemoveDialogTitle => 'डिवाइस से हटाएं?';

  @override
  String mediaSelectionRemoveDialogBody(int count) {
    return 'इस डिवाइस से $count कैश की गई फ़ाइल(लें) हटाकर जगह खाली करें। सर्वर की प्रतियाँ बनी रहती हैं — आप कभी भी फिर से डाउनलोड कर सकते हैं।';
  }

  @override
  String get storageMedia => 'मीडिया';

  @override
  String get storageRetentionTitle => 'पुराने नोट्स स्वतः हटाएं';

  @override
  String get storageRetentionSubtitle =>
      'केवल सार्वजनिक फ़ीड और दल नोट्स। सहेजे गए, देखे जा रहे, आपके अपने, DM और निजी दल हमेशा बने रहते हैं।';

  @override
  String get storageRetentionOff => 'बंद';

  @override
  String storageRetentionDays(int days) {
    return '$days दिन';
  }

  @override
  String get syncWindowTitle => 'सिंक विंडो';

  @override
  String get syncWindowSubtitle =>
      'फ़ीड और दल संदेशों का कितना पुराना इतिहास सिंक करना है। देखे जा रहे नोट्स और DM हमेशा पूरे सिंक होते हैं। अगली बार ऐप शुरू करने पर लागू होता है।';

  @override
  String syncWindowDays(int days) {
    return '$days दिन';
  }

  @override
  String get noteCardMediaDownloading => 'डाउनलोड हो रहा है…';

  @override
  String get noteCardMediaFailed => 'डाउनलोड विफल';

  @override
  String get manasDrawerHeaderTitle => 'ब्रह्मा';

  @override
  String get manasDrawerHeaderSubtitle => 'आपके नॉलेज ग्राफ़';

  @override
  String get manasDrawerBrahmaEntryTitle => 'ब्रह्मा';

  @override
  String get manasDrawerBrahmaEntrySubtitle =>
      'वह सब कुछ जो आपने सहेजा, लिखा और ड्राफ़्ट किया';

  @override
  String get manasDrawerSectionTitle => 'मानस';

  @override
  String get manasDrawerNewManasButton => 'नया';

  @override
  String get manasDrawerEmptyStateTitle => 'अभी तक कोई मानस नहीं';

  @override
  String get manasDrawerEmptyStateBody =>
      'किसी विषय पर ग्राफ़ को केंद्रित करने के लिए एक मानस बनाएं — आपके नोट्स के एक उपदल से बना एक उप-विशेषज्ञ मन।';

  @override
  String get manasDrawerEmptyStateCta => 'अपना पहला मानस बनाएं';

  @override
  String manasDrawerTileNoteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count नोट्स',
      one: '1 नोट',
    );
    return '$_temp0';
  }

  @override
  String get manasTileEmptyHint => '0 नोट्स · खोलने के लिए टैप करें';

  @override
  String get manasTileActionEdit => 'मानस संपादित करें';

  @override
  String get manasTileActionDelete => 'मानस हटाएं';

  @override
  String get manasDeleteConfirmTitle => 'मानस हटाएं?';

  @override
  String manasDeleteConfirmBody(String name) {
    return '“$name” हटा दिया जाएगा। नोट्स स्वयं बने रहते हैं — केवल मानस की सदस्यता हटाई जाती है।';
  }

  @override
  String get manasDeleteConfirmConfirm => 'हटाएं';

  @override
  String get manasDeleteConfirmCancel => 'रद्द करें';

  @override
  String get manasFormCreateTitle => 'नया मानस';

  @override
  String manasFormEditTitle(String name) {
    return 'संपादित करें · $name';
  }

  @override
  String get manasFormEditTitleFallback => 'मानस संपादित करें';

  @override
  String get manasFormSaveAction => 'सहेजें';

  @override
  String get manasFormDeleteAction => 'मानस हटाएं';

  @override
  String get manasFormNameLabel => 'नाम';

  @override
  String get manasFormNameHint => 'जैसे Rust विशेषज्ञ';

  @override
  String get manasFormDescriptionLabel => 'विवरण';

  @override
  String get manasFormDescriptionHint => 'वैकल्पिक। यह मानस किसलिए है?';

  @override
  String manasFormMembershipSectionTitle(int count) {
    return 'इस मानस में नोट्स ($count)';
  }

  @override
  String get manasFormMembershipEmpty =>
      'अभी तक कोई नोट नहीं। कुछ जोड़ने के लिए नीचे खोजें।';

  @override
  String get manasFormAddNotesSectionTitle => 'नोट्स जोड़ें';

  @override
  String get manasFormSearchHint => 'सहेजे गए, अपने या ड्राफ़्ट नोट्स खोजें';

  @override
  String get manasFormSearchEmpty => 'कोई मेल नहीं।';

  @override
  String get manasFormNoteUnavailable => '(नोट उपलब्ध नहीं)';

  @override
  String get manasFormKindSaved => 'सहेजे गए';

  @override
  String get manasFormKindOwn => 'अपने';

  @override
  String get manasFormKindDraft => 'ड्राफ़्ट';

  @override
  String get manasFormDeleteConfirmTitle => 'यह मानस हटाएं?';

  @override
  String get manasFormDeleteConfirmBody =>
      'इससे मानस और उसकी सभी सदस्यताएँ हट जाती हैं। नोट्स स्वयं ब्रह्मा में बने रहते हैं।';

  @override
  String get manasFormDeleteConfirmConfirm => 'हटाएं';

  @override
  String get manasFormDeleteConfirmCancel => 'रद्द करें';

  @override
  String get graphHeaderManasEditTooltip => 'मानस संपादित करें';

  @override
  String get graphHeaderUnnamedManas => 'मानस';

  @override
  String get noteCardAddToManas => 'मानस में जोड़ें';

  @override
  String get noteCardManasSaveFailed =>
      'नोट सहेज नहीं सके। फिर से प्रयास करें।';

  @override
  String get unsaveManasDialogTitle => 'नोट को असहेजें?';

  @override
  String get unsaveManasDialogBody =>
      'इस नोट को असहेजने से यह इनसे भी हट जाएगा:';

  @override
  String get unsaveManasDialogConfirm => 'असहेजें';

  @override
  String get unsaveManasDialogCancel => 'रद्द करें';

  @override
  String get manasMembershipSheetTitle => 'मानस में जोड़ें';

  @override
  String get manasMembershipSheetCreate => 'नया मानस बनाएं';

  @override
  String get manasMembershipSheetEmptyTitle => 'अभी तक कोई मानस नहीं';

  @override
  String get manasMembershipSheetEmptyBody =>
      'नोट्स को केंद्रित उप-विशेषज्ञों में समूहित करना शुरू करने के लिए अपना पहला मानस बनाएं।';

  @override
  String get manasMembershipSheetEmptyCta => 'मानस बनाएं';

  @override
  String get manasIconPickerTitle => 'एक आइकन चुनें';

  @override
  String get ganaListTitle => 'गण';

  @override
  String get ganaListNew => 'नया';

  @override
  String get ganaListSubtitle =>
      'स्वायत्त एजेंट जो किसी सतह को देखते हैं, किसी मानस पर तर्क करते हैं, और आपके लिए प्रकाशित करते हैं।';

  @override
  String get ganaListPaused => 'रुका हुआ';

  @override
  String get ganaListScopeAll => 'सभी नोट्स';

  @override
  String ganaListScopeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count मानस',
      one: '1 मानस',
    );
    return '$_temp0';
  }

  @override
  String get ganaDrawerEmptyTitle => 'अभी तक कोई गण नहीं';

  @override
  String get ganaDrawerEmptyBody =>
      'एक AI वर्कर बनाएं जो किसी सतह को देखता है और आपके लिए प्रकाशित करता है।';

  @override
  String get ganaTileDisabled => 'बंद';

  @override
  String get ganaTileTriggerReactive => 'प्रतिक्रियाशील';

  @override
  String ganaTileTriggerInterval(int n) {
    return 'हर $n मिनट';
  }

  @override
  String ganaTileTriggerBoth(int n) {
    return 'प्रतिक्रियाशील + हर $n मिनट';
  }

  @override
  String get ganaTileTriggerOnceOnEnable => 'सक्षम करने पर एक बार';

  @override
  String get ganaTileTriggerOnceOnInput => 'पहले इनपुट पर एक बार';

  @override
  String get ganaTileLastRunNever => 'अभी तक कोई रन नहीं';

  @override
  String ganaTileLastRunSucceeded(String when) {
    return 'पिछला रन · $when';
  }

  @override
  String ganaTileLastRunSkipped(String when) {
    return 'छोड़ा गया · $when';
  }

  @override
  String ganaTileLastRunFailed(String when) {
    return 'विफल · $when';
  }

  @override
  String get ganaRelativeJustNow => 'अभी-अभी';

  @override
  String ganaRelativeMinutes(int count) {
    return '$count मिनट पहले';
  }

  @override
  String ganaRelativeHours(int count) {
    return '$count घंटे पहले';
  }

  @override
  String ganaRelativeDays(int count) {
    return '$count दिन पहले';
  }

  @override
  String get ganaFormCreateTitle => 'नया गण';

  @override
  String ganaFormEditTitle(String name) {
    return 'संपादित करें · $name';
  }

  @override
  String get ganaFormEditTitleFallback => 'गण संपादित करें';

  @override
  String get ganaFormSaveAction => 'सहेजें';

  @override
  String get ganaFormDeleteAction => 'गण हटाएं';

  @override
  String get ganaFormNameLabel => 'नाम';

  @override
  String get ganaFormNameHint => 'जैसे Life Lessons Replier';

  @override
  String get ganaFormManasSectionTitle => 'ज्ञान';

  @override
  String get ganaFormManasSectionSubtitle =>
      'वह मानस जिस पर यह गण तर्क करता है।';

  @override
  String get ganaFormManasEmpty =>
      'अभी तक कोई मानस नहीं। एक गण को तर्क करने के लिए ज्ञान आधार चाहिए — जारी रखने के लिए एक बनाएं।';

  @override
  String get ganaFormManasCreateNew => 'मानस बनाएं';

  @override
  String get ganaFormModeRecurring => 'आवर्ती';

  @override
  String get ganaFormModeOneShot => 'एक-बारगी';

  @override
  String get ganaFormModeRecurringHelp =>
      'जब तक आप इसे अक्षम नहीं करते, हर मेल खाते ट्रिगर पर चलता रहता है।';

  @override
  String get ganaFormModeOneShotHelp =>
      'एक बार चलता है, फिर खुद को स्वतः अक्षम कर देता है। फिर से चलाने के लिए दोबारा सक्षम करें।';

  @override
  String get ganaFormBlockerName => 'जारी रखने के लिए एक नाम जोड़ें।';

  @override
  String get ganaFormBlockerManas =>
      'कम से कम एक मानस चुनें — एक गण को तर्क करने के लिए ज्ञान चाहिए।';

  @override
  String get ganaFormBlockerTask =>
      'एक टास्क प्रॉम्प्ट लिखें ताकि गण को पता हो कि क्या करना है।';

  @override
  String get ganaFormBlockerInputRef =>
      'इनपुट स्रोत चुनें — दल, DM, उपयोगकर्ता, या नोट।';

  @override
  String get ganaFormBlockerOutputRef =>
      'आउटपुट गंतव्य चुनें ताकि गण को पता हो कि कहाँ प्रकाशित करना है।';

  @override
  String get ganaFormBlockerOneShotReactive =>
      'इनपुट स्रोत वाले एक-बारगी गण के लिए नए इनपुट पर प्रतिक्रिया चालू होना चाहिए।';

  @override
  String get ganaFormBlockerInterval =>
      'स्वतंत्र आवर्ती गण के लिए एक अंतराल (≥ 5 मिनट) चाहिए।';

  @override
  String get ganaFormBlockerTrigger =>
      'नए इनपुट पर प्रतिक्रिया चालू करें, या एक अंतराल (≥ 5 मिनट) सेट करें।';

  @override
  String get ganaFormBlockerMaxOutputs =>
      '1 और 1000 के बीच अधिकतम-नोट सीमा सेट करें।';

  @override
  String get ganaFormMaxOutputsLabel => 'बनाने के लिए अधिकतम नोट्स';

  @override
  String get ganaFormMaxOutputsHelp =>
      'आवर्ती गण इतने नोट्स प्रकाशित करने के बाद स्वतः अक्षम हो जाते हैं। 1–1000।';

  @override
  String get ganaFormOneShotStandaloneNote =>
      'जब आप इस गण को सक्षम करेंगे तब एक बार चलेगा, फिर स्वतः अक्षम हो जाएगा।';

  @override
  String get ganaFormReactiveRequiredNote =>
      'इनपुट स्रोत वाले एक-बारगी गण के लिए आवश्यक।';

  @override
  String get ganaFormTaskPromptLabel => 'टास्क प्रॉम्प्ट';

  @override
  String get ganaFormTaskPromptHint =>
      'गण को बताएं कि क्या करना है। जैसे \"जब कोई यहाँ कोई सवाल पोस्ट करे, तो मेरे मानस से सबसे प्रासंगिक नोट के साथ उत्तर दें और एक पंक्ति टिप्पणी जोड़ें।\"';

  @override
  String get ganaFormInputSectionTitle => 'इनपुट';

  @override
  String get ganaFormInputStandalone => 'स्वतंत्र (कोई इनपुट नहीं)';

  @override
  String get ganaFormInputGroup => 'सार्वजनिक दल';

  @override
  String get ganaFormInputPrivateGroup => 'निजी दल';

  @override
  String get ganaFormInputDm => 'DM';

  @override
  String get ganaFormInputUser => 'किसी उपयोगकर्ता के नोट्स';

  @override
  String get ganaFormInputFollowedNote => 'देखे जा रहे नोट का थ्रेड';

  @override
  String get ganaFormInputPickHint => 'एक स्रोत चुनें';

  @override
  String get ganaFormInputUserHint => 'एक pubkey पेस्ट करें (hex या npub)';

  @override
  String get ganaFormOutputSectionTitle => 'आउटपुट';

  @override
  String get ganaFormOutputFeed => 'मुख्य फ़ीड (Kind 1)';

  @override
  String get ganaFormOutputGroup => 'सार्वजनिक दल';

  @override
  String get ganaFormOutputPrivateGroup => 'निजी दल';

  @override
  String get ganaFormOutputDm => 'DM';

  @override
  String get ganaFormOutputPickHint => 'एक गंतव्य चुनें';

  @override
  String get ganaFormModelSectionTitle => 'मॉडल';

  @override
  String get ganaFormModelUseActive => 'जो भी मॉडल सक्रिय हो उसका उपयोग करें';

  @override
  String get ganaFormTriggersSectionTitle => 'ट्रिगर';

  @override
  String get ganaFormTriggerQuestion => 'यह कब चलना चाहिए?';

  @override
  String get ganaFormPresetOnceOnEnable => 'एक बार, जब मैं इसे सक्षम करूँ';

  @override
  String get ganaFormPresetOnceOnFirstMessage => 'एक बार, पहले नए संदेश पर';

  @override
  String get ganaFormPresetEveryMessage => 'हर नए संदेश पर';

  @override
  String get ganaFormPresetOnSchedule => 'एक शेड्यूल पर (हर N मिनट)';

  @override
  String get ganaFormPresetMessageOrSchedule => 'हर नए संदेश पर और एक टाइमर पर';

  @override
  String get ganaFormReactiveLabel => 'नए इनपुट पर प्रतिक्रिया करें';

  @override
  String get ganaFormReactiveHelp =>
      'इनपुट सतह पर नए संदेश के कुछ सेकंड के भीतर चलता है।';

  @override
  String get ganaFormIntervalLabel => 'हर बार चलाएं';

  @override
  String get ganaFormIntervalUnit => 'मिनट (न्यूनतम 5)';

  @override
  String get ganaFormEnabledLabel => 'सक्षम';

  @override
  String get ganaFormEnabledHelp =>
      'डिफ़ॉल्ट रूप से बंद। कॉन्फ़िग की समीक्षा करने के बाद चालू करें।';

  @override
  String get ganaFormRunsSectionTitle => 'हाल के रन';

  @override
  String get ganaFormRunsEmpty => 'यह गण अभी तक नहीं चला है।';

  @override
  String get ganaFormDeleteConfirmTitle => 'यह गण हटाएं?';

  @override
  String get ganaFormDeleteConfirmBody =>
      'इससे वर्कर रुक जाता है और उसका रन लॉग हट जाता है। इसके द्वारा संदर्भित मानस और नोट्स प्रभावित नहीं होते।';

  @override
  String get ganaFormDeleteConfirmConfirm => 'हटाएं';

  @override
  String get ganaFormDeleteConfirmCancel => 'रद्द करें';

  @override
  String get ganaRunStatusSucceeded => 'सफल';

  @override
  String get ganaRunStatusSkipped => 'छोड़ा गया';

  @override
  String get ganaRunStatusFailed => 'विफल';

  @override
  String get ganaRunStatusRunning => 'चल रहा है';

  @override
  String get natarajTileAction => 'विचार जगाएं';

  @override
  String get natarajDrawerTitle => 'नटराज';

  @override
  String get natarajScopeSheetTitle => 'मानस चुनें';

  @override
  String get natarajScopeAllNotes => 'ब्रह्मा';

  @override
  String natarajScopeManasCount(int count) {
    return '$count मानस';
  }

  @override
  String get natarajNewChatTooltip => 'नई चैट';

  @override
  String get natarajEdgePublish => 'प्रकाशित करें';

  @override
  String get natarajEdgeDraft => 'ड्राफ़्ट';

  @override
  String get natarajEdgeDiscard => 'छोड़ें';

  @override
  String get natarajEdgeDiscuss => 'चर्चा करें';

  @override
  String get natarajReferencesLabel => 'संदर्भ';

  @override
  String get natarajReferencesView => 'संदर्भ देखें';

  @override
  String get natarajReferencesAttach =>
      'प्रकाशित करने पर चयनित नोट्स संदर्भ के रूप में संलग्न होते हैं।';

  @override
  String get natarajCoachTitle => 'विचार खोजने के लिए स्वाइप करें';

  @override
  String get natarajCoachDismiss => 'समझ गया';

  @override
  String get natarajGenerating => 'संबंध खोजे जा रहे हैं…';

  @override
  String get natarajRevisitingHint =>
      'पुराने विचारों को फिर से देख रहे हैं — नए विचारों के लिए नोट्स जोड़ें';

  @override
  String get natarajEmptyNeedsMoreTitle => 'अभी पर्याप्त नोट्स नहीं';

  @override
  String get natarajEmptyNeedsMoreBody =>
      'संबंध जगाने के लिए इस दायरे में कम से कम 2 नोट्स चाहिए।';

  @override
  String get natarajExhaustedTitle => 'आपने सभी देख लिए';

  @override
  String get natarajExhaustedBody => 'नए विचार जगाने के लिए और नोट्स जोड़ें।';

  @override
  String get natarajModelErrorTitle => 'विचार उत्पन्न नहीं कर सके';

  @override
  String get natarajModelErrorBody =>
      'AI मॉडल इस डिवाइस पर नहीं चल सका। कोई दूसरा (छोटा) मॉडल आज़माएं, या पुनः प्रयास पर टैप करें।';

  @override
  String get natarajNoIdeaTitle => 'इस बार कोई विचार नहीं';

  @override
  String get natarajNoIdeaBody =>
      'नोट्स के इस संयोजन से कुछ नहीं जगा। कुछ गलत नहीं है — बस फिर से प्रयास करें।';

  @override
  String get natarajPublishedSnack => 'नोट के रूप में प्रकाशित किया गया';

  @override
  String get natarajDraftSavedSnack => 'ड्राफ़्ट के रूप में सहेजा गया';

  @override
  String get natarajGenerateErrorSnack => 'अभी उत्पन्न नहीं कर सके';

  @override
  String get natarajYouName => 'आप';

  @override
  String get natarajYouHandle => '@you · अभी';

  @override
  String get natarajDraftLabel => 'ड्राफ़्ट';

  @override
  String natarajRefsCount(int count) {
    return '$count संदर्भ';
  }

  @override
  String get natarajRetry => 'फिर से प्रयास करें';

  @override
  String get receiveShareTitle => 'UNIUN में जोड़ें';

  @override
  String get receiveShareCommentHint => 'कुछ कहें… (वैकल्पिक)';

  @override
  String get receiveShareSaveDraft => 'ड्राफ़्ट में सहेजें';

  @override
  String get receiveShareDraftSaved => 'ड्राफ़्ट में सहेजा गया';

  @override
  String get receiveShareIngesting => 'अटैचमेंट तैयार किए जा रहे हैं…';

  @override
  String get receiveShareDraftNeedsText =>
      'ड्राफ़्ट सहेजने के लिए कुछ टेक्स्ट जोड़ें';

  @override
  String get receiveShareNothingToShare => 'पहले टेक्स्ट या मीडिया जोड़ें';

  @override
  String get jumpToLatest => 'नवीनतम पर जाएं';

  @override
  String get interestsEyebrow => 'अपनी फ़ीड बनाएं';

  @override
  String get interestsTitle => 'जो पसंद हो उसे टैप करें';

  @override
  String get interestsSubtitle =>
      'कम से कम 3 चुनें। हर एक रोज़ पोस्ट करता है, इसलिए आपकी फ़ीड पहले स्क्रॉल से ही जीवंत रहती है।';

  @override
  String get interestsSearchHint => 'रुचियाँ खोजें…';

  @override
  String get interestsNoResults => 'उससे कोई रुचि मेल नहीं खाती।';

  @override
  String get interestsContinue => 'मुझे मेरी फ़ीड दिखाएं';

  @override
  String interestsPickMore(int count) {
    return 'जारी रखने के लिए $count और चुनें';
  }

  @override
  String get interestsSkip => 'अभी के लिए छोड़ें';

  @override
  String get interestsFollowFailed =>
      'सभी को फ़ॉलो नहीं कर सके — कृपया फिर से प्रयास करें।';

  @override
  String get interestsLoadFailed =>
      'रुचियां लोड नहीं हो सकीं। अपना कनेक्शन जांचें।';

  @override
  String get interestsRetry => 'पुनः प्रयास करें';

  @override
  String get welcomeMoreLanguages => 'और भाषाएँ';

  @override
  String get languageSelectTitle => 'भाषा चुनें';

  @override
  String get languageComingSoon => 'जल्द आ रहा है';

  @override
  String get settingsLanguage => 'भाषा';

  @override
  String get settingsAppLanguage => 'ऐप की भाषा';

  @override
  String get graphEmptyHint =>
      'अपना नॉलेज ग्राफ़ बनाने के लिए नोट्स सहेजें।\n\nजब कोई नोट किसी दूसरे नोट का संदर्भ देता है, तब एजेस दिखाई देते हैं।';

  @override
  String get ganaDetailManasesLabel => 'मानस';

  @override
  String get settingsAppearance => 'दिखावट';

  @override
  String get settingsTheme => 'थीम';

  @override
  String get settingsThemeSheetTitle => 'थीम चुनें';

  @override
  String get settingsThemeSystem => 'सिस्टम के अनुसार';

  @override
  String get settingsThemeLight => 'लाइट';

  @override
  String get settingsThemeDark => 'डार्क';

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
  String get noteCardTranslate => 'अनुवाद करें';

  @override
  String get translateSheetTitle => 'इसमें अनुवाद करें';

  @override
  String get translateSheetAction => 'अनुवाद करें';

  @override
  String get translateSheetSettingsHint => 'आपकी ऐप भाषा से';

  @override
  String get translatingLabel => 'अनुवाद हो रहा है…';

  @override
  String translatedToLabel(String language) {
    return '$language में अनुवादित';
  }

  @override
  String get translationShowOriginal => 'मूल दिखाएँ';

  @override
  String get translationShowTranslation => 'अनुवाद दिखाएँ';

  @override
  String get translationChangeLanguage => 'बदलें';

  @override
  String get translationFailed =>
      'इस नोट का अनुवाद नहीं हो सका। पुनः प्रयास करें।';

  @override
  String get translationNotProduced =>
      'AI मॉडल इस नोट का अनुवाद नहीं कर सका। बड़ा मॉडल या UNIUN Cloud आज़माएँ।';

  @override
  String get brahmaPublishConfirmTitle => 'यह नोट प्रकाशित करें?';

  @override
  String get brahmaPublishConfirmBody =>
      'प्रकाशित नोट स्थायी होते हैं। वे रिले पर चले जाते हैं और उन्हें संपादित या हटाया नहीं जा सकता। अगर आप अभी भी काम कर रहे हैं तो इसे ड्राफ़्ट में रखें।';
}
