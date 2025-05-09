import SwiftUI
import AppKit

struct ActiveProcessesView: View {
    @State private var searchQuery: String = ""
    @State private var sortOption: SortOption = .name
    @State private var activeProcesses: [ProcessDetails] = []
    @State private var timer = Timer.publish(every: 4.0, on: .main, in: .common).autoconnect()

    enum SortOption: String, CaseIterable, Identifiable {
        case name = "Name"
        case pid = "PID"
        var id: String { self.rawValue }
    }

    var filteredProcesses: [ProcessDetails] {
        activeProcesses
            .filter { searchQuery.isEmpty || $0.name.localizedCaseInsensitiveContains(searchQuery) }
            .sorted {
                switch sortOption {
                case .name:
                    return $0.name.localizedCompare($1.name) == .orderedAscending
                case .pid:
                    return $0.pid < $1.pid
                }
            }
    }

    var body: some View {
        VStack(spacing: 10) {
            TextField("Search processes...", text: $searchQuery)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Picker("Sort By", selection: $sortOption) {
                ForEach(SortOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            List(filteredProcesses.prefix(5), id: \.id) { process in
                HStack {
                    VStack(alignment: .leading) {
                        Text(process.name)
                            .font(.body)
                        Text("PID: \(process.pid)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text("-")
                        .foregroundColor(.gray)
                }
            }
            .listStyle(PlainListStyle())
            .frame(height: 200)
            .padding()
        }
        .onAppear {
            fetchActiveProcesses()
        }
        .onReceive(timer) { _ in
            fetchActiveProcesses()
        }
    }

    private func fetchActiveProcesses() {
        let runningApps = NSWorkspace.shared.runningApplications
        self.activeProcesses = runningApps
            .filter { $0.processIdentifier != 0 && $0.localizedName != nil }
            .map {
                ProcessDetails(
                    name: $0.localizedName ?? $0.bundleIdentifier ?? "Unknown",
                    pid: Int($0.processIdentifier),
                    cpuUsage: 0
                )
            }
    }
}

struct ProcessDetails: Identifiable {
    let id = UUID()
    let name: String
    let pid: Int
    let cpuUsage: Double
}
