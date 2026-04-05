import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/shiv/model_select/cubit/select_ai_model_cubit.dart';
import 'package:uniun/shiv/model_select/widgets/model_card.dart';
import 'package:uniun/shiv/model_select/widgets/model_selection_footer.dart';

class AIModelSelectionPage extends StatelessWidget {
  const AIModelSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SelectAIModelCubit>(),
      child: const _AIModelSelectionView(),
    );
  }
}

class _AIModelSelectionView extends StatelessWidget {
  const _AIModelSelectionView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<SelectAIModelCubit, SelectAIModelState>(
      listener: (context, state) {
        if (state.status == SelectAIModelStatus.done) {
          Navigator.of(context).pop(true);
        }
        if (state.status == SelectAIModelStatus.error &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.aiModelDownloadError),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.onSurface),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              l10n.aiModelSelectionTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: AppColors.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 20),
                  children: [
                    Text(
                      l10n.aiModelAvailableHeader,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.aiModelSelectionSubtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),

                    ...state.models.map((model) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ModelCard(
                            model: model,
                            isSelected:
                                state.selectedModelId == model.modelId,
                            isActive: state.activeModelId == model.modelId,
                            onTap: () => context
                                .read<SelectAIModelCubit>()
                                .selectModel(model.modelId),
                          ),
                        )),

                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        border: Border.all(
                            color:
                                AppColors.primary.withValues(alpha: 0.2)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.aiModelDownloadInfoText,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              ModelSelectionFooter(state: state),
            ],
          ),
        );
      },
    );
  }
}
