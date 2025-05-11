import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "Automatic"
    case light = "Light"
    case dark = "Dark"
    var id: String { self.rawValue }
}

enum UpdateInterval: Double, CaseIterable, Identifiable {
    case fast = 2.0
    case normal = 4.0
    case slow = 8.0
    
    var id: Double { self.rawValue }
    var label: String {
        switch self {
        case .fast: return "Fast (2s)"
        case .normal: return "Normal (4s)"
        case .slow: return "Slow (8s)"
        }
    }
}

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("updateInterval") private var updateInterval: Double = UpdateInterval.normal.rawValue
    @AppStorage("maxProcesses") private var maxProcesses: Int = 5
    @AppStorage("showGraphGrid") private var showGraphGrid: Bool = true
    @AppStorage("graphHeight") private var graphHeight: Double = 200

    private var currentUpdateInterval: UpdateInterval {
        get { UpdateInterval(rawValue: updateInterval) ?? .normal }
        set { updateInterval = newValue.rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HeaderView(presentationMode: presentationMode)
                AppearanceSection(appearanceMode: $appearanceMode)
                UpdateIntervalSection(updateInterval: $updateInterval)
                ProcessListSection(maxProcesses: $maxProcesses)
                GraphSettingsSection(showGrid: $showGraphGrid, graphHeight: $graphHeight)
                Spacer()
            }
            .padding(32)
        }
        .frame(minWidth: 400, minHeight: 500)
        .background(Color(.windowBackgroundColor))
    }
}

struct HeaderView: View {
    let presentationMode: Binding<PresentationMode>
    
    var body: some View {
        HStack {
            Text("Settings")
                .font(.system(size: 28, weight: .bold, design: .rounded))
            Spacer()
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
            .help("Close settings")
        }
        .padding(.bottom, 24)
    }
}

struct AppearanceSection: View {
    @Binding var appearanceMode: AppearanceMode
    
    var body: some View {
        SettingsSection(title: "Appearance", icon: "paintbrush.fill", color: .blue) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(AppearanceMode.allCases) { mode in
                    AppearanceOption(mode: mode, selectedMode: $appearanceMode)
                }
            }
        }
    }
}

struct AppearanceOption: View {
    let mode: AppearanceMode
    @Binding var selectedMode: AppearanceMode
    
    var body: some View {
        HStack {
            Image(systemName: mode == .system ? "circle.lefthalf.filled" :
                    mode == .light ? "sun.max.fill" : "moon.fill")
                .foregroundColor(mode == .system ? .blue :
                                mode == .light ? .orange : .purple)
            Text(mode.rawValue)
                .font(.system(.body, design: .rounded))
            Spacer()
            if mode == selectedMode {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.windowBackgroundColor).opacity(0.5))
        )
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedMode = mode
            }
        }
    }
}

struct UpdateIntervalSection: View {
    @Binding var updateInterval: Double
    
    private var currentInterval: UpdateInterval {
        get { UpdateInterval(rawValue: updateInterval) ?? .normal }
        set { updateInterval = newValue.rawValue }
    }
    
    var body: some View {
        SettingsSection(title: "Update Interval", icon: "clock.fill", color: .green) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(UpdateInterval.allCases) { interval in
                    UpdateIntervalOption(interval: interval, selectedInterval: currentInterval) { newInterval in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            updateInterval = newInterval.rawValue
                        }
                    }
                }
            }
        }
    }
}

struct UpdateIntervalOption: View {
    let interval: UpdateInterval
    let selectedInterval: UpdateInterval
    let onSelect: (UpdateInterval) -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "timer")
                .foregroundColor(.green)
            Text(interval.label)
                .font(.system(.body, design: .rounded))
            Spacer()
            if interval == selectedInterval {
                Image(systemName: "checkmark")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.windowBackgroundColor).opacity(0.5))
        )
        .onTapGesture {
            onSelect(interval)
        }
    }
}

struct ProcessListSection: View {
    @Binding var maxProcesses: Int
    
    var body: some View {
        SettingsSection(title: "Process List", icon: "list.bullet", color: .orange) {
            HStack {
                Text("Maximum Processes")
                    .font(.system(.body, design: .rounded))
                Spacer()
                Picker("", selection: $maxProcesses) {
                    ForEach([3, 5, 10, 15], id: \.self) { count in
                        Text("\(count)").tag(count)
                    }
                }
                .frame(width: 80)
            }
        }
    }
}

struct GraphSettingsSection: View {
    @Binding var showGrid: Bool
    @Binding var graphHeight: Double
    
    var body: some View {
        SettingsSection(title: "Graph Settings", icon: "chart.line.uptrend.xyaxis", color: .purple) {
            VStack(alignment: .leading, spacing: 16) {
                Toggle("Show Grid", isOn: $showGrid)
                    .font(.system(.body, design: .rounded))
                
                HStack {
                    Text("Graph Height")
                        .font(.system(.body, design: .rounded))
                    Spacer()
                    Slider(value: $graphHeight, in: 100...300, step: 10)
                        .frame(width: 150)
                    Text("\(Int(graphHeight))")
                        .font(.system(.body, design: .rounded))
                        .frame(width: 40)
                }
            }
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    
    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.system(.headline, design: .rounded))
            }
            content
        }
        .padding(.vertical, 16)
    }
}
