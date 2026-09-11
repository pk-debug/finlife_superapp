import Flutter
import Network
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let messenger = engineBridge.applicationRegistrar.messenger()
    FlutterMethodChannel(name: "com.finlife.superapp/device_info", binaryMessenger: messenger)
      .setMethodCallHandler { call, result in
        switch call.method {
        case "getDeviceInfo":
          result([
            "batteryLevel": IOSDeviceInfo.batteryLevel() ?? NSNull(),
            "androidId": UIDevice.current.identifierForVendor?.uuidString ?? NSNull(),
            "installUuid": IOSDeviceInfo.installUuid(),
          ])
        case "setScreenCaptureProtection":
          // iOS cannot universally block screenshots. Recording/mirroring is
          // detectable, so the app can conceal sensitive Flutter UI if needed.
          result(nil)
        default: result(FlutterMethodNotImplemented)
        }
      }
    FlutterMethodChannel(name: "com.finlife.superapp/network", binaryMessenger: messenger)
      .setMethodCallHandler { call, result in
        guard call.method == "isOnline" else { result(FlutterMethodNotImplemented); return }
        result(IOSNetworkStatus.isOnline)
      }
    FlutterEventChannel(name: "com.finlife.superapp/battery_events", binaryMessenger: messenger)
      .setStreamHandler(IOSBatteryStreamHandler())
    FlutterEventChannel(name: "com.finlife.superapp/network_events", binaryMessenger: messenger)
      .setStreamHandler(IOSNetworkStreamHandler())
  }
}

private enum IOSDeviceInfo {
  static func batteryLevel() -> Int? {
    UIDevice.current.isBatteryMonitoringEnabled = true
    let level = UIDevice.current.batteryLevel
    return level >= 0 ? Int((level * 100).rounded()) : nil
  }
  static func installUuid() -> String {
    let key = "finlife_install_uuid"
    if let value = UserDefaults.standard.string(forKey: key) { return value }
    let value = UUID().uuidString
    UserDefaults.standard.set(value, forKey: key)
    return value
  }
}

private enum IOSNetworkStatus {
  static var isOnline: Bool {
    let monitor = NWPathMonitor(); var online = false; let semaphore = DispatchSemaphore(value: 0)
    monitor.pathUpdateHandler = { path in online = path.status == .satisfied; semaphore.signal() }
    monitor.start(queue: DispatchQueue(label: "finlife.network.check"))
    _ = semaphore.wait(timeout: .now() + 1); monitor.cancel(); return online
  }
}

private final class IOSBatteryStreamHandler: NSObject, FlutterStreamHandler {
  private var observer: NSObjectProtocol?
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    UIDevice.current.isBatteryMonitoringEnabled = true
    if let level = IOSDeviceInfo.batteryLevel() { events(level) }
    observer = NotificationCenter.default.addObserver(forName: UIDevice.batteryLevelDidChangeNotification, object: nil, queue: .main) { _ in
      if let level = IOSDeviceInfo.batteryLevel() { events(level) }
    }
    return nil
  }
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    if let observer { NotificationCenter.default.removeObserver(observer) }; observer = nil; return nil
  }
}

private final class IOSNetworkStreamHandler: NSObject, FlutterStreamHandler {
  private var monitor: NWPathMonitor?
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    let monitor = NWPathMonitor(); monitor.pathUpdateHandler = { path in events(path.status == .satisfied) }
    monitor.start(queue: DispatchQueue(label: "finlife.network.events")); self.monitor = monitor; return nil
  }
  func onCancel(withArguments arguments: Any?) -> FlutterError? { monitor?.cancel(); monitor = nil; return nil }
}
