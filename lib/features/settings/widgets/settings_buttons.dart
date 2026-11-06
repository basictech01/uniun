import 'package:flutter/material.dart';
class SettingsToggle extends StatelessWidget {
  const SettingsToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: Theme.of(context).colorScheme.primary,
      activeTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
