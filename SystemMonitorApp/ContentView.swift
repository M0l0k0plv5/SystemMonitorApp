import SwiftUI
import Darwin
import Combine

struct ContentView: View {
    @State private var cpuCores: Int = 0
    @State private var freeMemory: Double = 0.0
    @State private var totalMemory: Double = 0.0
    @State private var osName: String = ""
    @State private var uptime: Int = 0
    @State private var cpuUsage: [Double] = Array(repeating: 0.0, count: 20)
    @State private var systemModel: String = ""
    @State private var cpuArchitecture: String = ""
    @State private var bootTime: String = ""
    @State private var totalDiskSpace: Double = 0.0
    @State private var usedDiskSpace: Double = 0.0
    @State private var freeDiskSpace: Double = 0.0
    @State private var showSettings = false
    @AppStorage("updateInterval") private var updateInterval: Double = UpdateInterval.normal.rawValue
    
    // CPU usage tracking
    @State private var previousTotalTicks: UInt64 = 0
    @State private var previousIdleTicks: UInt64 = 0

    private var timer: Publishers.Autoconnect<Timer.TimerPublisher> {
        Timer.publish(every: updateInterval, on: .main, in: .common).autoconnect()
    }

    var formattedUptime: String {
        let hours = uptime / 3600
        let minutes = (uptime % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    var averageCPU: Double {
        cpuUsage.reduce(0, +) / Double(cpuUsage.count)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VisualEffectBlur()
                .ignoresSafeArea()

            HStack(spacing: 0) {
                // Left Section: System Info
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("System Info")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .padding(.top)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Settings Button moved here
                        Button(action: { showSettings = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Settings")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(.primary)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.windowBackgroundColor).opacity(0.5))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)

                    Group {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("CPU Info").font(.headline)
                            HStack {
                                Image(systemName: "cpu")
                                    .foregroundColor(.blue)
                                Text("Cores: \(cpuCores)")
                            }
                            HStack {
                                Image(systemName: "memorychip")
                                    .foregroundColor(.blue)
                                Text("Architecture: \(cpuArchitecture)")
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(.windowBackgroundColor).opacity(0.5))
                        .cornerRadius(10)
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Memory Info").font(.headline)
                            HStack {
                                Image(systemName: "memorychip")
                                    .foregroundColor(.green)
                                Text("Free Memory: \(Int(ceil(freeMemory / 1024))) GB")
                            }
                            HStack {
                                Image(systemName: "memorychip.fill")
                                    .foregroundColor(.green)
                                Text("Total Memory: \(Int(ceil(totalMemory / 1024))) GB")
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(.windowBackgroundColor).opacity(0.5))
                        .cornerRadius(10)
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Disk Info").font(.headline)
                            HStack {
                                Image(systemName: "externaldrive")
                                    .foregroundColor(.orange)
                                Text("Total: \(totalDiskSpace, specifier: "%.2f") GB")
                            }
                            HStack {
                                Image(systemName: "externaldrive.fill")
                                    .foregroundColor(.orange)
                                Text("Used: \(usedDiskSpace, specifier: "%.2f") GB")
                            }
                            HStack {
                                Image(systemName: "externaldrive.badge.checkmark")
                                    .foregroundColor(.orange)
                                Text("Free: \(freeDiskSpace, specifier: "%.2f") GB")
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(.windowBackgroundColor).opacity(0.5))
                        .cornerRadius(10)
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("System Info").font(.headline)
                            HStack {
                                Image(systemName: "desktopcomputer")
                                    .foregroundColor(.purple)
                                Text("Model: \(systemModel)")
                            }
                            HStack {
                                Image(systemName: "apple.logo")
                                    .foregroundColor(.purple)
                                Text("OS: \(osName)")
                            }
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.purple)
                                Text("Boot Time: \(bootTime)")
                            }
                            HStack {
                                Image(systemName: "timer")
                                    .foregroundColor(.purple)
                                Text("Uptime: \(formattedUptime)")
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(.windowBackgroundColor).opacity(0.5))
                        .cornerRadius(10)
                    }
                    Spacer()
                }
                .font(.system(.body, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                Divider()

                // Right Section: CPU Utilization Graph & Active Processes
                VStack(spacing: 20) {
                    VStack {
                        Text("CPU Utilization")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .padding(.top)
                            .foregroundColor(.primary)
                        if let currentCPU = cpuUsage.last {
                            Text("\(Int(currentCPU))%")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(currentCPU > 80 ? .red : .green)
                                .padding(.bottom, 2)
                            Text("Avg: \(Int(averageCPU))%")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        LineChartView(cpuUsage: cpuUsage)
                            .frame(height: 200)
                            .padding()
                            .background(Color(.windowBackgroundColor).opacity(0.5))
                            .cornerRadius(15)
                    }
                    ActiveProcessesView()
                        .background(Color(.windowBackgroundColor).opacity(0.5))
                        .cornerRadius(15)
                    Spacer()
                }
                .font(.system(.body, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onAppear {
            fetchSystemInfo()
            updateMemoryInfo()
            updateDiskInfo()
        }
        .onReceive(timer) { _ in
            updateCPUUsage()
            updateMemoryInfo()
            updateDiskInfo()
            self.uptime = Int(ProcessInfo.processInfo.systemUptime)
        }
    }

    private func fetchSystemInfo() {
        self.cpuCores = ProcessInfo.processInfo.processorCount
        self.totalMemory = Double(ProcessInfo.processInfo.physicalMemory) / (1024 * 1024)
        self.uptime = Int(ProcessInfo.processInfo.systemUptime)
        self.osName = ProcessInfo.processInfo.operatingSystemVersionString
        self.cpuArchitecture = ProcessInfo.processInfo.isOperatingSystemAtLeast(.init(majorVersion: 11, minorVersion: 0, patchVersion: 0)) ? "ARM64" : "x86_64"
        self.systemModel = Host.current().localizedName ?? "Unknown Model"
        self.bootTime = calculateBootTime(from: uptime)
    }

    private func calculateBootTime(from uptime: Int) -> String {
        let bootDate = Date().addingTimeInterval(TimeInterval(-uptime))
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: bootDate)
    }

    private func updateCPUUsage() {
        var numCPUs: natural_t = 0
        var numCpuInfo: mach_msg_type_number_t = 0
        var cpuInfo: processor_info_array_t?
        
        let result = host_processor_info(mach_host_self(),
                                       PROCESSOR_CPU_LOAD_INFO,
                                       &numCPUs,
                                       &cpuInfo,
                                       &numCpuInfo)
        
        if result == KERN_SUCCESS, let cpuInfo = cpuInfo {
            var totalTicks: UInt64 = 0
            var idleTicks: UInt64 = 0
            
            let cpuLoadInfo = UnsafeMutableRawPointer(cpuInfo).bindMemory(to: processor_cpu_load_info.self, capacity: Int(numCPUs))
            
            for i in 0..<Int(numCPUs) {
                let user = UInt64(cpuLoadInfo[i].cpu_ticks.0)
                let system = UInt64(cpuLoadInfo[i].cpu_ticks.1)
                let idle = UInt64(cpuLoadInfo[i].cpu_ticks.2)
                
                totalTicks += user + system + idle
                idleTicks += idle
            }
            
            if previousTotalTicks > 0 {
                let totalDiff = totalTicks - previousTotalTicks
                let idleDiff = idleTicks - previousIdleTicks
                
                if totalDiff > 0 {
                    let usage = 100.0 * (1.0 - Double(idleDiff) / Double(totalDiff))
                    withAnimation(.easeInOut(duration: 1)) {
                        cpuUsage.append(usage)
                        if cpuUsage.count > 20 {
                            cpuUsage.removeFirst()
                        }
                    }
                }
            }
            
            previousTotalTicks = totalTicks
            previousIdleTicks = idleTicks
            
            // Free the CPU info
            vm_deallocate(mach_task_self_,
                         vm_address_t(bitPattern: cpuInfo),
                         vm_size_t(UInt(numCpuInfo) * UInt(MemoryLayout<Int32>.stride)))
        }
    }

    private func updateMemoryInfo() {
        let mem = getMemoryInfo()
        freeMemory = mem.free / (1024 * 1024)
        totalMemory = mem.total / (1024 * 1024)
    }

    private func updateDiskInfo() {
        let disk = getDiskSpace()
        totalDiskSpace = disk.total
        freeDiskSpace = disk.free
        usedDiskSpace = disk.used
    }
}

// MARK: - Helpers

import Darwin

func getMemoryInfo() -> (free: Double, total: Double) {
    var stats = vm_statistics64()
    var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
    let hostPort: mach_port_t = mach_host_self()
    let result = withUnsafeMutablePointer(to: &stats) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
            host_statistics64(hostPort, HOST_VM_INFO64, $0, &count)
        }
    }
    let pageSize = Double(vm_kernel_page_size)
    if result == KERN_SUCCESS {
        let free = Double(stats.free_count + stats.inactive_count) * pageSize
        let total = Double(ProcessInfo.processInfo.physicalMemory)
        return (free, total)
    } else {
        return (0, Double(ProcessInfo.processInfo.physicalMemory))
    }
}

func getDiskSpace() -> (total: Double, free: Double, used: Double) {
    let fileManager = FileManager.default
    let homeURL = fileManager.homeDirectoryForCurrentUser
    
    do {
        let resourceValues = try homeURL.resourceValues(forKeys: [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey
        ])
        
        if let total = resourceValues.volumeTotalCapacity,
           let free = resourceValues.volumeAvailableCapacityForImportantUsage {
            let totalGB = Double(total) / (1024 * 1024 * 1024)
            let freeGB = Double(free) / (1024 * 1024 * 1024)
            let usedGB = totalGB - freeGB
            return (totalGB, freeGB, usedGB)
        }
    } catch {
        print("Error getting disk space: \(error.localizedDescription)")
    }
    
    return (0, 0, 0)
}
