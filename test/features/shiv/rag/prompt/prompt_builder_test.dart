import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/core/enum/document_kind.dart';
import 'package:uniun/core/enum/message_role.dart';
import 'package:uniun/domain/entities/graph_edge/graph_edge_entity.dart';
import 'package:uniun/domain/entities/graph_node/graph_node_entity.dart';
import 'package:uniun/domain/entities/memory_node/memory_node_entity.dart';
import 'package:uniun/domain/entities/shiv/scored_chunk.dart';
import 'package:uniun/domain/entities/shiv/scored_note.dart';
import 'package:uniun/domain/entities/shiv/shiv_message_entity.dart';
import 'package:uniun/features/shiv/rag/prompt/prompt_budget.dart';
import 'package:uniun/features/shiv/rag/prompt/prompt_builder.dart';
import 'package:uniun/features/shiv/rag/retrieval/enriched_context.dart';

ShivMessageEntity _msg(MessageRole role, String content) => ShivMessageEntity(
      messageId: 'm',
      conversationId: 'c',
      role: role,
      content: content,
      createdAt: DateTime(2026, 1, 1),
    );

ScoredNote _note(String id, String content, {double score = 0.9}) =>
    ScoredNote(noteId: id, score: score, content: content);

GraphEdgeEntity _edge(String source, String target, {String type = 'related'}) =>
    GraphEdgeEntity(
      sourceKey: source,
      targetKey: target,
      relationType: type,
      sourceNoteId: 'n1',
      createdAt: DateTime(2026, 1, 1),
    );

