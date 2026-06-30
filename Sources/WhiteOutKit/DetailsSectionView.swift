import SwiftUI

struct DetailsSectionView: View {
    @ObservedObject var dm: DisplayManager
    @Binding var showDetails: Bool

    var body: some View {
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
                        CurveGraphView(
                            isEnabled: dm.isEnabled,
                            reduction: dm.reduction,
                            curveExponent: dm.curveExponent
                        )
                        .frame(height: 120)
                        .background(Color.black.opacity(0.15))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                        )

                        // Overlay percentage markers
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
}
