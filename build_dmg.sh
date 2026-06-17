#!/bin/bash
# build_dmg.sh — ReduceWhitePoint .app 번들 + DMG 생성 스크립트

set -e

APP_NAME="WhiteOut"
BUNDLE_ID="com.tankjw.whiteout"
VERSION="1.6.6"
DMG_NAME="${APP_NAME}.dmg"
ZIP_NAME="${APP_NAME}.zip"
BUILD_DIR=".build/release"
APP_DIR="${APP_NAME}.app"

echo "🧹 이전 빌드 아티팩트 청소 중..."
rm -rf .build/arm64 .build/x86_64 .build/release

echo "🔨 arm64 Release 빌드 중..."
swift build -c release -Xswiftc -target -Xswiftc arm64-apple-macosx13.0 --build-path .build/arm64

echo "🔨 x86_64 Release 빌드 중..."
swift build -c release -Xswiftc -target -Xswiftc x86_64-apple-macosx13.0 --build-path .build/x86_64

echo "💿 유니버셜 바이너리(Universal Binary) 생성 중..."
mkdir -p .build/release

# 빌드된 바이너리 경로 탐색 (dSYM 제외)
ARM64_BIN=$(find .build/arm64 -name "${APP_NAME}" -type f | grep -v "\.dSYM" | head -n 1)
X86_64_BIN=$(find .build/x86_64 -name "${APP_NAME}" -type f | grep -v "\.dSYM" | head -n 1)

if [ -z "$ARM64_BIN" ] || [ -z "$X86_64_BIN" ]; then
  echo "❌ 빌드된 arm64 또는 x86_64 바이너리를 찾을 수 없습니다."
  exit 1
fi

lipo -create -output .build/release/Whiteout "$ARM64_BIN" "$X86_64_BIN"

echo "📦 .app 번들 구조 생성 중..."
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

# 실행 파일 복사
cp "${BUILD_DIR}/${APP_NAME}" "${APP_DIR}/Contents/MacOS/${APP_NAME}"
chmod +x "${APP_DIR}/Contents/MacOS/${APP_NAME}"

# 아이콘 자원 복사
if [ -f "assets/AppIcon.icns" ]; then
  echo "🎨 AppIcon.icns 복사 중..."
  cp assets/AppIcon.icns "${APP_DIR}/Contents/Resources/AppIcon.icns"
else
  echo "⚠️ 경고: assets/AppIcon.icns 파일이 없습니다! 아이콘 없이 빌드됩니다."
fi

echo "📝 Info.plist 생성 중..."
cat > "${APP_DIR}/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>${APP_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>${BUNDLE_ID}</string>
  <key>CFBundleName</key>
  <string>WhiteOut</string>
  <key>CFBundleDisplayName</key>
  <string>WhiteOut</string>
  <key>CFBundleVersion</key>
  <string>${VERSION}</string>
  <key>CFBundleShortVersionString</key>
  <string>${VERSION}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleSignature</key>
  <string>????</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>LSUIElement</key>
  <true/>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
</dict>
</plist>
EOF

echo "✍️  애드훅 서명 중..."
codesign --force --deep --sign - "${APP_DIR}"

echo "💿 DMG 생성 중..."
rm -f "${DMG_NAME}" temp.dmg

# 1. 임시 DMG 생성 (Read/Write 가능)
hdiutil create -size 45m -fs HFS+ -volname "WhiteOut" -ov temp.dmg

# 2. 마운트
MOUNT_DIR="/Volumes/WhiteOut"
ATTACH_OUT=$(hdiutil attach temp.dmg -readwrite -mountpoint "${MOUNT_DIR}")
echo "${ATTACH_OUT}"
DEV_NODE=$(echo "${ATTACH_OUT}" | grep Apple_HFS | awk '{print $1}')

# 3. 파일 복사 및 바로가기 생성
cp -r "${APP_DIR}" "${MOUNT_DIR}/"
ln -s /Applications "${MOUNT_DIR}/Applications"

# 4. 배경 이미지 복사 (.background 디렉토리에 숨김 처리 및 600x600 해상도 매칭)
mkdir -p "${MOUNT_DIR}/.background"
if [ -f "assets/dmg_background.png" ]; then
  echo "🎨 DMG 배경화면 설정 중 (600x600 리사이징)..."
  sips -s format png -z 600 600 assets/dmg_background.png --out "${MOUNT_DIR}/.background/dmg_background.png" > /dev/null
fi

# 5. AppleScript를 이용해 Finder 창 레이아웃 설정
echo "🎨 DMG 레이아웃 및 배경 적용 중..."
osascript <<EOF
tell application "Finder"
    tell disk "WhiteOut"
        open
        delay 1
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 1000, 700} -- 가로 600, 세로 600
        set viewOptions to the icon view options of container window
        set icon size of viewOptions to 100
        set arrangement of viewOptions to not arranged
        if exists file ".background:dmg_background.png" then
            set background picture of viewOptions to file ".background:dmg_background.png"
        end if
        
        -- 앱 아이콘 및 Applications 심볼릭 링크 위치 정렬
        -- 생성된 백그라운드의 A 로고와 폴더 아이콘에 맞춤
        set position of item "WhiteOut.app" to {150, 310}
        set position of item "Applications" to {450, 310}
        
        close container window
        open
        delay 2
        close container window
    end tell
end tell
EOF

# 6. 동기화 및 마운트 해제
sync
if [ -n "${DEV_NODE}" ]; then
  hdiutil detach -force "${DEV_NODE}"
else
  hdiutil detach -force "${MOUNT_DIR}"
fi

# 7. 최종 배포용 DMG 생성 (압축형식 UDZO)
hdiutil convert temp.dmg -format UDZO -imagekey zlib-level=9 -o "${DMG_NAME}"
rm -f temp.dmg

echo "🗜️  ZIP 생성 중 (자동 업데이트용)..."
rm -f "${ZIP_NAME}"
ditto -c -k --keepParent "${APP_DIR}" "${ZIP_NAME}"

echo ""
echo "✅ 완료!"
echo "   📁 앱 번들: ${APP_DIR}"
echo "   💿 DMG:     ${DMG_NAME}"
echo "   🗜️  ZIP:     ${ZIP_NAME}"
echo ""
echo "⚠️  다른 맥에서 처음 실행 시:"
echo "   Finder에서 앱을 우클릭 → '열기' → '열기' 버튼 클릭"
echo "   (애플 공증 없는 앱이라 최초 1회만 이 과정 필요)"
