/// go_router route **names**. Used with `context.goNamed` / `context.pushNamed`.
///
/// The actual URL paths live in [appRouter] (`app_router.dart`). The three
/// deep-linkable routes (groupDetail, privateGroupDetail, chatDm) map to
/// clean path patterns that double as universal-link paths — see [DeepLink].
abstract class AppRoutes {
  static const splash = 'splash';
  static const welcome = 'welcome';
  static const importIdentity = 'importIdentity';
  static const yourIdentityKeys = 'yourIdentityKeys';
  static const interests = 'interests';
  static const aboutYou = 'aboutYou';
  static const howItWorks = 'howItWorks';
  static const home = 'home';
  static const settings = 'settings';
  static const selectLanguage = 'selectLanguage';
  static const editProfile = 'editProfile';
  static const privacyPolicy = 'privacyPolicy';
  static const followedNoteDetail = 'followedNoteDetail';
  static const thread = 'thread';
  static const aiModelSelection = 'aiModelSelection';
  static const groupEntry = 'groupEntry';
  static const createGroup = 'createGroup';
  static const joinGroup = 'joinGroup';
  static const savedNotes = 'savedNotes';
  static const surrounding = 'surrounding';
  static const blockedUsers = 'blockedUsers';
  static const groupDetail = 'groupDetail';
  static const graph = 'graph';
  static const createDm = 'createDm';
  static const chatDm = 'chatDm';
  static const brahmaCreate = 'brahmaCreate';
  static const privateGroupEntry = 'privateGroupEntry';
  static const createPrivateGroup = 'createPrivateGroup';
  static const joinPrivateGroup = 'joinPrivateGroup';
  static const privateGroupDetail = 'privateGroupDetail';
  static const scanQr = 'scanQr';
  static const userProfile = 'userProfile';
  static const receiveShare = 'receiveShare';
  static const mediaGallery = 'mediaGallery';
  static const mediaDetail = 'mediaDetail';
  static const documentViewer = 'documentViewer';
  static const brahmaManasForm = 'brahmaManasForm';
  static const shivGanaList = 'shivGanaList';
  static const shivGanaForm = 'shivGanaForm';
  static const shivGanaDetail = 'shivGanaDetail';
  static const shivNataraj = 'shivNataraj';
}
