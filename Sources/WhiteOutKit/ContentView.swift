import SwiftUI

public struct ContentView: View {
    @EnvironmentObject var dm: DisplayManager
    @EnvironmentObject var updater: UpdateChecker
    @State private var showDetails = false

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
                if dm.isEnabled { dm.applyReduction() }
            }
        )
    }

    private var exponentBinding: Binding<Double> {
        Binding(
            get: { dm.curveExponent },
            set: { newVal in
                dm.curveExponent = newVal
                if dm.isEnabled { dm.applyReduction() }
            }
        )
    }

    // MARK: - Body

    public var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                headerSection
                Divider().opacity(0.5)
                controlSection
                Divider().opacity(0.5)
                shortcutSection
                Divider().opacity(0.5)
                launchAtLoginSection
                Divider().opacity(0.5)
                curveSection
                Divider().opacity(0.5)
                timeSection
                Divider().opacity(0.5)
                footerSection
            }
            .frame(width: 290)

            if showDetails {
                Divider().opacity(0.5)
                DetailsSectionView(dm: dm, showDetails: $showDetails)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .frame(width: showDetails ? 590 : 290)
        .background(.ultraThinMaterial)
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: showDetails)
        .animation(.easeInOut(duration: 0.2), value: dm.isShortcutEnabled)
        .alert(LocalizedStrings.updateNetworkErrorTitle(isEN: dm.language == "en"), isPresented: $updater.showNetworkErrorAlert) {
            Button(dm.language == "en" ? "OK" : "확인", role: .cancel) {}
        } message: {
            Text(LocalizedStrings.updateNetworkErrorMsg(isEN: dm.language == "en"))
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        dm.isEnabled
                        ? LinearGradient(colors: [.orange.opacity(0.25), .yellow.opacity(0.12)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color.primary.opacity(0.08), Color.primary.opacity(0.04)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 38, height: 38)
                Image(systemName: dm.isEnabled ? "sun.min.fill" : "sun.min")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(dm.isEnabled ? Color.orange : Color.secondary)
            }

            // Title + status
            let isEN = dm.language == "en"
            VStack(alignment: .leading, spacing: 1) {
                Text(isEN ? "White" : "화이트")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.primary)
                if dm.isEnabled {
                    Text(isEN ? "out" : "아웃")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(statusColor(isEnabled: dm.isEnabled, reduction: dm.reduction))
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity
                        ))
                }
            }
            .frame(minHeight: 36, alignment: .leading)

            Spacer()

            // Info Button
            Button {
                withAnimation {
                    showDetails.toggle()
                }
            } label: {
                Image(systemName: showDetails ? "info.circle.fill" : "info.circle")
                    .font(.system(size: 15))
                    .foregroundStyle(showDetails ? Color.orange : Color.secondary)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 2)

            // Toggle
            Toggle("", isOn: enabledBinding)
                .toggleStyle(.switch)
                .labelsHidden()
                .tint(.orange)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Controls

    private var controlSection: some View {
        let isEN = dm.language == "en"
        return VStack(spacing: 12) {
            // App Rule Active Banner
            if let activeAppName = dm.activeRuleAppName {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.shield.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                    Text(LocalizedStrings.ruleActiveBanner(isEN: isEN, appName: activeAppName))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.orange)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.08))
                .cornerRadius(6)
                .transition(.move(edge: .top).combined(with: .opacity))
            } else if let activeTimeId = dm.activeTimeRuleId,
                      let rule = dm.timeRules.first(where: { $0.id == activeTimeId }) {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                    let startStr = String(format: "%02d:%02d", rule.startHour, rule.startMinute)
                    let endStr = String(format: "%02d:%02d", rule.endHour, rule.endMinute)
                    Text(LocalizedStrings.timeRuleActiveBanner(isEN: isEN, range: "\(startStr) ~ \(endStr)"))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.orange)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.08))
                .cornerRadius(6)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Display Picker
            HStack {
                Text(LocalizedStrings.displayLabel(isEN: isEN))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(dm.isEnabled ? Color.primary : Color.secondary)
                Spacer()
                Picker("", selection: $dm.selectedDisplayID) {
                    Text(LocalizedStrings.allDisplays(isEN: isEN))
                        .tag("all")
                    ForEach(Array(dm.displaySettings.values.sorted(by: { $0.name < $1.name }))) { setting in
                        Text(setting.name)
                            .tag(String(setting.displayID))
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .scaleEffect(0.9)
                .frame(maxHeight: 24)
            }
            .padding(.bottom, 2)

            // Label row
            HStack {
                Text(LocalizedStrings.reductionLabel(isEN: isEN))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(dm.isEnabled ? Color.primary : Color.secondary)
                Spacer()
                Text("\(Int((dm.reduction * 30).rounded()))%")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(dm.isEnabled ? Color.orange : Color.secondary)
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: 0.15), value: dm.reduction)
            }

            // Slider
            Slider(value: reductionBinding, in: 0...1, step: 1.0/6.0)
                .tint(.orange)
                .disabled(!dm.isEnabled)

            // White point visualizer bar
            whitepointBar

            // Info labels
            HStack {
                Label(LocalizedStrings.preserveBlacks(isEN: isEN), systemImage: "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.green)
                Spacer()
                Text(LocalizedStrings.maxWhiteLevel(isEN: isEN, percent: 100 - Int((dm.reduction * 30).rounded())))
                    .font(.system(size: 10))
                    .foregroundStyle(statusColor(isEnabled: dm.isEnabled, reduction: dm.reduction))
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: 0.15), value: dm.reduction)
            }
        }
        .padding(16)
    }

    // MARK: - Curve Preset Section

    private var curveSection: some View {
        let isEN = dm.language == "en"
        return VStack(spacing: 10) {
            HStack {
                Text(LocalizedStrings.curveTypeLabel(isEN: isEN))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(dm.isEnabled ? Color.primary : Color.secondary)
                Spacer()
                if dm.isEnabled {
                    Text(String(format: "T = %.1f", dm.curveExponent))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.orange)
                }
            }

            // 3-way segmented toggle
            HStack(spacing: 6) {
                let segments = [
                    (2.5, LocalizedStrings.curveGeneral(isEN: isEN)),
                    (4.0, LocalizedStrings.curveDocs(isEN: isEN)),
                    (6.0, LocalizedStrings.curveHighlights(isEN: isEN))
                ]
                ForEach(segments, id: \.0) { value, label in
                    let selected = dm.curveExponent == value
                    Button {
                        exponentBinding.wrappedValue = value
                    } label: {
                        Text(label)
                            .font(.system(size: 11, weight: selected ? .semibold : .regular))
                            .foregroundStyle(selected ? Color.black : (dm.isEnabled ? Color.primary : Color.secondary))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selected ? Color.orange : Color.primary.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(!dm.isEnabled)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Shortcut Section

    private var shortcutSection: some View {
        let isEN = dm.language == "en"
        return VStack(spacing: 8) {
            HStack {
                Text(LocalizedStrings.shortcutToggle(isEN: isEN))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(dm.isEnabled ? Color.primary : Color.secondary)
                Spacer()
                Toggle("", isOn: $dm.isShortcutEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .tint(.orange)
            }

            if dm.isShortcutEnabled {
                HStack {
                    Text(LocalizedStrings.shortcutRecord(isEN: isEN))
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary)
                    Spacer()
                    ShortcutRecorderView(shortcut: $dm.shortcut)
                        .frame(width: 120, height: 22)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Launch at Login Section

    private var launchAtLoginSection: some View {
        let isEN = dm.language == "en"
        return HStack {
            Text(LocalizedStrings.launchAtLogin(isEN: isEN))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.primary)
            Spacer()
            Toggle("", isOn: $dm.launchAtLogin)
                .toggleStyle(.switch)
                .labelsHidden()
                .tint(.orange)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - White Point Bar

    /// Canvas-based visualization of the gamma reduction.
    /// Left anchor = black (always 0), right = max white output (reduced).
    /// The clipped region (beyond new white point) is shown dimmed.
    private var whitepointBar: some View {
        let whitePointRatio = CGFloat(1.0 - dm.reduction * 0.3)
        let active = dm.isEnabled && dm.reduction > 0.01

        return Canvas { ctx, size in
            // --- Base gradient: black → white ---
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

                // Dimmed overlay for the clipped region
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

                // Orange marker line at the new white point
                let markerRect = CGRect(x: cutX - 1, y: 0, width: 2, height: size.height)
                ctx.fill(Path(markerRect), with: .color(.orange))

                // Small triangle / tick below the marker
                var tick = Path()
                tick.move(to: CGPoint(x: cutX - 4, y: size.height))
                tick.addLine(to: CGPoint(x: cutX + 4, y: size.height))
                tick.addLine(to: CGPoint(x: cutX, y: size.height - 5))
                tick.closeSubpath()
                ctx.fill(tick, with: .color(.orange))
            }
        }
        .frame(height: 22)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5)
        )
        .animation(.easeInOut(duration: 0.2), value: dm.reduction)
    }

    // MARK: - Update Banner

    @ViewBuilder
    private var updateBanner: some View {
        let isEN = dm.language == "en"
        if updater.updateAvailable {
            if updater.isDownloading {
                // 다운로드 진행 중
                VStack(spacing: 8) {
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
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.orange.opacity(0.06))

            } else {
                // 업데이트 가능 — 클릭 시 자동 업데이트
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
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(Color.orange.opacity(0.08))
            }
        }
    }


    // MARK: - Time Rules Section

    private var timeSection: some View {
        let isEN = dm.language == "en"
        return VStack(spacing: 6) {
            HStack {
                Text(LocalizedStrings.timeRulesSectionTitle(isEN: isEN))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(dm.isEnabled ? Color.primary : Color.secondary)
                Spacer()
                Button {
                    withAnimation {
                        dm.addTimeRule()
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(dm.isEnabled ? Color.orange : Color.secondary)
                }
                .buttonStyle(.plain)
                .disabled(!dm.isEnabled)
            }

            if dm.timeRules.isEmpty {
                Text(isEN ? "No time rules configured." : "설정된 시간별 규칙이 없습니다.")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                VStack(spacing: 4) {
                    ForEach(Array(dm.timeRules.enumerated()), id: \.element.id) { index, rule in
                        timeRuleRow(index: index, rule: rule, isEN: isEN)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func timeRuleRow(index: Int, rule: TimeRule, isEN: Bool) -> some View {
        let isActive = dm.activeTimeRuleId == rule.id
        
        return HStack(spacing: 4) {
            // Active Indicator or Toggle
            Toggle("", isOn: Binding(
                get: { rule.isEnabled },
                set: { newVal in
                    dm.timeRules[index].isEnabled = newVal
                }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
            .scaleEffect(0.65)
            .frame(width: 28)
            .disabled(!dm.isEnabled)

            // Start Date Picker (default compact style on macOS)
            DatePicker("", selection: Binding(
                get: { rule.startDate },
                set: { newVal in
                    dm.timeRules[index].startDate = newVal
                }
            ), displayedComponents: .hourAndMinute)
            .labelsHidden()
            .scaleEffect(0.85)
            .frame(width: 58)
            .disabled(!dm.isEnabled || !rule.isEnabled)

            Text("~")
                .font(.system(size: 10))
                .foregroundStyle(Color.secondary)

            // End Date Picker
            DatePicker("", selection: Binding(
                get: { rule.endDate },
                set: { newVal in
                    dm.timeRules[index].endDate = newVal
                }
            ), displayedComponents: .hourAndMinute)
            .labelsHidden()
            .scaleEffect(0.85)
            .frame(width: 58)
            .disabled(!dm.isEnabled || !rule.isEnabled)

            Spacer(minLength: 0)

            // Percentage Picker
            Picker("", selection: Binding(
                get: { rule.reduction },
                set: { newVal in
                    dm.timeRules[index].reduction = newVal
                }
            )) {
                ForEach(0...6, id: \.self) { i in
                    let pct = i * 5
                    let val = Double(i) / 6.0
                    Text("\(pct)%").tag(val)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .scaleEffect(0.8)
            .frame(width: 48)
            .disabled(!dm.isEnabled || !rule.isEnabled)

            // Trash delete button
            Button {
                withAnimation {
                    dm.deleteTimeRule(at: index)
                }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 10))
                    .foregroundStyle(dm.isEnabled ? Color.red.opacity(0.8) : Color.secondary)
            }
            .buttonStyle(.plain)
            .disabled(!dm.isEnabled)
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 4)
        .background(isActive ? Color.orange.opacity(0.06) : Color.clear)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isActive ? Color.orange.opacity(0.2) : Color.clear, lineWidth: 0.5)
        )
    }

    // MARK: - Footer

    private var footerSection: some View {
        let isEN = dm.language == "en"
        return VStack(spacing: 0) {
            updateBanner

            HStack {
                // KR / EN Language Switch Button
                Button {
                    withAnimation {
                        dm.language = (dm.language == "ko") ? "en" : "ko"
                    }
                } label: {
                    HStack(spacing: 2) {
                        Text("KR")
                            .foregroundStyle(dm.language == "ko" ? Color.orange : Color.secondary.opacity(0.5))
                        Text("/")
                            .foregroundStyle(Color.secondary.opacity(0.3))
                        Text("EN")
                            .foregroundStyle(dm.language == "en" ? Color.orange : Color.secondary.opacity(0.5))
                    }
                    .font(.system(size: 10, weight: .bold))
                }
                .buttonStyle(.plain)

                Spacer()

                // 버전 텍스트 — 클릭하면 수동 업데이트 확인
                Button {
                    updater.manualCheck()
                } label: {
                    HStack(spacing: 4) {
                        Text("v\(UpdateChecker.currentVersion)")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.secondary.opacity(0.5))
                        if updater.isChecking {
                            ProgressView()
                                .scaleEffect(0.45)
                                .frame(width: 10, height: 10)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 9))
                                .foregroundStyle(Color.secondary.opacity(0.35))
                        }
                    }
                }
                .buttonStyle(.plain)
                .help(LocalizedStrings.manualCheckHelp(isEN: isEN))

                Spacer()

                Button {
                    dm.quit()
                } label: {
                    Text(LocalizedStrings.quitLabel(isEN: isEN))
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.secondary)
                .keyboardShortcut("q")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
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

