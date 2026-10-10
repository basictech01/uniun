part of '../pages/gana_form_page.dart';

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.nameCtrl,
    required this.taskCtrl,
    required this.userRefCtrl,
    required this.intervalCtrl,
    required this.maxOutputsCtrl,
  });

  final GanaFormState state;
  final TextEditingController nameCtrl;
  final TextEditingController taskCtrl;
  final TextEditingController userRefCtrl;
  final TextEditingController intervalCtrl;
  final TextEditingController maxOutputsCtrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        // ── Identity ──────────────────────────────────────────────────────
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FieldLabel(l10n.ganaFormNameLabel),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                decoration: _inputDeco(context, l10n.ganaFormNameHint),
                onChanged: (v) => context
                    .read<GanaFormBloc>()
                    .add(GanaFormNameChangedEvent(v)),
                maxLength: 60,
                buildCounter: _noCounter,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // ── Task ──────────────────────────────────────────────────────────
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(l10n.ganaFormTaskPromptLabel),
              const SizedBox(height: 10),
              TextField(
                controller: taskCtrl,
                decoration: _inputDeco(context, l10n.ganaFormTaskPromptHint),
                onChanged: (v) => context
                    .read<GanaFormBloc>()
                    .add(GanaFormTaskPromptChangedEvent(v)),
                minLines: 4,
                maxLines: 10,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // ── Knowledge scope ──────────────────────────────────────
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(l10n.ganaFormManasSectionTitle),
              const SizedBox(height: 4),
              _SectionSubtitle(l10n.ganaFormManasSectionSubtitle),
              const SizedBox(height: 12),
              FilterChip(
                label: Text(l10n.brahmaTitle),
                selected: state.selectedManasId == null,
                onSelected: (_) => context.read<GanaFormBloc>().add(
                  const GanaFormSelectBrahmaEvent(),
                ),
              ),
              const SizedBox(height: 8),
              if (state.manases.isEmpty)
                _NoManasesCta()
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final m in state.manases)
                      FilterChip(
                        label: Text(m.name),
                        selected: state.selectedManasId == m.manasId,
                        onSelected: (_) => context
                            .read<GanaFormBloc>()
                            .add(GanaFormToggleManasEvent(m.manasId)),
                        showCheckmark: true,
                        selectedColor:
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    // Opens Brahma's Manas form and refreshes the picker on return.
                    ActionChip(
                      avatar: Icon(Icons.add,
                          size: 16, color: Theme.of(context).colorScheme.primary),
                      label: Text(l10n.ganaFormManasCreateNew,
                          style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                      onPressed: () async {
                        final created = await context
                            .pushNamed<bool>(AppRoutes.brahmaManasForm);
                        if (created == true && context.mounted) {
                          context
                              .read<GanaFormBloc>()
                              .add(const GanaFormRefreshManasesEvent());
                        }
                      },
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // ── Connections (input · output · model) ──────────────────────────
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(l10n.ganaFormInputSectionTitle),
              const SizedBox(height: 10),
              _InputSection(state: state, userRefCtrl: userRefCtrl),
              const _CardDivider(),
              _SectionTitle(l10n.ganaFormOutputSectionTitle),
              const SizedBox(height: 10),
              _OutputSection(state: state),
              const _CardDivider(),
              _SectionTitle(l10n.ganaFormModelSectionTitle),
              const SizedBox(height: 10),
              _ModelDropdown(state: state),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // ── Schedule ──────────────────────────────────────────────────────
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(l10n.ganaFormTriggersSectionTitle),
              const SizedBox(height: 10),
              _TriggersSection(
                state: state,
                intervalCtrl: intervalCtrl,
                maxOutputsCtrl: maxOutputsCtrl,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // ── Enable ────────────────────────────────────────────────────────
        _Card(child: _EnabledSwitch(state: state)),
        // Save-blocker hint — only shows when canSave is false. Tells the
        // user exactly what's missing so they don't have to guess why the
        // Save button is greyed out.
        if (!state.canSave) ...[
          const SizedBox(height: 14),
          _SaveBlockerHint(reason: state.saveBlocker(l10n) ?? ''),
        ],
      ],
    );
  }
}

