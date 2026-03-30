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
    required this.channels,
    required this.dms,
  });

  final String userName;
  final String npub;        // short display (first 12 chars + …)
  final String pubkeyHex;   // full hex key — used as avatar seed
  final String? avatarUrl;
  final List<DrawerChannelItem> channels;
  final List<DrawerDmItem> dms;
}

final class DrawerError extends DrawerState {
  const DrawerError(this.message);
  final String message;
}

// ── Lightweight data classes (no Isar — channels/DMs not built yet) ──────────

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
