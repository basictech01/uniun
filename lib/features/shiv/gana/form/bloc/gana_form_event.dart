part of 'gana_form_bloc.dart';

sealed class GanaFormEvent {
  const GanaFormEvent();
}

class GanaFormLoadEvent extends GanaFormEvent {
  const GanaFormLoadEvent(this.ganaId);
  final String? ganaId; // null ⇒ create mode
}

/// Refresh the Manas picker without reloading the Gana draft.
class GanaFormRefreshManasesEvent extends GanaFormEvent {
  const GanaFormRefreshManasesEvent();
}

class GanaFormNameChangedEvent extends GanaFormEvent {
  const GanaFormNameChangedEvent(this.value);
  final String value;
}

class GanaFormToggleManasEvent extends GanaFormEvent {
  const GanaFormToggleManasEvent(this.manasId);
  final String manasId;
}

class GanaFormSelectBrahmaEvent extends GanaFormEvent {
  const GanaFormSelectBrahmaEvent();
}

class GanaFormTaskPromptChangedEvent extends GanaFormEvent {
  const GanaFormTaskPromptChangedEvent(this.value);
  final String value;
}

class GanaFormInputTypeChangedEvent extends GanaFormEvent {
  const GanaFormInputTypeChangedEvent(this.value);
  final GanaInputType? value;
}

class GanaFormInputRefChangedEvent extends GanaFormEvent {
  const GanaFormInputRefChangedEvent(this.value);
  final String? value;
}

class GanaFormOutputTypeChangedEvent extends GanaFormEvent {
  const GanaFormOutputTypeChangedEvent(this.value);
  final GanaOutputType value;
}

class GanaFormOutputRefChangedEvent extends GanaFormEvent {
  const GanaFormOutputRefChangedEvent(this.value);
  // Type depends on state.outputType: String? for group/privateGroup,
  // int? for dm, ignored for feed.
  final Object? value;
}

class GanaFormModelChangedEvent extends GanaFormEvent {
  const GanaFormModelChangedEvent(this.value, {this.backend});
  final String? value; // null ⇒ "use active"
  final LlmBackendType? backend;
}

class GanaFormReactiveToggleEvent extends GanaFormEvent {
  const GanaFormReactiveToggleEvent(this.value);
  final bool value;
}

class GanaFormIntervalChangedEvent extends GanaFormEvent {
  const GanaFormIntervalChangedEvent(this.value);
  final int? value;
}

class GanaFormTriggerModeChangedEvent extends GanaFormEvent {
  const GanaFormTriggerModeChangedEvent(this.value);
  final GanaTriggerMode value;
}

/// User picked a single trigger preset from the form's "When should this
/// run?" radio. Bloc folds it back into the raw (mode, reactive, interval)
/// triple — see [GanaTriggerPreset] for the mapping.
class GanaFormTriggerPresetChangedEvent extends GanaFormEvent {
  const GanaFormTriggerPresetChangedEvent(this.value);
  final GanaTriggerPreset value;
}

class GanaFormMaxOutputsChangedEvent extends GanaFormEvent {
  const GanaFormMaxOutputsChangedEvent(this.value);
  final int? value;
}

class GanaFormEnabledToggleEvent extends GanaFormEvent {
  const GanaFormEnabledToggleEvent(this.value);
  final bool value;
}

class GanaFormSubmitEvent extends GanaFormEvent {
  const GanaFormSubmitEvent();
}

class GanaFormDeleteEvent extends GanaFormEvent {
  const GanaFormDeleteEvent();
}
