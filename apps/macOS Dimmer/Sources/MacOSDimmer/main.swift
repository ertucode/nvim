import AppKit
import Carbon
import Darwin

private enum DimmingCommand: String {
  case decrease
  case increase
  case startDecrease = "start-decrease"
  case startIncrease = "start-increase"
  case stop
  case reset
  case quit
}

final class AppDelegate: NSObject, NSApplicationDelegate {
  private let opacityKey = "overlayOpacity"
  private let softwareStep = 0.2
  private let systemBrightness = SystemBrightnessController()
  private let maximumOpacity = 0.9
  private var isReady = false
  private var overlays: [NSWindow] = []
  private var pendingCommands: [DimmingCommand] = []
  private var hudWindow: NSPanel?
  private var hideHUDWorkItem: DispatchWorkItem?
  private var hudPresentationID = 0
  private var repeatDelayWorkItem: DispatchWorkItem?
  private var repeatTimer: Timer?

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory)
    rebuildOverlays()

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(screenParametersDidChange),
      name: NSApplication.didChangeScreenParametersNotification,
      object: nil
    )

    isReady = true
    pendingCommands.forEach(handle)
    pendingCommands.removeAll()
  }

  @objc func handleGetURLEvent(
    _ event: NSAppleEventDescriptor,
    withReplyEvent replyEvent: NSAppleEventDescriptor
  ) {
    guard let value = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
          let url = URL(string: value)
    else {
      return
    }

    handle(url)
  }

  func applicationShouldTerminateAfterLastWindowClosed(
    _ sender: NSApplication
  ) -> Bool {
    false
  }

  @objc private func screenParametersDidChange() {
    rebuildOverlays()
  }

  private var opacity: Double {
    get { UserDefaults.standard.double(forKey: opacityKey) }
    set {
      UserDefaults.standard.set(newValue, forKey: opacityKey)
      updateOverlays()
    }
  }

  private func handle(_ command: DimmingCommand) {
    switch command {
    case .decrease:
      decreaseBrightness()
    case .increase:
      increaseBrightness()
    case .startDecrease:
      startRepeating(.decrease)
    case .startIncrease:
      startRepeating(.increase)
    case .stop:
      stopRepeating()
    case .reset:
      stopRepeating()
      opacity = 0
    case .quit:
      stopRepeating()
      NSApp.terminate(nil)
    }
  }

  private func startRepeating(_ command: DimmingCommand) {
    stopRepeating()
    handle(command)

    let workItem = DispatchWorkItem { [weak self] in
      guard let self else { return }
      handle(command)
      repeatTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) {
        [weak self] _ in
        self?.handle(command)
      }
    }
    repeatDelayWorkItem = workItem
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: workItem)
  }

  private func stopRepeating() {
    repeatDelayWorkItem?.cancel()
    repeatDelayWorkItem = nil
    repeatTimer?.invalidate()
    repeatTimer = nil
  }

  private func handle(_ url: URL) {
    guard url.scheme == "macos-dimmer",
          let commandName = url.host ?? url.pathComponents.last,
          let command = DimmingCommand(rawValue: commandName)
    else {
      return
    }

    if isReady {
      handle(command)
    } else {
      pendingCommands.append(command)
    }
  }

  private func decreaseBrightness() {
    if opacity > 0 {
      opacity = min(maximumOpacity, opacity + softwareStep)
      showHUD(value: softwareHUDLevel)
      return
    }

    if let brightness = systemBrightness.decrease() {
      showHUD(value: hardwareHUDLevel(for: brightness))
      return
    }

    opacity = softwareStep
    showHUD(value: softwareHUDLevel)
  }

  private func increaseBrightness() {
    if opacity > 0 {
      opacity = max(0, opacity - softwareStep)
      showHUD(value: softwareHUDLevel)
      return
    }

    if let brightness = systemBrightness.increase() {
      showHUD(value: hardwareHUDLevel(for: brightness))
    }
  }

  private func rebuildOverlays() {
    overlays.forEach { $0.close() }
    overlays = NSScreen.screens.map(makeOverlay)
    updateOverlays()
  }

  private func makeOverlay(for screen: NSScreen) -> NSWindow {
    let window = NSWindow(
      contentRect: screen.frame,
      styleMask: [.borderless],
      backing: .buffered,
      defer: false,
      screen: screen
    )

    window.animationBehavior = .none
    window.backgroundColor = .clear
    window.collectionBehavior = [
      .canJoinAllSpaces,
      .fullScreenAuxiliary,
      .ignoresCycle,
      .stationary,
    ]
    window.hasShadow = false
    window.ignoresMouseEvents = true
    window.isOpaque = false
    window.isReleasedWhenClosed = false
    window.level = NSWindow.Level(
      rawValue: Int(CGWindowLevelForKey(.assistiveTechHighWindow))
    )

    return window
  }

  private func updateOverlays() {
    let color = NSColor.black.withAlphaComponent(opacity)

    for window in overlays {
      window.backgroundColor = color
      if opacity > 0 {
        window.orderFrontRegardless()
      } else {
        window.orderOut(nil)
      }
    }
  }

  private var softwareHUDLevel: Double {
    (1.0 / 16.0) * (1 - opacity)
  }

  private func hardwareHUDLevel(for brightness: Float) -> Double {
    max(0, min(1, Double(brightness)))
  }

  private func showHUD(value: Double) {
    hideHUDWorkItem?.cancel()
    hudPresentationID += 1
    let presentationID = hudPresentationID

    let panel = hudWindow ?? makeHUDWindow()
    positionHUD(panel)
    if let effectView = panel.contentView as? NSVisualEffectView,
       let hudView = effectView.subviews.first as? BrightnessHUDView
    {
      hudView.level = value
    }
    panel.alphaValue = 1
    panel.orderFrontRegardless()

    let workItem = DispatchWorkItem { [weak self, weak panel] in
      guard let self, hudPresentationID == presentationID else { return }
      panel?.orderOut(nil)
    }
    hideHUDWorkItem = workItem
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.9, execute: workItem)
  }

  private func makeHUDWindow() -> NSPanel {
    let size = NSSize(width: 200, height: 200)
    let panel = NSPanel(
      contentRect: NSRect(origin: .zero, size: size),
      styleMask: [.borderless, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )
    let effectView = NSVisualEffectView(frame: NSRect(origin: .zero, size: size))
    let hudView = BrightnessHUDView(frame: effectView.bounds)

    effectView.appearance = NSAppearance(named: .darkAqua)
    effectView.blendingMode = .behindWindow
    effectView.material = .hudWindow
    effectView.state = .active
    effectView.wantsLayer = true
    effectView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.36).cgColor
    effectView.layer?.borderWidth = 0
    effectView.layer?.cornerRadius = 28
    effectView.layer?.masksToBounds = true
    effectView.addSubview(hudView)

    panel.collectionBehavior = [
      .canJoinAllSpaces,
      .fullScreenAuxiliary,
      .ignoresCycle,
      .stationary,
    ]
    panel.contentView = effectView
    panel.hasShadow = false
    panel.hidesOnDeactivate = false
    panel.ignoresMouseEvents = true
    panel.isFloatingPanel = true
    panel.isOpaque = false
    panel.level = NSWindow.Level(
      rawValue: Int(CGWindowLevelForKey(.assistiveTechHighWindow)) + 1
    )
    panel.worksWhenModal = true
    panel.backgroundColor = .clear
    hudWindow = panel
    return panel
  }

  private func positionHUD(_ panel: NSPanel) {
    let screenFrame = NSScreen.main?.visibleFrame ?? NSScreen.screens[0].visibleFrame
    let panelSize = panel.frame.size
    panel.setFrameOrigin(
      NSPoint(
        x: screenFrame.midX - panelSize.width / 2,
        y: screenFrame.minY + screenFrame.height * 0.22 - panelSize.height / 2
      )
    )
  }
}