GraphNodeEntity _node(String key, String name) => GraphNodeEntity(
      key: key,
      name: name,
      type: 'concept',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

ScoredChunk _chunk(
  String content, {
  String label = '3',
  int ordinal = 0,
  DocumentKind kind = DocumentKind.pdf,
}) =>
    ScoredChunk(
      chunkId: 's:$ordinal',
      sha256: 's',
      kind: kind,
      label: label,
      score: 0.9,
      content: content,
    );

MemoryNodeEntity _memory(String summary) => MemoryNodeEntity(
      noteId: 'n1',
      summary: summary,
      keyPoints: const [],
      concepts: const [],
      linkedNoteIds: const [],
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  const builder = PromptBuilder();
  final defaultBudget = PromptBudget.forActiveModel(null);

  group('buildSystemInstruction', () {
    test('with no name/bio, omits the personalization block entirely', () {
      final s = builder.buildSystemInstruction(const PersonalizationContext());

      expect(s, contains('You are Shiv'));
      expect(s, isNot(contains('user\'s name')));
      expect(s, isNot(endsWith('\n')));
    });

    test('with a name but no bio, includes the name line only', () {
      final s = builder.buildSystemInstruction(
          const PersonalizationContext(userName: 'Alice'));

      expect(s, contains('The user\'s name is Alice'));
      expect(s, isNot(contains('About the user')));
    });

    test('with name and bio, includes both', () {
      final s = builder.buildSystemInstruction(const PersonalizationContext(
          userName: 'Alice', userBio: 'Loves hiking'));

      expect(s, contains('The user\'s name is Alice'));
      expect(s, contains('About the user: Loves hiking'));
    });

    test('an empty-string name is treated as absent', () {
      final s = builder.buildSystemInstruction(
          const PersonalizationContext(userName: '', userBio: 'bio'));

      expect(s, isNot(contains('user\'s name')));
      expect(s, isNot(contains('About the user')));
    });

    test('a bio with an empty name is not rendered (name gates bio)', () {
      final s = builder.buildSystemInstruction(
          const PersonalizationContext(userBio: 'orphan bio'));

      expect(s, isNot(contains('orphan bio')));
    });
  });

  group('buildBranchContextSummary', () {
    test('an empty branch returns an empty string', () {
      expect(builder.buildBranchContextSummary(const []), '');
    });

    test('renders each message with its role label', () {
      final s = builder.buildBranchContextSummary([
        _msg(MessageRole.user, 'What is the weather?'),
        _msg(MessageRole.assistant, 'It is sunny today.'),
      ]);

      expect(s, contains('User: What is the weather?'));
      expect(s, contains('Shiv: It is sunny today.'));
      expect(s, contains('[Continue naturally from this context]'));
    });

    test('caps to the last 6 messages (3 exchanges) of a longer branch', () {
      final branch = List.generate(
          10, (i) => _msg(MessageRole.user, 'message $i'));

      final s = builder.buildBranchContextSummary(branch);

      expect(s, isNot(contains('message 3')));
      expect(s, contains('message 4'));
      expect(s, contains('message 9'));
    });

    test('a user message is truncated to the first sentence within 100 chars',
        () {
      final s = builder.buildBranchContextSummary([
        _msg(MessageRole.user, 'Is this a question? This part should be cut.'),
      ]);

      expect(s, contains('User: Is this a question?'));
      expect(s, isNot(contains('This part should be cut')));
    });

    test('a user message with no sentence boundary within 100 chars is '
        'hard-truncated with an ellipsis', () {
      final long = 'x' * 150;
      final s = builder.buildBranchContextSummary([_msg(MessageRole.user, long)]);

      expect(s, contains('${'x' * 100}…'));
    });

    test('an assistant message strips markdown (headers, bold, code, '
        'bullets) before summarizing', () {
      final s = builder.buildBranchContextSummary([
        _msg(MessageRole.assistant,
            '# Header\n**bold** and `code` and\n- a bullet\n1. numbered. Rest.'),
      ]);

      expect(s, isNot(contains('#')));
      expect(s, isNot(contains('**')));
      expect(s, isNot(contains('`')));
    });

    test('an empty-after-trim message summarizes as an ellipsis, not a '
        'crash', () {
      final s = builder.buildBranchContextSummary([_msg(MessageRole.user, '   ')]);

      expect(s, contains('User: …'));
    });
  });

  group('buildUserMessage — no context (persona-only path)', () {
    test('empty context still anchors persona and asks the question', () {
      final msg = builder.buildUserMessage(
        userQuestion: 'hi there',
        context: EnrichedContext.empty,
        budget: defaultBudget,
      );

      expect(msg, contains('You are Shiv. Reply as Shiv.'));
      expect(msg, contains('Question: hi there'));
      expect(msg, endsWith('Shiv:'));
    });

    test('a known userName sharpens the anchor with an explicit negation',
        () {
      final msg = builder.buildUserMessage(
        userQuestion: 'hi',
        context: EnrichedContext.empty,
        budget: defaultBudget,
        userName: 'Bob',
      );

      expect(msg, contains('You are NOT Bob'));
    });
  });

  group('buildUserMessage — with context', () {
    test('renders seed notes under "## Question" with the persona anchor '
        'immediately before it', () {
      final ctx = EnrichedContext(
        seedNotes: [_note('n1', 'a relevant note')],
        graphNodes: const [],
        graphEdges: const [],
        memories: const [],
      );

      final msg = builder.buildUserMessage(
        userQuestion: 'what did I write?',
        context: ctx,
        budget: defaultBudget,
      );

      expect(msg, contains('## Relevant Notes'));
      expect(msg, contains('• a relevant note'));
      expect(msg, contains('## Question\nwhat did I write?'));
      final personaIdx = msg.indexOf('You are Shiv');
      final questionIdx = msg.indexOf('## Question');
      expect(personaIdx, lessThan(questionIdx));
    });

    test('splits seed notes into top-2 "Relevant Notes" and the rest under '
        '"Additional Notes"', () {
      final ctx = EnrichedContext(
        seedNotes: [
          _note('n1', 'first'),
          _note('n2', 'second'),
          _note('n3', 'third'),
        ],
        graphNodes: const [],
        graphEdges: const [],
        memories: const [],
      );

      final msg = builder.buildUserMessage(
        userQuestion: 'q',
        context: ctx,
        budget: defaultBudget,
      );

      expect(msg, contains('## Relevant Notes'));
      expect(msg, contains('• first'));
      expect(msg, contains('• second'));
      expect(msg, contains('## Additional Notes'));
      expect(msg, contains('• third'));
    });

    test('renders graph relations resolving node names, falling back to '
        'the raw key when a node is missing', () {
      final ctx = EnrichedContext(
        seedNotes: const [],
        graphNodes: [_node('catKey', 'Cats')],
        graphEdges: [_edge('catKey', 'dogKey', type: 'related_to')],
        memories: const [],
      );

      final msg = builder.buildUserMessage(
        userQuestion: 'q',
        context: ctx,
        budget: defaultBudget,
      );

      expect(msg, contains('## Related Concepts'));
      expect(msg, contains('- Cats → related_to → dogKey'));
    });

    test('dedupes identical (source, relation, target) edges asserted by '
        'multiple notes', () {
      final ctx = EnrichedContext(
        seedNotes: const [],
        graphNodes: const [],
        graphEdges: [_edge('a', 'b'), _edge('a', 'b')],
        memories: const [],
      );

      final msg = builder.buildUserMessage(
        userQuestion: 'q',
        context: ctx,
        budget: defaultBudget,
      );

      expect('- a → related → b'.allMatches(msg).length, 1);
    });

    test('renders memory summaries, skipping blank ones', () {
      final ctx = EnrichedContext(
        seedNotes: const [],
        graphNodes: const [],
        graphEdges: const [],
        memories: [_memory('a real summary'), _memory('   ')],
      );

      final msg = builder.buildUserMessage(
        userQuestion: 'q',
        context: ctx,
        budget: defaultBudget,
      );

      expect(msg, contains('## Summaries'));
      expect(msg, contains('- a real summary'));
    });

    test('a context with only blank memories (nothing else) falls back to '
        'the no-context persona-only path', () {
      final ctx = EnrichedContext(
        seedNotes: const [],
        graphNodes: const [],
        graphEdges: const [],
        memories: [_memory('   ')],
      );
      // isEmpty checks seedNotes/graphEdges/memories lists, not their
      // rendered content — a non-empty memories LIST with only blank
      // summaries is NOT context.isEmpty, but IS empty after rendering.
      expect(ctx.isEmpty, isFalse);

      final msg = builder.buildUserMessage(
        userQuestion: 'q',
        context: ctx,
        budget: defaultBudget,
      );

      expect(msg, contains('Question: q'));
      expect(msg, isNot(contains('## Summaries')));
    });

    test('a relations section that would overflow maxTokens is dropped '
        'entirely, not truncated mid-section', () {
      final ctx = EnrichedContext(
        seedNotes: const [],
        graphNodes: const [],
        graphEdges: [_edge('a', 'b')],
        memories: const [],
      );
      // A budget whose maxTokens is smaller than even one relation line's
      // estimated cost — the section must be skipped, not partially added.
      const tinyBudget = PromptBudget(
        maxTokens: 1,
        queryTokens: 1,
        topNotesTokens: 100,
        graphRelationsTokens: 100,
        memoriesTokens: 100,
        topK: 3,
        maxHops: 1,
      );

      final msg = builder.buildUserMessage(
        userQuestion: 'q',
        context: ctx,
        budget: tinyBudget,
      );

      expect(msg, isNot(contains('## Related Concepts')));
    });

    test('a notes section capped to a tiny tokenCap keeps at least the '
        'first note (never renders zero notes if any exist)', () {
      final ctx = EnrichedContext(
        seedNotes: [_note('n1', 'x' * 500)],
        graphNodes: const [],
        graphEdges: const [],
        memories: const [],
      );
      const tinyNotesBudget = PromptBudget(
        maxTokens: 100000,
        queryTokens: 1,
        topNotesTokens: 0, // ~0 tokens per section after ~/2
        graphRelationsTokens: 100,
        memoriesTokens: 100,
        topK: 3,
        maxHops: 1,
      );

      final msg = builder.buildUserMessage(
        userQuestion: 'q',
        context: ctx,
        budget: tinyNotesBudget,
      );

      expect(msg, contains('## Relevant Notes'));
      expect(msg, contains('x' * 500));
    });
  });

  group('buildExtractionPrompt', () {
    test('embeds the note content and the strict JSON shape instructions',
        () {
      final prompt = builder.buildExtractionPrompt(
        noteContent: 'Samarth is the son of Rajendrasinh.',
        similarNotes: const [],
      );

      expect(prompt, contains('NEW_NOTE:'));
      expect(prompt, contains('Samarth is the son of Rajendrasinh.'));
      expect(prompt, contains('"summary"'));
      expect(prompt, contains('"relations"'));
      expect(prompt, isNot(contains('SIMILAR_NOTES:')));
    });

    test('includes a SIMILAR_NOTES block only when notes are provided', () {
      final prompt = builder.buildExtractionPrompt(
        noteContent: 'new note',
        similarNotes: [_note('sim1', 'a similar note')],
      );

      expect(prompt, contains('SIMILAR_NOTES:'));
      expect(prompt, contains('- id:sim1  a similar note'));
    });
  });

  group('buildUserMessage — document chunks', () {
    EnrichedContext ctx({
      List<ScoredNote> notes = const [],
      List<ScoredChunk> chunks = const [],
    }) =>
        EnrichedContext(
          seedNotes: notes,
          graphNodes: const [],
          graphEdges: const [],
          memories: const [],
          seedChunks: chunks,
        );

    test('a chunk-only context is not empty and renders a Documents section',
        () {
      final c = ctx(chunks: [_chunk('leave policy revised', label: '3')]);

      expect(c.isEmpty, isFalse);
      final msg = builder.buildUserMessage(
          userQuestion: 'q', context: c, budget: defaultBudget);

      expect(msg, contains('## Relevant Documents'));
      expect(msg, contains('(p.3) leave policy revised'));
    });

    test('the page label of each chunk is carried into the prompt', () {
      final msg = builder.buildUserMessage(
        userQuestion: 'q',
        context: ctx(chunks: [
          _chunk('first', label: '1'),
          _chunk('seventh', label: '7', ordinal: 1),
        ]),
        budget: defaultBudget,
      );

      expect(msg, contains('(p.1) first'));
      expect(msg, contains('(p.7) seventh'));
    });

    test('a DOCX chunk is marked with its heading, not as a page', () {
      final msg = builder.buildUserMessage(
        userQuestion: 'q',
        context: ctx(chunks: [
          _chunk('24 days a year', label: 'Annual Leave', kind: DocumentKind.docx),
        ]),
        budget: defaultBudget,
      );

      expect(msg, contains('• (Annual Leave) 24 days a year'));
      expect(msg, isNot(contains('(p.')));
    });

    test('an image passage is marked as coming from an image', () {
      final msg = builder.buildUserMessage(
        userQuestion: 'q',
        context: ctx(chunks: [
          _chunk('OFFICE ORDER leave rules', label: '', kind: DocumentKind.image),
        ]),
        budget: defaultBudget,
      );

      expect(msg, contains('• (image) OFFICE ORDER leave rules'),
          reason: 'OCR text must not read as something the user wrote');
    });

    test('a chunk with no location gets no marker', () {
      final msg = builder.buildUserMessage(
        userQuestion: 'q',
        context: ctx(chunks: [
          _chunk('untitled passage', label: '', kind: DocumentKind.docx),
        ]),
        budget: defaultBudget,
      );

      expect(msg, contains('• untitled passage'));
      expect(msg, isNot(contains('()')));
    });

    test('PDF and DOCX chunks render side by side in their own forms', () {
      final msg = builder.buildUserMessage(
        userQuestion: 'q',
        context: ctx(chunks: [
          _chunk('from a pdf', label: '5'),
          _chunk('from a docx',
              label: 'Remote Work', ordinal: 1, kind: DocumentKind.docx),
        ]),
        budget: defaultBudget,
      );

      expect(msg, contains('(p.5) from a pdf'));
      expect(msg, contains('(Remote Work) from a docx'));
    });

    test('documents come after the notes', () {
      final msg = builder.buildUserMessage(
        userQuestion: 'q',
        context:
            ctx(notes: [_note('n1', 'a note')], chunks: [_chunk('a chunk')]),
        budget: defaultBudget,
      );

      expect(msg.indexOf('## Relevant Notes'),
          lessThan(msg.indexOf('## Relevant Documents')));
    });

    test('an over-budget section is dropped whole, never truncated mid-chunk',
        () {
      const tiny = PromptBudget(
        maxTokens: 60,
        queryTokens: 6,
        topNotesTokens: 21,
        graphRelationsTokens: 12,
        memoriesTokens: 9,
        topK: 3,
        maxHops: 1,
      );
      final msg = builder.buildUserMessage(
        userQuestion: 'q',
        context: ctx(
            notes: [_note('n1', 'short note')], chunks: [_chunk('x' * 700)]),
        budget: tiny,
      );

      expect(msg, contains('## Relevant Notes'));
      expect(msg, isNot(contains('Relevant Documents')));
      expect(msg, isNot(contains('xxxx')));
    });

    test('with no chunks nothing about documents appears', () {
      final msg = builder.buildUserMessage(
        userQuestion: 'q',
        context: ctx(notes: [_note('n1', 'a note')]),
        budget: defaultBudget,
      );

      expect(msg, isNot(contains('Relevant Documents')));
    });
  });
}
