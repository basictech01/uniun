import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:uniun/common/locator.dart';
import 'package:uniun/common/qr/uniun_qr_payload.dart';
import 'package:uniun/common/qr/uniun_qr_scanner_page.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/router/deep_link.dart';
import 'package:uniun/core/utils/pubkey_normalizer.dart';
import 'package:uniun/domain/usecases/get_group_by_id_usecase.dart';
import 'package:uniun/domain/usecases/private_group_usecases.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';
import 'package:uniun/features/brahma/graph/pages/graph_compose_page.dart';
import 'package:uniun/features/brahma/graph/pages/graph_page.dart';
import 'package:uniun/features/brahma/manas/pages/manas_form_page.dart';
import 'package:uniun/features/shiv/chat/bloc/shiv_ai_bloc.dart';
import 'package:uniun/features/shiv/document_viewer/pages/document_viewer_page.dart';
import 'package:uniun/features/shiv/gana/detail/pages/gana_detail_page.dart';
import 'package:uniun/features/shiv/gana/form/pages/gana_form_page.dart';
import 'package:uniun/features/shiv/gana/dashboard/pages/gana_dashboard_page.dart';
import 'package:uniun/features/shiv/nataraj/pages/nataraj_deck_page.dart';
import 'package:uniun/features/groups/create/pages/create_group_page.dart';
import 'package:uniun/features/groups/entry/pages/group_entry_page.dart';
import 'package:uniun/features/groups/feed/pages/group_feed_page.dart';
import 'package:uniun/features/groups/join/pages/join_group_page.dart';
import 'package:uniun/features/dm/chat/pages/dm_chat_page.dart';
import 'package:uniun/features/dm/create/pages/create_dm_page.dart';
import 'package:uniun/features/home/pages/home_page.dart';
import 'package:uniun/features/onboarding/pages/about_you_page.dart';
import 'package:uniun/features/onboarding/pages/how_it_works_page.dart';
import 'package:uniun/features/onboarding/interests/interests_page.dart';
import 'package:uniun/features/onboarding/pages/import_identity_page.dart';
import 'package:uniun/features/onboarding/pages/splash_page.dart';
import 'package:uniun/features/onboarding/pages/welcome_page.dart';
import 'package:uniun/features/onboarding/pages/your_identity_keys_page.dart';
import 'package:uniun/features/private_groups/create/pages/create_private_group_page.dart';
import 'package:uniun/features/private_groups/detail/pages/private_group_detail_page.dart';
import 'package:uniun/features/private_groups/entry/pages/private_group_entry_page.dart';
import 'package:uniun/features/private_groups/join/pages/join_private_group_page.dart';
import 'package:uniun/features/profile/pages/user_profile_page.dart';
import 'package:uniun/features/receive_share/pages/receive_share_sheet_page.dart';
import 'package:uniun/features/receive_share/widgets/shared_incoming.dart';
import 'package:uniun/domain/entities/shiv/document_citation.dart';
import 'package:uniun/features/media/pages/media_detail_page.dart';
import 'package:uniun/features/media/pages/media_gallery_page.dart';
import 'package:uniun/features/saved_notes/pages/saved_notes_page.dart';
import 'package:uniun/features/surrounding/pages/surrounding_feed_page.dart';
import 'package:uniun/features/settings/pages/blocked_users_page.dart';
import 'package:uniun/features/settings/pages/edit_profile_page.dart';
import 'package:uniun/features/settings/pages/language_selection_page.dart';
import 'package:uniun/features/settings/pages/privacy_policy_page.dart';
import 'package:uniun/features/settings/pages/settings_page.dart';
import 'package:uniun/features/shiv/model_select/pages/ai_model_selection_page.dart';
import 'package:uniun/features/thread/pages/thread_page.dart';

