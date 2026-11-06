import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/common/atoms/uniun_button.dart';
import 'package:uniun/common/widgets/drop_loading_indicator.dart';
import 'package:uniun/core/enum/report_type.dart';
import 'package:uniun/features/moderation/cubit/report_sheet_cubit.dart';
import 'package:uniun/features/moderation/widgets/submit_button.dart';
import 'package:uniun/l10n/app_localizations.dart';

class _MockCubit extends MockCubit<ReportSheetState>
    implements ReportSheetCubit {}

/// Covers: SubmitButton disabled until a type is picked, fires submit when
/// enabled, shows a spinner and ignores taps while submitting.
void main() {
  late _MockCubit cubit;

  setUp(() => cubit = _MockCubit());

  Future<void> pump(WidgetTester t, ReportSheetState state) async {
    when(() => cubit.state).thenReturn(state);
    when(() => cubit.submit()).thenAnswer((_) async {});
    await t.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<ReportSheetCubit>.value(
            value: cubit,
            child: const SubmitButton(),
          ),
        ),
      ),
    );
  }

  testWidgets('no type picked: disabled, tap does not submit', (t) async {
    await pump(t, const ReportSheetState());

    await t.tap(find.byType(UniunButton));

    verifyNever(() => cubit.submit());
  });

  testWidgets('type picked: tap submits', (t) async {
    await pump(t, const ReportSheetState(type: ReportType.spam));

    await t.tap(find.byType(UniunButton));

    verify(() => cubit.submit()).called(1);
  });

  testWidgets('submitting: spinner shown, tap ignored', (t) async {
    await pump(
      t,
      const ReportSheetState(
        type: ReportType.spam,
        status: ReportSheetStatus.submitting,
      ),
    );

    expect(find.byType(DropLoadingIndicator), findsOneWidget);
    await t.tap(find.byType(UniunButton));
    verifyNever(() => cubit.submit());
  });
}
