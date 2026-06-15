import SwiftUI

@main
struct ReduceWhitePointApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var displayManager = DisplayManager()
    @StateObject private var updateChecker  = UpdateChecker()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(displayManager)
                .environmentObject(updateChecker)
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)
        .onChange(of: updateChecker.updateAvailable) { _ in }  // trigger redraw if needed
    }

    private var menuBarLabel: some View {
        HStack(spacing: 3) {
            Image(systemName: displayManager.isEnabled ? "sun.min.fill" : "sun.min")
            if displayManager.isEnabled && displayManager.reduction > 0.01 {
                Text("\(Int((displayManager.reduction * 30).rounded()))%")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
            }
        }
        .task {
            // 앱 시작 시 업데이트 확인 + 120시간 주기 타이머 시작
            updateChecker.startPeriodicChecks()
        }
    }
}

