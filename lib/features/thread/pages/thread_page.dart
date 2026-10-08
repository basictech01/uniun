import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/common/widgets/drop_loading_indicator.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/features/thread/bloc/thread_bloc.dart';
import 'package:uniun/features/thread/widgets/thread_app_bar.dart';
import 'package:uniun/features/thread/widgets/thread_empty_states.dart';
import 'package:uniun/common/widgets/thread/message_thread_page.dart';

/// The single thread screen for every note, regardless of which collection
/// holds it. [ThreadBloc] resolves the id across all collections.
class ThreadPage extends StatelessWidget {
  const ThreadPage({super.key, required this.noteId, this.savedOnly = false});
  final String noteId;
  final bool savedOnly;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<ThreadBloc>()
            ..add(LoadThreadEvent(noteId, savedOnly: savedOnly)),
        ),
      ],
      child: _ThreadView(noteId: noteId),
    );
  }
}

class _ThreadView extends StatefulWidget {
  const _ThreadView({required this.noteId});
  final String noteId;

  @override
  State<_ThreadView> createState() => _ThreadViewState();
}

class _ThreadViewState extends State<_ThreadView> {
  // Note ids currently open as a ThreadPage, in stack order (oldest first) —
  // prevents pushing a duplicate of a page already in the back stack, and lets
  // us pop back to it. A list (not a set) so we know how many pages sit above a
  // given thread; go_router names pages by route name ('thread'), not by the
  // resolved location, so we can't identify a page by its note id via Route.
  static final List<String> _openNoteIds = [];

  @override
  void initState() {
    super.initState();
    _openNoteIds.add(widget.noteId);
  }

  @override
  void dispose() {
    _openNoteIds.remove(widget.noteId);
    super.dispose();
  }

  void _openThread(BuildContext ctx, String noteId) {
    final existingIndex = _openNoteIds.indexOf(noteId);
    if (existingIndex != -1) {
      // Already open deeper in the stack — pop the thread pages stacked above it
      // instead of pushing a duplicate. We pop by count (rather than matching on
      // Route) because go_router names every thread page 'thread', so a Route
      // can't be identified by its note id.
      final popCount = _openNoteIds.length - 1 - existingIndex;
      final navigator = Navigator.of(ctx);
      for (var i = 0; i < popCount && navigator.canPop(); i++) {
        navigator.pop();
      }
      return;
    }
    final bloc = context.read<ThreadBloc>();
    final savedOnly = bloc.state.savedOnly;
    // Reload this thread when the child pops so new nested replies are reflected.
    ctx
        .pushNamed(
      AppRoutes.thread,
      pathParameters: {'noteId': noteId},
      extra: savedOnly ? true : null,
    )
        .then((_) {
      if (mounted) {
        bloc.add(LoadThreadEvent(widget.noteId, savedOnly: savedOnly));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ThreadBloc, ThreadState>(
      listenWhen: (prev, curr) => prev.postStatus != curr.postStatus,
      listener: (context, state) {
        if (state.postStatus == ThreadPostStatus.error &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        if (state.status == ThreadStatus.loading ||
            state.status == ThreadStatus.initial) {
          return Scaffold(
            backgroundColor: colorScheme.surface,
            appBar: const ThreadAppBar(),
            body: Center(
              child: DropLoadingIndicator(color: colorScheme.primary),
            ),
          );
        }
        if (state.status == ThreadStatus.error || state.rootNote == null) {
          return Scaffold(
            backgroundColor: colorScheme.surface,
            appBar: const ThreadAppBar(),
            body: ThreadErrorBody(
                message: state.errorMessage ?? 'Failed to load thread'),
          );
        }

        final bloc = context.read<ThreadBloc>();

        return MessageThreadPage(
          appBar: ThreadAppBar(sourceNote: state.rootNote),
          root: state.rootNote!,
          profiles: state.profiles,
          parentNotes: state.parentNotes,
          mentionedNotes: state.mentionedNotes,
          replies: state.replies,
          replyCount: state.replies.length,
          unreadMarkers: state.unreadMarkers,
          isSending: state.postStatus == ThreadPostStatus.posting,
          onSendReply: (text, refs, attachments) => bloc.add(
            PostReplyEvent(text,
                mentionRefs: refs, attachments: attachments),
          ),
          onOpenThread: (id) => _openThread(context, id),
        );
      },
    );
  }
}
