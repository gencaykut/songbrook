import AVFoundation
let url = URL(fileURLWithPath: CommandLine.arguments[1])
let asset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: CommandLine.arguments.count > 2])
let sem = DispatchSemaphore(value: 0)
Task {
  let d = try await asset.load(.duration)
  let tracks = try await asset.load(.tracks)
  var td = "-"
  if let t = tracks.first { td = String(try await t.load(.timeRange).duration.seconds) }
  print("precise=\(CommandLine.arguments.count > 2) assetDuration=\(d.seconds) trackDuration=\(td)")
  sem.signal()
}
sem.wait()
