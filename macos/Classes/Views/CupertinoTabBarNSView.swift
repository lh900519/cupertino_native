import FlutterMacOS
import Cocoa

private final class TabBarSegmentedCell: NSSegmentedCell {
  var labelColor: NSColor?

  override func drawSegment(
    _ segment: Int,
    inFrame frame: NSRect,
    with controlView: NSView
  ) {
    guard let labelColor,
          segment != selectedSegment,
          isEnabled(forSegment: segment),
          image(forSegment: segment) == nil,
          let label = label(forSegment: segment),
          !label.isEmpty else {
      super.drawSegment(segment, inFrame: frame, with: controlView)
      return
    }

    setLabel("", forSegment: segment)
    super.drawSegment(segment, inFrame: frame, with: controlView)
    setLabel(label, forSegment: segment)

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center
    paragraphStyle.lineBreakMode = .byTruncatingTail
    let controlSize = (controlView as? NSControl)?.controlSize ?? .regular
    let font = self.font ?? NSFont.systemFont(
      ofSize: NSFont.systemFontSize(for: controlSize)
    )
    let attributes: [NSAttributedString.Key: Any] = [
      .foregroundColor: labelColor,
      .font: font,
      .paragraphStyle: paragraphStyle,
    ]
    let attributedLabel = NSAttributedString(string: label, attributes: attributes)
    let labelHeight = attributedLabel.size().height
    let labelRect = NSRect(
      x: frame.minX + 4,
      y: frame.midY - labelHeight / 2,
      width: max(0, frame.width - 8),
      height: labelHeight
    )
    attributedLabel.draw(
      with: labelRect,
      options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine]
    )
  }
}

class CupertinoTabBarNSView: NSView {
  private let channel: FlutterMethodChannel
  private let control: NSSegmentedControl
  private let segmentedCell: TabBarSegmentedCell
  private var currentLabels: [String] = []
  private var currentSymbols: [String] = []
  private var currentSizes: [NSNumber] = []
  private var currentTint: NSColor? = nil
  private var currentBackground: NSColor? = nil
  private var currentLabelColor: NSColor? = nil

  init(viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
    self.channel = FlutterMethodChannel(name: "CupertinoNativeTabBar_\(viewId)", binaryMessenger: messenger)
    self.segmentedCell = TabBarSegmentedCell()
    self.control = NSSegmentedControl(frame: .zero)
    self.control.cell = self.segmentedCell
    self.segmentedCell.trackingMode = .selectOne

    var labels: [String] = []
    var symbols: [String] = []
    var sizes: [NSNumber] = []
    var selectedIndex: Int = 0
    var isDark: Bool = false
    var tint: NSColor? = nil
    var bg: NSColor? = nil
    var labelColor: NSColor? = nil

    if let dict = args as? [String: Any] {
      labels = (dict["labels"] as? [String]) ?? []
      symbols = (dict["sfSymbols"] as? [String]) ?? []
      sizes = (dict["sfSymbolSizes"] as? [NSNumber]) ?? []
      if let v = dict["selectedIndex"] as? NSNumber { selectedIndex = v.intValue }
      if let v = dict["isDark"] as? NSNumber { isDark = v.boolValue }
      if let style = dict["style"] as? [String: Any] {
        if let n = style["tint"] as? NSNumber { tint = Self.colorFromARGB(n.intValue) }
        if let n = style["backgroundColor"] as? NSNumber { bg = Self.colorFromARGB(n.intValue) }
        if let n = style["labelColor"] as? NSNumber { labelColor = Self.colorFromARGB(n.intValue) }
      }
    }

    super.init(frame: .zero)

    wantsLayer = true
    layer?.backgroundColor = NSColor.clear.cgColor
    appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)

    configureSegments(labels: labels, symbols: symbols, sizes: sizes)
    if selectedIndex >= 0 { control.selectedSegment = selectedIndex }
    // Save current style and content for retinting
    self.currentLabels = labels
    self.currentSymbols = symbols
    self.currentSizes = sizes
    self.currentTint = tint
    self.currentBackground = bg
    self.currentLabelColor = labelColor
    self.segmentedCell.labelColor = labelColor
    if let b = bg { wantsLayer = true; layer?.backgroundColor = b.cgColor }
    applySegmentTint()

    control.target = self
    control.action = #selector(onChanged(_:))

