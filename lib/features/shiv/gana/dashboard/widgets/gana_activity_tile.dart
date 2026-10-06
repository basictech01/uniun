import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uniun/core/enum/gana_run_status.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/domain/entities/gana/gana_run_entity.dart';
import 'package:uniun/features/shiv/gana/utils/gana_formatters.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// One run in the recent-activity list: "Gana name · status", when, and the
/// error for a failed run. With [showError] a failed run is the attention
/// card — error up to three lines instead of one.
class GanaActivityTile extends StatelessWidget {
  const GanaActivityTile({
    super.key,
    required this.ganaName,
    required this.run,
    this.showError = false,
  });

  final String ganaName;
  final GanaRunEntity run;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final color = ganaRunColor(context, run.status);
    final error = run.status == GanaRunStatus.failed ? run.error : null;
    return InkWell(
      onTap: () => context.pushNamed(
        AppRoutes.shivGanaDetail,
        pathParameters: {'ganaId': run.ganaId},
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 5, right: 10),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$ganaName · ${ganaRunStatusLabel(run.status, l10n)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (error != null && error.isNotEmpty)
                    Text(
                      error,
                      maxLines: showError ? 3 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: colorScheme.error),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              ganaRelativeWhen(run.startedAt, l10n),
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
