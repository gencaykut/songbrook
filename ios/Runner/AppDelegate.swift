import Flutter
import UIKit
import WidgetKit
import AppIntents
import ImageIO
import CryptoKit

final class BStreamWidgetActionRelay {
  static let shared = BStreamWidgetActionRelay()
  var channel: FlutterMethodChannel?
  private var pendingAction: String?

  func accept(_ url: URL) {
    guard url.scheme == "bstreammusic", url.host == "widget" else { return }
    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    let action = components?.queryItems?.first(where: { $0.name == "action" })?.value
    guard let action, ["toggle", "next", "previous", "repeat", "favorite"].contains(action) else { return }
    pendingAction = action
    channel?.invokeMethod("widgetAction", arguments: action) { [weak self] result in
      if result == nil, self?.pendingAction == action {
        self?.pendingAction = nil
      }
    }
  }

  func consume() -> String? {
    defer { pendingAction = nil }
    return pendingAction
  }

  /// True once Dart has installed its widget action handler.
  private(set) var isReady = false

  func markReady() {
    isReady = true
  }

  /// Runs a widget button's action in the running app. Returns false when
  /// Flutter has not started, as after a background launch by the system.
  func dispatch(_ action: String) async -> Bool {
    guard isReady, let channel else { return false }
    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      channel.invokeMethod("widgetAction", arguments: action) { _ in
        continuation.resume()
      }
    }
    return true
  }

  /// Keeps the action until Dart registers after the app comes to the front.
  func queue(_ action: String) {
    pendingAction = action
  }
}

@available(iOS 17.0, *)
extension SongbrookWidgetControlIntent: ForegroundContinuableIntent {}

