import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/common/atoms/uniun_button.dart';
import 'package:uniun/features/moderation/cubit/report_sheet_cubit.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// Primary "Submit report" button. Disabled until a [ReportType] is picked,
/// shows a spinner while the cubit's three-step submit pipeline runs.
class SubmitButton extends StatelessWidget {
  const SubmitButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<ReportSheetCubit, ReportSheetState>(
      builder: (context, state) {
        return UniunButton(
          label: l10n.reportSheetSubmit,
          loading: state.status == ReportSheetStatus.submitting,
          onPressed: state.canSubmit
              ? () => context.read<ReportSheetCubit>().submit()
              : null,
        );
      },
    );
  }
}
