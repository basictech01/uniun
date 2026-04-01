import 'package:flutter/material.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/followed_notes/note_intelligence_detail/widgets/note_header_card.dart';
import 'package:uniun/followed_notes/note_intelligence_detail/widgets/note_intelligence_app_bar.dart';
import 'package:uniun/followed_notes/note_intelligence_detail/widgets/note_references_section.dart';
import 'package:uniun/followed_notes/note_intelligence_detail/widgets/note_thread_button.dart';

/// Displays detailed view of a single note with references, connections, and thread.
/// Input: note ID passed via route arguments (or later via parameter/cubit).
///
/// For now, showing placeholder data structure. Wire to actual note data once
/// NoteEntity + GetNoteByIdUseCase are available.
class NoteIntelligencePage extends StatelessWidget {
  const NoteIntelligencePage({super.key, this.noteId});

  final String? noteId;

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with actual cubit + bloc once GetNoteByIdUseCase is wired
    final note = _PlaceholderNoteData();

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      body: CustomScrollView(
        slivers: [
          NoteIntelligenceAppBar(onBack: () => Navigator.pop(context)),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Note Header ─────────────────────────────────────────
                NoteHeaderCard(
                  authorName: note.authorName,
                  authorPubkey: note.authorPubkey,
                  avatarUrl: note.avatarUrl,
                  content: note.content,
                  hashtags: note.hashtags,
                  timestamp: note.timestamp,
                ),
                const SizedBox(height: 20),

                // ── References ──────────────────────────────────────────
                NoteReferencesSection(
                  title: 'REFERENCES',
                  references: note.references,
                ),
                const SizedBox(height: 16),

                // ── Related Notes ───────────────────────────────────────
                NoteReferencesSection(
                  title: 'RELATED CONNECTIONS',
                  references: note.relatedConnections,
                ),
                const SizedBox(height: 16),

                // ── Thread Info ────────────────────────────────────────
                if (note.replyCount > 0) ...[
                  NoteThreadButton(
                    replyCount: note.replyCount,
                    onPressed: () {
                      // Navigate to thread view once route is set up
                      Navigator.pushNamed(
                        context,
                        AppRoutes.home, // TODO: add threadView route
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Bottom spacing ─────────────────────────────────────
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Placeholder data for now ───────────────────────────────────────────────────

class _PlaceholderNoteData {
  final String authorName = 'Elena Vance';
  final String authorPubkey =
      'npub1vance000000000000000000000000000000000000000000000';
  final String? avatarUrl = null;
  final String content =
      'The intersection of distributed systems and decentralized systems replaces 65% of direct control structures with emergent coordination patterns.';
  final List<String> hashtags = ['Quantum-Computing', 'Systems-Design'];
  final DateTime timestamp = DateTime.now().subtract(const Duration(hours: 2));
  final List<String> references = [
    'Byzantine Fault Tolerance in Asynchronous Networks (Lamport, 1982)',
    'Self-Organizing Systems and Emergence (Holland, 1995)',
    'Consensus Mechanisms in Distributed Ledgers (Nakamoto, 2008)',
  ];
  final List<String> relatedConnections = [
    'Your recent note on "Graph Theory Applications"',
    'Marcus Thorne\'s work on "Complexity and Emergence"',
    'Community discussion thread: "Protocol Design Patterns"',
  ];
  final int replyCount = 4;
}
