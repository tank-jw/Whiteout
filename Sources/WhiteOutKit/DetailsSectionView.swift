import SwiftUI

struct DetailsSectionView: View {
    @ObservedObject var dm: DisplayManager
    @Binding var showDetails: Bool

    var body: some View {
        let isEN = dm.language == "en"
        VStack(spacing: 0) {
            // Navigation Bar
            HStack {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        showDetails = false
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .bold))
                        Text(LocalizedStrings.backButton(isEN: isEN))
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(Color.orange)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 6)
                    .background(Color.orange.opacity(0.08))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Spacer()

                Text(LocalizedStrings.settingsTitle(isEN: isEN))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.primary)

                Spacer()

                // Balancing spacer
                Color.clear.frame(width: 48, height: 16)
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider().opacity(0.4)

            // Scrollable Content
            ScrollView {
                VStack(spacing: 12) {
                    // 1. Shortcuts & System Card
                    shortcutsAndSystemCard(isEN: isEN)

                    // 2. Time-Based Rules Card
                    timeRulesCard(isEN: isEN)

                    // 3. App-Specific Rules Card
                    appRulesCard(isEN: isEN)

                    // 4. Live Curve Diagnostics & Principles Card
                    curveDiagnosticsCard(isEN: isEN)
                }
                .padding(14)
            }
        }
        .frame(width: 310)
    }

    // MARK: - 1. Shortcuts & System Card

    private func shortcutsAndSystemCard(isEN: Bool) -> some View {
        VStack(spacing: 10) {
            HStack {
                Label(LocalizedStrings.shortcutsAndLaunchSection(isEN: isEN), systemImage: "keyboard")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.secondary)
                Spacer()
            }

            // Shortcut row
            VStack(spacing: 6) {
                HStack {
                    Text(LocalizedStrings.shortcutToggle(isEN: isEN))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.primary)
                    Spacer()
                    Toggle("", isOn: $dm.isShortcutEnabled)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .tint(.orange)
                        .scaleEffect(0.8)
                }

                if dm.isShortcutEnabled {
                    HStack {
                        Text(LocalizedStrings.shortcutRecord(isEN: isEN))
                            .font(.system(size: 10))
                            .foregroundStyle(Color.secondary)
                        Spacer()
                        ShortcutRecorderView(shortcut: $dm.shortcut)
                            .frame(width: 120, height: 22)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }

            Divider().opacity(0.3)

            // Launch at login row
            HStack {
                Text(LocalizedStrings.launchAtLogin(isEN: isEN))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.primary)
                Spacer()
                Toggle("", isOn: $dm.launchAtLogin)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .tint(.orange)
                    .scaleEffect(0.8)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
    }

    // MARK: - 2. Time Rules Card

    private func timeRulesCard(isEN: Bool) -> some View {
        VStack(spacing: 8) {
            HStack {
                Label(LocalizedStrings.timeRulesSectionTitle(isEN: isEN), systemImage: "clock")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.secondary)
                Spacer()
                Button {
                    withAnimation {
                        dm.addTimeRule()
                    }
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "plus")
                            .font(.system(size: 9, weight: .bold))
                        Text(isEN ? "Add" : "추가")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            if dm.timeRules.isEmpty {
                Text(isEN ? "No scheduled time rules." : "설정된 시간별 규칙이 없습니다.")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 6)
            } else {
                VStack(spacing: 6) {
                    ForEach(Array(dm.timeRules.enumerated()), id: \.element.id) { index, rule in
                        timeRuleRow(index: index, rule: rule, isEN: isEN)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
    }

    private func timeRuleRow(index: Int, rule: TimeRule, isEN: Bool) -> some View {
        let isActive = dm.activeTimeRuleId == rule.id

        return HStack(spacing: 4) {
            Toggle("", isOn: Binding(
                get: { rule.isEnabled },
                set: { newVal in
                    dm.timeRules[index].isEnabled = newVal
                }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
            .tint(.orange)
            .scaleEffect(0.65)
            .frame(width: 26)

            DatePicker("", selection: Binding(
                get: { rule.startDate },
                set: { newVal in
                    dm.timeRules[index].startDate = newVal
                }
            ), displayedComponents: .hourAndMinute)
            .labelsHidden()
            .scaleEffect(0.82)
            .frame(width: 60)
            .disabled(!rule.isEnabled)

            Text("~")
                .font(.system(size: 10))
                .foregroundStyle(Color.secondary)

            DatePicker("", selection: Binding(
                get: { rule.endDate },
                set: { newVal in
                    dm.timeRules[index].endDate = newVal
                }
            ), displayedComponents: .hourAndMinute)
            .labelsHidden()
            .scaleEffect(0.82)
            .frame(width: 60)
            .disabled(!rule.isEnabled)

            Spacer(minLength: 0)

            Menu {
                let currentPct = Int((rule.reduction * 30).rounded())
                let presets = [0, 5, 10, 15, 20, 25, 30]
                if !presets.contains(currentPct) {
                    Button {
                        // Current live value
                    } label: {
                        Text("✓ \(currentPct)%")
                    }
                    Divider()
                }
                ForEach(presets, id: \.self) { pct in
                    Button {
                        dm.timeRules[index].reduction = Double(pct) / 30.0
                        if isActive {
                            dm.applyReduction()
                        }
                    } label: {
                        if currentPct == pct {
                            Text("✓ \(pct)%")
                        } else {
                            Text("\(pct)%")
                        }
                    }
                }
            } label: {
                HStack(spacing: 3) {
                    Text("\(Int((rule.reduction * 30).rounded()))%")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(rule.isEnabled ? (isActive ? Color.orange : Color.primary) : Color.secondary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 7, weight: .semibold))
                        .foregroundStyle(Color.secondary.opacity(0.8))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(isActive ? Color.orange.opacity(0.15) : Color(nsColor: .controlColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(isActive ? Color.orange.opacity(0.3) : Color.primary.opacity(0.08), lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)
            .fixedSize()
            .disabled(!rule.isEnabled)

            Button {
                withAnimation {
                    dm.deleteTimeRule(at: index)
                }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.red.opacity(0.8))
            }
            .buttonStyle(.plain)
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

    // MARK: - 3. App Rules Card

    private func appRulesCard(isEN: Bool) -> some View {
        VStack(spacing: 8) {
            HStack {
                Label(LocalizedStrings.appRulesSectionTitle(isEN: isEN), systemImage: "app.badge")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.secondary)
                Spacer()
                Button {
                    withAnimation {
                        dm.addAppRuleForLastActiveApp()
                    }
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "plus")
                            .font(.system(size: 9, weight: .bold))
                        Text(isEN ? "Add" : "추가")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            if dm.appRules.isEmpty {
                Text(isEN ? "No app-specific rules." : "등록된 앱 규칙이 없습니다.")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 6)
            } else {
                VStack(spacing: 6) {
                    ForEach(dm.appRules) { rule in
                        appRuleRow(rule: rule, isEN: isEN)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
    }

    private func appRuleRow(rule: AppRule, isEN: Bool) -> some View {
        let active = dm.activeRuleAppName == rule.appName

        return VStack(spacing: 4) {
            HStack(spacing: 6) {
                if let icon = dm.getAppIcon(bundleIdentifier: rule.bundleIdentifier) {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 14, height: 14)
                } else {
                    Image(systemName: "app.fill")
                        .font(.system(size: 12))
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
                        .font(.system(size: 10))
                        .foregroundStyle(Color.red.opacity(0.8))
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
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
                .scaleEffect(0.65)
                .frame(width: 26)

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

                Text("\(Int((rule.reduction * 30).rounded()))%")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(rule.isEnabled ? Color.primary : Color.secondary)
                    .frame(width: 26, alignment: .trailing)

                Menu {
                    ForEach([2.5, 4.0, 6.0], id: \.self) { exp in
                        Button {
                            if let idx = dm.appRules.firstIndex(where: { $0.bundleIdentifier == rule.bundleIdentifier }) {
                                dm.appRules[idx].curveExponent = exp
                                dm.applyReduction()
                            }
                        } label: {
                            if abs(rule.curveExponent - exp) < 0.1 {
                                Text(String(format: "✓ %.1f", exp))
                            } else {
                                Text(String(format: "%.1f", exp))
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 2) {
                        Text(String(format: "%.1f", rule.curveExponent))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(rule.isEnabled ? Color.primary : Color.secondary)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 7, weight: .semibold))
                            .foregroundStyle(Color.secondary.opacity(0.8))
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(Color(nsColor: .controlColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
                .fixedSize()
                .disabled(!rule.isEnabled)
            }
            .padding(.leading, 20)
        }
        .padding(8)
        .background(active ? Color.orange.opacity(0.04) : Color.primary.opacity(0.02))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(active ? Color.orange.opacity(0.2) : Color.clear, lineWidth: 0.5)
        )
    }

    // MARK: - 4. Curve Diagnostics Card

    private func curveDiagnosticsCard(isEN: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(LocalizedStrings.detailsSectionTitle(isEN: isEN), systemImage: "waveform.path.ecg")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.secondary)

            ZStack(alignment: .bottomTrailing) {
                CurveGraphView(
                    isEnabled: dm.isEnabled,
                    reduction: dm.reduction,
                    curveExponent: dm.curveExponent
                )
                .frame(height: 110)
                .background(Color.black.opacity(0.15))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                )

                Text("100%")
                    .font(.system(size: 7, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary.opacity(0.5))
                    .padding(.leading, 6)
                    .padding(.top, 4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                Text("0%")
                    .font(.system(size: 7, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary.opacity(0.5))
                    .padding(.leading, 6)
                    .padding(.bottom, 4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)

                Text("100%")
                    .font(.system(size: 7, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary.opacity(0.5))
                    .padding(.trailing, 6)
                    .padding(.bottom, 4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }

            // Exponent Explanation
            VStack(alignment: .leading, spacing: 3) {
                Text(curveTypeTitle)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.orange)
                Text(curveTypeDescription)
                    .font(.system(size: 9.5))
                    .foregroundStyle(.secondary)
                    .lineSpacing(1.8)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.06))
            .cornerRadius(6)

            // Method Comparison
            VStack(alignment: .leading, spacing: 5) {
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
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
    }

    private func bulletPoint(title: String, desc: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Circle()
                    .fill(title.contains("Whiteout") || title.contains("화이트아웃") ? Color.orange : Color.secondary)
                    .frame(width: 3.5, height: 3.5)
                Text(title)
                    .font(.system(size: 9.5, weight: .semibold))
            }
            Text(desc)
                .font(.system(size: 8.5))
                .foregroundStyle(.secondary)
                .padding(.leading, 7)
                .lineSpacing(1.6)
        }
    }

    private var curveTypeTitle: String {
        let isEN = dm.language == "en"
        switch dm.curveExponent {
        case 2.5:
            return isEN ? "Natural Mode (t = 2.5)" : "일반 모드 (t = 2.5)"
        case 4.0:
            return isEN ? "Docs · Reading Mode (t = 4.0)" : "문서 · 독서 모드 (t = 4.0)"
        case 6.0:
            return isEN ? "Highlight Protection Mode (t = 6.0)" : "하이라이트 보호 모드 (t = 6.0)"
        default:
            return isEN ? "Custom Mode" : "커스텀 모드"
        }
    }

    private var curveTypeDescription: String {
        let isEN = dm.language == "en"
        switch dm.curveExponent {
        case 2.5:
            return isEN 
                ? "Lowers brightness smoothly and naturally across the whole screen. Recommended for daily tasks."
                : "전반적으로 자연스럽고 부드럽게 밝기를 낮춥니다. 웹서핑 및 일상 작업에 가장 권장됩니다."
        case 4.0:
            return isEN 
                ? "Perfectly preserves text contrast while compressing glaring white backgrounds. Ideal for reading."
                : "텍스트의 선명한 블랙을 완벽히 유지하면서 눈부신 흰 배경만 집중 감쇄합니다. 독서와 문서 작업에 적합합니다."
        case 6.0:
            return isEN 
                ? "Maximally preserves dark and mid-tones, compressing only peak bright highlights. Tailored for dark rooms."
                : "어두운 톤과 중간 톤을 최대로 보존하고 가장 밝은 극단적 광원만 눌러줍니다. 어두운 환경에 특화되어 있습니다."
        default:
            return isEN 
                ? "Nonlinear dimming is applied based on the configured exponent."
                : "설정된 곡선 지수에 따라 비선형 감쇄가 적용됩니다."
        }
    }
}
