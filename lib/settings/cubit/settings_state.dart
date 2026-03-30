part of 'settings_cubit.dart';

@immutable
class SettingsState {
  const SettingsState({
    this.isLoading = true,
    this.userName,
    this.handle,
    this.npub,
    this.pubkeyHex,
    this.nsec,
    this.avatarUrl,
    this.aiEnabled = true,
    this.dmNotifications = true,
    this.channelAlerts = false,
    this.nsecVisible = false,
    this.error,
  });

  final bool isLoading;
  final String? userName;
  final String? handle;      // short display handle (e.g. first 16 chars of npub)
  final String? npub;
  final String? pubkeyHex;   // full hex key — used as avatar seed
  final String? nsec;        // only populated after user reveals
  final String? avatarUrl;
  final bool aiEnabled;
  final bool dmNotifications;
  final bool channelAlerts;
  final bool nsecVisible;
  final String? error;

  SettingsState copyWith({
    bool? isLoading,
    String? userName,
    String? handle,
    String? npub,
    String? pubkeyHex,
    String? nsec,
    String? avatarUrl,
    bool? aiEnabled,
    bool? dmNotifications,
    bool? channelAlerts,
    bool? nsecVisible,
    String? error,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      userName: userName ?? this.userName,
      handle: handle ?? this.handle,
      npub: npub ?? this.npub,
      pubkeyHex: pubkeyHex ?? this.pubkeyHex,
      nsec: nsec ?? this.nsec,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      aiEnabled: aiEnabled ?? this.aiEnabled,
      dmNotifications: dmNotifications ?? this.dmNotifications,
      channelAlerts: channelAlerts ?? this.channelAlerts,
      nsecVisible: nsecVisible ?? this.nsecVisible,
      error: error ?? this.error,
    );
  }
}
