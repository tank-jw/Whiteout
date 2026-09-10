import SwiftUI

public struct ContentView: View {
    @EnvironmentObject var dm: DisplayManager
    @EnvironmentObject var updater: UpdateChecker
    @State private var showingPreferences = false

    public init() {}

    // MARK: - Bindings

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { dm.isEnabled },
            set: { dm.setEnabled($0) }
        )
    }

    private var reductionBinding: Binding<Double> {
        Binding(
            get: { dm.reduction },
            set: { newVal in
                dm.reduction = newVal
            }
        )
    }

    private var exponentBinding: Binding<Double> {
        Binding(
            get: { dm.curveExponent },
            set: { newVal in
                dm.curveExponent = newVal
            }
        )
    }

    // MARK: - Body

    public var body: some View {
        ZStack {
            if showingPreferences {
                DetailsSectionView(dm: dm, showDetails: $showingPreferences)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            } else {
                mainControlsView
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
        .frame(width: 310)
        .background(.ultraThinMaterial)
        .animation(.spring(response: 0.35, dampingFraction: 0.84), value: showingPreferences)
        .alert(LocalizedStrings.updateNetworkErrorTitle(isEN: dm.language == "en"), isPresented: $updater.showNetworkErrorAlert) {
            Button(dm.language == "en" ? "OK" : "확인", role: .cancel) {}
        } message: {
            Text(LocalizedStrings.updateNetworkErrorMsg(isEN: dm.language == "en"))
        }
    }

    // MARK: - Main Controls View

    private var mainControlsView: some View {
        let isEN = dm.language == "en"
        return VStack(spacing: 0) {
            headerSection(isEN: isEN)

            activeRuleBanner(isEN: isEN)

            VStack(spacing: 10) {
                reductionCard(isEN: isEN)
                curveProfileCard(isEN: isEN)
            }
            .padding(.horizontal, 14)
            .padding(.top, 4)
            .padding(.bottom, 6)

            Divider().opacity(0.4)

            footerSection(isEN: isEN)
        }
    }

    // MARK: - Header

    private func headerSection(isEN: Bool) -> some View {
        HStack(spacing: 10) {
            // Squircle Sun Icon
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(
                        dm.isEnabled
                        ? LinearGradient(colors: [Color.orange, Color.orange.opacity(0.85)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color.primary.opacity(0.12), Color.primary.opacity(0.06)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 32, height: 32)
                    .shadow(color: dm.isEnabled ? Color.orange.opacity(0.25) : Color.clear, radius: 4, y: 1.5)

                Image(systemName: dm.isEnabled ? "sun.max.fill" : "sun.min")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(dm.isEnabled ? Color.white : Color.secondary)
            }

            // Title + Status
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("WhiteOut")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.primary)

                    if dm.isEnabled {
                        Text("\(Int((dm.reduction * 30).rounded()))%")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.orange)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.orange.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                Text(dm.isEnabled ? LocalizedStrings.activeStatus(isEN: isEN) : LocalizedStrings.inactiveStatus(isEN: isEN))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(dm.isEnabled ? Color.orange.opacity(0.9) : Color.secondary)
            }

            Spacer()

            // Settings Gear Button
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.84)) {
                    showingPreferences = true
                }
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.secondary)
                    .padding(6)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help(LocalizedStrings.settingsGear(isEN: isEN))

            // Master Toggle
            Toggle("", isOn: enabledBinding)
                .toggleStyle(.switch)
                .labelsHidden()
                .tint(.orange)
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    // MARK: - Active Rule Banner

    @ViewBuilder
    private func activeRuleBanner(isEN: Bool) -> some View {
        if let activeAppName = dm.activeRuleAppName {
            HStack(spacing: 6) {
                Image(systemName: "bolt.shield.fill")
                    .font(.system(size: 10))
                Text(LocalizedStrings.ruleActiveBanner(isEN: isEN, appName: activeAppName))
                    .font(.system(size: 11, weight: .semibold))
                Spacer()
            }
            .foregroundStyle(Color.orange)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.orange.opacity(0.09))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .padding(.horizontal, 14)
            .padding(.bottom, 6)
            .transition(.move(edge: .top).combined(with: .opacity))
        } else if let activeTimeId = dm.activeTimeRuleId,
                  let rule = dm.timeRules.first(where: { $0.id == activeTimeId }) {
            let startStr = String(format: "%02d:%02d", rule.startHour, rule.startMinute)
            let endStr = String(format: "%02d:%02d", rule.endHour, rule.endMinute)
            HStack(spacing: 6) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 10))
                Text(LocalizedStrings.timeRuleActiveBanner(isEN: isEN, range: "\(startStr) ~ \(endStr)"))
                    .font(.system(size: 11, weight: .semibold))
                Spacer()
            }
            .foregroundStyle(Color.orange)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.orange.opacity(0.09))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .padding(.horizontal, 14)
            .padding(.bottom, 6)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: - Card 1: Reduction & Display

    private func reductionCard(isEN: Bool) -> some View {
        VStack(spacing: 11) {
            // Display Picker Row (only if multi-monitor)
            if dm.activeDisplaySettings.count > 1 {
                HStack {
                    Label(LocalizedStrings.displayLabel(isEN: isEN), systemImage: "display")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(dm.isEnabled ? Color.primary : Color.secondary)
                    Spacer()
                    Picker("", selection: $dm.selectedDisplayID) {
                        Text(LocalizedStrings.allDisplays(isEN: isEN)).tag("all")
                        ForEach(dm.activeDisplaySettings) { setting in
                            Text(setting.name).tag(String(setting.displayID))
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .scaleEffect(0.9)
                }
                Divider().opacity(0.3)
            }

            // Percentage Header
            HStack {
                Text(LocalizedStrings.reductionLabel(isEN: isEN))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(dm.isEnabled ? Color.primary : Color.secondary)
                Spacer()
                Text("\(Int((dm.reduction * 30).rounded()))%")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(dm.isEnabled ? Color.orange : Color.secondary)
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: 0.15), value: dm.reduction)
            }

            // Slider
            Slider(value: reductionBinding, in: 0...1, step: 1.0/6.0)
                .tint(.orange)
                .disabled(!dm.isEnabled)

            // Visualizer Bar
            whitepointBar

            // Subtitle info
            HStack {
                Text(LocalizedStrings.preserveBlacks(isEN: isEN))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.secondary)
                Spacer()
                Text(LocalizedStrings.maxWhiteLevel(isEN: isEN, percent: 100 - Int((dm.reduction * 30).rounded())))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(statusColor(isEnabled: dm.isEnabled, reduction: dm.reduction))
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: 0.15), value: dm.reduction)
            }
        }
        .padding(13)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
    }

    // MARK: - Card 2: Curve Profile

    private func curveProfileCard(isEN: Bool) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(LocalizedStrings.curveTypeLabel(isEN: isEN))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(dm.isEnabled ? Color.primary : Color.secondary)

            // 3-way Segmented Button Row
            HStack(spacing: 5) {
                let segments: [(Double, String, String)] = [
                    (2.5, LocalizedStrings.curveGeneral(isEN: isEN), "sun.min"),
                    (4.0, LocalizedStrings.curveDocs(isEN: isEN), "doc.text"),
                    (6.0, LocalizedStrings.curveHighlights(isEN: isEN), "sparkles")
                ]
                ForEach(segments, id: \.0) { value, label, icon in
                    let selected = dm.curveExponent == value
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            exponentBinding.wrappedValue = value
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: icon)
                                .font(.system(size: 10))
                            Text(label)
                                .font(.system(size: 11, weight: selected ? .semibold : .regular))
                        }
                        .foregroundStyle(selected ? (dm.isEnabled ? Color.orange : Color.primary) : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(selected ? Color.orange.opacity(0.12) : Color.primary.opacity(0.03))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .strokeBorder(selected ? Color.orange.opacity(0.25) : Color.clear, lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!dm.isEnabled)
                }
            }
        }
        .padding(13)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
    }

    // MARK: - White Point Bar

    private var whitepointBar: some View {
        let whitePointRatio = CGFloat(1.0 - dm.reduction * 0.3)
        let active = dm.isEnabled && dm.reduction > 0.01

        return Canvas { ctx, size in
            let baseGrad = Gradient(stops: [
                .init(color: .black, location: 0),
                .init(color: .white, location: 1)
            ])
            ctx.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(baseGrad,
                                      startPoint: .zero,
                                      endPoint: CGPoint(x: size.width, y: 0))
            )

            if active {
                let cutX = size.width * whitePointRatio
                let dimmingGrad = Gradient(stops: [
                    .init(color: Color.gray.opacity(0.0), location: 0),
                    .init(color: Color.gray.opacity(0.72), location: 1)
                ])
                let clippedRect = CGRect(x: cutX, y: 0,
                                         width: size.width - cutX, height: size.height)
                ctx.fill(
                    Path(clippedRect),
                    with: .linearGradient(dimmingGrad,
                                          startPoint: CGPoint(x: cutX, y: 0),
                                          endPoint: CGPoint(x: size.width, y: 0))
                )

                let markerRect = CGRect(x: cutX - 1, y: 0, width: 2, height: size.height)
                ctx.fill(Path(markerRect), with: .color(.orange))

                var tick = Path()
                tick.move(to: CGPoint(x: cutX - 4, y: size.height))
                tick.addLine(to: CGPoint(x: cutX + 4, y: size.height))
                tick.addLine(to: CGPoint(x: cutX, y: size.height - 5))
                tick.closeSubpath()
                ctx.fill(tick, with: .color(.orange))
            }
        }
        .frame(height: 20)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5)
        )
        .animation(.easeInOut(duration: 0.2), value: dm.reduction)
    }

    // MARK: - Footer

    private func footerSection(isEN: Bool) -> some View {
        VStack(spacing: 0) {
            updateBanner(isEN: isEN)

            HStack {
                // KR / EN Language Switch Button
                Button {
                    withAnimation {
                        dm.language = (dm.language == "ko") ? "en" : "ko"
                    }
                } label: {
                    Text(dm.language == "ko" ? "🇰🇷 한국어" : "🇺🇸 English")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.secondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.primary.opacity(0.04))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Spacer()

                // Version text (Click to check updates)
                Button {
                    updater.manualCheck()
                } label: {
                    HStack(spacing: 4) {
                        Text("v\(UpdateChecker.currentVersion)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Color.secondary.opacity(0.7))
                        if updater.isChecking {
                            ProgressView()
                                .scaleEffect(0.4)
                                .frame(width: 10, height: 10)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 8))
                                .foregroundStyle(Color.secondary.opacity(0.5))
                        }
                    }
                }
                .buttonStyle(.plain)
                .help(LocalizedStrings.manualCheckHelp(isEN: isEN))

                Spacer()

                // Quit button
                Button {
                    dm.quit()
                } label: {
                    Text(LocalizedStrings.quitLabel(isEN: isEN))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.secondary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("q")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Update Banner

    @ViewBuilder
    private func updateBanner(isEN: Bool) -> some View {
        if updater.updateAvailable {
            if updater.isDownloading {
                VStack(spacing: 6) {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundStyle(.orange)
                        Text(LocalizedStrings.updateDownloading(isEN: isEN, ver: updater.latestVersion))
                            .font(.system(size: 11, weight: .semibold))
                        Spacer()
                        Text("\(Int(updater.downloadProgress * 100))%")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: updater.downloadProgress)
                        .tint(.orange)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.06))
            } else {
                Button {
                    updater.performUpdate()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(LocalizedStrings.updateAvailable(isEN: isEN, ver: updater.latestVersion))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.primary)
                            Text(LocalizedStrings.updateClickToUpdate(isEN: isEN))
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(Color.orange.opacity(0.08))
            }
        }
    }

    private func statusColor(isEnabled: Bool, reduction: Double) -> Color {
        guard isEnabled else { return Color.secondary }
        let startColor = NSColor.textColor
        let endColor = NSColor.orange

        guard let startRGB = startColor.usingColorSpace(.sRGB),
              let endRGB = endColor.usingColorSpace(.sRGB) else {
            return Color.orange
        }

        let t = CGFloat(reduction)
        let r = startRGB.redComponent   + t * (endRGB.redComponent   - startRGB.redComponent)
        let g = startRGB.greenComponent + t * (endRGB.greenComponent - startRGB.greenComponent)
        let b = startRGB.blueComponent  + t * (endRGB.blueComponent  - startRGB.blueComponent)

        return Color(NSColor(red: r, green: g, blue: b, alpha: 1.0))
    }
}
