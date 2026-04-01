import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/domain/entities/followed_note/followed_note_entity.dart';
import 'package:uniun/followed_notes/cubit/followed_notes_cubit.dart';
import 'package:uniun/followed_notes/widgets/followed_note_card.dart';
import 'package:uniun/followed_notes/widgets/followed_notes_app_bar.dart';
import 'package:uniun/followed_notes/widgets/followed_notes_empty_state.dart';
import 'package:uniun/followed_notes/widgets/followed_notes_filter_row.dart';
import 'package:uniun/followed_notes/widgets/followed_notes_search_bar.dart';

class FollowedNotesPage extends StatelessWidget {
  const FollowedNotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<FollowedNotesCubit>()..load(),
      child: const _FollowedNotesView(),
    );
  }
}

class _FollowedNotesView extends StatefulWidget {
  const _FollowedNotesView();

  @override
  State<_FollowedNotesView> createState() => _FollowedNotesViewState();
}

class _FollowedNotesViewState extends State<_FollowedNotesView> {
  final _searchController = TextEditingController();
  FollowedNotesFilter _activeFilter = FollowedNotesFilter.all;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FollowedNoteEntity> _applyFilter(List<FollowedNoteEntity> notes) {
    var list = notes;

    if (_query.isNotEmpty) {
      list = list
          .where((n) =>
              n.contentPreview.toLowerCase().contains(_query.toLowerCase()))
          .toList();
    }

    switch (_activeFilter) {
      case FollowedNotesFilter.all:
        break;
      case FollowedNotesFilter.updated:
      case FollowedNotesFilter.unread:
        list = list.where((n) => n.newReferenceCount > 0).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      body: CustomScrollView(
        slivers: [
          FollowedNotesAppBar(onBack: () => Navigator.pop(context)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Following',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                      height: 1.1,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Track notes and see how they evolve.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FollowedNotesSearchBar(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  const SizedBox(height: 16),
                  FollowedNotesFilterRow(
                    active: _activeFilter,
                    onChanged: (f) => setState(() => _activeFilter = f),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          BlocBuilder<FollowedNotesCubit, FollowedNotesState>(
            builder: (context, state) {
              if (state.status == FollowedNotesStatus.loading) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }

              if (state.status == FollowedNotesStatus.error) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(
                      state.error ?? 'Something went wrong',
                      style:
                          const TextStyle(color: AppColors.onSurfaceVariant),
                    ),
                  ),
                );
              }

              final filtered = _applyFilter(state.notes);

              if (filtered.isEmpty) {
                return const SliverFillRemaining(
                    child: FollowedNotesEmptyState());
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final note = filtered[i];
                    return FollowedNoteCard(
                      note: note,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.followedNoteFeed,
                          arguments: note.eventId,
                        );
                        context
                            .read<FollowedNotesCubit>()
                            .clearNewReferences(note.eventId);
                      },
                      onUnfollow: () =>
                          _confirmUnfollow(context, note.eventId),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmUnfollow(BuildContext context, String eventId) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Unfollow note?',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface),
        ),
        content: const Text(
          'You will stop receiving new reference updates for this note.',
          style: TextStyle(
              fontSize: 14, color: AppColors.onSurfaceVariant, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<FollowedNotesCubit>().unfollowNote(eventId);
            },
            child: const Text(
              'Unfollow',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