/// Root navigator key — lets non-widget code (deep-link redirects) reach the
/// navigator if needed.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// App-wide router. go_router resolves inbound universal-link paths
/// (`https://www.uniun.in/...`) against these same routes, so external
/// links and in-app navigation share one table. Deep-linkable routes carry a
/// `dl=1` flag (see [kDeepLinkFlag]); their redirects run auth/relay/membership
/// work only when that flag is present, leaving in-app navigation untouched.
final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      name: AppRoutes.splash,
      path: '/',
      builder: (_, __) => const SplashPage(),
    ),
    GoRoute(
      name: AppRoutes.welcome,
      path: '/welcome',
      builder: (_, __) => const WelcomePage(),
    ),
    GoRoute(
      name: AppRoutes.howItWorks,
      path: '/how-it-works',
      builder: (_, __) => const HowItWorksPage(),
    ),
    GoRoute(
      name: AppRoutes.importIdentity,
      path: '/import-identity',
      builder: (_, __) => const ImportIdentityPage(),
    ),
    GoRoute(
      name: AppRoutes.aboutYou,
      path: '/about-you',
      builder: (_, state) => AboutYouPage(args: _asMap(state.extra)),
    ),
    GoRoute(
      name: AppRoutes.yourIdentityKeys,
      path: '/your-identity-keys',
      builder: (_, state) => YourIdentityKeysPage(args: _asMap(state.extra)),
    ),
    GoRoute(
      name: AppRoutes.interests,
      path: '/interests',
      builder: (_, __) => const InterestsPage(),
    ),
    GoRoute(
      name: AppRoutes.home,
      path: '/home',
      builder: (_, __) => const HomePage(),
    ),
    GoRoute(
      name: AppRoutes.settings,
      path: '/settings',
      builder: (_, __) => const SettingsPage(),
    ),
    GoRoute(
      name: AppRoutes.selectLanguage,
      path: '/select-language',
      builder: (_, __) => const LanguageSelectionPage(),
    ),
    GoRoute(
      name: AppRoutes.editProfile,
      path: '/edit-profile',
      builder: (_, __) => const EditProfilePage(),
    ),
    GoRoute(
      name: AppRoutes.privacyPolicy,
      path: '/privacy-policy',
      builder: (_, state) => PrivacyPolicyPage(expandTerms: state.extra == true),
    ),
    GoRoute(
      name: AppRoutes.thread,
      path: '/thread/:noteId',
      builder: (_, state) => ThreadPage(
        noteId: state.pathParameters['noteId']!,
        savedOnly: state.extra is bool ? state.extra as bool : false,
      ),
    ),
    GoRoute(
      name: AppRoutes.aiModelSelection,
      path: '/ai-model-selection',
      builder: (_, __) => const AIModelSelectionPage(),
    ),
    GoRoute(
      name: AppRoutes.groupEntry,
      path: '/group-entry',
      builder: (_, __) => const GroupEntryPage(),
    ),
    GoRoute(
      name: AppRoutes.createGroup,
      path: '/create-group',
      builder: (_, __) => const CreateGroupPage(),
    ),
    GoRoute(
      name: AppRoutes.joinGroup,
      path: '/join-group',
      builder: (_, state) =>
          JoinGroupPage(payload: _groupPayloadFrom(state)),
    ),
    GoRoute(
      name: AppRoutes.savedNotes,
      path: '/saved-notes',
      builder: (_, __) => const SavedNotesPage(),
    ),
    GoRoute(
      name: AppRoutes.mediaGallery,
      path: '/media',
      builder: (_, __) => const MediaGalleryPage(),
    ),
    GoRoute(
      name: AppRoutes.mediaDetail,
      path: '/media/:sha256',
      builder: (_, state) => MediaDetailPage(
        sha256: state.pathParameters['sha256']!,
      ),
    ),
    GoRoute(
      name: AppRoutes.documentViewer,
      path: '/document/:sha256',
      // The citation rides as `extra`: the viewer needs its page or heading,
      // which a path cannot carry. A cold deep link has no extra and no
      // meaning here, so it is sent back rather than shown empty.
      redirect: (_, state) => state.extra is DocumentCitation ? null : '/',
      builder: (_, state) =>
          DocumentViewerPage(citation: state.extra! as DocumentCitation),
    ),
    GoRoute(
      name: AppRoutes.blockedUsers,
      path: '/blocked-users',
      builder: (_, __) => const BlockedUsersPage(),
    ),
    GoRoute(
      name: AppRoutes.surrounding,
      path: '/surrounding',
      builder: (_, __) => const SurroundingFeedPage(),
    ),
    // ── Deep-linkable: public group ──────────────────────────────────────
    // https://<host>/group/<groupId>?dl=1&relays=...&name=...
    GoRoute(
      name: AppRoutes.groupDetail,
      path: '/$kGroupSegment/:groupId',
      redirect: (_, state) async {
        // In-app navigation (no dl flag) → build the page directly; the user is
        // already a member, so skip the membership/relay/auth round-trips.
        if (state.uri.queryParameters[kDeepLinkFlag] != '1') return null;
        // External link: require an identity first, then sync relay hints.
        final gate = await _deepLinkAuthGate();
        if (gate != null) return gate;
        final relays = state.uri.queryParametersAll['relays'] ?? const [];
        await ensureRelays(relays);
        final id = state.pathParameters['groupId']!;
        final res = await getIt<GetGroupByIdUseCase>().call(id);
        if (res.isRight()) return null; // joined → show detail
        // Not joined → carry hints to the pre-filled join page.
        final name = state.uri.queryParameters['name'];
        return Uri(path: '/join-group', queryParameters: {
          'cid': id,
          if (name != null) 'name': name,
          if (relays.isNotEmpty) 'relays': relays,
        }).toString();
      },
      builder: (_, state) =>
          GroupFeedPage(groupId: state.pathParameters['groupId']!),
    ),
    // Legacy `/channel/<id>` deep links (pre channel→group rename) → forward to
    // the canonical `/group/<id>` route, preserving query hints.
    GoRoute(
      path: '/$kLegacyGroupSegment/:groupId',
      redirect: (_, state) {
        final id = state.pathParameters['groupId']!;
        final q = state.uri.query;
        return '/$kGroupSegment/$id${q.isNotEmpty ? '?$q' : ''}';
      },
    ),
    GoRoute(
      name: AppRoutes.graph,
      path: '/graph',
      pageBuilder: (_, state) => const NoTransitionPage(child: GraphPage()),
    ),
    GoRoute(
      name: AppRoutes.createDm,
      path: '/create-dm',
      builder: (_, state) {
        final extra = state.extra;
        return CreateDmPage(
          initialPubkey: extra is String ? extra : null,
          payload: extra is UniunQrPayload ? extra : null,
        );
      },
    ),
    // In-app only — opening a DM thread. DMs are not universal-linkable; a
    // shared `/user/<npub>` link opens the person's profile (below) instead.
    GoRoute(
      name: AppRoutes.chatDm,
      path: '/dm/:id',
      builder: (_, state) =>
          DmChatPage(otherPubkey: _normalizePubkey(state.pathParameters['id']!)),
    ),
    GoRoute(
      name: AppRoutes.brahmaCreate,
      path: '/brahma-create',
      builder: (_, state) {
        final args = _asMap(state.extra);
        return GraphComposePage(
          initialDraftId: args?['draftId'] as String?,
          autoPublish: args?['autoPublish'] as bool? ?? false,
        );
      },
    ),
    GoRoute(
      name: AppRoutes.brahmaManasForm,
      path: '/brahma/manas/form',
      builder: (_, state) {
        final args = _asMap(state.extra);
        return ManasFormPage(manasId: args?['manasId'] as String?);
      },
    ),
    GoRoute(
      name: AppRoutes.shivGanaList,
      path: '/shiv/gana',
      builder: (_, __) => const GanaDashboardPage(),
    ),
    GoRoute(
      name: AppRoutes.shivGanaForm,
      path: '/shiv/gana/form',
      builder: (_, state) {
        final args = _asMap(state.extra);
        return GanaFormPage(ganaId: args?['ganaId'] as String?);
      },
    ),
    GoRoute(
      name: AppRoutes.shivGanaDetail,
      path: '/shiv/gana/:ganaId',
      builder: (_, state) =>
          GanaDetailPage(ganaId: state.pathParameters['ganaId']!),
    ),
    GoRoute(
      name: AppRoutes.shivNataraj,
      path: '/nataraj',
      builder: (_, state) {
        final manasIds =
            (_asMap(state.extra)?['manasIds'] as List?)?.cast<String>() ??
                const <String>[];
        return BlocProvider(
          create: (_) =>
              getIt<ShivAIBloc>()..add(const ShivAIEvent.loadConversations()),
          child: NatarajDeckPage(manasIds: manasIds),
        );
      },
    ),
    GoRoute(
      name: AppRoutes.privateGroupEntry,
      path: '/private-group-entry',
      builder: (_, __) => const PrivateGroupEntryPage(),
    ),
    GoRoute(
      name: AppRoutes.createPrivateGroup,
      path: '/create-private-group',
      builder: (_, __) => const CreatePrivateGroupPage(),
    ),
    GoRoute(
      name: AppRoutes.joinPrivateGroup,
      path: '/join-private-group',
      builder: (_, state) =>
          JoinPrivateGroupPage(payload: _privatePayloadFrom(state)),
    ),
    // ── Deep-linkable: private group ─────────────────────────────────────
    // https://<host>/private/<groupId>?dl=1&relays=...&name=...
    GoRoute(
      name: AppRoutes.privateGroupDetail,
      path: '/$kPrivateSegment/:groupId',
      redirect: (_, state) async {
        if (state.uri.queryParameters[kDeepLinkFlag] != '1') return null;
        final gate = await _deepLinkAuthGate();
        if (gate != null) return gate;
        final relays = state.uri.queryParametersAll['relays'] ?? const [];
        await ensureRelays(relays);
        final id = state.pathParameters['groupId']!;
        final group =
            await getIt<GetPrivateGroupEntityUsecase>().execute(id);
        if (group != null) return null; // joined → show detail
        final name = state.uri.queryParameters['name'];
        return Uri(path: '/join-private-group', queryParameters: {
          'gid': id,
          if (name != null) 'name': name,
          if (relays.isNotEmpty) 'relays': relays,
        }).toString();
      },
      builder: (_, state) =>
          PrivateGroupDetailPage(groupId: state.pathParameters['groupId']!),
    ),
    GoRoute(
      name: AppRoutes.scanQr,
      path: '/scan-qr',
      builder: (_, state) => UniunQrScannerPage(
        intent: state.extra is UniunQrScanIntent
            ? state.extra as UniunQrScanIntent
            : UniunQrScanIntent.generic,
      ),
    ),
    // In-app only — landing surface for content shared INTO UNIUN from another
    // app. Not universal-linkable; reached via pushNamed from the share-intent
    // listener with a SharedIncoming payload in `extra`.
    GoRoute(
      name: AppRoutes.receiveShare,
      path: '/receive-share',
      builder: (_, state) => ReceiveShareSheetPage(
        incoming: state.extra as SharedIncoming,
      ),
    ),
    // In-app profile route (args passed via `extra`).
    GoRoute(
      name: AppRoutes.userProfile,
      path: '/user-profile',
      builder: (_, state) =>
          UserProfilePage(args: state.extra is UserProfileArgs
              ? state.extra as UserProfileArgs
              : null),
    ),
    // ── Deep-linkable: user profile ────────────────────────────────────────
    // https://<host>/user/<npub>?dl=1&relays=...  (path id may be npub or hex)
    GoRoute(
      path: '/$kUserSegment/:id',
      redirect: (_, state) async {
        if (state.uri.queryParameters[kDeepLinkFlag] != '1') return null;
        final gate = await _deepLinkAuthGate();
        if (gate != null) return gate;
        await ensureRelays(state.uri.queryParametersAll['relays'] ?? const []);
        return null;
      },
      builder: (_, state) => UserProfilePage(
        args: UserProfileArgs(
          pubkeyHex: _normalizePubkey(state.pathParameters['id']!),
          hintName: state.uri.queryParameters['name'],
        ),
      ),
    ),
  ],
);

