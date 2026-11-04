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
    _init();
  }

  Future<void> _init() async {
    try {
      await HomeWidget.setAppGroupId(StorageKeys.appGroupId);
    } catch (_) {
      // Ignored if platform does not require or support app group
    }
  }

  @override
  Future<bool?> saveString(String key, String value) async {
    try {
      return await HomeWidget.saveWidgetData<String>(key, value);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> getString(String key) async {
    try {
      return await HomeWidget.getWidgetData<String>(key);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool?> notifyWidgetsUpdated() async {
    try {
      // Notify Android Glance widget receiver
      await HomeWidget.updateWidget(
        name: 'SensorGlanceWidgetReceiver',
        androidName: 'SensorGlanceWidgetReceiver',
        qualifiedAndroidName: 'io.github.sphaerox.influx_sensor_widgets.glance.SensorGlanceWidgetReceiver',
        iOSName: 'SensorWidget',
      );
      return true;
    } catch (_) {
      return false;
    }
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