/// Rounded white container that groups one logical section. The page sits on
/// a tinted [Theme.of(context).colorScheme.surfaceContainerLow] background so these cards pop.
class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        // ListTiles (RadioListTile/SwitchListTile) paint their background and
        // ink splashes on the nearest Material ancestor. Without this the
        // Container's decoration color would suppress them — Flutter asserts.
        child: Material(
          type: MaterialType.transparency,
          child: child,
        ),
      );
}

/// Hairline separator between sub-sections inside a single [_Card].
class _CardDivider extends StatelessWidget {
  const _CardDivider();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Divider(
          height: 1,
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      );
}

/// Sticky bottom action bar — primary Save plus, in edit mode, a destructive
/// delete affordance. Replaces the easy-to-miss greyed AppBar action.
class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.state});
  final GanaFormState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            if (state.isEditMode) ...[
              SizedBox(
                width: 54,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => _confirmDeleteGana(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(
                        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.4)),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, size: 20),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: state.canSave
                      ? () => context
                          .read<GanaFormBloc>()
                          .add(const GanaFormSubmitEvent())
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    disabledBackgroundColor:
                        Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    l10n.ganaFormSaveAction,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Counter-suppressing builder for the name field — keeps the card tidy.
Widget? _noCounter(
  BuildContext context, {
  required int currentLength,
  required bool isFocused,
  int? maxLength,
}) =>
    null;

Future<void> _confirmDeleteGana(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: Text(l10n.ganaFormDeleteConfirmTitle),
      content: Text(l10n.ganaFormDeleteConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx).pop(false),
          child: Text(l10n.ganaFormDeleteConfirmCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogCtx).pop(true),
          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
          child: Text(l10n.ganaFormDeleteConfirmConfirm),
        ),
      ],
    ),
  );
  if (ok != true) return;
  if (context.mounted) {
    context.read<GanaFormBloc>().add(const GanaFormDeleteEvent());
  }
}

// ── Sections ─────────────────────────────────────────────────────────────────

// All three sections share the same shape: a tappable "selector tile"
// that summarises the current pick, and on tap opens a bottom sheet
// with a scrollable list of options. The Material `DropdownButtonFormField`
// looked cramped (12-line popup, no selected-state visuals, no avatars).
// The new sheet pattern matches `manas_membership_sheet.dart` so the
// rest of the app feels consistent.

class _InputSection extends StatelessWidget {
  const _InputSection({required this.state, required this.userRefCtrl});
  final GanaFormState state;
  final TextEditingController userRefCtrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SelectorTile(
          icon: Icons.input_rounded,
          title: l10n.ganaFormInputSectionTitle,
          subtitle: _inputTypeLabel(l10n, state.inputType),
          onTap: () => _openInputTypeSheet(context, state, l10n),
        ),
        const SizedBox(height: 10),
        if (state.inputType != null)
          _InputRefPicker(state: state, userRefCtrl: userRefCtrl),
      ],
    );
  }
}

