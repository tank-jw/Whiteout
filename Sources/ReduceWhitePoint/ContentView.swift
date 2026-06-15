import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dm: DisplayManager
    @EnvironmentObject var updater: UpdateChecker

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
        VStack(spacing: 0) {
            headerSection
            Divider().opacity(0.5)
            controlSection
            Divider().opacity(0.5)
            curveSection
            Divider().opacity(0.5)
            footerSection
        }
        .frame(width: 290)
        .background(.ultraThinMaterial)
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
            VStack(alignment: .leading, spacing: 3) {
                Text("화이트포인트 낮추기")
                    .font(.system(size: 13, weight: .semibold))
                Text(dm.isEnabled
                     ? "최대 밝기 \(100 - Int((dm.reduction * 30).rounded()))% 로 제한 중"
                     : "비활성화됨")
                    .font(.system(size: 11))
                    .foregroundStyle(dm.isEnabled ? Color.orange : Color.secondary)
                    .animation(.easeInOut(duration: 0.2), value: dm.isEnabled)
            }

            Spacer()

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
        VStack(spacing: 14) {
            // Label row
            HStack {
                Text("감소량")
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
                Label("검정 유지", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.green)
                Spacer()
                Text("흰색 최대값 \(100 - Int((dm.reduction * 30).rounded()))%")
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
        VStack(spacing: 10) {
            HStack {
                Text("곡선 타입")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(dm.isEnabled ? Color.primary : Color.secondary)
                Spacer()
            }

            // 3-way segmented toggle
            HStack(spacing: 6) {
                ForEach([
                    (2.5, "일반"),
                    (4.0, "문서 · PDF"),
                    (6.0, "하이라이트")
                ], id: \.0) { value, label in
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
        if updater.updateAvailable {
            Divider().opacity(0.5)
            Button {
                updater.openReleasePage()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("새 버전 v\(updater.latestVersion) 사용 가능")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text("클릭하여 다운로드")
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

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 0) {
            updateBanner

            HStack {
                Button {
                    withAnimation { dm.resetAll() }
                } label: {
                    Text("초기화")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundStyle(dm.isEnabled || dm.reduction > 0 ? Color.secondary : Color.secondary.opacity(0.4))
                .disabled(!dm.isEnabled && dm.reduction == 0)

                Spacer()

                Text("v\(UpdateChecker.currentVersion)")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.secondary.opacity(0.5))

                Spacer()

                Button {
                    dm.quit()
                } label: {
                    Text("종료")
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
