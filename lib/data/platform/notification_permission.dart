import 'package:flutter/services.dart';

/// Asks the OS for permission to post threshold notifications.
///
/// Platform channel instead of a plugin: Android `MainActivity` and iOS
/// `AppDelegate` answer `requestPermission` with a bool. The notifications
/// themselves are posted by the native widget refresh code.
class NotificationPermission {
  static const String channelName = 'sensor_widgets/notifications';
  static const MethodChannel _channel = MethodChannel(channelName);

  Future<bool> request() async {
    try {
      return await _channel.invokeMethod<bool>('requestPermission') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
