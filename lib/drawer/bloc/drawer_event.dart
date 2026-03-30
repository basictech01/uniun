part of 'drawer_bloc.dart';

@immutable
sealed class DrawerEvent {}

/// Load user profile + channels + DMs on drawer open.
final class DrawerLoadEvent extends DrawerEvent {}
