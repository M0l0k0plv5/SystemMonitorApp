import SwiftUI
import Darwin

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
    
    // CPU usage tracking
    @State private var previousTotalTicks: UInt64 = 0
    @State private var previousIdleTicks: UInt64 = 0

    private let timer = Timer.publish(every: 4.0, on: .main, in: .common).autoconnect() // 4 seconds

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
                    Text("System Info")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .padding(.top)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("CPU Info").font(.headline)
                        Text("Cores: \(cpuCores)")
                        Text("Architecture: \(cpuArchitecture)")
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Memory Info").font(.headline)
                        Text("Free Memory: \(Int(ceil(freeMemory / 1024))) GB")
                        Text("Total Memory: \(Int(ceil(totalMemory / 1024))) GB")
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Disk Info").font(.headline)
                        Text("Total Disk Space: \(totalDiskSpace, specifier: "%.2f") GB")
                        Text("Used Disk Space: \(usedDiskSpace, specifier: "%.2f") GB")
                        Text("Free Disk Space: \(freeDiskSpace, specifier: "%.2f") GB")
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 10) {
                        Text("System Info").font(.headline)
                        Text("Model: \(systemModel)")
                        Text("OS: \(osName)")
                        Text("Boot Time: \(bootTime)")
                        Text("Uptime: \(formattedUptime)")
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
                    }
                    ActiveProcessesView()
                    Spacer()
                }
                .font(.system(.body, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            }

            // Settings Button (bottom right)
            Button(action: { showSettings = true }) {
                Label("Settings", systemImage: "gearshape")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 20)
                    .background(
                        Capsule()
                            .fill(Color.secondary.opacity(0.15))
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.trailing, 24)
            .padding(.bottom, 24)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
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
    if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: "/"),
       let total = attrs[.systemSize] as? NSNumber,
       let free = attrs[.systemFreeSize] as? NSNumber {
        let totalGB = total.doubleValue / (1024 * 1024 * 1024)
        let freeGB = free.doubleValue / (1024 * 1024 * 1024)
        let usedGB = totalGB - freeGB
        return (totalGB, freeGB, usedGB)
    }
    return (0, 0, 0)
}