class _InputRefPicker extends StatelessWidget {
  const _InputRefPicker({required this.state, required this.userRefCtrl});
  final GanaFormState state;
  final TextEditingController userRefCtrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (state.inputType!) {
      case GanaInputType.group:
        return _SelectorTile(
          icon: Icons.forum_outlined,
          title: l10n.ganaFormInputGroup,
          subtitle: _groupName(state.groups, state.inputRefId) ??
              l10n.ganaFormInputPickHint,
          empty: state.inputRefId == null,
          onTap: () => _openSheet<String>(
            context: context,
            title: l10n.ganaFormInputGroup,
            current: state.inputRefId,
            options: [
              for (final c in state.groups)
                _PickOption(value: c.groupId, label: c.name),
            ],
            onPicked: (v) => context
                .read<GanaFormBloc>()
                .add(GanaFormInputRefChangedEvent(v)),
          ),
        );
      case GanaInputType.privateGroup:
        return _SelectorTile(
          icon: Icons.lock_outline,
          title: l10n.ganaFormInputPrivateGroup,
          subtitle: _privateGroupName(state.privateGroups, state.inputRefId) ??
              l10n.ganaFormInputPickHint,
          empty: state.inputRefId == null,
          onTap: () => _openSheet<String>(
            context: context,
            title: l10n.ganaFormInputPrivateGroup,
            current: state.inputRefId,
            options: [
              for (final c in state.privateGroups)
                _PickOption(value: c.groupId, label: c.name),
            ],
            onPicked: (v) => context
                .read<GanaFormBloc>()
                .add(GanaFormInputRefChangedEvent(v)),
          ),
        );
      case GanaInputType.dm:
        return _SelectorTile(
          icon: Icons.alternate_email_rounded,
          title: l10n.ganaFormInputDm,
          subtitle: _dmName(state.dmConversations, state.dmDisplayNames,
                  state.inputRefId) ??
              l10n.ganaFormInputPickHint,
          empty: state.inputRefId == null,
          onTap: () => _openSheet<String>(
            context: context,
            title: l10n.ganaFormInputDm,
            current: state.inputRefId,
            options: [
              for (final d in state.dmConversations)
                _PickOption(
                  value: d.id.toString(),
                  label: state.dmDisplayNames[d.otherPubkey] ??
                      _shortKey(d.otherPubkey),
                ),
            ],
            onPicked: (v) => context
                .read<GanaFormBloc>()
                .add(GanaFormInputRefChangedEvent(v)),
          ),
        );
      case GanaInputType.user:
        // Pubkeys aren't a curated list — keep the text field.
        return TextField(
          controller: userRefCtrl,
          decoration: _inputDeco(context, l10n.ganaFormInputUserHint),
          onChanged: (v) => context
              .read<GanaFormBloc>()
              .add(GanaFormInputRefChangedEvent(v.isEmpty ? null : v)),
        );
      case GanaInputType.followedNote:
        return _SelectorTile(
          icon: Icons.bookmark_outline,
          title: l10n.ganaFormInputFollowedNote,
          subtitle: _followedNoteLabel(state.followedNotes, state.inputRefId) ??
              l10n.ganaFormInputPickHint,
          empty: state.inputRefId == null,
          onTap: () => _openSheet<String>(
            context: context,
            title: l10n.ganaFormInputFollowedNote,
            current: state.inputRefId,
            options: [
              for (final f in state.followedNotes)
                _PickOption(
                  value: f.eventId,
                  label: f.contentPreview.isEmpty
                      ? f.eventId.substring(0, 12)
                      : f.contentPreview,
                ),
            ],
            onPicked: (v) => context
                .read<GanaFormBloc>()
                .add(GanaFormInputRefChangedEvent(v)),
          ),
        );
    }
  }
}

class _OutputSection extends StatelessWidget {
  const _OutputSection({required this.state});
  final GanaFormState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SelectorTile(
          icon: Icons.upload_rounded,
          title: l10n.ganaFormOutputSectionTitle,
          subtitle: _outputTypeLabel(l10n, state.outputType),
          onTap: () => _openOutputTypeSheet(context, state, l10n),
        ),
        const SizedBox(height: 10),
        if (state.outputType != GanaOutputType.feed)
          _OutputRefPicker(state: state),
      ],
    );
  }
}

