part of 'drawer_bloc.dart';

@immutable
sealed class DrawerState {
  const DrawerState();
}

final class DrawerInitial extends DrawerState {}

final class DrawerLoading extends DrawerState {}

final class DrawerLoaded extends DrawerState {
  const DrawerLoaded({
    required this.userName,
    required this.npub,
    required this.pubkeyHex,
    this.avatarUrl,
    required this.followedNotes,
    required this.channels,
    required this.dms,
  });

  final String userName;
  final String npub;
  final String pubkeyHex;
  final String? avatarUrl;
  // Notes the user is tracking. Any Kind 1 note that e-tags a followed note
  // is captured in that note's reference feed (distinct from saved notes,
  // which exist only for AI/knowledge graph context).
  final List<DrawerFollowedNoteItem> followedNotes;
  final List<DrawerChannelItem> channels;
  final List<DrawerDmItem> dms;
}

final class DrawerError extends DrawerState {
  const DrawerError(this.message);
  final String message;
}

class DrawerChannelItem {
  const DrawerChannelItem({
    required this.id,
    required this.name,
    this.hasUnread = false,
  });

  final String id;
  final String name;
  final bool hasUnread;
}

class DrawerDmItem {
  const DrawerDmItem({
    required this.pubkey,
    required this.name,
    this.avatarUrl,
    this.unreadCount = 0,
  });

  final String pubkey;
  final String name;
  final String? avatarUrl;
  final int unreadCount;
}

class DrawerFollowedNoteItem {
  const DrawerFollowedNoteItem({
    required this.eventId,
    required this.contentPreview,
    this.newReferenceCount = 0,
  });

  final String eventId;
  final String contentPreview;
  final int newReferenceCount;
}
