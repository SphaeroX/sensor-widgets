import 'package:home_widget/home_widget.dart';
import 'package:sensor_widgets/core/constants/storage_keys.dart';

/// Delegate interface for shared widget storage operations.
abstract class WidgetStorageDelegate {
  Future<bool?> saveString(String key, String value);
  Future<String?> getString(String key);
  Future<bool?> notifyWidgetsUpdated();
}

/// Default implementation backed by the `home_widget` package.
class HomeWidgetStorageDelegate implements WidgetStorageDelegate {
  HomeWidgetStorageDelegate() {
    HomeWidget.setAppGroupId(StorageKeys.appGroupId);
  }

  @override
  Future<bool?> saveString(String key, String value) {
    return HomeWidget.saveWidgetData<String>(key, value);
  }

  @override
  Future<String?> getString(String key) {
    return HomeWidget.getWidgetData<String>(key);
  }

  @override
  Future<bool?> notifyWidgetsUpdated() async {
    // Notify all Android widgets & iOS timelines
    await HomeWidget.updateWidget(
      name: 'SingleValueWidget',
      androidName: 'SingleValueWidgetReceiver',
      iOSName: 'SingleValueWidget',
    );
    await HomeWidget.updateWidget(
      name: 'HistoryChartWidget',
      androidName: 'HistoryChartWidgetReceiver',
      iOSName: 'HistoryChartWidget',
    );
    await HomeWidget.updateWidget(
      name: 'IndicatorLampWidget',
      androidName: 'IndicatorLampWidgetReceiver',
      iOSName: 'IndicatorLampWidget',
    );
    await HomeWidget.updateWidget(
      name: 'MultiValueWidget',
      androidName: 'MultiValueWidgetReceiver',
      iOSName: 'MultiValueWidget',
    );
    await HomeWidget.updateWidget(
      name: 'AggregateWidget',
      androidName: 'AggregateWidgetReceiver',
      iOSName: 'AggregateWidget',
    );
    await HomeWidget.updateWidget(
      name: 'GaugeBarWidget',
      androidName: 'GaugeBarWidgetReceiver',
      iOSName: 'GaugeBarWidget',
    );
    return true;
  }
}

/// Facade for managing shared widget definitions in App Group / SharedPreferences storage.
class SharedWidgetStore {
  final WidgetStorageDelegate _delegate;

  SharedWidgetStore({WidgetStorageDelegate? delegate})
    : _delegate = delegate ?? HomeWidgetStorageDelegate();

  Future<void> saveString(String key, String value) async {
    await _delegate.saveString(key, value);
  }

  Future<String?> getString(String key) async {
    return _delegate.getString(key);
  }

  Future<void> notifyWidgetsUpdated() async {
    await _delegate.notifyWidgetsUpdated();
  }
}
