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

            VStack(spacing: 9) {
                liveCurveCard(isEN: isEN)
                reductionAndProfileCard(isEN: isEN)
            }
            .padding(.horizontal, 14)
            .padding(.top, 2)
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
        .padding(.bottom, 8)
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

    // MARK: - Card 1: Live Curve Monitor Card

    private func liveCurveCard(isEN: Bool) -> some View {
        let maxWhite = 100 - Int((dm.reduction * 30).rounded())
        let activeMax = dm.isEnabled ? maxWhite : 100

        return VStack(spacing: 6) {
            HStack {
                Label(LocalizedStrings.liveCurveTitle(isEN: isEN), systemImage: "waveform.path.ecg")
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundStyle(Color.secondary)

                Spacer()

                if dm.isEnabled {
                    Text(String(format: "t = %.1f", dm.curveExponent))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.orange)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.orange.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            ZStack(alignment: .bottomTrailing) {
                CurveGraphView(
                    isEnabled: dm.isEnabled,
                    reduction: dm.reduction,
                    curveExponent: dm.curveExponent
                )
                .frame(height: 110)
                .background(Color.black.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
                )

                // 100% output reference label (top left)
                Text("100%")
                    .font(.system(size: 7.5, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary.opacity(0.5))
                    .padding(.leading, 6)
                    .padding(.top, 4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                // Max reduced output percentage label (top right)
                Text("\(activeMax)%")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(dm.isEnabled ? Color.orange.opacity(0.9) : Color.secondary.opacity(0.5))
                    .padding(.trailing, 6)
                    .padding(.top, 4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

                // Black level indicator label (bottom left)
                Text("0%")
                    .font(.system(size: 7.5, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary.opacity(0.5))
                    .padding(.leading, 6)
                    .padding(.bottom, 4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)

                // 100% input reference label (bottom right)
                Text("100%")
                    .font(.system(size: 7.5, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary.opacity(0.5))
                    .padding(.trailing, 6)
                    .padding(.bottom, 4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
        }
        .padding(11)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
    }

    // MARK: - Card 2: Reduction & Curve Profile Card

    private func reductionAndProfileCard(isEN: Bool) -> some View {
        VStack(spacing: 10) {
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

            // Slider & Percentage Header
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

            // Curve Profile 3-Way Segmented Buttons
            HStack(spacing: 4) {
                let segments: [(Double, String, String)] = [
                    (2.5, LocalizedStrings.curveGeneral(isEN: isEN), "sun.min"),
                    (4.0, LocalizedStrings.curveDocs(isEN: isEN), "doc.text"),
                    (6.0, LocalizedStrings.curveHighlights(isEN: isEN), "sparkles")
                ]
                ForEach(segments, id: \.0) { value, label, icon in
                    let selected = dm.curveExponent == value
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            exponentBinding.wrappedValue = value
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: icon)
                                .font(.system(size: 9.5))
                            Text(label)
                                .font(.system(size: 10.5, weight: selected ? .semibold : .regular))
                        }
                        .foregroundStyle(selected ? (dm.isEnabled ? Color.orange : Color.primary) : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(selected ? Color.orange.opacity(0.12) : Color.primary.opacity(0.03))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(selected ? Color.orange.opacity(0.25) : Color.clear, lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!dm.isEnabled)
                }
            }
        }
        .padding(11)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
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
            .padding(.vertical, 9)
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
}
