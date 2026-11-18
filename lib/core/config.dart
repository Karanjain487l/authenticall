/// Configure Agora in the app's Call tab, or supply AGORA_APP_ID at build time.
class AppConfig {
  static const String agoraAppId = String.fromEnvironment('AGORA_APP_ID');
}