class _OutputRefPicker extends StatelessWidget {
  const _OutputRefPicker({required this.state});
  final GanaFormState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (state.outputType) {
      case GanaOutputType.feed:
        return const SizedBox.shrink();
      case GanaOutputType.group:
        return _SelectorTile(
          icon: Icons.forum_outlined,
          title: l10n.ganaFormOutputGroup,
          subtitle: _groupName(state.groups, state.outputGroupId) ??
              l10n.ganaFormOutputPickHint,
          empty: state.outputGroupId == null,
          onTap: () => _openSheet<String>(
            context: context,
            title: l10n.ganaFormOutputGroup,
            current: state.outputGroupId,
            options: [
              for (final c in state.groups)
                _PickOption(value: c.groupId, label: c.name),
            ],
            onPicked: (v) => context
                .read<GanaFormBloc>()
                .add(GanaFormOutputRefChangedEvent(v)),
          ),
        );
      case GanaOutputType.privateGroup:
        return _SelectorTile(
          icon: Icons.lock_outline,
          title: l10n.ganaFormOutputPrivateGroup,
          subtitle: _privateGroupName(state.privateGroups, state.outputPrivateGroupId) ??
              l10n.ganaFormOutputPickHint,
          empty: state.outputPrivateGroupId == null,
          onTap: () => _openSheet<String>(
            context: context,
            title: l10n.ganaFormOutputPrivateGroup,
            current: state.outputPrivateGroupId,
            options: [
              for (final c in state.privateGroups)
                _PickOption(value: c.groupId, label: c.name),
            ],
            onPicked: (v) => context
                .read<GanaFormBloc>()
                .add(GanaFormOutputRefChangedEvent(v)),
          ),
        );
      case GanaOutputType.dm:
        return _SelectorTile(
          icon: Icons.alternate_email_rounded,
          title: l10n.ganaFormOutputDm,
          subtitle: _dmName(
                state.dmConversations,
                state.dmDisplayNames,
                state.outputDmConversationId?.toString(),
              ) ??
              l10n.ganaFormOutputPickHint,
          empty: state.outputDmConversationId == null,
          onTap: () => _openSheet<int>(
            context: context,
            title: l10n.ganaFormOutputDm,
            current: state.outputDmConversationId,
            options: [
              for (final d in state.dmConversations)
                _PickOption(
                  value: d.id,
                  label: state.dmDisplayNames[d.otherPubkey] ??
                      _shortKey(d.otherPubkey),
                ),
            ],
            onPicked: (v) => context
                .read<GanaFormBloc>()
                .add(GanaFormOutputRefChangedEvent(v)),
          ),
        );
    }
  }
}

class _ModelDropdown extends StatelessWidget {
  const _ModelDropdown({required this.state});
  final GanaFormState state;

  /// [rawId] is the stored [AIModelId.name] for a local pin — never shown to
  /// the user directly. Falls back to the raw id for a cloud pin, or if a
  /// local id no longer matches a known [AIModelId] (a model retired after
  /// this Gana was created).
  static String _label(String rawId, LlmBackendType? backend, AppLocalizations l10n) {
    if (backend == LlmBackendType.uniunCloud) return rawId;
    for (final id in AIModelId.values) {
      if (id.name == rawId) return id.displayName(l10n);
    }
    return rawId;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _SelectorTile(
      icon: Icons.psychology_alt_outlined,
      title: l10n.ganaFormModelSectionTitle,
      subtitle: state.desiredModelId != null
          ? _label(state.desiredModelId!, state.desiredBackend, l10n)
          : l10n.ganaFormModelUseActive,
      onTap: () {
        final bloc = context.read<GanaFormBloc>();
        showModelPickerSheet(
          context,
          nullableOptionLabel: l10n.ganaFormModelUseActive,
          currentOverrideId: state.desiredModelId,
          onNullSelected: () =>
              bloc.add(const GanaFormModelChangedEvent(null)),
          onLocalSelected: (m) => bloc.add(GanaFormModelChangedEvent(
            m.modelId.name,
            backend: LlmBackendType.localGemma,
          )),
          onCloudSelected: (m) => bloc.add(GanaFormModelChangedEvent(
            m.id,
            backend: LlmBackendType.uniunCloud,
          )),
        );
      },
    );
  }
}

// ── Sheet plumbing ───────────────────────────────────────────────────────────

