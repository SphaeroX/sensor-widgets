import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/data/platform/notification_permission.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(NotificationPermission.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('asks the native side and returns its answer', () async {
    final calls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return true;
    });

    expect(await NotificationPermission().request(), isTrue);
    expect(calls, ['requestPermission']);
  });

  test('a missing native handler counts as not granted', () async {
    expect(await NotificationPermission().request(), isFalse);
  });
}
