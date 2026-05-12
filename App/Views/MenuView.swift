import SwiftUI
import FanDomain

struct MenuView: View {
    @Bindable var model: FanListModel
    @Bindable var installer: HelperInstaller

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            HelperStatusRow(installer: installer)

            Divider()

            if model.fans.isEmpty {
                Text("No fans detected (this Mac may be fanless).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(model.fans) { fan in
                    FanRowView(fan: fan) { mode in
                        model.setMode(mode, forFan: fan.index)
                    }
                }
            }

            if let error = model.lastError {
                Divider()
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(3)
            }

            Divider()

            HStack {
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
                    .buttonStyle(.borderless)
                    .keyboardShortcut("q")
            }
        }
        .padding(14)
        .frame(width: 320)
        .task {
            await installer.refresh()
            model.startPolling()
        }
        .onDisappear { model.stopPolling() }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Image(systemName: "fanblades")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text("MacFanControl")
                    .font(.headline)
                if let rpm = model.headlineRPM {
                    Text("\(rpm) rpm").font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }
}

private struct HelperStatusRow: View {
    @Bindable var installer: HelperInstaller

    var body: some View {
        HStack(spacing: 8) {
            StatusPill(presentation: presentation)
            Spacer()
            actions
        }
    }

    private var presentation: StatusPresentation {
        switch installer.health {
        case .unknown:           return .init(label: "Checking…", color: .gray)
        case .notInstalled:      return .init(label: "Not installed", color: .gray)
        case .requiresApproval:  return .init(label: "Needs approval", color: .yellow)
        case .healthy(let v):    return .init(label: "Helper v\(v)", color: .green)
        case .unreachable:       return .init(label: "Unreachable", color: .red)
        case .failed:            return .init(label: "Error", color: .red)
        }
    }

    @ViewBuilder
    private var actions: some View {
        switch installer.health {
        case .unknown:
            EmptyView()
        case .notInstalled:
            Button("Install") { installer.install() }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        case .requiresApproval:
            Button("Open Settings") { installer.openLoginItems() }
                .controlSize(.small)
        case .healthy:
            Menu {
                Button("Recheck") { Task { await installer.refresh() } }
                Button("Reinstall") { installer.reinstall() }
                Divider()
                Button("Uninstall", role: .destructive) { installer.uninstall() }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        case .unreachable:
            Button("Reinstall") { installer.reinstall() }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        case .failed:
            Button("Retry") { installer.install() }
                .controlSize(.small)
        }
    }
}

private struct StatusPresentation {
    let label: String
    let color: Color
}

private struct StatusPill: View {
    let presentation: StatusPresentation
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(presentation.color).frame(width: 8, height: 8)
            Text(presentation.label).font(.subheadline)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(presentation.color.opacity(0.12), in: Capsule())
    }
}
