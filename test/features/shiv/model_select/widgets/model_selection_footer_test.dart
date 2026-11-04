import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/common/atoms/uniun_button.dart';
import 'package:uniun/domain/entities/ai_model/ai_model_entity.dart';
import 'package:uniun/features/shiv/model_select/cubit/select_ai_model_cubit.dart';
import 'package:uniun/features/shiv/model_select/widgets/model_selection_footer.dart';
import 'package:uniun/l10n/app_localizations.dart';

class _MockCubit extends MockCubit<SelectAIModelState>
    implements SelectAIModelCubit {}

/// Covers: the footer button disabled without a pick, downloading on tap,
/// "set active" for a downloaded model, the grey "already active" look, and
/// no button while downloading.
void main() {
  late _MockCubit cubit;

  setUp(() {
    cubit = _MockCubit();
    when(() => cubit.downloadAndActivate()).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester t, SelectAIModelState state) async {
    when(() => cubit.state).thenReturn(state);
    await t.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<SelectAIModelCubit>.value(
            value: cubit,
            child: ModelSelectionFooter(state: state),
          ),
        ),
      ),
    );
  }

  BoxDecoration deco(WidgetTester t) => t
      .widget<Container>(
        find
            .descendant(
              of: find.byType(UniunButton),
              matching: find.byType(Container),
            )
            .first,
      )
      .decoration! as BoxDecoration;

  testWidgets('no model picked: the button is disabled', (t) async {
    await pump(t, const SelectAIModelState());

    await t.tap(find.byType(UniunButton));

    verifyNever(() => cubit.downloadAndActivate());
  });

  testWidgets('a model picked: tapping downloads and activates it', (t) async {
    await pump(t, const SelectAIModelState(selectedModelId: AIModelId.gemma4E2b));

    await t.tap(find.byType(UniunButton));

    verify(() => cubit.downloadAndActivate()).called(1);
    expect(find.byIcon(Icons.download_rounded), findsOneWidget);
  });

  testWidgets('a downloaded model shows the check icon', (t) async {
    await pump(
      t,
      const SelectAIModelState(
        selectedModelId: AIModelId.gemma4E2b,
        downloadedModelIds: {AIModelId.gemma4E2b},
      ),
    );

    expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
  });

  testWidgets('the already-active model uses the grey outline colour',
      (t) async {
    await pump(
      t,
      const SelectAIModelState(
        selectedModelId: AIModelId.gemma4E2b,
        activeModelId: AIModelId.gemma4E2b,
        downloadedModelIds: {AIModelId.gemma4E2b},
      ),
    );
    final scheme = Theme.of(t.element(find.byType(UniunButton))).colorScheme;

    expect(deco(t).color, scheme.outline);
  });

  testWidgets('downloading: progress shown, no action button', (t) async {
    await pump(
      t,
      const SelectAIModelState(
        status: SelectAIModelStatus.downloading,
        downloadProgress: 0.4,
      ),
    );

    expect(find.byType(UniunButton), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}
