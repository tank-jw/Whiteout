import SwiftUI

struct CurveGraphView: View {
    let isEnabled: Bool
    let reduction: Double
    let curveExponent: Double

    var body: some View {
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
                        u = uSplit + ratio * (1.0 - tSplit)
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
            let amount = isEnabled ? reduction : 0.0
            let maxOutput = 1.0 - amount * 0.3
            let exp = curveExponent

            // 4. Draw the actual curve
            var curvePath = Path()
            for i in 0...steps {
                let u = Double(i) / Double(steps)
                let t = getT(u)
                let sf = 1.0 - pow(t, exp) * (1.0 - maxOutput)
                let finalVal = t * sf
                
                let x = CGFloat(u) * w
                let y = h - CGFloat(finalVal) * h
                
                if i == 0 {
                    curvePath.move(to: CGPoint(x: x, y: y))
                } else {
                    curvePath.addLine(to: CGPoint(x: x, y: y))
                }
            }
            ctx.stroke(curvePath, with: .color(isEnabled ? Color.orange : Color.secondary), style: StrokeStyle(lineWidth: 2))
        }
    }
}
