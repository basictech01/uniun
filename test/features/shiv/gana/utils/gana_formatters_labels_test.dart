import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/core/enum/gana_input_type.dart';
import 'package:uniun/core/enum/gana_trigger_mode.dart';
import 'package:uniun/features/shiv/gana/utils/gana_formatters.dart';
import 'package:uniun/l10n/app_localizations_en.dart';

import '../../../../_helpers/fixtures.dart';

/// The trigger, scope and time labels a Gana card is built from.
void main() {
  final l10n = AppLocalizationsEn();

  group('ganaTriggerSummary', () {
    test('a one-shot with no input fires once when enabled', () {
      final g = aGana(triggerMode: GanaTriggerMode.oneShot);
      expect(ganaTriggerSummary(g, l10n), 'Once on enable');
    });

    test('a one-shot with an input source waits for the first input', () {
      final g = aGana(
        triggerMode: GanaTriggerMode.oneShot,
      ).copyWith(inputType: GanaInputType.group);
      expect(ganaTriggerSummary(g, l10n), 'Once on first input');
    });

    test('reactive plus a timer says both', () {
      final g = aGana(triggerReactive: true, triggerIntervalMinutes: 30);
      expect(ganaTriggerSummary(g, l10n), 'Reactive + every 30m');
    });

    test('reactive alone', () {
      expect(
        ganaTriggerSummary(aGana(triggerReactive: true), l10n),
        'Reactive',
      );
    });

    test('a timer alone', () {
      expect(
        ganaTriggerSummary(aGana(triggerIntervalMinutes: 15), l10n),
        'Every 15m',
      );
    });

    test('a Gana with no trigger shows a dash', () {
      expect(ganaTriggerSummary(aGana(), l10n), '—');
    });
  });

  group('ganaTriggerIcon', () {
    test('a bolt for a recurring reactive Gana', () {
      expect(ganaTriggerIcon(aGana(triggerReactive: true)), Icons.bolt_rounded);
    });

    test('a clock for a timer, no trigger, or a one-shot', () {
      expect(
        ganaTriggerIcon(aGana(triggerIntervalMinutes: 5)),
        Icons.schedule_rounded,
      );
      expect(
        ganaTriggerIcon(
          aGana(triggerMode: GanaTriggerMode.oneShot, triggerReactive: true),
        ),
        Icons.schedule_rounded,
      );
    });
  });

  group('ganaScopeLabel', () {
    test('no Manas means all notes', () {
      expect(ganaScopeLabel(aGana(), l10n), 'All notes');
    });

    test('counts Manas, singular and plural', () {
      expect(ganaScopeLabel(aGana(manasIds: ['a']), l10n), '1 Manas');
      expect(ganaScopeLabel(aGana(manasIds: ['a', 'b', 'c']), l10n), '3 Manas');
    });
  });

  group('ganaRelativeWhen', () {
    String when(Duration ago) =>
        ganaRelativeWhen(DateTime.now().subtract(ago), l10n);

    test('steps through seconds, minutes, hours and days', () {
      expect(when(const Duration(seconds: 5)), 'just now');
      expect(when(const Duration(minutes: 4, seconds: 5)), '4m ago');
      expect(when(const Duration(hours: 3, minutes: 1)), '3h ago');
      expect(when(const Duration(days: 2, hours: 1)), '2d ago');
    });

    test('falls back to an ISO date after a week', () {
      final t = DateTime(2020, 3, 7);
      expect(ganaRelativeWhen(t, l10n), '2020-03-07');
    });
  });
}
