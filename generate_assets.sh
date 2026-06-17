#!/bin/bash
# generate_assets.sh — macOS용 AppIcon.icns 생성 스크립트
set -e

SRC_RAW="assets/AppIcon.png"
ICON_SRC="assets/AppIcon_masked.png"
ICONSET_DIR="assets/AppIcon.iconset"

if [ ! -f "$SRC_RAW" ]; then
    echo "❌ 에러: $SRC_RAW 파일을 찾을 수 없습니다."
    exit 1
fi

echo "🧹 기존 임시 폴더 및 아이콘 파일 청소 중..."
rm -rf "$ICONSET_DIR"
rm -f assets/AppIcon.icns assets/AppIcon_masked.png mask_icon

echo "⚙️ Swift 마스킹 도구 컴파일 및 실행 중..."
swiftc mask_icon.swift -o mask_icon
./mask_icon

# 임시 실행 파일 삭제
rm -f mask_icon

if [ ! -f "$ICON_SRC" ]; then
    echo "❌ 에러: 마스킹된 이미지($ICON_SRC)가 생성되지 않았습니다."
    exit 1
fi

echo "📁 iconset 디렉토리 생성 중..."
mkdir -p "$ICONSET_DIR"

echo "🎨 다양한 해상도로 아이콘 이미지 생성 중 (sips)..."
sips -s format png -z 16 16     "$ICON_SRC" --out "$ICONSET_DIR/icon_16x16.png" > /dev/null
sips -s format png -z 32 32     "$ICON_SRC" --out "$ICONSET_DIR/icon_16x16@2x.png" > /dev/null
sips -s format png -z 32 32     "$ICON_SRC" --out "$ICONSET_DIR/icon_32x32.png" > /dev/null
sips -s format png -z 64 64     "$ICON_SRC" --out "$ICONSET_DIR/icon_32x32@2x.png" > /dev/null
sips -s format png -z 128 128   "$ICON_SRC" --out "$ICONSET_DIR/icon_128x128.png" > /dev/null
sips -s format png -z 256 256   "$ICON_SRC" --out "$ICONSET_DIR/icon_128x128@2x.png" > /dev/null
sips -s format png -z 256 256   "$ICON_SRC" --out "$ICONSET_DIR/icon_256x256.png" > /dev/null
sips -s format png -z 512 512   "$ICON_SRC" --out "$ICONSET_DIR/icon_256x256@2x.png" > /dev/null
sips -s format png -z 512 512   "$ICON_SRC" --out "$ICONSET_DIR/icon_512x512.png" > /dev/null
sips -s format png -z 1024 1024 "$ICON_SRC" --out "$ICONSET_DIR/icon_512x512@2x.png" > /dev/null

echo "💿 iconset을 .icns 파일로 컴파일 중 (iconutil)..."
iconutil -c icns "$ICONSET_DIR" -o assets/AppIcon.icns

echo "🧹 임시 파일 정리 중..."
rm -rf "$ICONSET_DIR"
rm -f "$ICON_SRC"

echo "✅ 완료: assets/AppIcon.icns 생성 성공!"