    addSubview(control)
    control.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      control.leadingAnchor.constraint(equalTo: leadingAnchor),
      control.trailingAnchor.constraint(equalTo: trailingAnchor),
      control.topAnchor.constraint(equalTo: topAnchor),
      control.bottomAnchor.constraint(equalTo: bottomAnchor)
    ])

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { result(nil); return }
      switch call.method {
      case "getIntrinsicSize":
        let size = self.control.intrinsicContentSize
        result(["width": Double(size.width), "height": Double(size.height)])
      case "setSelectedIndex":
        if let args = call.arguments as? [String: Any], let idx = (args["index"] as? NSNumber)?.intValue {
          self.control.selectedSegment = idx
          self.applySegmentTint()
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing index", details: nil)) }
      case "setStyle":
        if let args = call.arguments as? [String: Any] {
          if let n = args["tint"] as? NSNumber { self.currentTint = Self.colorFromARGB(n.intValue) }
          if let n = args["backgroundColor"] as? NSNumber {
            let c = Self.colorFromARGB(n.intValue)
            self.currentBackground = c
            self.wantsLayer = true
            self.layer?.backgroundColor = c.cgColor
          }
          if args.keys.contains("labelColor") {
            self.currentLabelColor = (args["labelColor"] as? NSNumber).map {
              Self.colorFromARGB($0.intValue)
            }
            self.segmentedCell.labelColor = self.currentLabelColor
          }
          self.applySegmentTint()
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing style", details: nil)) }
      case "setItems":
        if let args = call.arguments as? [String: Any] {
          self.currentLabels = (args["labels"] as? [String]) ?? []
          self.currentSymbols = (args["sfSymbols"] as? [String]) ?? []
          if let sizes = args["sfSymbolSizes"] as? [NSNumber] {
            self.currentSizes = sizes
          }
          self.configureSegments(
            labels: self.currentLabels,
            symbols: self.currentSymbols,
            sizes: self.currentSizes
          )
          if let idx = (args["selectedIndex"] as? NSNumber)?.intValue {
            self.control.selectedSegment = idx
          }
          self.applySegmentTint()
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing items", details: nil)) }
      case "setBrightness":
        if let args = call.arguments as? [String: Any], let isDark = (args["isDark"] as? NSNumber)?.boolValue {
          self.appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)
          self.control.needsDisplay = true
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing isDark", details: nil)) }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  required init?(coder: NSCoder) { return nil }

  private func configureSegments(labels: [String], symbols: [String], sizes: [NSNumber]) {
    let count = max(labels.count, symbols.count)
    control.segmentCount = count
    for i in 0..<count {
      if i < symbols.count, #available(macOS 11.0, *), var image = NSImage(systemSymbolName: symbols[i], accessibilityDescription: nil) {
        if i < sizes.count, #available(macOS 12.0, *) {
          let size = CGFloat(truncating: sizes[i])
          let cfg = NSImage.SymbolConfiguration(pointSize: size, weight: .regular)
          image = image.withSymbolConfiguration(cfg) ?? image
        }
        control.setImage(image, forSegment: i)
      } else if i < labels.count {
        control.setLabel(labels[i], forSegment: i)
      } else {
        control.setLabel("", forSegment: i)
      }
    }
  }

  private func applySegmentTint() {
    let count = control.segmentCount
    guard count > 0 else { return }
    let sel = control.selectedSegment
    for i in 0..<count {
      // Only retint symbol-based segments
      if let name = (i < currentSymbols.count ? currentSymbols[i] : nil), !name.isEmpty,
         var image = NSImage(systemSymbolName: name, accessibilityDescription: nil) {
        if i < currentSizes.count, #available(macOS 12.0, *) {
          let size = CGFloat(truncating: currentSizes[i])
          let cfg = NSImage.SymbolConfiguration(pointSize: size, weight: .regular)
          image = image.withSymbolConfiguration(cfg) ?? image
        }
        if i == sel, let tint = currentTint {
          if #available(macOS 12.0, *) {
            let cfg = NSImage.SymbolConfiguration(hierarchicalColor: tint)
            image = image.withSymbolConfiguration(cfg) ?? image
          } else {
            image = image.tinted(with: tint)
          }
        }
        control.setImage(image, forSegment: i)
      }
    }
    control.needsDisplay = true
  }

  private static func colorFromARGB(_ argb: Int) -> NSColor {
    let a = CGFloat((argb >> 24) & 0xFF) / 255.0
    let r = CGFloat((argb >> 16) & 0xFF) / 255.0
    let g = CGFloat((argb >> 8) & 0xFF) / 255.0
    let b = CGFloat(argb & 0xFF) / 255.0
    return NSColor(srgbRed: r, green: g, blue: b, alpha: a)
  }

  @objc private func onChanged(_ sender: NSSegmentedControl) {
    applySegmentTint()
    channel.invokeMethod("valueChanged", arguments: ["index": sender.selectedSegment])
  }
}

private extension NSImage {
  func tinted(with color: NSColor) -> NSImage {
    let img = NSImage(size: size)
    img.lockFocus()
    let rect = NSRect(origin: .zero, size: size)
    color.set()
    rect.fill()
    draw(in: rect, from: .zero, operation: .destinationIn, fraction: 1.0)
    img.unlockFocus()
    return img
  }
}
