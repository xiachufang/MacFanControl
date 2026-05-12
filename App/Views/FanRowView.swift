import SwiftUI
import FanDomain

struct FanRowView: View {
    let fan: Fan
    let onSelect: (FanMode) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(fan.displayName).font(.subheadline).bold()
                Spacer()
                Text("\(fan.currentRPM) rpm").font(.subheadline).monospacedDigit()
            }
            HStack {
                Text("\(fan.minRPM)–\(fan.maxRPM)")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                modePicker
            }
        }
        .padding(.vertical, 2)
    }

    private var modePicker: some View {
        Picker("", selection: Binding(get: { fan.mode },
                                       set: { onSelect($0) })) {
            ForEach(FanMode.allCases, id: \.self) { mode in
                Text(mode.displayName).tag(mode)
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .frame(maxWidth: 130)
    }
}
