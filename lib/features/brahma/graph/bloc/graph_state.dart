part of 'graph_bloc.dart';

enum GraphStatus { initial, loading, loaded, error }

class GraphState {
  const GraphState({
    this.status = GraphStatus.initial,
    this.nodes = const [],
    this.adjacency = const {},
    this.profiles = const {},
    this.selectedNodeId,
    this.errorMessage,
    this.scopedManasId,
    this.scopedManasName,
    this.scopedManasIconName,
    this.searchQuery = '',
    this.matchedNodeIds = const {},
    this.matchOrder = const [],
    this.matchIndex = -1,
    this.connectionAnchorId,
    this.connectionIndex = -1,
  });

  final GraphStatus status;

  /// All graph nodes (saved notes, own notes, drafts).
  final List<GraphNodeData> nodes;

  /// Bidirectional adjacency: nodeId → set of connected nodeIds.
  final Map<String, Set<String>> adjacency;

  /// pubkeyHex → ProfileEntity for node author display.
  final Map<String, ProfileEntity> profiles;

  /// The currently selected node id, null = nothing selected.
  final String? selectedNodeId;

  final String? errorMessage;

  /// When non-null, the graph is scoped to this Manas's membership.
  /// Null = full Brahma graph (default).
  final String? scopedManasId;

  /// Display name of the scoped Manas (for the header). May be null even
  /// when [scopedManasId] is set (loaded without a name hint).
  final String? scopedManasName;

  /// Icon name (key into `ManasIcons.all`) for the scoped Manas. Null
  /// when unscoped or when the Manas has no chosen icon — header falls
  /// back to `ManasIcons.fallback`.
  final String? scopedManasIconName;

  /// Active free-text graph search. Empty = not searching.
  final String searchQuery;

  /// Node ids whose label/content match [searchQuery]. Only meaningful while
  /// [searchQuery] is non-empty; matched nodes stay lit, the rest dim.
  final Set<String> matchedNodeIds;

  /// [matchedNodeIds] as a stepping order (newest note first). Same members,
  /// so `matchOrder.length` is the match count.
  final List<String> matchOrder;

  /// Position in [matchOrder] the camera is parked on, or -1 when the user has
  /// typed but not stepped yet — the graph highlights every match but has not
  /// moved.
  final int matchIndex;

  /// The node whose connections the node panel's stepper walks. It stays put
  /// while stepping — otherwise each step would re-orbit around the node just
  /// reached and `‹` would not lead back where it came from. Any fresh
  /// selection re-anchors it.
  final String? connectionAnchorId;

  /// Position in [connectionOrder], or -1 when no connection is focused.
  final int connectionIndex;

  bool get isSearching => searchQuery.isNotEmpty;

  /// The match the camera should be centred on, or null when none is focused.
  String? get focusedMatchId =>
      matchIndex >= 0 && matchIndex < matchOrder.length
          ? matchOrder[matchIndex]
          : null;

  /// The anchor's neighbours in stepping order (newest note first).
  List<String> get connectionOrder {
    final anchor = connectionAnchorId;
    if (anchor == null) return const [];
    final neighbours = adjacency[anchor];
    if (neighbours == null || neighbours.isEmpty) return const [];
    final byId = {for (final n in nodes) n.eventId: n};
    final ordered = [
      for (final id in neighbours)
        if (byId.containsKey(id)) byId[id]!,
    ]..sort((a, b) =>
        (b.created ?? DateTime(0)).compareTo(a.created ?? DateTime(0)));
    return [for (final n in ordered) n.eventId];
  }

  String? get focusedConnectionId {
    final order = connectionOrder;
    return connectionIndex >= 0 && connectionIndex < order.length
        ? order[connectionIndex]
        : null;
  }

  /// The node the camera should fly to. A search owns the camera while it is
  /// open; otherwise the connection walk does.
  String? get focusedNodeId =>
      isSearching ? focusedMatchId : focusedConnectionId;

  GraphState copyWith({
    GraphStatus? status,
    List<GraphNodeData>? nodes,
    Map<String, Set<String>>? adjacency,
    Map<String, ProfileEntity>? profiles,
    String? selectedNodeId,
    bool clearSelection = false,
    String? errorMessage,
    String? scopedManasId,
    String? scopedManasName,
    String? scopedManasIconName,
    bool clearScope = false,
    String? searchQuery,
    Set<String>? matchedNodeIds,
    List<String>? matchOrder,
    int? matchIndex,
    String? connectionAnchorId,
    int? connectionIndex,
    bool clearConnections = false,
  }) {
    return GraphState(
      status: status ?? this.status,
      nodes: nodes ?? this.nodes,
      adjacency: adjacency ?? this.adjacency,
      profiles: profiles ?? this.profiles,
      selectedNodeId:
          clearSelection ? null : (selectedNodeId ?? this.selectedNodeId),
      errorMessage: errorMessage ?? this.errorMessage,
      scopedManasId:
          clearScope ? null : (scopedManasId ?? this.scopedManasId),
      scopedManasName:
          clearScope ? null : (scopedManasName ?? this.scopedManasName),
      scopedManasIconName: clearScope
          ? null
          : (scopedManasIconName ?? this.scopedManasIconName),
      searchQuery: searchQuery ?? this.searchQuery,
      matchedNodeIds: matchedNodeIds ?? this.matchedNodeIds,
      matchOrder: matchOrder ?? this.matchOrder,
      matchIndex: matchIndex ?? this.matchIndex,
      connectionAnchorId: clearConnections
          ? null
          : (connectionAnchorId ?? this.connectionAnchorId),
      connectionIndex: clearConnections ? -1 : (connectionIndex ?? this.connectionIndex),
    );
  }

  GraphNodeData? get selectedNode {
    if (selectedNodeId == null) return null;
    try {
      return nodes.firstWhere((n) => n.eventId == selectedNodeId);
    } catch (_) {
      return null;
    }
  }

  bool isConnectedToSelected(String nodeId) {
    if (selectedNodeId == null) return false;
    return adjacency[selectedNodeId]?.contains(nodeId) ?? false;
  }

  // Value equality so BlocBuilder skips rebuilds when an emitted state carries
  // no real change. The large collections (nodes/adjacency/profiles) are reused
  // by reference across copyWith, so identity comparison is both correct and
  // cheap here; only the small scalar/search fields are value-compared.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GraphState &&
          status == other.status &&
          identical(nodes, other.nodes) &&
          identical(adjacency, other.adjacency) &&
          identical(profiles, other.profiles) &&
          selectedNodeId == other.selectedNodeId &&
          errorMessage == other.errorMessage &&
          scopedManasId == other.scopedManasId &&
          scopedManasName == other.scopedManasName &&
          scopedManasIconName == other.scopedManasIconName &&
          searchQuery == other.searchQuery &&
          matchedNodeIds.length == other.matchedNodeIds.length &&
          matchedNodeIds.containsAll(other.matchedNodeIds) &&
          matchIndex == other.matchIndex &&
          connectionAnchorId == other.connectionAnchorId &&
          connectionIndex == other.connectionIndex;

  @override
  int get hashCode => Object.hash(
        status,
        identityHashCode(nodes),
        identityHashCode(adjacency),
        identityHashCode(profiles),
        selectedNodeId,
        errorMessage,
        scopedManasId,
        scopedManasName,
        scopedManasIconName,
        searchQuery,
        matchedNodeIds.length,
        matchIndex,
        connectionAnchorId,
        connectionIndex,
      );
}
