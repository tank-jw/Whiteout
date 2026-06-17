import AppKit
import Foundation

let inputPath = "assets/AppIcon.png"
let outputPath = "assets/AppIcon_masked.png"

guard let image = NSImage(contentsOfFile: inputPath) else {
    print("❌ 에러: \(inputPath) 파일을 불러올 수 없습니다.")
    exit(1)
}

guard let tiffData = image.tiffRepresentation,
      let imageRep = NSBitmapImageRep(data: tiffData) else {
    print("❌ 에러: 이미지의 비트맵 데이터를 추출할 수 없습니다.")
    exit(1)
}

// 1. 둥근 사각형 아이콘 본체의 바운딩 박스를 픽셀 분석을 통해 검출합니다.
func detectBoundingBox(imageRep: NSBitmapImageRep) -> NSRect {
    let width = imageRep.pixelsWide
    let height = imageRep.pixelsHigh
    
    var minX = width
    var maxX = 0
    var minY = height
    var maxY = 0
    
    // 배경은 매우 어두우므로 밝기 임계값을 설정하여 걸러냅니다.
    let threshold: CGFloat = 0.12
    
    for y in 0..<height {
        for x in 0..<width {
            guard let color = imageRep.colorAt(x: x, y: y) else { continue }
            let r = color.redComponent
            let g = color.greenComponent
            let b = color.blueComponent
            
            // 가중치 평균 밝기 계산
            let brightness = 0.299 * r + 0.587 * g + 0.114 * b
            if brightness > threshold {
                if x < minX { minX = x }
                if x > maxX { maxX = x }
                if y < minY { minY = y }
                if y > maxY { maxY = y }
            }
        }
    }
    
    // 검출 실패 시 전체 이미지 크기의 92% 영역으로 기본 크롭
    if minX >= maxX || minY >= maxY {
        print("⚠️ 경고: 바운딩 박스 검출 실패. 기본 중앙 크롭을 적용합니다.")
        let size = CGFloat(min(width, height)) * 0.92
        let x = (CGFloat(width) - size) / 2
        let y = (CGFloat(height) - size) / 2
        return NSRect(x: x, y: y, width: size, height: size)
    }
    
    let boxWidth = maxX - minX
    let boxHeight = maxY - minY
    
    // 정밀도를 위해 아주 약간의 여백(패딩)을 추가합니다. (약 3% 수준)
    let padding = Int(CGFloat(max(boxWidth, boxHeight)) * 0.015)
    minX = max(0, minX - padding)
    maxX = min(width - 1, maxX + padding)
    minY = max(0, minY - padding)
    maxY = min(height - 1, maxY + padding)
    
    let finalWidth = maxX - minX
    let finalHeight = maxY - minY
    
    // 아이콘 규격은 항상 1:1 정사각형이므로 가장 큰 엣지 기준 정사각형으로 맞춥니다.
    let size = max(finalWidth, finalHeight)
    let centerX = minX + finalWidth / 2
    let centerY = minY + finalHeight / 2
    
    var cropX = centerX - size / 2
    var cropY = centerY - size / 2
    
    // 범위 초과 보정
    if cropX < 0 { cropX = 0 }
    if cropY < 0 { cropY = 0 }
    if cropX + size > width { cropX = width - size }
    if cropY + size > height { cropY = height - size }
    
    let cropRect = NSRect(x: CGFloat(cropX), y: CGFloat(cropY), width: CGFloat(size), height: CGFloat(size))
    print("🎯 검출된 아이콘 영역: \(cropRect)")
    return cropRect
}

let cropRect = detectBoundingBox(imageRep: imageRep)

// 2. 바운딩 박스를 기준으로 이미지 크롭
guard let cgImage = imageRep.cgImage else {
    print("❌ 에러: CGImage를 생성할 수 없습니다.")
    exit(1)
}

// CoreGraphics 좌표계 보정 (Y축 반전 대비)
let yCorrection = CGFloat(imageRep.pixelsHigh) - cropRect.origin.y - cropRect.size.height
let cgCropRect = CGRect(x: cropRect.origin.x, y: yCorrection, width: cropRect.size.width, height: cropRect.size.height)

guard let croppedCgImage = cgImage.cropping(to: cgCropRect) else {
    print("❌ 에러: 이미지 크롭에 실패했습니다.")
    exit(1)
}

let croppedImage = NSImage(cgImage: croppedCgImage, size: cropRect.size)

// 3. 투명 배경의 1024x1024 최종 캔버스 생성 및 마스킹 적용
let finalSize = NSSize(width: 1024, height: 1024)
let outputImage = NSImage(size: finalSize)

outputImage.lockFocus()

// 투명한 투명 배경 클리어
NSGraphicsContext.current?.imageInterpolation = .high
NSColor.clear.set()
NSRect(origin: .zero, size: finalSize).fill()

// macOS Big Sur 이후 표준 앱 아이콘 가이드라인:
// 캔버스 크기 1024x1024, 내부 아이콘 영역은 824x824 px (즉, 좌우상하 여백이 100px 씩 존재)
let targetContentSize: CGFloat = 824
let margin = (finalSize.width - targetContentSize) / 2
let targetRect = NSRect(x: margin, y: margin, width: targetContentSize, height: targetContentSize)

// macOS Squircle (둥근 모서리 반경은 약 824x824 규격 기준 176~180px 정도가 규격에 해당)
let cornerRadius: CGFloat = 180.0
let maskPath = NSBezierPath(roundedRect: targetRect, xRadius: cornerRadius, yRadius: cornerRadius)

// 마스크 클리핑 영역 활성화
maskPath.addClip()

// 크롭된 이미지를 824x824 영역에 맞춰 그림 (둥근 모서리 바깥쪽은 클리핑되어 날아감)
croppedImage.draw(in: targetRect, from: NSRect(origin: .zero, size: cropRect.size), operation: .sourceOver, fraction: 1.0)

outputImage.unlockFocus()

// 4. 결과를 PNG 파일로 저장
guard let outputTiff = outputImage.tiffRepresentation,
      let outputRep = NSBitmapImageRep(data: outputTiff),
      let pngData = outputRep.representation(using: .png, properties: [:]) else {
    print("❌ 에러: 출력 이미지를 PNG로 포맷 변환하는 데 실패했습니다.")
    exit(1)
}

do {
    try pngData.write(to: URL(fileURLWithPath: outputPath))
    print("✅ 성공: \(outputPath)로 투명 둥근 사각형 마스킹 완료!")
} catch {
    print("❌ 에러: 파일을 쓰는 도중 문제가 발생했습니다: \(error)")
    exit(1)
}