private final class BrightnessHUDView: NSView {
  var level: Double = 0 {
    didSet {
      let clampedLevel = max(0, min(1, level))
      if level != clampedLevel {
        level = clampedLevel
        return
      }
      needsDisplay = true
    }
  }

  private let segmentCount = 16
  private let symbolView: NSImageView

  override init(frame frameRect: NSRect) {
    symbolView = NSImageView(
      frame: NSRect(x: 43, y: 59, width: 114, height: 114)
    )
    super.init(frame: frameRect)

    let configuration = NSImage.SymbolConfiguration(
      pointSize: 82,
      weight: .medium
    )
    symbolView.image = NSImage(
      systemSymbolName: "sun.max",
      accessibilityDescription: "Brightness"
    )?.withSymbolConfiguration(configuration)
    symbolView.contentTintColor = NSColor.white.withAlphaComponent(0.94)
    symbolView.imageScaling = .scaleProportionallyUpOrDown
    addSubview(symbolView)
  }

  required init?(coder: NSCoder) {
    nil
  }

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)

    let bar = NSRect(x: 20, y: 25, width: 160, height: 6)
    let path = NSBezierPath(roundedRect: bar, xRadius: 1, yRadius: 1)
    NSColor.white.withAlphaComponent(0.18).setFill()
    path.fill()

    let gap: CGFloat = 1.5
    let segmentWidth = (bar.width - gap * CGFloat(segmentCount - 1)) /
      CGFloat(segmentCount)
    let scaledLevel = level * Double(segmentCount)
    let fullSegments = Int(floor(scaledLevel))
    let partialSegment = scaledLevel - Double(fullSegments)

    NSColor.white.withAlphaComponent(0.94).setFill()
    for index in 0..<segmentCount {
      let fillFraction: CGFloat
      if index < fullSegments {
        fillFraction = 1
      } else if index == fullSegments {
        fillFraction = CGFloat(partialSegment)
      } else {
        fillFraction = 0
      }

      guard fillFraction > 0 else { continue }
      let segment = NSRect(
        x: bar.minX + CGFloat(index) * (segmentWidth + gap),
        y: bar.minY,
        width: segmentWidth * fillFraction,
        height: bar.height
      )
      NSBezierPath(rect: segment).fill()
    }
  }
}

