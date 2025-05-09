import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "Automatic"
    case light = "Light"
    case dark = "Dark"
    var id: String { self.rawValue }
}

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Spacer()
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Label("Close", systemImage: "xmark")
                        .labelStyle(.iconOnly)
                        .foregroundColor(.secondary)
                        .padding(6)
                }
                .buttonStyle(PlainButtonStyle())
            }

            Text("Settings")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .padding(.top, 8)

            Text("Appearance")
                .font(.headline)

            Picker("Appearance", selection: $appearanceMode) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.trailing)

            Spacer()
        }
        .padding(32)
        .frame(minWidth: 350, minHeight: 220)
    }
}
