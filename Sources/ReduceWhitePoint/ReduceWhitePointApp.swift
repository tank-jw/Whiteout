import SwiftUI

@main
struct ReduceWhitePointApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var displayManager = DisplayManager()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(displayManager)
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)
    }

    private var menuBarLabel: some View {
        HStack(spacing: 3) {
            Image(systemName: displayManager.isEnabled ? "sun.min.fill" : "sun.min")
            if displayManager.isEnabled && displayManager.reduction > 0.01 {
                Text("\(Int((displayManager.reduction * 30).rounded()))%")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
            }
        }
    }
}
