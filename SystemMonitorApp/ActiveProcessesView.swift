import SwiftUI
import AppKit
import Darwin

struct ActiveProcessesView: View {
    @State private var searchQuery: String = ""
    @State private var sortOption: SortOption = .name
    @State private var activeProcesses: [ProcessDetails] = []
    @State private var timer = Timer.publish(every: 4.0, on: .main, in: .common).autoconnect()

    enum SortOption: String, CaseIterable, Identifiable {
        case name = "Name"
        case pid = "PID"
        case cpu = "CPU"
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
                case .cpu:
                    return $0.cpuUsage > $1.cpuUsage
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
                    Text(String(format: "%.1f%%", process.cpuUsage))
                        .foregroundColor(process.cpuUsage > 80 ? .red : .gray)
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
        var processes: [ProcessDetails] = []
        
        for app in runningApps where app.processIdentifier != 0 && app.localizedName != nil {
            let cpuUsage = getProcessCPUUsage(pid: app.processIdentifier)
            processes.append(ProcessDetails(
                name: app.localizedName ?? app.bundleIdentifier ?? "Unknown",
                pid: Int(app.processIdentifier),
                cpuUsage: cpuUsage
            ))
        }
        
        self.activeProcesses = processes
    }
    
    private func getProcessCPUUsage(pid: pid_t) -> Double {
        var taskInfo = task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<task_basic_info>.size / MemoryLayout<natural_t>.size)
        
        let result = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_,
                         task_flavor_t(TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let userTime = Double(taskInfo.user_time.seconds) + Double(taskInfo.user_time.microseconds) / 1_000_000.0
            let systemTime = Double(taskInfo.system_time.seconds) + Double(taskInfo.system_time.microseconds) / 1_000_000.0
            return (userTime + systemTime) * 100.0
        }
        
        return 0.0
    }
}

struct ProcessDetails: Identifiable {
    let id = UUID()
    let name: String
    let pid: Int
    let cpuUsage: Double
}
