import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';
import 'package:uniun/followed_notes/cubit/followed_notes_cubit.dart';
import 'package:uniun/thread/bloc/thread_bloc.dart';
import 'package:uniun/thread/widgets/thread_app_bar.dart';
import 'package:uniun/thread/widgets/thread_empty_states.dart'; // ThreadEmptyReplies
import 'package:uniun/thread/widgets/thread_reply_composer.dart';
import 'package:uniun/thread/widgets/thread_reply_item.dart';
import 'package:uniun/thread/widgets/thread_root_note_card.dart';

class ThreadPage extends StatelessWidget {
  const ThreadPage({super.key, required this.noteId});
  final String noteId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<ThreadBloc>()..add(LoadThreadEvent(noteId)),
        ),
        BlocProvider(
          create: (_) => getIt<FollowedNotesCubit>()..load(),
        ),
      ],
      child: const _ThreadView(),
    );
  }
}

// ── View ──────────────────────────────────────────────────────────────────────

class _ThreadView extends StatefulWidget {
  const _ThreadView();

  @override
  State<_ThreadView> createState() => _ThreadViewState();
}

class _ThreadViewState extends State<_ThreadView> {
  final _replyController = TextEditingController();
  final _focusNode = FocusNode();
  String? _avatarUrl;
  String _pubkeySeed = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final result = await getIt<GetActiveUserProfileUseCase>().call();
    result.fold((_) {}, (userProfile) {
      if (mounted) {
        setState(() {
          _pubkeySeed = userProfile.pubkeyHex;
          _avatarUrl = userProfile.avatarUrl;
        });
      }
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ThreadBloc, ThreadState>(
      listener: (context, state) {
        if (state.postStatus == ThreadPostStatus.posted) {
          _replyController.clear();
          _focusNode.unfocus();
        }
        if (state.postStatus == ThreadPostStatus.error &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      builder: (context, state) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Scaffold(
            backgroundColor: AppColors.surface,
            appBar: const ThreadAppBar(),
            body: switch (state.status) {
              ThreadStatus.loading || ThreadStatus.initial => const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 2),
                ),
              ThreadStatus.error => ThreadErrorBody(
                  message: state.errorMessage ?? 'Failed to load thread'),
              _ => _ThreadBody(state: state, focusNode: _focusNode),
            },
            bottomNavigationBar: ThreadReplyComposer(
              state: state,
              controller: _replyController,
              focusNode: _focusNode,
              avatarUrl: _avatarUrl,
              pubkeySeed: _pubkeySeed,
            ),
          ),
        );
      },
    );
  }
}

// ── Body — scroll + sliver layout ────────────────────────────────────────────

class _ThreadBody extends StatelessWidget {
  const _ThreadBody({required this.state, required this.focusNode});
  final ThreadState state;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final root = state.rootNote!;

    return CustomScrollView(
      slivers: [
        // Root note card
        SliverPadding(
          padding: const EdgeInsets.only(top: 16, left: 20, right: 20),
          sliver: SliverToBoxAdapter(
            child: ThreadRootNoteCard(
              note: root,
              profile: state.profileFor(root.authorPubkey),
            ),
          ),
        ),

        // Replies
        if (state.replies.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: ThreadEmptyReplies(),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.only(
                left: 20, right: 20, top: 12, bottom: 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final reply = state.replies[i];
                  final name = state.profileFor(reply.authorPubkey)?.name ??
                      reply.authorPubkey.substring(0, 8);
                  return ThreadReplyItem(
                    key: ValueKey(reply.id),
                    reply: reply,
                    profile: state.profileFor(reply.authorPubkey),
                    nestedReplies: state.nestedReplies[reply.id] ?? [],
                    nestedProfiles: state.profiles,
                    allNestedReplies: state.nestedReplies,
                    replyCounts: state.replyCounts,
                    replyCount: state.replyCounts[reply.id] ?? 0,
                    showThreadLine: i < state.replies.length - 1,
                    onReplyTap: () {
                      ctx.read<ThreadBloc>().add(
                            SetReplyTargetEvent(
                                replyToId: reply.id, replyToName: name),
                          );
                      focusNode.requestFocus();
                    },
                  );
                },
                childCount: state.replies.length,
              ),
            ),
          ),
      ],
    );
  }
}

