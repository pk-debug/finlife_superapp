import Cocoa
import FlutterMacOS
import IOKit
import IOKit.ps
import Network

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    registerNativeChannels(with: flutterViewController)

    super.awakeFromNib()
  }

  private func registerNativeChannels(with controller: FlutterViewController) {
    let messenger = controller.engine.binaryMessenger

    FlutterMethodChannel(
      name: "com.finlife.superapp/device_info",
      binaryMessenger: messenger
    ).setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "getDeviceInfo":
        let deviceInfo: [String: Any] = [
          "batteryLevel": MacDeviceInfo.batteryLevel() ?? NSNull(),
          "androidId": MacDeviceInfo.deviceId() ?? NSNull(),
          "installUuid": MacDeviceInfo.installUuid(),
        ]
        result(deviceInfo)
      case "setScreenCaptureProtection":
        let arguments = call.arguments as? [String: Any]
        let enabled = arguments?["enabled"] as? Bool ?? true
        self?.sharingType = enabled ? .none : .readWrite
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    FlutterMethodChannel(
      name: "com.finlife.superapp/network",
      binaryMessenger: messenger
    ).setMethodCallHandler { call, result in
      guard call.method == "isOnline" else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(MacNetworkStatus.isOnline)
    }

    FlutterEventChannel(
      name: "com.finlife.superapp/battery_events",
      binaryMessenger: messenger
    ).setStreamHandler(MacBatteryStreamHandler())

    FlutterEventChannel(
      name: "com.finlife.superapp/network_events",
      binaryMessenger: messenger
    ).setStreamHandler(MacNetworkStreamHandler())
  }
}

private enum MacDeviceInfo {
  static func batteryLevel() -> Int? {
    let info = IOPSCopyPowerSourcesInfo().takeRetainedValue()
    let sources = IOPSCopyPowerSourcesList(info).takeRetainedValue() as [CFTypeRef]
    for source in sources {
      guard let description = IOPSGetPowerSourceDescription(info, source)?
        .takeUnretainedValue() as? [String: Any],
        let capacity = description[kIOPSCurrentCapacityKey] as? Int else { continue }
      return capacity
    }
    return nil
  }

  static func deviceId() -> String? {
    let service = IOServiceGetMatchingService(
      kIOMasterPortDefault,
      IOServiceMatching("IOPlatformExpertDevice")
    )
    guard service != 0 else { return nil }
    defer { IOObjectRelease(service) }
    return IORegistryEntryCreateCFProperty(
      service,
      "IOPlatformUUID" as CFString,
      kCFAllocatorDefault,
      0
    )?.takeRetainedValue() as? String
  }

  static func installUuid() -> String {
    let key = "finlife_install_uuid"
    if let value = UserDefaults.standard.string(forKey: key) { return value }
    let value = UUID().uuidString
    UserDefaults.standard.set(value, forKey: key)
    return value
  }
}

private enum MacNetworkStatus {
  static var isOnline: Bool {
    let monitor = NWPathMonitor()
    var result = false
    let semaphore = DispatchSemaphore(value: 0)
    monitor.pathUpdateHandler = { path in
      result = path.status == .satisfied
      semaphore.signal()
    }
    monitor.start(queue: DispatchQueue(label: "finlife.network.check"))
    _ = semaphore.wait(timeout: .now() + 1)
    monitor.cancel()
    return result
  }
}

private final class MacBatteryStreamHandler: NSObject, FlutterStreamHandler {
  private var timer: Timer?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    if let level = MacDeviceInfo.batteryLevel() { events(level) }
    timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
      if let level = MacDeviceInfo.batteryLevel() { events(level) }
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    timer?.invalidate()
    timer = nil
    return nil
  }
}

private final class MacNetworkStreamHandler: NSObject, FlutterStreamHandler {
  private var monitor: NWPathMonitor?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    let monitor = NWPathMonitor()
    monitor.pathUpdateHandler = { path in events(path.status == .satisfied) }
    monitor.start(queue: DispatchQueue(label: "finlife.network.events"))
    self.monitor = monitor
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    monitor?.cancel()
    monitor = nil
    return nil
  }
}
