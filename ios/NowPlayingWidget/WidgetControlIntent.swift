import AppIntents

/// Widget buttons on iOS 17+. As an `AudioPlaybackIntent` that is also built
/// into the app, the system runs it in the app process, so a tap controls
/// playback without bringing Songbrook to the front.
@available(iOS 17.0, *)
struct SongbrookWidgetControlIntent: AudioPlaybackIntent {
  static var title: LocalizedStringResource = "Songbrook"
  static var isDiscoverable = false

  @available(iOS 26.0, *)
  static var supportedModes: IntentModes { [.background, .foreground(.dynamic)] }

  @Parameter(title: "Action")
  var action: String

  init() {}

  init(action: String) {
    self.action = action
  }

  @MainActor
  func perform() async throws -> some IntentResult {
    try await SongbrookWidgetControl.perform?(self)
    return .result()
  }
}

/// Installed by the app; the widget extension only builds the buttons.
@available(iOS 17.0, *)
enum SongbrookWidgetControl {
  @MainActor static var perform: ((SongbrookWidgetControlIntent) async throws -> Void)?
}
