import SwiftUI

struct VisualEffectBlur: View {
    var body: some View {
        BlurEffect()
            .ignoresSafeArea()
    }
}

struct BlurEffect: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let blurView = NSVisualEffectView()
        blurView.blendingMode = .behindWindow
        blurView.material = .hudWindow
        blurView.state = .active
        return blurView
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
