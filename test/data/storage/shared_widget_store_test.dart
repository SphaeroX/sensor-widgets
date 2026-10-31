import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sensor_widgets/data/storage/shared_widget_store.dart';

class MockWidgetStorageDelegate extends Mock implements WidgetStorageDelegate {}

void main() {
  group('SharedWidgetStore', () {
    late MockWidgetStorageDelegate mockDelegate;
    late SharedWidgetStore store;

    setUp(() {
      mockDelegate = MockWidgetStorageDelegate();
      store = SharedWidgetStore(delegate: mockDelegate);
    });

    test('saves and retrieves strings', () async {
      when(() => mockDelegate.saveString('key1', 'val1'))
          .thenAnswer((_) async => true);
      when(() => mockDelegate.getString('key1'))
          .thenAnswer((_) async => 'val1');

      await store.saveString('key1', 'val1');
      final result = await store.getString('key1');

      expect(result, 'val1');
      verify(() => mockDelegate.saveString('key1', 'val1')).called(1);
    });

    test('notifies widgets updated', () async {
      when(() => mockDelegate.notifyWidgetsUpdated())
          .thenAnswer((_) async => true);

      await store.notifyWidgetsUpdated();
      verify(() => mockDelegate.notifyWidgetsUpdated()).called(1);
    });
  });
}
