import SwiftUI

@available(iOS 14.0, *)
struct CupertinoSwitchView: View {
  @ObservedObject var model: SwitchModel

  var body: some View {
    let base = Toggle("", isOn: $model.value)
      .labelsHidden()
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

  init(value: Bool, enabled: Bool, onChange: @escaping (Bool) -> Void) {
    self.value = value
    self.enabled = enabled
    self.onChange = onChange
  }
}
