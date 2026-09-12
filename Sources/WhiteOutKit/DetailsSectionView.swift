import SwiftUI

struct DetailsSectionView: View {
    @ObservedObject var dm: DisplayManager

    var body: some View {
        let lang = dm.appLanguage
        VStack(spacing: 10) {
            // 1. Time-Based Rules Card
            timeRulesCard(lang: lang)

            // 2. App-Specific Rules Card
            appRulesCard(lang: lang)

            // 3. Shortcuts & System Card
            shortcutsAndSystemCard(lang: lang)

            // 4. Principles & Mode Guide Card
            principlesCard(lang: lang)
        }
    }

    // MARK: - 1. Shortcuts & System Card

    private func shortcutsAndSystemCard(lang: AppLanguage) -> some View {
        VStack(spacing: 10) {
            HStack {
                Label(LocalizedStrings.shortcutsAndLaunchSection(lang: lang), systemImage: "keyboard")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.secondary)
                Spacer()
            }

            // Shortcut row
            VStack(spacing: 6) {
                HStack {
                    Text(LocalizedStrings.shortcutToggle(lang: lang))
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
                        Text(LocalizedStrings.shortcutRecord(lang: lang))
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
                Text(LocalizedStrings.launchAtLogin(lang: lang))
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

    private func timeRulesCard(lang: AppLanguage) -> some View {
        VStack(spacing: 8) {
            HStack {
                Label(LocalizedStrings.timeRulesSectionTitle(lang: lang), systemImage: "clock")
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
                        Text(LocalizedStrings.add(lang: lang))
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
                Text(LocalizedStrings.noTimeRules(lang: lang))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 6)
            } else {
                VStack(spacing: 6) {
                    ForEach(Array(dm.timeRules.enumerated()), id: \.element.id) { index, rule in
                        timeRuleRow(index: index, rule: rule, lang: lang)
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

    private func timeRuleRow(index: Int, rule: TimeRule, lang: AppLanguage) -> some View {
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
            .frame(width: 28)

            Spacer().frame(width: 6)

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
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(isActive ? Color.orange.opacity(0.06) : Color.clear)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isActive ? Color.orange.opacity(0.2) : Color.clear, lineWidth: 0.5)
        )
    }

    // MARK: - 3. App Rules Card

    private func appRulesCard(lang: AppLanguage) -> some View {
        VStack(spacing: 8) {
            HStack {
                Label(LocalizedStrings.appRulesSectionTitle(lang: lang), systemImage: "app.badge")
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
                        Text(LocalizedStrings.add(lang: lang))
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
                Text(LocalizedStrings.noAppRules(lang: lang))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 6)
            } else {
                VStack(spacing: 6) {
                    ForEach(dm.appRules) { rule in
                        appRuleRow(rule: rule, lang: lang)
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

    private func appRuleRow(rule: AppRule, lang: AppLanguage) -> some View {
        let active = dm.activeRuleAppName == rule.appName

        return VStack(spacing: 5) {
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
                    Text(LocalizedStrings.activeRuleBadge(lang: lang))
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.orange.opacity(0.12))
                        .cornerRadius(3)
                }

                Spacer()
            }

            HStack(spacing: 4) {
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
                .frame(width: 28)

                Spacer().frame(width: 6)

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
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background(active ? Color.orange.opacity(0.04) : Color.primary.opacity(0.02))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(active ? Color.orange.opacity(0.2) : Color.clear, lineWidth: 0.5)
        )
    }

    // MARK: - 4. Principles & Mode Guide Card

    private func principlesCard(lang: AppLanguage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(LocalizedStrings.detailsSectionTitle(lang: lang), systemImage: "info.circle")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.secondary)

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
                    title: LocalizedStrings.compareOurApp(lang: lang),
                    desc: LocalizedStrings.compareOurAppDesc(lang: lang)
                )
                bulletPoint(
                    title: LocalizedStrings.compareOverlay(lang: lang),
                    desc: LocalizedStrings.compareOverlayDesc(lang: lang)
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
                    .fill(title.contains("Whiteout") || title.contains("화이트아웃") || title.contains("WhiteOut") ? Color.orange : Color.secondary)
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
        let lang = dm.appLanguage
        switch dm.curveExponent {
        case 2.5: return LocalizedStrings.curveDescGeneral(lang: lang)
        case 4.0: return LocalizedStrings.curveDescDocs(lang: lang)
        case 6.0: return LocalizedStrings.curveDescHighlights(lang: lang)
        default:  return LocalizedStrings.curveDescCustom(lang: lang)
        }
    }

    private var curveTypeDescription: String {
        let lang = dm.appLanguage
        switch dm.curveExponent {
        case 2.5: return LocalizedStrings.curveDescDetailGeneral(lang: lang)
        case 4.0: return LocalizedStrings.curveDescDetailDocs(lang: lang)
        case 6.0: return LocalizedStrings.curveDescDetailHighlights(lang: lang)
        default:  return LocalizedStrings.curveDescDetailCustom(lang: lang)
        }
    }
}
