import SwiftUI

@main
struct MacFanControlApp: App {
    @State private var model: FanListModel
    @State private var installer: HelperInstaller

    init() {
        let (model, installer) = Composition.bootstrap()
        _model = State(initialValue: model)
        _installer = State(initialValue: installer)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuView(model: model, installer: installer)
        } label: {
            MenuBarLabel(model: model)
        }
        .menuBarExtraStyle(.window)
    }
}

private struct MenuBarLabel: View {
    let model: FanListModel
    var body: some View {
        if let rpm = model.headlineRPM {
            Label("\(rpm)", systemImage: "fanblades")
        } else {
            Image(systemName: "fanblades")
        }
    }
}
