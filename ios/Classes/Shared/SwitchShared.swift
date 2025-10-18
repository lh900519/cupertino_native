import SwiftUI

@available(iOS 14.0, *)
struct CupertinoSwitchView: View {
  @ObservedObject var model: SwitchModel

  var body: some View {
    let base = Toggle("", isOn: $model.value)
      .labelsHidden()
      .scaleEffect(model.scale)  // 缩放
      .disabled(!model.enabled)
      .onChange(of: model.value) { newValue in
        model.onChange(newValue)
      }

    if #available(iOS 15.0, *) {
      base.tint(model.tintColor)
    } else {
      base.accentColor(model.tintColor)
    }
  }
}

class SwitchModel: ObservableObject {
  @Published var value: Bool
  @Published var enabled: Bool
  @Published var tintColor: Color = .accentColor
  var onChange: (Bool) -> Void
  @Published var scale: CGSize

  init(value: Bool, enabled: Bool, scale: CGSize, onChange: @escaping (Bool) -> Void) {
    self.value = value
    self.enabled = enabled
    self.scale = scale
    self.onChange = onChange
  }
}
