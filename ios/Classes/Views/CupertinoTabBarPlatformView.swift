import Flutter
import UIKit

class CupertinoTabBarPlatformView: NSObject, FlutterPlatformView, UITabBarDelegate {
    // MARK: - Properties
    private let channel: FlutterMethodChannel
    private let container: UIView
    private var tabBar: UITabBar?
    private var tabBarLeft: UITabBar?
    private var tabBarRight: UITabBar?

    // Configuration properties
    private var isSplit: Bool = false
    private var rightCountVal: Int = 1
    private var currentLabels: [String] = []
    private var currentSymbols: [String] = []
    private var leftInsetVal: CGFloat = 0
    private var rightInsetVal: CGFloat = 0
    private var splitSpacingVal: CGFloat = 8
    private var currentStyle: TabBarStyle?
    private var isDarkMode: Bool = false

    // MARK: - Configuration Structures
    private struct TabBarStyle {
        let tintColor: UIColor?
        let backgroundColor: UIColor?
    }

    private struct TabBarConfiguration {
        let labels: [String]
        let symbols: [String]
        let iconBytes: [FlutterStandardTypedData]
        let iconBytesActive: [FlutterStandardTypedData]
        let sizes: [NSNumber]
        let selectedIndex: Int
        let isDark: Bool
        let style: TabBarStyle?
        let isSplit: Bool
        let rightCount: Int
        let splitSpacing: CGFloat
        let leftInset: CGFloat
        let rightInset: CGFloat
    }

    // MARK: - Initialization
    init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
        self.channel = FlutterMethodChannel(name: "CupertinoNativeTabBar_\(viewId)", binaryMessenger: messenger)
        self.container = UIView(frame: frame)

        super.init()

