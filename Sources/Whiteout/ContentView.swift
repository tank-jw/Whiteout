import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dm: DisplayManager
    @EnvironmentObject var updater: UpdateChecker
    @State private var showDetails = false

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

    var body: some View {
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
                footerSection
            }
            .frame(width: 290)

            if showDetails {
                Divider().opacity(0.5)
                detailsSection
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

    // MARK: - Details Panel

    private var detailsSection: some View {
        let isEN = dm.language == "en"
        return ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // Header
                HStack {
                    Text(LocalizedStrings.detailsSectionTitle(isEN: isEN))
                        .font(.system(size: 13, weight: .bold))
                    Spacer()
                    Button {
                        withAnimation {
                            showDetails = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 2)

                // Live Curve Graph
                VStack(alignment: .leading, spacing: 6) {
                    Text(LocalizedStrings.detailsTitle(isEN: isEN))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)

                    ZStack(alignment: .bottomTrailing) {
                        curveGraph
                            .frame(height: 120)
                            .background(Color.black.opacity(0.15))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                            )

                        // Overlay percentage markers
                        // Top-left: 100%
                        Text("100%")
                            .font(.system(size: 7, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.secondary.opacity(0.5))
                            .padding(.leading, 6)
                            .padding(.top, 4)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                        // Bottom-left: 0%
                        Text("0%")
                            .font(.system(size: 7, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.secondary.opacity(0.5))
                            .padding(.leading, 6)
                            .padding(.bottom, 4)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)

                        // Bottom-right: 100%
                        Text("100%")
                            .font(.system(size: 7, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.secondary.opacity(0.5))
                            .padding(.trailing, 6)
                            .padding(.bottom, 4)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    }
                }

                // Dynamic Exponent Explanation
                VStack(alignment: .leading, spacing: 4) {
                    Text(curveTypeTitle)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.orange)
                    Text(curveTypeDescription)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineSpacing(2)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.06))
                .cornerRadius(6)

                // How it works comparison
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStrings.detailsHowItWorks(isEN: isEN))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 6) {
                        bulletPoint(
                            title: LocalizedStrings.compareOurApp(isEN: isEN),
                            desc: LocalizedStrings.compareOurAppDesc(isEN: isEN)
                        )
                        bulletPoint(
                            title: LocalizedStrings.compareOverlay(isEN: isEN),
                            desc: LocalizedStrings.compareOverlayDesc(isEN: isEN)
                        )
                    }
                }

                Divider().opacity(0.5)

                // App-Specific Rules Section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(LocalizedStrings.appRulesSectionTitle(isEN: isEN))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }

                    // Add current app button
                    if let lastAppName = dm.lastActiveAppName {
                        Button {
                            withAnimation {
                                dm.addAppRuleForLastActiveApp()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                if let bundleID = dm.lastActiveAppBundleIdentifier,
                                   let icon = dm.getAppIcon(bundleIdentifier: bundleID) {
                                    Image(nsImage: icon)
                                        .resizable()
                                        .frame(width: 12, height: 12)
                                } else {
                                    Image(systemName: "plus.app.fill")
                                        .font(.system(size: 11))
                                }
                                Text(LocalizedStrings.addRuleBtn(isEN: isEN, appName: lastAppName))
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.orange.opacity(0.08))
                            .cornerRadius(6)
                            .foregroundStyle(.orange)
                        }
                        .buttonStyle(.plain)
                    }

                    // List of registered rules
                    if dm.appRules.isEmpty {
                        Text(isEN ? "No app rules registered." : "등록된 앱 규칙이 없습니다.")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 4)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(dm.appRules) { rule in
                                appRuleRow(rule: rule, isEN: isEN)
                            }
                        }
                    }
                }
            }
            .padding(14)
        }
        .frame(width: 300)
    }

    private func appRuleRow(rule: AppRule, isEN: Bool) -> some View {
        let active = dm.activeRuleAppName == rule.appName
        
        return VStack(spacing: 6) {
            HStack(spacing: 8) {
                if let icon = dm.getAppIcon(bundleIdentifier: rule.bundleIdentifier) {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: "app.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                
                Text(rule.appName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(active ? Color.orange : Color.primary)
                    .lineLimit(1)
                
                if active {
                    Text(isEN ? "Active" : "작동 중")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.orange.opacity(0.12))
                        .cornerRadius(3)
                }
                
                Spacer()
                
                Button {
                    if let idx = dm.appRules.firstIndex(where: { $0.bundleIdentifier == rule.bundleIdentifier }) {
                        withAnimation {
                            dm.deleteAppRule(at: idx)
                        }
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.red.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            
            HStack(spacing: 12) {
                Toggle("", isOn: Binding(
                    get: { rule.isEnabled },
                    set: { newVal in
                        if let idx = dm.appRules.firstIndex(where: { $0.bundleIdentifier == rule.bundleIdentifier }) {
                            dm.appRules[idx].isEnabled = newVal
                            dm.applyReduction()
                        }
                    }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
                .tint(.orange)
                .scaleEffect(0.7)
                .frame(width: 32)
                
                Slider(value: Binding(
                    get: { rule.reduction },
                    set: { newVal in
                        if let idx = dm.appRules.firstIndex(where: { $0.bundleIdentifier == rule.bundleIdentifier }) {
                            dm.appRules[idx].reduction = newVal
                            dm.applyReduction()
                        }
                    }
                ), in: 0...1, step: 1.0/6.0)
                .tint(.orange)
                .disabled(!rule.isEnabled)
                .scaleEffect(0.85)
                
                Picker("", selection: Binding(
                    get: { rule.curveExponent },
                    set: { newVal in
                        if let idx = dm.appRules.firstIndex(where: { $0.bundleIdentifier == rule.bundleIdentifier }) {
                            dm.appRules[idx].curveExponent = newVal
                            dm.applyReduction()
                        }
                    }
                )) {
                    Text("2.5").tag(2.5)
                    Text("4.0").tag(4.0)
                    Text("6.0").tag(6.0)
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .scaleEffect(0.8)
                .frame(width: 44)
                .disabled(!rule.isEnabled)
            }
            .padding(.leading, 24)
        }
        .padding(8)
        .background(active ? Color.orange.opacity(0.04) : Color.primary.opacity(0.02))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(active ? Color.orange.opacity(0.2) : Color.clear, lineWidth: 0.5)
        )
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

    private func bulletPoint(title: String, desc: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Circle()
                    .fill(title.contains("WhiteOut") ? Color.orange : Color.secondary)
                    .frame(width: 3.5, height: 3.5)
                Text(title)
                    .font(.system(size: 9.5, weight: .semibold))
            }
            Text(desc)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
                .padding(.leading, 7)
                .lineSpacing(1.8)
        }
    }

    private var curveTypeTitle: String {
        let isEN = dm.language == "en"
        switch dm.curveExponent {
        case 2.5:
            return isEN ? "General Mode (Exponent = 2.5)" : "일반 모드 (Exponent = 2.5)"
        case 4.0:
            return isEN ? "Docs · PDF Mode (Exponent = 4.0)" : "문서 · PDF 모드 (Exponent = 4.0)"
        case 6.0:
            return isEN ? "Highlight Mode (Exponent = 6.0)" : "하이라이트 모드 (Exponent = 6.0)"
        default:
            return isEN ? "Custom Mode" : "커스텀 모드"
        }
    }

    private var curveTypeDescription: String {
        let isEN = dm.language == "en"
        switch dm.curveExponent {
        case 2.5:
            return isEN 
                ? "Lowers brightness smoothly and naturally. Best standard curve for web browsing and daily tasks."
                : "전반적으로 자연스럽고 부드럽게 밝기를 낮춥니다. 웹서핑 및 데일리 작업에 가장 적합한 표준 곡선입니다."
        case 4.0:
            return isEN 
                ? "Perfectly preserves text (black) sharpness while compressing white backgrounds. Ideal for comfortable reading."
                : "텍스트(검정색)의 또렷함을 완벽히 유지하면서 흰 배경 영역만 집중해서 감쇄합니다. 눈이 편안한 텍스트 리딩에 이상적입니다."
        case 6.0:
            return isEN 
                ? "Maximum preservation of dark and mid-tones, compressing only the brightest extremes. Tailored for dark rooms and night work."
                : "어두운 톤과 중간 톤을 최대로 보존하고 가장 밝은 극단적 광원 영역만 눌러줍니다. 어두운 방이나 야간 작업에 특화되어 있습니다."
        default:
            return isEN 
                ? "Nonlinear dimming is applied based on the configured exponent."
                : "설정된 곡선 지수에 따라 비선형 감쇄가 적용됩니다."
        }
    }

    private var curveGraph: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height

            let uSplit = 0.2
            let tSplit = 0.3
            let base = 10.0

            let getT = { (u: Double) -> Double in
                if u < uSplit {
                    let ratio = u / uSplit
                    return (pow(base, ratio) - 1.0) / (base - 1.0) * tSplit
                } else {
                    let ratio = (u - uSplit) / (1.0 - uSplit)
                    return tSplit + ratio * (1.0 - tSplit)
                }
            }

            // 1. Draw Grid Lines
            let gridPath = Path { p in
                // Horizontal grid lines (linear)
                for y in [0.25, 0.5, 0.75] {
                    p.move(to: CGPoint(x: 0, y: h * y))
                    p.addLine(to: CGPoint(x: w, y: h * y))
                }
                
                // Vertical grid lines (logarithmic below 30%, linear above)
                let verticalTs = [0.1, 0.2, 0.5, 0.75]
                for t in verticalTs {
                    let u: Double
                    if t < tSplit {
                        let ratio = log10((t / tSplit) * 9.0 + 1.0)
                        u = ratio * uSplit
                    } else {
                        let ratio = (t - tSplit) / (1.0 - tSplit)
                        u = uSplit + ratio * (1.0 - uSplit)
                    }
                    let x = CGFloat(u) * w
                    p.move(to: CGPoint(x: x, y: 0))
                    p.addLine(to: CGPoint(x: x, y: h))
                }
            }
            ctx.stroke(gridPath, with: .color(Color.primary.opacity(0.04)), style: StrokeStyle(lineWidth: 0.8, dash: [3, 3]))

            // 2. Draw Diagonal Baseline (Reference: 100% Unreduced)
            var baseLine = Path()
            let steps = 60
            for i in 0...steps {
                let u = Double(i) / Double(steps)
                let t = getT(u)
                let x = CGFloat(u) * w
                let y = h - CGFloat(t) * h
                
                if i == 0 {
                    baseLine.move(to: CGPoint(x: x, y: y))
                } else {
                    baseLine.addLine(to: CGPoint(x: x, y: y))
                }
            }
            ctx.stroke(baseLine, with: .color(Color.secondary.opacity(0.25)), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))

            // 3. Calculate curve parameters
            let amount = dm.isEnabled ? dm.reduction : 0.0
            let maxOutput = 1.0 - amount * 0.3
            let exp = dm.curveExponent

            // 4. Draw the actual curve
            var curvePath = Path()

            for i in 0...steps {
                let u = Double(i) / Double(steps)
                let t = getT(u)
                let scaleFactor = 1.0 - pow(t, exp) * (1.0 - maxOutput)
                let output = t * scaleFactor

                let x = CGFloat(u) * w
                let y = h - CGFloat(output) * h

                if i == 0 {
                    curvePath.move(to: CGPoint(x: x, y: y))
                } else {
                    curvePath.addLine(to: CGPoint(x: x, y: y))
                }
            }

            let grad = Gradient(colors: [.orange, .yellow.opacity(0.85)])
            ctx.stroke(
                curvePath,
                with: .linearGradient(grad, startPoint: CGPoint(x: 0, y: h), endPoint: CGPoint(x: w, y: 0)),
                lineWidth: 2.0
            )

            // 5. Draw the endpoint indicator dot if reduced
            if amount > 0.01 {
                let endPoint = CGPoint(x: w, y: h - CGFloat(maxOutput) * h)
                ctx.fill(
                    Path(ellipseIn: CGRect(x: endPoint.x - 3.5, y: endPoint.y - 3.5, width: 7, height: 7)),
                    with: .color(.orange)
                )
                ctx.stroke(
                    Path(ellipseIn: CGRect(x: endPoint.x - 5.5, y: endPoint.y - 5.5, width: 11, height: 11)),
                    with: .color(.orange.opacity(0.4)),
                    lineWidth: 1.2
                )
            }
        }
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
}

