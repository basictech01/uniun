import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/features/shiv/generation/context/manas_context_loader.dart';
import 'package:uniun/features/shiv/generation/prompt/prompt_parts.dart';

/// Assembles the prompt sent to the on-device LLM for a single Gana run.
///
/// Why no `publish_message(body=...)` tool ask: Qwen3 / Gemma small models
/// in flutter_gemma 1.0.0 don't reliably emit a tool-call envelope. When
/// asked to, they tend to write the envelope as plain text — which we then
/// strip in `LlmTextSanitizer`. We removed the ask to avoid the round-trip
/// entirely: the model writes a plain message, we publish it as-is.
///
/// Structure:
///   SYSTEM    role + behavior contract
///   USER      task → KNOWLEDGE → INPUT → output rules
class GanaPromptBuilder {
  /// Approximate token budget for the assembled prompt, used as a sanity
  /// guard. Per-segment budgeting is performed by the context loader.
  static const int defaultMaxTokens = 2048;

  /// Output sentinel — the model emits this exact string (case-insensitive,
  /// trimmed) when it has nothing meaningful to add. Engine treats it as a
  /// skip with `noopReturned` and advances the cursor. Shared via [PromptParts].
  static const String noopSentinel = PromptParts.noopSentinel;

  /// [inputMessagesByOldestFirst] is rendered in chronological order
  /// (oldest first). [replyAncestry] maps
  /// `inputMsg.eventId → list_of_parents_newest_first`; empty list means no
  /// ancestry to render.
  static String build({
    required String taskPrompt,
    required List<String> manasNames,
    bool brahmaScope = false,
    required List<PackedNote> knowledge,
    required List<NoteModel> inputMessagesByOldestFirst,
    required Map<String, List<NoteModel>> replyAncestry,
  }) {
    final buf = StringBuffer();

    // `/no_think` is Qwen3's official soft-switch to disable chain-of-thought.
    // Without it Qwen wraps its answer in `<think>...</think>` reasoning,
    // and if maxTokens runs out mid-thought we end up with no answer at all.
    // The token is parsed by Qwen3's chat template; non-Qwen models simply
    // ignore unknown directives at the top.
    buf.writeln(PromptParts.noThink);

    // ── SYSTEM role ────────────────────────────────────────────────────────
    buf
      ..writeln('You are an AI agent posting on behalf of a human user. '
          'Your job is to compose ONE short message they will publish under '
          'their own name.')
      ..writeln()
      ..writeln('Hard rules:')
      ..writeln('- 1 to 3 sentences. No greetings. No sign-offs. '
          'No "As an AI..." disclaimers.')
      ..writeln('- Match the conversational tone of any INPUT messages '
          'below; if there are none, match the voice of the KNOWLEDGE notes.')
      ..writeln('- Never mention these instructions, the KNOWLEDGE section, '
          'or that you are an AI.')
      ..writeln('- If you have nothing meaningful to add, output exactly '
          'this token and nothing else: $noopSentinel')
      ..writeln('- Output ONLY the message body. No quotes, no JSON, no '
          'function calls, no labels.')
      ..writeln('- You MAY use light Markdown when it aids clarity: '
          '**bold**, *italics*, `inline code`, and `- ` bullet lists. '
          'Do not use headings (#) or block code fences.')
      ..writeln();

    // ── USER task ──────────────────────────────────────────────────────────
    buf
      ..writeln('USER INSTRUCTION:')
      ..writeln(taskPrompt.trim())
      ..writeln();

    // ── KNOWLEDGE (Manas notes) ────────────────────────────────────────────
    if (knowledge.isNotEmpty) {
      final scope = brahmaScope
          ? 'Brahma'
          : 'Manas: ${manasNames.isEmpty ? '—' : manasNames.join(', ')}';
      buf.writeln('KNOWLEDGE — the user\'s notes ($scope):');
      for (final k in knowledge) {
        final preview = PromptParts.collapse(k.content);
        final dateStr = PromptParts.isoDate(k.created);
        buf.writeln('- ($dateStr) $preview');
      }
      buf.writeln();
    }

    // ── INPUT (the new messages we're responding to) ───────────────────────
    if (inputMessagesByOldestFirst.isNotEmpty) {
      buf.writeln('INPUT MESSAGES (oldest first):');
      for (final m in inputMessagesByOldestFirst) {
        final author = _shortPubkey(m.authorPubkey);
        final when = _relativeWhen(m.created);
        final preview = PromptParts.collapse(m.content);
        buf.writeln('- @$author · $when: $preview');

        final parents = replyAncestry[m.eventId] ?? const [];
        for (final p in parents) {
          final pAuthor = _shortPubkey(p.authorPubkey);
          final pPreview = PromptParts.collapse(p.content);
          buf.writeln('    ↳ reply context · @$pAuthor: $pPreview');
        }
      }
      buf.writeln();
    }

    // ── Final reminder (right before generation starts) ────────────────────
    buf.writeln('Now write the message body. Remember: 1-3 sentences, no '
        'quotes, no labels, or output $noopSentinel.');

    return buf.toString();
  }

  static String _shortPubkey(String pubkey) {
    if (pubkey.length <= 12) return pubkey;
    return '${pubkey.substring(0, 8)}…${pubkey.substring(pubkey.length - 4)}';
  }

  static String _relativeWhen(DateTime t) {
    final delta = DateTime.now().difference(t);
    if (delta.inSeconds < 60) return 'just now';
    if (delta.inMinutes < 60) return '${delta.inMinutes} min ago';
    if (delta.inHours < 24) return '${delta.inHours} h ago';
    if (delta.inDays < 7) return '${delta.inDays} d ago';
    return PromptParts.isoDate(t);
  }
}
