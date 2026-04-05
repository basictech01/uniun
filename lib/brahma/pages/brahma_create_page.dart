import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/brahma/bloc/brahma_create_bloc.dart';
import 'package:uniun/brahma/widgets/graph_preview_card.dart';
import 'package:uniun/brahma/widgets/note_compose_card.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/core/theme/app_theme.dart';

class BrahmaCreatePage extends StatelessWidget {
  const BrahmaCreatePage({super.key, this.onPublished});

  final VoidCallback? onPublished;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BrahmaCreateBloc>(
      create: (_) => getIt<BrahmaCreateBloc>(),
      child: _BrahmaCreateView(onPublished: onPublished),
    );
  }
}

class _BrahmaCreateView extends StatefulWidget {
  const _BrahmaCreateView({this.onPublished});

  final VoidCallback? onPublished;

  @override
  State<_BrahmaCreateView> createState() => _BrahmaCreateViewState();
}

class _BrahmaCreateViewState extends State<_BrahmaCreateView> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<String> _extractedTags = const [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final tags = RegExp(r'#(\w+)')
        .allMatches(_controller.text)
        .map((m) => m.group(1)!)
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();
    if (tags.length != _extractedTags.length ||
        !tags.every(_extractedTags.contains)) {
      setState(() => _extractedTags = tags);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BrahmaCreateBloc, BrahmaCreateState>(
      listener: (context, state) {
        if (state.status == BrahmaCreateStatus.success) {
          _controller.clear();
          widget.onPublished?.call();
        }
        if (state.status == BrahmaCreateStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? AppLocalizations.of(context)!.brahmaFailedToPublish),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: [
            // ── Background decoration ────────────────────────────────────
            Positioned(
              top: -80,
              left: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              right: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.05),
                ),
              ),
            ),

            // ── Main content ─────────────────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  // ── Header ─────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        // X button — clears compose
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: AppColors.onSurfaceVariant),
                          onPressed: () {
                            _controller.clear();
                            context.read<BrahmaCreateBloc>().add(const ResetBrahmaEvent());
                          },
                        ),

                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.brahmaTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),

                        // Spacer to balance the X button width
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),

                  // ── Scrollable body ────────────────────────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                          16, 8, 16, 100 + MediaQuery.of(context).viewInsets.bottom),
                      child: Column(
                        children: [
                          // Compose card
                          NoteComposeCard(
                            controller: _controller,
                            focusNode: _focusNode,
                            isSubmitting:
                                state.status == BrahmaCreateStatus.submitting,
                            canSubmit: _controller.text.trim().isNotEmpty &&
                                !state.isSubmitting,
                            onSubmit: () {
                              context.read<BrahmaCreateBloc>().add(
                                    SubmitNoteEvent(
                                        content: _controller.text),
                                  );
                            },
                          ),
                          const SizedBox(height: 28),

                          // Graph preview (updates as hashtags are typed)
                          GraphPreviewCard(hashtags: _extractedTags),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ],
          ),
        );
      },
    );
  }
}
