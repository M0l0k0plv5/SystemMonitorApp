import SwiftUI

struct LineChartView: View {
    let cpuUsage: [Double]
    @AppStorage("showGraphGrid") private var showGraphGrid: Bool = true
    @AppStorage("graphHeight") private var graphHeight: Double = 200

    var body: some View {
        GeometryReader { geometry in
            let maxY = 100.0
            let minY = 0.0
            let rangeY = maxY - minY
            let stepX = geometry.size.width / CGFloat(max(cpuUsage.count - 1, 1))
            let stepY = geometry.size.height / CGFloat(rangeY)

            ZStack {
                // Background grid
                if showGraphGrid {
                    VStack(spacing: geometry.size.height / 4) {
                        ForEach(0..<4) { _ in
                            Divider()
                                .background(Color.secondary.opacity(0.2))
                        }
                    }
                }
                
                // Gradient fill
                Path { path in
                    guard cpuUsage.count > 1 else { return }
                    let startY = geometry.size.height - ((CGFloat(cpuUsage.first ?? 0.0) - CGFloat(minY)) * stepY)
                    path.move(to: CGPoint(x: 0, y: geometry.size.height))
                    path.addLine(to: CGPoint(x: 0, y: startY))
                    
                    for index in 1..<cpuUsage.count {
                        let x = CGFloat(index) * stepX
                        let y = geometry.size.height - ((CGFloat(cpuUsage[index]) - CGFloat(minY)) * stepY)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    
                    let lastX = CGFloat(cpuUsage.count - 1) * stepX
                    path.addLine(to: CGPoint(x: lastX, y: geometry.size.height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.3),
                            Color.blue.opacity(0.1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Line
                Path { path in
                    guard cpuUsage.count > 1 else { return }
                    let startY = geometry.size.height - ((CGFloat(cpuUsage.first ?? 0.0) - CGFloat(minY)) * stepY)
                    path.move(to: CGPoint(x: 0, y: startY))
                    
                    for index in 1..<cpuUsage.count {
                        let x = CGFloat(index) * stepX
                        let y = geometry.size.height - ((CGFloat(cpuUsage[index]) - CGFloat(minY)) * stepY)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .blue.opacity(0.7)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .frame(height: graphHeight)
    }
}
