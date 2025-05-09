import SwiftUI

struct LineChartView: View {
    let cpuUsage: [Double]

    var body: some View {
        GeometryReader { geometry in
            let maxY = 100.0
            let minY = 0.0
            let rangeY = maxY - minY
            let stepX = geometry.size.width / CGFloat(max(cpuUsage.count - 1, 1))
            let stepY = geometry.size.height / CGFloat(rangeY)

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
            .stroke(Color.blue, lineWidth: 2)
        }
    }
}
