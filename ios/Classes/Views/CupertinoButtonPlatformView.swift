import Flutter
import UIKit

class CupertinoButtonPlatformView: NSObject, FlutterPlatformView {
  private let channel: FlutterMethodChannel
  private let container: UIView
  private let button: UIButton
  private var isEnabled: Bool = true
  private var currentButtonStyle: String = "automatic"

  init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "CupertinoNativeButton_\(viewId)", binaryMessenger: messenger)
    container = UIView(frame: frame)
    button = UIButton(type: .system)

    var title: String?
    var fontSize: NSNumber?

    var spacing: NSNumber?

    var iconName: String?
    var iconBytes: FlutterStandardTypedData?

    var iconSize: NSNumber?
    var iconColor: UIColor?
    var makeRound: Bool = false
    var isDark: Bool = false
    var tint: UIColor?
    var buttonStyle: String = "automatic"
    var enabled: Bool = true
    var iconMode: String?
    var iconPalette: [NSNumber] = []

    if let dict = args as? [String: Any] {
      if let t = dict["buttonTitle"] as? String { title = t }
      if let f = dict["buttonFontSize"] as? NSNumber { fontSize = f }
      if let s = dict["buttonSpacing"] as? NSNumber { spacing = s }
      if let s = dict["buttonIconName"] as? String { iconName = s }
      if let i = dict["buttonIconBytes"] as? FlutterStandardTypedData { iconBytes = i }
      if let s = dict["buttonIconSize"] as? NSNumber { iconSize = s }
      if let c = dict["buttonIconColor"] as? NSNumber { iconColor = Self.colorFromARGB(c.intValue) }
      if let r = dict["round"] as? NSNumber { makeRound = r.boolValue }
      if let v = dict["isDark"] as? NSNumber { isDark = v.boolValue }
      if let style = dict["style"] as? [String: Any], let n = style["tint"] as? NSNumber { tint = Self.colorFromARGB(n.intValue) }
      if let bs = dict["buttonStyle"] as? String { buttonStyle = bs }
      if let e = dict["enabled"] as? NSNumber { enabled = e.boolValue }
      if let m = dict["buttonIconRenderingMode"] as? String { iconMode = m }
      if let pal = dict["buttonIconPaletteColors"] as? [NSNumber] { iconPalette = pal }
    }

    super.init()

    container.backgroundColor = .clear
    if #available(iOS 13.0, *) { container.overrideUserInterfaceStyle = isDark ? .dark : .light }

    button.translatesAutoresizingMaskIntoConstraints = false
    if let t = tint { button.tintColor = t }
    else if #available(iOS 13.0, *) { button.tintColor = .label }

    container.addSubview(button)
    NSLayoutConstraint.activate([
      button.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      button.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      button.topAnchor.constraint(equalTo: container.topAnchor),
      button.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ])

    applyButtonStyle(buttonStyle: buttonStyle, round: makeRound)
    currentButtonStyle = buttonStyle
    button.isEnabled = enabled
    isEnabled = enabled

    var finalImage: UIImage?
    var image: UIImage?

    if let bytes = iconBytes {
      image = UIImage(data: bytes.data, scale: UIScreen.main.scale)
    } else if let name = iconName {
      image = UIImage(systemName: name)
    }

    if var image = image {
      if let sz = iconSize {
        // image = image.applyingSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: sz)) ?? image
        image = image.resized(to: CGSize(width: Int(truncating: sz), height: Int(truncating: sz))) ?? image
      }

      if let mode = iconMode {
        switch mode {
        case "hierarchical":
          if #available(iOS 15.0, *), let col = iconColor {
            let cfg = UIImage.SymbolConfiguration(hierarchicalColor: col)
            image = image.applyingSymbolConfiguration(cfg) ?? image
          }
        case "palette":
          if #available(iOS 15.0, *), !iconPalette.isEmpty {
            let cols = iconPalette.map { Self.colorFromARGB($0.intValue) }
            let cfg = UIImage.SymbolConfiguration(paletteColors: cols)
            image = image.applyingSymbolConfiguration(cfg) ?? image
          }
        case "multicolor":
          if #available(iOS 15.0, *) {
            let cfg = UIImage.SymbolConfiguration.preferringMulticolor()
            image = image.applyingSymbolConfiguration(cfg) ?? image
          }
        case "monochrome":
          if let col = iconColor, #available(iOS 13.0, *) {
            image = image.withTintColor(col, renderingMode: .alwaysOriginal)
          }
        default:
          break
        }
      } else if let col = iconColor, #available(iOS 13.0, *) {
        image = image.withTintColor(col, renderingMode: .alwaysOriginal)
      }
      finalImage = image
    }

    setButtonContent(title: title, image: finalImage, iconOnly: title == nil, fontSize: fontSize, spacing: spacing)

    // Default system highlight/pressed behavior
    button.addTarget(self, action: #selector(onPressed(_:)), for: .touchUpInside)
    button.adjustsImageWhenHighlighted = true

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { result(nil); return }
      switch call.method {
      case "getIntrinsicSize":
        let size = self.button.intrinsicContentSize
        result(["width": Double(size.width), "height": Double(size.height)])
      case "setStyle":
        if let args = call.arguments as? [String: Any] {
          if let n = args["tint"] as? NSNumber {
            self.button.tintColor = Self.colorFromARGB(n.intValue)
            // Re-apply style so configuration picks up new base colors
            self.applyButtonStyle(buttonStyle: self.currentButtonStyle, round: makeRound)
          }
          if let bs = args["buttonStyle"] as? String {
            self.currentButtonStyle = bs
            self.applyButtonStyle(buttonStyle: bs, round: makeRound)
          }
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing style", details: nil)) }
      case "setEnabled":
        if let args = call.arguments as? [String: Any], let e = args["enabled"] as? NSNumber {
          self.isEnabled = e.boolValue
          self.button.isEnabled = self.isEnabled
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing enabled", details: nil)) }
      case "setPressed":
        if let args = call.arguments as? [String: Any], let p = args["pressed"] as? NSNumber {
          self.button.isHighlighted = p.boolValue
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing pressed", details: nil)) }
      case "setButtonTitle", "setButtonIcon":
        if let args = call.arguments as? [String: Any] {
          if let t = args["buttonTitle"] as? String { title = t }

          if let f = args["buttonFontSize"] as? NSNumber { fontSize = f }
          if let s = args["buttonSpacing"] as? NSNumber { spacing = s }

          if let i = args["buttonIconBytes"] as? FlutterStandardTypedData { iconBytes = i }
          if let s = args["buttonIconSize"] as? NSNumber { iconSize = s }
          if let c = args["buttonIconColor"] as? NSNumber { iconColor = Self.colorFromARGB(c.intValue) }
          if let s = args["buttonIconName"] as? String { iconName = s }
          if let m = args["buttonIconRenderingMode"] as? String { iconMode = m }

          var image: UIImage?
          if let bytes = iconBytes {
            image = UIImage(data: bytes.data, scale: UIScreen.main.scale)
          } else if let name = iconName, !name.isEmpty {
            image = UIImage(systemName: name)
          }

          if let sz = iconSize, let img = image {
            // image = img.applyingSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: CGFloat(truncating: s))) ?? img
            image = img.resized(to: CGSize(width: Int(truncating: sz), height: Int(truncating: sz))) ?? img
          }

          if let mode = iconMode, let img0 = image {
            let img = img0
            switch mode {
            case "hierarchical":
              if #available(iOS 15.0, *), let c = args["buttonIconColor"] as? NSNumber {
                let cfg = UIImage.SymbolConfiguration(hierarchicalColor: Self.colorFromARGB(c.intValue))
                image = img.applyingSymbolConfiguration(cfg) ?? img
              }
            case "palette":
              if #available(iOS 15.0, *), let pal = args["buttonIconPaletteColors"] as? [NSNumber] {
                let cols = pal.map { Self.colorFromARGB($0.intValue) }
                let cfg = UIImage.SymbolConfiguration(paletteColors: cols)
                image = img.applyingSymbolConfiguration(cfg) ?? img
              }
            case "multicolor":
              if #available(iOS 15.0, *) {
                let cfg = UIImage.SymbolConfiguration.preferringMulticolor()
                image = img.applyingSymbolConfiguration(cfg) ?? img
              }
            case "monochrome":
              if let c = args["buttonIconColor"] as? NSNumber, #available(iOS 13.0, *) {
                image = img.withTintColor(Self.colorFromARGB(c.intValue), renderingMode: .alwaysOriginal)
              }
            default:
              break
            }
          } else if let c = iconColor, let img = image, #available(iOS 13.0, *) {
            image = img.withTintColor(c, renderingMode: .alwaysOriginal)
          }

          finalImage = image

          setButtonContent(title: title, image: finalImage, iconOnly: title == nil, fontSize: fontSize, spacing: spacing)
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing icon args", details: nil)) }
      case "setBrightness":
        if let args = call.arguments as? [String: Any], let isDark = (args["isDark"] as? NSNumber)?.boolValue {
          if #available(iOS 13.0, *) { self.container.overrideUserInterfaceStyle = isDark ? .dark : .light }
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing isDark", details: nil)) }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  func view() -> UIView { container }

  @objc private func onPressed(_ sender: UIButton) {
    guard isEnabled else { return }
    channel.invokeMethod("pressed", arguments: nil)
  }

  private static func colorFromARGB(_ argb: Int) -> UIColor {
    let a = CGFloat((argb >> 24) & 0xFF) / 255.0
    let r = CGFloat((argb >> 16) & 0xFF) / 255.0
    let g = CGFloat((argb >> 8) & 0xFF) / 255.0
    let b = CGFloat(argb & 0xFF) / 255.0
    return UIColor(red: r, green: g, blue: b, alpha: a)
  }

  private func applyButtonStyle(buttonStyle: String, round: Bool) {
    if #available(iOS 15.0, *) {
      // Preserve current content while swapping configurations
      let currentTitle = button.configuration?.title
      let currentImage = button.configuration?.image
      let currentSymbolCfg = button.configuration?.preferredSymbolConfigurationForImage
      var config: UIButton.Configuration
      switch buttonStyle {
      case "plain": config = .plain()
      case "gray": config = .gray()
      case "tinted": config = .tinted()
      case "bordered": config = .bordered()
      case "borderedProminent": config = .borderedProminent()
      case "filled": config = .filled()
      case "glass":
        if #available(iOS 26.0, *) {
          config = .glass()
        } else {
          config = .tinted()
        }
      case "prominentGlass":
        if #available(iOS 26.0, *) {
          config = .prominentGlass()
        } else {
          config = .tinted()
        }
      default:
        config = .plain()
      }
      config.cornerStyle = round ? .capsule : .dynamic
      // Apply theme tint to configuration in a platform-standard way
      if let tint = button.tintColor {
        switch buttonStyle {
        case "filled", "borderedProminent", "prominentGlass":
          // Treat prominentGlass like filled: color the background and let system pick readable foreground
          config.baseBackgroundColor = tint
        case "tinted", "bordered", "gray", "plain", "glass":
          // Foreground-only tint
          config.baseForegroundColor = tint
        default:
          break
        }
      }
      // Restore content after style swap
      config.title = currentTitle
      config.image = currentImage
      config.preferredSymbolConfigurationForImage = currentSymbolCfg
      button.configuration = config
    } else {
      button.layer.cornerRadius = round ? 999 : 8
      button.clipsToBounds = true
      // Default background to preserve pressed/highlight behavior; custom glass handled above for iOS15+
      button.backgroundColor = .clear
      button.layer.borderWidth = 0
    }
  }

  private func setButtonContent(
    title: String?,
    image: UIImage?,
    iconOnly: Bool,
    fontSize: NSNumber?,
    spacing: NSNumber?
  ) {
    // 👉 默认值
    let fontSizeValue = CGFloat(fontSize?.floatValue ?? 14)
    let spacingValue = CGFloat(spacing?.floatValue ?? 6)
    let font = UIFont.systemFont(ofSize: fontSizeValue)

    if #available(iOS 15.0, *) {
      var cfg = button.configuration ?? .plain()

      cfg.image = image

      if !iconOnly, let title = title {
        var attrTitle = AttributedString(title)
        attrTitle.font = font
        cfg.attributedTitle = attrTitle
      } else {
        cfg.attributedTitle = nil
      }

      // 👉 间距控制
      cfg.imagePadding = (title != nil && image != nil && !iconOnly) ? spacingValue : 0

      // 👉 iconOnly padding
      if iconOnly {
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
      } else {
        cfg.contentInsets = .zero
      }

      button.configuration = cfg

    } else {
      button.setTitle(iconOnly ? nil : title, for: .normal)
      button.setImage(image, for: .normal)
      button.titleLabel?.font = font

      if iconOnly {
        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
      } else if title != nil && image != nil {
        // 👉 间距控制（老版本）
        button.imageEdgeInsets = UIEdgeInsets(
          top: 0,
          left: -spacingValue / 2,
          bottom: 0,
          right: spacingValue / 2
        )
        button.titleEdgeInsets = UIEdgeInsets(
          top: 0,
          left: spacingValue / 2,
          bottom: 0,
          right: -spacingValue / 2
        )
        button.contentEdgeInsets = .zero
      } else {
        // 👉 reset（防止复用错位）
        button.imageEdgeInsets = .zero
        button.titleEdgeInsets = .zero
        button.contentEdgeInsets = .zero
      }
    }
  }
}