@available(iOS 17.0, *)
@MainActor
private func installWidgetControl() {
  SongbrookWidgetControl.perform = { intent in
    let relay = BStreamWidgetActionRelay.shared
    if await relay.dispatch(intent.action) { return }
    // Flutter only starts with the app's window, so a killed app has to come
    // to the front; the queued action runs once Dart registers.
    relay.queue(intent.action)
    if #available(iOS 26.0, *) {
      try await intent.continueInForeground(alwaysConfirm: false)
    } else {
      throw intent.needsToContinueInForegroundError()
    }
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var localMediaChannel: FlutterMethodChannel?
  private let localMediaPlugin = IOSLocalMediaPlugin()
  private var fileExportChannel: FlutterMethodChannel?
  private let fileExportPlugin = IOSFileExportPlugin()
  private var screenChannel: FlutterMethodChannel?
  private var homeWidgetChannel: FlutterMethodChannel?
  private var audioOutputPlugin: BStreamAudioOutputPlugin?
  private var localAudioQualityPlugin: IOSLocalAudioQualityPlugin?
  private var castPlugin: BStreamCastPlugin?
  private let widgetGroup = "group.io.github.gencaykut.songbrook"
  private let widgetKind = "BStreamNowPlaying"
  private let widgetArtworkQueue = DispatchQueue(label: "com.bstream.homeWidget.artwork", qos: .utility)

  private func widgetCoverName(_ trackId: String) -> String {
    let digest = SHA256.hash(data: Data(trackId.utf8))
    let prefix = digest.prefix(10).map { String(format: "%02x", $0) }.joined()
    return "now_playing_\(prefix).jpg"
  }

  // Runs on widgetArtworkQueue; the visible filename only changes after a
  // complete atomic write and a fresh check against the active song.
  private func saveWidgetCover(_ bytes: Data, trackId: String, defaults: UserDefaults, container: URL) {
    guard defaults.string(forKey: "trackId") == trackId else { return }
    let coverName = widgetCoverName(trackId)
    do {
      try bytes.write(to: container.appendingPathComponent(coverName), options: .atomic)
    } catch { return }
    DispatchQueue.main.async {
      guard defaults.string(forKey: "trackId") == trackId else {
        self.removeObsoleteWidgetCover(coverName, defaults: defaults, container: container)
        return
      }
      let previous = defaults.string(forKey: "coverFile")
      defaults.set(coverName, forKey: "coverFile")
      defaults.set(true, forKey: "hasCover")
      if #available(iOS 14.0, *) {
        WidgetCenter.shared.reloadTimelines(ofKind: self.widgetKind)
      }
      if let previous, previous != coverName {
        self.removeObsoleteWidgetCover(previous, defaults: defaults, container: container)
      }
    }
  }

  private func removeObsoleteWidgetCover(_ filename: String, defaults: UserDefaults, container: URL) {
    widgetArtworkQueue.async {
      // A rapid return to the same song may already be preparing this file.
      guard defaults.string(forKey: "coverFile") != filename,
            self.widgetCoverName(defaults.string(forKey: "trackId") ?? "") != filename else { return }
      try? FileManager.default.removeItem(at: container.appendingPathComponent(filename))
    }
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 17.0, *) { installWidgetControl() }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let audioMessenger = engineBridge.applicationRegistrar.messenger()
    audioOutputPlugin = BStreamAudioOutputPlugin(messenger: audioMessenger)
    localAudioQualityPlugin?.dispose()
    localAudioQualityPlugin = IOSLocalAudioQualityPlugin(messenger: audioMessenger)
    castPlugin = BStreamCastPlugin(messenger: audioMessenger)

    let channel = FlutterMethodChannel(
      name: "bstream_music/local_audio",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      self?.localMediaPlugin.handle(call, result: result)
    }
    localMediaChannel = channel

    let exportChannel = FlutterMethodChannel(
      name: "bstream_music/file_export",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    exportChannel.setMethodCallHandler { [weak self] call, result in
      self?.fileExportPlugin.handle(call, result: result)
    }
    fileExportChannel = exportChannel

    let displayChannel = FlutterMethodChannel(
      name: "bstream_music/screen",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    displayChannel.setMethodCallHandler { call, result in
      guard call.method == "setKeepScreenOn" else {
        result(FlutterMethodNotImplemented)
        return
      }
      let arguments = call.arguments as? [String: Any]
      UIApplication.shared.isIdleTimerDisabled = arguments?["enabled"] as? Bool ?? false
      result(nil)
    }
    screenChannel = displayChannel

    let widgetChannel = FlutterMethodChannel(
      name: "bstream_music/home_widget",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    widgetChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else { result(FlutterMethodNotImplemented); return }
      switch call.method {
      case "update":
        guard let data = call.arguments as? [String: Any],
              let defaults = UserDefaults(suiteName: self.widgetGroup) else {
          result(FlutterError(code: "widget_group", message: "App Group unavailable", details: nil))
          return
        }
        let trackId = data["trackId"] as? String ?? ""
        // Retain the last complete cover until its replacement is ready.
        if trackId.isEmpty {
          defaults.set(false, forKey: "hasCover")
          if let previous = defaults.string(forKey: "coverFile"),
             let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: self.widgetGroup) {
            try? FileManager.default.removeItem(at: container.appendingPathComponent(previous))
          }
          defaults.removeObject(forKey: "coverFile")
        }
        defaults.set(trackId, forKey: "trackId")
        defaults.set(data["title"] as? String ?? "", forKey: "title")
        defaults.set(data["artist"] as? String ?? "", forKey: "artist")
        defaults.set(data["isPlaying"] as? Bool ?? false, forKey: "playing")
        defaults.set(data["isFavorite"] as? Bool ?? false, forKey: "favorite")
        defaults.set(data["repeatMode"] as? String ?? "off", forKey: "repeatMode")
        defaults.set(data["accentColor"] as? Int ?? 0xFFF5F7F5, forKey: "accent")
        defaults.set(data["languageCode"] as? String ?? "es", forKey: "language")
        if #available(iOS 14.0, *) { WidgetCenter.shared.reloadTimelines(ofKind: self.widgetKind) }
        result(nil)
      case "updateArtwork":
        guard let data = call.arguments as? [String: Any],
              let defaults = UserDefaults(suiteName: self.widgetGroup),
              data["trackId"] as? String == defaults.string(forKey: "trackId"),
              let path = data["artworkPath"] as? String,
              let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: self.widgetGroup) else {
          result(nil)
          return
        }
        self.widgetArtworkQueue.async {
          guard defaults.string(forKey: "trackId") == data["trackId"] as? String else { return }
          let source = URL(fileURLWithPath: path)
          let options: [CFString: Any] = [kCGImageSourceShouldCache: false]
          if let imageSource = CGImageSourceCreateWithURL(source as CFURL, options as CFDictionary),
             let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, [
               kCGImageSourceCreateThumbnailFromImageAlways: true,
               kCGImageSourceThumbnailMaxPixelSize: 320,
               kCGImageSourceCreateThumbnailWithTransform: true,
             ] as CFDictionary),
             let bytes = UIImage(cgImage: thumbnail).jpegData(compressionQuality: 0.84) {
            self.saveWidgetCover(bytes, trackId: data["trackId"] as? String ?? "", defaults: defaults, container: container)
          }
        }
        result(nil)
      case "updateArtworkBytes":
        guard let data = call.arguments as? [String: Any],
              let defaults = UserDefaults(suiteName: self.widgetGroup),
              data["trackId"] as? String == defaults.string(forKey: "trackId"),
              let encoded = data["bytes"] as? FlutterStandardTypedData,
              let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: self.widgetGroup) else {
          result(nil)
          return
        }
        self.widgetArtworkQueue.async {
          guard defaults.string(forKey: "trackId") == data["trackId"] as? String else { return }
          if let image = UIImage(data: encoded.data),
             let bytes = image.jpegData(compressionQuality: 0.84) {
            self.saveWidgetCover(bytes, trackId: data["trackId"] as? String ?? "", defaults: defaults, container: container)
          }
        }
        result(nil)
      case "consumePendingAction":
        result(BStreamWidgetActionRelay.shared.consume())
      case "registerActionHandler":
        BStreamWidgetActionRelay.shared.markReady()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    homeWidgetChannel = widgetChannel
    BStreamWidgetActionRelay.shared.channel = widgetChannel
  }
}
