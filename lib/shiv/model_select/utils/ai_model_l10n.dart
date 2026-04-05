import 'package:uniun/domain/entities/ai_model/ai_model_entity.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// Presentation-layer extension — maps [AIModelId] to localized strings.
/// Lives in the UI layer so the domain entity stays Flutter-free.
extension AIModelIdL10n on AIModelId {
  String displayName(AppLocalizations l10n) => switch (this) {
        AIModelId.qwen25_05b => l10n.aiModelQwen25Name,
        AIModelId.deepseekR1 => l10n.aiModelDeepSeekR1Name,
        AIModelId.gemma4E2b => l10n.aiModelGemma4E2bName,
        AIModelId.gemma4E4b => l10n.aiModelGemma4E4bName,
      };

  String description(AppLocalizations l10n) => switch (this) {
        AIModelId.qwen25_05b => l10n.aiModelQwen25Desc,
        AIModelId.deepseekR1 => l10n.aiModelDeepSeekR1Desc,
        AIModelId.gemma4E2b => l10n.aiModelGemma4E2bDesc,
        AIModelId.gemma4E4b => l10n.aiModelGemma4E4bDesc,
      };
}