private final class SystemBrightnessController {
  private typealias GetBrightness = @convention(c) (
    CGDirectDisplayID,
    UnsafeMutablePointer<Float>
  ) -> Int32
  private typealias SetBrightness = @convention(c) (
    CGDirectDisplayID,
    Float
  ) -> Int32

  private let firstNotch: Float = 1.0 / 16.0
  private let framework: UnsafeMutableRawPointer?
  private let getBrightness: GetBrightness?
  private let setBrightness: SetBrightness?

  init() {
    framework = dlopen(
      "/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices",
      RTLD_LAZY
    )

    if let framework,
       let getSymbol = dlsym(framework, "DisplayServicesGetBrightness"),
       let setSymbol = dlsym(framework, "DisplayServicesSetBrightness")
    {
      getBrightness = unsafeBitCast(getSymbol, to: GetBrightness.self)
      setBrightness = unsafeBitCast(setSymbol, to: SetBrightness.self)
    } else {
      getBrightness = nil
      setBrightness = nil
    }
  }

  deinit {
    if let framework {
      dlclose(framework)
    }
  }

  func decrease() -> Float? {
    guard let brightness = currentBrightness(),
          brightness > firstNotch + 0.001
    else {
      return nil
    }

    let newBrightness = max(firstNotch, brightness - firstNotch)
    return set(newBrightness) ? newBrightness : nil
  }

  func increase() -> Float? {
    guard let brightness = currentBrightness() else { return nil }
    let newBrightness = min(1, brightness + firstNotch)
    return set(newBrightness) ? newBrightness : nil
  }

  private func currentBrightness() -> Float? {
    guard let display = builtInDisplay,
          let getBrightness
    else {
      return nil
    }

    var brightness: Float = 0
    guard getBrightness(display, &brightness) == 0 else { return nil }
    return brightness
  }

  private func set(_ brightness: Float) -> Bool {
    guard let display = builtInDisplay,
          let setBrightness
    else {
      return false
    }

    return setBrightness(display, brightness) == 0
  }

  private var builtInDisplay: CGDirectDisplayID? {
    let mainDisplay = CGMainDisplayID()
    guard CGDisplayIsBuiltin(mainDisplay) != 0 else { return nil }
    return mainDisplay
  }
}

let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
NSAppleEventManager.shared().setEventHandler(
  delegate,
  andSelector: #selector(AppDelegate.handleGetURLEvent(_:withReplyEvent:)),
  forEventClass: AEEventClass(kInternetEventClass),
  andEventID: AEEventID(kAEGetURL)
)
application.run()
