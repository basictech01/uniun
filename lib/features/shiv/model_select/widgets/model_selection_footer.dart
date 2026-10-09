import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/domain/entities/llm/llm_backend_type.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/features/shiv/model_select/cubit/select_ai_model_cubit.dart';

class ModelSelectionFooter extends StatelessWidget {
  const ModelSelectionFooter({super.key, required this.state});

  final SelectAIModelState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDownloading = state.status == SelectAIModelStatus.downloading;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
        border: Border(
          top: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).padding.bottom + 14,
      ),
      child: isDownloading
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: state.downloadProgress,
                    minHeight: 6,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.aiModelDownloadingProgress(
                        (state.downloadProgress * 100).round(),
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.read<SelectAIModelCubit>().cancelDownload(),
                      child: Text(
                        l10n.actionCancel,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : state.isEmbeddingDownloading
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.aiEmbeddingSetupInProgress,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.read<SelectAIModelCubit>().close(),
                      child: Text(
                        l10n.actionCancel,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Builder(
              builder: (context) {
                final selectedId = state.selectedModelId;
                final isAlreadyDownloaded =
                    selectedId != null &&
                    state.downloadedModelIds.contains(selectedId);
                // A downloaded local model is only "already active" when the
                // local backend is actually serving — not while cloud is in
                // use, even if this model was the last one downloaded.
                final isAlreadyActive =
                    selectedId == state.activeModelId &&
                    state.activeBackend == LlmBackendType.localGemma;
                final label = isAlreadyActive
                    ? l10n.aiModelAlreadyActive
                    : isAlreadyDownloaded
                    ? l10n.aiModelSetActive
                    : l10n.aiModelUseThisButton;
                final icon = isAlreadyDownloaded
                    ? Icons.check_circle_outline_rounded
                    : Icons.download_rounded;

                return FilledButton(
                  onPressed: selectedId == null
                      ? null
                      : () => context
                            .read<SelectAIModelCubit>()
                            .downloadAndActivate(),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: isAlreadyActive
                        ? Theme.of(context).colorScheme.outline
                        : Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        icon,
                        size: 18,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
