part of 'graph_bloc.dart';

sealed class GraphEvent {
  const GraphEvent();
}

final class LoadGraphEvent extends GraphEvent {
  const LoadGraphEvent({this.manasId, this.manasName});

  /// When non-null, scopes the graph to the membership of this Manas.
  /// Null = full Brahma graph (default).
  final String? manasId;

  /// Display name of the scoped Manas, used by the header. Optional —
  /// when null the header falls back to a generic label.
  final String? manasName;
}

/// Tap a node — if already selected, deselects it.
final class SelectGraphNodeEvent extends GraphEvent {
  const SelectGraphNodeEvent(this.nodeId);
  final String nodeId;
}

final class DeselectGraphNodeEvent extends GraphEvent {
  const DeselectGraphNodeEvent();
}

/// Delete a draft node from the graph (and from Isar).
final class DeleteDraftNodeEvent extends GraphEvent {
  const DeleteDraftNodeEvent(this.draftId);
  final String draftId;
}

/// Filter the graph by a free-text query — matching nodes stay lit, the rest
/// dim. An empty/blank query clears the search.
final class SearchGraphEvent extends GraphEvent {
  const SearchGraphEvent(this.query);
  final String query;
}

/// Move the search cursor [delta] matches (wrapping at both ends) and select
/// the match it lands on, so the canvas flies to it and its panel opens.
final class StepGraphMatchEvent extends GraphEvent {
  const StepGraphMatchEvent(this.delta);
  final int delta;
}

/// Same walk over the selected node's connections instead of search matches —
/// the way to follow a note's edges without searching for anything.
final class StepConnectedNodeEvent extends GraphEvent {
  const StepConnectedNodeEvent(this.delta);
  final int delta;
}
