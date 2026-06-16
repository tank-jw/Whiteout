import SwiftUI
import KeyboardShortcuts

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
            let percent = 100 - Int((dm.reduction * 30).rounded())
            VStack(alignment: .leading, spacing: 3) {
                Text(LocalizedStrings.title(isEN: isEN))
                    .font(.system(size: 13, weight: .semibold))
                Text(dm.isEnabled
                     ? LocalizedStrings.statusActive(isEN: isEN, percent: percent)
                     : LocalizedStrings.statusDisabled(isEN: isEN))
                    .font(.system(size: 11))
                    .foregroundStyle(dm.isEnabled ? Color.orange : Color.secondary)
                    .animation(.easeInOut(duration: 0.2), value: dm.isEnabled)
            }

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
        return VStack(spacing: 14) {
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
                    .foregroundStyle(Color.secondary)
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
                    KeyboardShortcuts.Recorder("", name: .toggleWhiteout)
                }
            }
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
                            title: isEN ? "Whiteout (GPU Gamma)" : "Whiteout (GPU 감마 조절)",
                            desc: isEN 
                                ? "Perfectly preserves black levels (0), keeping contrast ratio and OLED blacks intact."
                                : "검정색(0) 레벨을 100% 보존하여 명암비와 검정색 표현력이 완벽히 유지됩니다."
                        )
                        bulletPoint(
                            title: isEN ? "Software Overlay Filter" : "소프트웨어 오버레이 필터",
                            desc: isEN 
                                ? "Draws a black semi-transparent mask over the screen, raising black levels and degrading contrast."
                                : "화면에 검은 막을 씌워 블랙 레벨을 들뜨게 하고 명암비를 손상시킵니다."
                        )
                    }
                }
            }
            .padding(14)
        }
        .frame(width: 300)
    }

    private func bulletPoint(title: String, desc: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Circle()
                    .fill(title.contains("Whiteout") ? Color.orange : Color.secondary)
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
            let steps = 120
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
        Group {
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

// MARK: - Localization

struct LocalizedStrings {
    static func title(isEN: Bool) -> String {
        isEN ? "Whiteout" : "화이트아웃"
    }
    static func statusActive(isEN: Bool, percent: Int) -> String {
        isEN ? "Max brightness limited to \(percent)%" : "최대 밝기 \(percent)% 로 제한 중"
    }
    static func statusDisabled(isEN: Bool) -> String {
        isEN ? "Disabled" : "비활성화됨"
    }
    static func reductionLabel(isEN: Bool) -> String {
        isEN ? "Reduction" : "감소량"
    }
    static func preserveBlacks(isEN: Bool) -> String {
        isEN ? "Preserve Blacks" : "검정 유지"
    }
    static func maxWhiteLevel(isEN: Bool, percent: Int) -> String {
        isEN ? "Max white level \(percent)%" : "흰색 최대값 \(percent)%"
    }
    static func shortcutToggle(isEN: Bool) -> String {
        isEN ? "Toggle via Shortcut" : "단축키로 On/Off"
    }
    static func shortcutRecord(isEN: Bool) -> String {
        isEN ? "Configure Shortcut" : "단축키 설정"
    }
    static func curveTypeLabel(isEN: Bool) -> String {
        isEN ? "Curve Type" : "곡선 타입"
    }
    static func curveGeneral(isEN: Bool) -> String {
        isEN ? "General" : "일반"
    }
    static func curveDocs(isEN: Bool) -> String {
        isEN ? "Docs · PDF" : "문서·PDF"
    }
    static func curveHighlights(isEN: Bool) -> String {
        isEN ? "Highlights" : "하이라이트"
    }
    static func manualCheckHelp(isEN: Bool) -> String {
        isEN ? "Check for updates" : "업데이트 확인 (120시간마다 자동 확인)"
    }
    static func quitLabel(isEN: Bool) -> String {
        isEN ? "Quit" : "종료"
    }
    static func detailsTitle(isEN: Bool) -> String {
        isEN ? "Brightness Curve (x-axis: Input ➔ y-axis: Output)" : "밝기 변환 곡선 (x축 : 입력 밝기 → y축 : 출력 밝기)"
    }
    static func detailsSectionTitle(isEN: Bool) -> String {
        isEN ? "Principles & Curve Analysis" : "원리 및 곡선 분석"
    }
    static func detailsHowItWorks(isEN: Bool) -> String {
        isEN ? "Comparison of Methods" : "작동 방식 차이점"
    }
    static func updateDownloading(isEN: Bool, ver: String) -> String {
        isEN ? "Downloading v\(ver)..." : "v\(ver) 다운로드 중..."
    }
    static func updateAvailable(isEN: Bool, ver: String) -> String {
        isEN ? "New version v\(ver) available" : "새 버전 v\(ver) 사용 가능"
    }
    static func updateClickToUpdate(isEN: Bool) -> String {
        isEN ? "Click to auto update" : "클릭하여 자동 업데이트"
    }
    static func updateNetworkErrorTitle(isEN: Bool) -> String {
        isEN ? "Update Error" : "업데이트 오류"
    }
    static func updateNetworkErrorMsg(isEN: Bool) -> String {
        isEN ? "Failed to get update info. Please check your network connection." : "업데이트 정보를 가져오지 못했습니다. 네트워크 연결 상태를 확인해 주세요."
    }
}
