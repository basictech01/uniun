import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/common/atoms/uniun_button.dart';
import 'package:uniun/core/enum/message_role.dart';
import 'package:uniun/domain/entities/shiv/shiv_message_entity.dart';
import 'package:uniun/features/shiv/chat/tree/widgets/node_action_panel.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// Covers: the Open branch button calls back, for a user and an assistant
/// message.
void main() {
  ShivMessageEntity message(MessageRole role) => ShivMessageEntity(
    messageId: 'm1',
    conversationId: 'c1',
    parentId: null,
    role: role,
    content: 'hello',
    createdAt: DateTime(2026),
  );

  for (final role in MessageRole.values) {
    testWidgets('${role.name}: Open branch calls onOpenBranch', (t) async {
      var opened = 0;
      await t.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: NodeActionPanel(
                message: message(role),
                messageCount: 3,
                isActiveBranch: true,
                onDismiss: () {},
                onOpenBranch: () => opened++,
              ),
            ),
          ),
        ),
      );

      await t.tap(find.byType(UniunButton));

      expect(opened, 1);
    });
  }
}