/// Guards the deep-linkable routes: a universal link tapped before the user has
/// an identity is sent to onboarding (otherwise they'd land on a page that needs
/// a signing key). Returns a redirect path, or null when an identity exists.
Future<String?> _deepLinkAuthGate() async {
  final active = await getIt<GetActiveUserUseCase>().call();
  return active.isLeft() ? '/welcome' : null;
}

Map? _asMap(Object? extra) => extra is Map ? extra : null;

String _normalizePubkey(String raw) {
  try {
    return normalizeNostrPubkey(raw);
  } catch (_) {
    return raw.toLowerCase();
  }
}

/// Rebuilds a public-group [UniunQrPayload] from either the QR scanner's
/// `extra` or the not-joined redirect's query params.
UniunQrPayload? _groupPayloadFrom(GoRouterState state) {
  final extra = state.extra;
  if (extra is UniunQrPayload) return extra;
  final cid = state.uri.queryParameters['cid'];
  if (cid == null || cid.isEmpty) return null;
  return UniunQrPayload(
    kind: UniunQrKind.publicGroup,
    id: cid,
    name: state.uri.queryParameters['name'],
    relays: state.uri.queryParametersAll['relays'] ?? const [],
  );
}

UniunQrPayload? _privatePayloadFrom(GoRouterState state) {
  final extra = state.extra;
  if (extra is UniunQrPayload) return extra;
  final gid = state.uri.queryParameters['gid'];
  if (gid == null || gid.isEmpty) return null;
  return UniunQrPayload(
    kind: UniunQrKind.privateGroup,
    id: gid,
    name: state.uri.queryParameters['name'],
    relays: state.uri.queryParametersAll['relays'] ?? const [],
  );
}