        setupContainer()
        configureFromArguments(args)
        setupMethodChannelHandler()
    }

    // MARK: - Setup Methods
    private func setupContainer() {
        container.backgroundColor = .clear
        if #available(iOS 13.0, *) {
            container.overrideUserInterfaceStyle = .light
        }
    }

    private func configureFromArguments(_ args: Any?) {
        guard let dict = args as? [String: Any] else { return }

        let config = parseConfiguration(from: dict)

        // Store current state
        self.currentLabels = config.labels
        self.currentSymbols = config.symbols
        self.isSplit = config.isSplit
        self.rightCountVal = config.rightCount
        self.splitSpacingVal = config.splitSpacing
        self.leftInsetVal = config.leftInset
        self.rightInsetVal = config.rightInset
        self.currentStyle = config.style
        self.isDarkMode = config.isDark

        setupTabBars(with: config)
    }

    private func parseConfiguration(from dict: [String: Any]) -> TabBarConfiguration {
        let labels = (dict["labels"] as? [String]) ?? []
        let symbols = (dict["sfSymbols"] as? [String]) ?? []
        let iconBytes = (dict["iconBytes"] as? [FlutterStandardTypedData]) ?? []
        let iconBytesActive = (dict["iconBytesActive"] as? [FlutterStandardTypedData]) ?? []
        let sizes = (dict["sfSymbolSizes"] as? [NSNumber]) ?? []
        let selectedIndex = (dict["selectedIndex"] as? NSNumber)?.intValue ?? 0
        let isDark = (dict["isDark"] as? NSNumber)?.boolValue ?? false
        let isSplit = (dict["split"] as? NSNumber)?.boolValue ?? false
        let rightCount = (dict["rightCount"] as? NSNumber)?.intValue ?? 1
        let splitSpacing = CGFloat(truncating: (dict["splitSpacing"] as? NSNumber) ?? 8)
        let leftInset: CGFloat = 0 // Controlled by Flutter padding
        let rightInset: CGFloat = 0 // Controlled by Flutter padding

        var style: TabBarStyle?
        if let styleDict = dict["style"] as? [String: Any] {
            let tintColor = (styleDict["tint"] as? NSNumber).map { Self.colorFromARGB($0.intValue) }
            let backgroundColor = (styleDict["backgroundColor"] as? NSNumber).map { Self.colorFromARGB($0.intValue) }
            style = TabBarStyle(tintColor: tintColor, backgroundColor: backgroundColor)
        }

        return TabBarConfiguration(
            labels: labels,
            symbols: symbols,
            iconBytes: iconBytes,
            iconBytesActive: iconBytesActive,
            sizes: sizes,
            selectedIndex: selectedIndex,
            isDark: isDark,
            style: style,
            isSplit: isSplit,
            rightCount: rightCount,
            splitSpacing: splitSpacing,
            leftInset: leftInset,
            rightInset: rightInset
        )
    }

    // MARK: - Tab Bar Setup
    private func setupTabBars(with config: TabBarConfiguration) {
        let count = max(config.labels.count, config.symbols.count)

        if config.isSplit && count > config.rightCount {
            setupSplitTabBars(with: config, totalCount: count)
        } else {
            setupSingleTabBar(with: config, totalCount: count)
        }
    }

    private func setupSingleTabBar(with config: TabBarConfiguration, totalCount: Int) {
        let bar = createTabBar(with: config.style)
        tabBar = bar

        bar.items = buildTabBarItems(for: 0..<totalCount, with: config)
        setSelectedItem(at: config.selectedIndex, for: bar, in: 0..<totalCount)

        container.addSubview(bar)
        applySingleTabBarConstraints(to: bar)
    }

    private func setupSplitTabBars(with config: TabBarConfiguration, totalCount: Int) {
        let leftEnd = totalCount - config.rightCount

        let leftBar = createTabBar(with: config.style)
        let rightBar = createTabBar(with: config.style)

        tabBarLeft = leftBar
        tabBarRight = rightBar

        leftBar.items = buildTabBarItems(for: 0..<leftEnd, with: config)
        rightBar.items = buildTabBarItems(for: leftEnd..<totalCount, with: config)

        // Set selected item
        if config.selectedIndex < leftEnd {
            setSelectedItem(at: config.selectedIndex, for: leftBar, in: 0..<leftEnd)
            rightBar.selectedItem = nil
        } else {
            let rightIndex = config.selectedIndex - leftEnd
            setSelectedItem(at: rightIndex, for: rightBar, in: 0..<config.rightCount)
            leftBar.selectedItem = nil
        }

        container.addSubview(leftBar)
        container.addSubview(rightBar)

        applySplitTabBarConstraints(leftBar: leftBar, rightBar: rightBar, config: config)
    }

    private func createTabBar(with style: TabBarStyle?) -> UITabBar {
        let bar = UITabBar(frame: .zero)
        bar.delegate = self
        bar.translatesAutoresizingMaskIntoConstraints = false

        // Apply style
        if let backgroundColor = style?.backgroundColor {
            bar.barTintColor = backgroundColor
        }

        if #available(iOS 10.0, *), let tintColor = style?.tintColor {
            bar.tintColor = tintColor
        }

        // Configure appearance
        if #available(iOS 13.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.stackedLayoutAppearance.normal.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 0)

            bar.standardAppearance = appearance
            if #available(iOS 15.0, *) {
                bar.scrollEdgeAppearance = appearance
            }
        }

        return bar
    }

    private func buildTabBarItems(for range: Range<Int>, with config: TabBarConfiguration) -> [UITabBarItem] {
        return range.compactMap { index in
            createTabBarItem(at: index, with: config)
        }
    }

    private func createTabBarItem(at index: Int, with config: TabBarConfiguration) -> UITabBarItem? {
        let title = index < config.labels.count ? config.labels[index] : nil

        var image: UIImage?
        var selectedImage: UIImage?

        if index < config.symbols.count {
            let symbol = config.symbols[index]
            let size = index < config.sizes.count ? CGSize(
                width: CGFloat(truncating: config.sizes[index]),
                height: CGFloat(truncating: config.sizes[index])
            ) : nil

            // Try to load custom image first
            if index < config.iconBytes.count {
                image = UIImage(data: config.iconBytes[index].data, scale: UIScreen.main.scale)
                selectedImage = image

                if index < config.iconBytesActive.count {
                    selectedImage = UIImage(data: config.iconBytesActive[index].data, scale: UIScreen.main.scale)
                }
            } else {
                // Use SF Symbol
                image = UIImage(systemName: symbol)
                selectedImage = image
            }

            // Resize and set rendering mode
            if let size = size {
                image = image?.resized(to: size)?.withRenderingMode(.alwaysOriginal)
                selectedImage = selectedImage?.resized(to: size)?.withRenderingMode(.alwaysOriginal)
            }
        }

        return UITabBarItem(title: title, image: image, selectedImage: selectedImage)
    }

    private func setSelectedItem(at index: Int, for tabBar: UITabBar, in range: Range<Int>) {
        guard index >= 0,
              index < range.count,
              let items = tabBar.items,
              index < items.count else { return }

        tabBar.selectedItem = items[index]
    }

    // MARK: - Constraints
    private func applySingleTabBarConstraints(to bar: UITabBar) {
        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: -20),
            bar.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: 20),
            bar.topAnchor.constraint(equalTo: container.topAnchor),
            bar.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 20)
        ])
    }

    private func applySplitTabBarConstraints(leftBar: UITabBar, rightBar: UITabBar, config: TabBarConfiguration) {
        let spacing = config.splitSpacing
        let leftWidth = leftBar.sizeThatFits(.zero).width + config.leftInset * 2
        let rightWidth = rightBar.sizeThatFits(.zero).width + config.rightInset * 2
        let totalWidth = leftWidth + rightWidth + spacing

        if totalWidth > container.bounds.width {
            // Use proportional widths
            let rightFraction = CGFloat(config.rightCount) / CGFloat(max(config.labels.count, config.symbols.count))

            NSLayoutConstraint.activate([
                // Left bar
                leftBar.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: config.leftInset - 20),
                leftBar.trailingAnchor.constraint(equalTo: rightBar.leadingAnchor, constant: -spacing),
                leftBar.topAnchor.constraint(equalTo: container.topAnchor),
                leftBar.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 20),

                // Right bar
                rightBar.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -config.rightInset + 20),
                rightBar.topAnchor.constraint(equalTo: container.topAnchor),
                rightBar.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 20),
                rightBar.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: rightFraction),
            ])
        } else {
            // Use fixed widths
            NSLayoutConstraint.activate([
                // Right bar
                rightBar.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -config.rightInset + 20),
                rightBar.topAnchor.constraint(equalTo: container.topAnchor),
                rightBar.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 20),
                rightBar.widthAnchor.constraint(equalToConstant: rightWidth),

                // Left bar
                leftBar.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: config.leftInset - 20),
                leftBar.topAnchor.constraint(equalTo: container.topAnchor),
                leftBar.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 20),
                leftBar.widthAnchor.constraint(equalToConstant: leftWidth),

                // Spacing constraint
                leftBar.trailingAnchor.constraint(lessThanOrEqualTo: rightBar.leadingAnchor, constant: -spacing + 20)
            ])
        }
    }

    // MARK: - Method Channel Handler
    private func setupMethodChannelHandler() {
        channel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else {
                result(nil)
                return
            }

            self.handleMethodCall(call, result: result)
        }
    }

    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getIntrinsicSize":
            handleGetIntrinsicSize(result: result)

        case "setItems":
            handleSetItems(call: call, result: result)

        case "setLayout":
            handleSetLayout(call: call, result: result)

        case "setSelectedIndex":
            handleSetSelectedIndex(call: call, result: result)

        case "setStyle":
            handleSetStyle(call: call, result: result)

        case "setBrightness":
            handleSetBrightness(call: call, result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Method Handlers
    private func handleGetIntrinsicSize(result: @escaping FlutterResult) {
        let referenceBar = tabBar ?? tabBarLeft ?? tabBarRight

        if let bar = referenceBar {
            let size = bar.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
            result(["width": Double(size.width), "height": Double(size.height)])
        } else {
            result(["width": Double(container.bounds.width), "height": 50.0])
        }
    }

    private func handleSetItems(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "bad_args", message: "Missing arguments", details: nil))
            return
        }

        let labels = (args["labels"] as? [String]) ?? []
        let symbols = (args["sfSymbols"] as? [String]) ?? []
        let selectedIndex = (args["selectedIndex"] as? NSNumber)?.intValue ?? 0

        currentLabels = labels
        currentSymbols = symbols

        let config = TabBarConfiguration(
            labels: labels,
            symbols: symbols,
            iconBytes: (args["iconBytes"] as? [FlutterStandardTypedData]) ?? [],
            iconBytesActive: (args["iconBytesActive"] as? [FlutterStandardTypedData]) ?? [],
            sizes: (args["sfSymbolSizes"] as? [NSNumber]) ?? [],
            selectedIndex: selectedIndex,
            isDark: isDarkMode,
            style: currentStyle,
            isSplit: isSplit,
            rightCount: rightCountVal,
            splitSpacing: splitSpacingVal,
            leftInset: leftInsetVal,
            rightInset: rightInsetVal
        )

        updateTabBarItems(with: config)
        result(nil)
    }

    private func updateTabBarItems(with config: TabBarConfiguration) {
        let count = max(config.labels.count, config.symbols.count)

        if isSplit, count > rightCountVal,
           let leftBar = tabBarLeft, let rightBar = tabBarRight {
            let leftEnd = count - rightCountVal
            leftBar.items = buildTabBarItems(for: 0..<leftEnd, with: config)
            rightBar.items = buildTabBarItems(for: leftEnd..<count, with: config)

            // Update selected item
            if config.selectedIndex < leftEnd {
                setSelectedItem(at: config.selectedIndex, for: leftBar, in: 0..<leftEnd)
                rightBar.selectedItem = nil
            } else {
                let rightIndex = config.selectedIndex - leftEnd
                setSelectedItem(at: rightIndex, for: rightBar, in: 0..<rightCountVal)
                leftBar.selectedItem = nil
            }
        } else if let bar = tabBar {
            bar.items = buildTabBarItems(for: 0..<count, with: config)
            setSelectedItem(at: config.selectedIndex, for: bar, in: 0..<count)
        }
    }

    private func handleSetLayout(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "bad_args", message: "Missing layout arguments", details: nil))
            return
        }

        let split = (args["split"] as? NSNumber)?.boolValue ?? false
        let rightCount = (args["rightCount"] as? NSNumber)?.intValue ?? 1
        let selectedIndex = (args["selectedIndex"] as? NSNumber)?.intValue ?? 0

        if let spacingNumber = args["splitSpacing"] as? NSNumber {
            splitSpacingVal = CGFloat(truncating: spacingNumber)
        }

        // Clear existing tab bars
        clearAllTabBars()

        // Update configuration
        isSplit = split
        rightCountVal = rightCount

        let config = TabBarConfiguration(
            labels: currentLabels,
            symbols: currentSymbols,
            iconBytes: [],
            iconBytesActive: [],
            sizes: [],
            selectedIndex: selectedIndex,
            isDark: isDarkMode,
            style: currentStyle,
            isSplit: split,
            rightCount: rightCount,
            splitSpacing: splitSpacingVal,
            leftInset: leftInsetVal,
            rightInset: rightInsetVal
        )

        setupTabBars(with: config)
        result(nil)
    }

    private func clearAllTabBars() {
        tabBar?.removeFromSuperview()
        tabBarLeft?.removeFromSuperview()
        tabBarRight?.removeFromSuperview()

        tabBar = nil
        tabBarLeft = nil
        tabBarRight = nil
    }

    private func handleSetSelectedIndex(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let index = (args["index"] as? NSNumber)?.intValue else {
            result(FlutterError(code: "bad_args", message: "Missing index", details: nil))
            return
        }

        if updateSelectedIndex(to: index) {
            result(nil)
        } else {
            result(FlutterError(code: "bad_args", message: "Index out of range", details: nil))
        }
    }

    private func updateSelectedIndex(to index: Int) -> Bool {
        // Single tab bar
        if let bar = tabBar, let items = bar.items,
           index >= 0, index < items.count {
            bar.selectedItem = items[index]
            return true
        }

        // Split tab bars
        if let leftBar = tabBarLeft, let leftItems = leftBar.items {
            if index >= 0, index < leftItems.count {
                leftBar.selectedItem = leftItems[index]
                tabBarRight?.selectedItem = nil
                return true
            }

            if let rightBar = tabBarRight, let rightItems = rightBar.items {
                let rightIndex = index - leftItems.count
                if rightIndex >= 0, rightIndex < rightItems.count {
                    rightBar.selectedItem = rightItems[rightIndex]
                    leftBar.selectedItem = nil
                    return true
                }
            }
        }

        return false
    }

    private func handleSetStyle(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "bad_args", message: "Missing style arguments", details: nil))
            return
        }

        if let tintValue = args["tint"] as? NSNumber {
            let tintColor = Self.colorFromARGB(tintValue.intValue)
            applyTintColor(tintColor)
            currentStyle = TabBarStyle(
                tintColor: tintColor,
                backgroundColor: currentStyle?.backgroundColor
            )
        }

        if let backgroundValue = args["backgroundColor"] as? NSNumber {
            let backgroundColor = Self.colorFromARGB(backgroundValue.intValue)
            applyBackgroundColor(backgroundColor)
            currentStyle = TabBarStyle(
                tintColor: currentStyle?.tintColor,
                backgroundColor: backgroundColor
            )
        }

        result(nil)
    }

    private func applyTintColor(_ color: UIColor) {
        tabBar?.tintColor = color
        tabBarLeft?.tintColor = color
        tabBarRight?.tintColor = color
    }

    private func applyBackgroundColor(_ color: UIColor) {
        tabBar?.barTintColor = color
        tabBarLeft?.barTintColor = color
        tabBarRight?.barTintColor = color
    }

    private func handleSetBrightness(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let isDark = (args["isDark"] as? NSNumber)?.boolValue else {
            result(FlutterError(code: "bad_args", message: "Missing isDark parameter", details: nil))
            return
        }

        isDarkMode = isDark
        if #available(iOS 13.0, *) {
            container.overrideUserInterfaceStyle = isDark ? .dark : .light
        }

        result(nil)
    }

    // MARK: - FlutterPlatformView
    func view() -> UIView {
        return container
    }

    // MARK: - UITabBarDelegate
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        let index = calculateSelectedIndex(for: tabBar, item: item)
        channel.invokeMethod("valueChanged", arguments: ["index": index])
    }

    private func calculateSelectedIndex(for tabBar: UITabBar, item: UITabBarItem) -> Int {
        // Single tab bar
        if let singleBar = self.tabBar, singleBar === tabBar,
           let items = singleBar.items, let index = items.firstIndex(of: item) {
            return index
        }

        // Split left tab bar
        if let leftBar = tabBarLeft, leftBar === tabBar,
           let items = leftBar.items, let index = items.firstIndex(of: item) {
            tabBarRight?.selectedItem = nil
            return index
        }

        // Split right tab bar
        if let rightBar = tabBarRight, rightBar === tabBar,
           let items = rightBar.items, let index = items.firstIndex(of: item),
           let leftBar = tabBarLeft, let leftItems = leftBar.items {
            tabBarLeft?.selectedItem = nil
            return leftItems.count + index
        }

        return 0
    }

    // MARK: - Utility Methods
    private static func colorFromARGB(_ argb: Int) -> UIColor {
        let alpha = CGFloat((argb >> 24) & 0xFF) / 255.0
        let red = CGFloat((argb >> 16) & 0xFF) / 255.0
        let green = CGFloat((argb >> 8) & 0xFF) / 255.0
        let blue = CGFloat(argb & 0xFF) / 255.0
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

// MARK: - UIImage Extension
extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }

        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
