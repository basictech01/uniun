import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:uniun/common/atoms/uniun_back_button.dart';
import 'package:uniun/common/note_thread_navigator.dart';
import 'package:uniun/common/widgets/drop_loading_indicator.dart';
import 'package:uniun/domain/entities/saved_note/saved_note_entity.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/features/saved_notes/cubit/saved_notes_cubit.dart';
import 'package:uniun/features/saved_notes/cubit/saved_notes_state.dart';
import 'package:uniun/features/thread/pages/thread_page.dart';
import 'package:uniun/common/widgets/note_card/note_card.dart';

class SavedNotesPage extends StatelessWidget {
  const SavedNotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider(create: (_) => SavedNotesCubit()..load())],
      child: const _SavedNotesView(),
    );
  }
}

// ── View ───────────────────────────────────────────────────────────────────────

class _SavedNotesView extends StatefulWidget {
  const _SavedNotesView();

  @override
  State<_SavedNotesView> createState() => _SavedNotesViewState();
}

class _SavedNotesViewState extends State<_SavedNotesView> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SavedNoteEntity> _filter(List<SavedNoteEntity> notes) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return notes;
    return notes.where((n) {
      return n.content.toLowerCase().contains(q) ||
          n.tTags.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        leading: const UniunBackButton(),
        title: Text(
          l10n.savedNotesTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        elevation: 0,
      ),
      body: KeyboardDismissOnTap(
        child: BlocBuilder<SavedNotesCubit, SavedNotesState>(
          builder: (context, state) {
            if (state.status == SavedNotesStatus.initial ||
                state.status == SavedNotesStatus.loading) {
              return Center(
                child: DropLoadingIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              );
            }
            if (state.status == SavedNotesStatus.error) {
              return Center(
                child: Text(
                  state.errorMessage ?? 'Failed to load saved notes',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              );
            }

            final filtered = _filter(state.notes);

            return Column(
              children: [
                // ── Search bar ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.savedNotesSearch,
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      suffixIcon: _query.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            )
                          : null,
                      filled: true,
                      fillColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLow,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // ── List ────────────────────────────────────────────────────
                Expanded(
                  child: RefreshIndicator(
                    color: Theme.of(context).colorScheme.primary,
                    onRefresh: () => context.read<SavedNotesCubit>().load(),
                    child: filtered.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.5,
                                child: state.notes.isEmpty
                                    ? const _EmptyState()
                                    : const _NoResultsState(),
                              ),
                            ],
                          )
                        : Builder(
                            builder: (ctx) {
                              return ListView.separated(
                                padding: const EdgeInsets.only(bottom: 24),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox.shrink(),
                                itemBuilder: (ctx, i) {
                                  final cubit = context.read<SavedNotesCubit>();
                                  final note = filtered[i];
                                  final savedEventIds = state.notes
                                      .map((n) => n.eventId)
                                      .toSet();
                                  return NoteCard(
                                    key: ValueKey(note.eventId),
                                    note: note.toNoteEntity(
                                      savedEventIds: savedEventIds,
                                      sourceLabel:
                                          state.sourceLabels[note.eventId],
                                    ),
                                    onTap: () async {
                                      await openEventThread(
                                        ctx,
                                        note.eventId,
                                        openAsNote: () => Navigator.push(
                                          ctx,
                                          MaterialPageRoute(
                                            builder: (_) => ThreadPage(
                                              noteId: note.eventId,
                                              savedOnly: true,
                                            ),
                                          ),
                                        ),
                                      );
                                      cubit.load();
                                    },
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.savedNotesEmpty,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.savedNotesEmptySub,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  const _NoResultsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        AppLocalizations.of(context)!.savedNoSearchResults,
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
