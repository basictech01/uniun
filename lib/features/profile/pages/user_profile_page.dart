import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:uniun/common/atoms/uniun_button.dart';
import 'package:uniun/common/atoms/uniun_back_button.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/common/snackbar.dart';
import 'package:uniun/common/widgets/drop_loading_indicator.dart';
import 'package:uniun/common/widgets/note_card/note_card.dart';
import 'package:uniun/common/widgets/user_avatar.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/router/nav_extensions.dart';
import 'package:uniun/features/profile/bloc/user_profile_bloc.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/core/theme/app_custom_colors.dart';

class UserProfileArgs {
  const UserProfileArgs({required this.pubkeyHex, this.hintName});
  final String pubkeyHex;
  final String? hintName;
}

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key, required this.args});

  final UserProfileArgs? args;

  @override
  Widget build(BuildContext context) {
    final args = this.args;
    if (args == null || args.pubkeyHex.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.canPop(context)) Navigator.pop(context);
      });
      return const Scaffold();
    }
    final hex = args.pubkeyHex;
    final hintName = args.hintName;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<UserProfileBloc>()
            ..add(LoadUserProfileEvent(hex, hintName: hintName)),
        ),
      ],
      child: const _UserProfileView(),
    );
  }
}

class _UserProfileView extends StatelessWidget {
  const _UserProfileView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: BlocBuilder<UserProfileBloc, UserProfileState>(
        builder: (context, state) {
          if (state.loading) {
            return SafeArea(
              child: Center(
                child: DropLoadingIndicator(color: Theme.of(context).colorScheme.primary),
              ),
            );
          }
          return CustomScrollView(
            slivers: [
              _GlassAppBar(state: state),
              SliverToBoxAdapter(child: _Header(state: state, l10n: l10n)),
              SliverToBoxAdapter(child: _NotesSectionLabel(l10n: l10n)),
              if (state.notes.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Center(
                      child: Text(
                        l10n.userProfileNoNotes,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final note = state.notes[i];
                      return NoteCard(
                        key: ValueKey(note.id),
                        note: note,
                        onTap: () => context.pushNamed(
                          AppRoutes.thread,
                          pathParameters: {'noteId': note.id},
                        ),
                      );
                    },
                    childCount: state.notes.length,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Pinned, translucent app bar. Keeps the user's name as the title.
class _GlassAppBar extends StatelessWidget {
  const _GlassAppBar({required this.state});

  final UserProfileState state;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.80),
              border: Border(
                bottom: BorderSide(color: context.custom.borderSubtle),
              ),
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          const SizedBox(width: 4),
          UniunBackButton(onPressed: () => context.popOrHome()),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              _displayName(state),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state, required this.l10n});

  final UserProfileState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final hex = state.pubkeyHex ?? '';
    final profile = state.profile;
    final name = _displayName(state);
    final nip05 = profile?.nip05?.trim();
    final about = profile?.about?.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar beside name + verified handle.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              UserAvatar(
                seed: hex,
                photoUrl: profile?.avatarUrl,
                size: 64,
                showBorder: true,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (nip05 != null && nip05.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            size: 15,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              nip05,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // npub + copy.
          const SizedBox(height: 12),
          _NpubRow(pubkeyHex: hex, l10n: l10n),

          // about.
          if (about != null && about.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              about,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.55,
                color: context.custom.textBody,
              ),
            ),
          ],

          // actions.
          if (!state.isSelf) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _FollowButton(state: state)),
                const SizedBox(width: 10),
                Expanded(child: _MessageButton(pubkeyHex: hex)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _NpubRow extends StatelessWidget {
  const _NpubRow({required this.pubkeyHex, required this.l10n});

  final String pubkeyHex;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final npub = Nip19.encodePubkey(pubkeyHex);
    final shown = npub.length > 20
        ? '${npub.substring(0, 14)}…${npub.substring(npub.length - 4)}'
        : npub;
    return Row(
      children: [
        Flexible(
          child: Text(
            shown,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontFeatures: [FontFeature.tabularFigures()],
              color: context.custom.textMuted,
            ),
          ),
        ),
        const SizedBox(width: 2),
        IconButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: npub));
            AppSnackbar.success(context, l10n.drawerNpubCopied);
          },
          tooltip: l10n.userProfileCopyNpub,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
          icon: Icon(
            Icons.content_copy_rounded,
            size: 14,
            color: context.custom.textMuted,
          ),
        ),
      ],
    );
  }
}

class _NotesSectionLabel extends StatelessWidget {
  const _NotesSectionLabel({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: context.custom.borderSubtle),
          bottom: BorderSide(color: context.custom.borderSubtle),
        ),
      ),
      child: Text(
        l10n.userProfileNotesLabel.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: context.custom.textMuted,
        ),
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.state});

  final UserProfileState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isFollowing = state.isFollowing;
    final onPressed = state.busy
        ? null
        : () => context.read<UserProfileBloc>().add(const ToggleFollowEvent());

    if (isFollowing) {
      return UniunButton(
        variant: UniunButtonVariant.outlined,
        height: 40,
        borderRadius: 22,
        borderColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.check_rounded, size: 18),
        label: l10n.userProfileFollowing,
        onPressed: onPressed,
      );
    }
    return UniunButton(
      height: 40,
      borderRadius: 22,
      icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
      label: l10n.userProfileFollow,
      onPressed: onPressed,
    );
  }
}

class _MessageButton extends StatelessWidget {
  const _MessageButton({required this.pubkeyHex});

  final String pubkeyHex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return UniunButton(
      variant: UniunButtonVariant.outlined,
      height: 40,
      borderRadius: 22,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      borderColor: Theme.of(context).colorScheme.outlineVariant,
      icon: const Icon(Icons.mail_outline_rounded, size: 18),
      label: l10n.userProfileMessage,
      onPressed: () => context.pushNamed(
        AppRoutes.createDm,
        extra: pubkeyHex,
      ),
    );
  }
}

/// Best display name: profile name → username → hint → truncated hex.
String _displayName(UserProfileState state) {
  final hex = state.pubkeyHex ?? '';
  final profile = state.profile;
  final hint = state.hintName?.trim();
  if (profile?.name?.trim().isNotEmpty == true) return profile!.name!;
  if (profile?.username?.trim().isNotEmpty == true) return profile!.username!;
  if (hint != null && hint.isNotEmpty) return hint;
  return hex.length > 12 ? '${hex.substring(0, 12)}…' : hex;
}
