#!/bin/bash
# build_dmg.sh — ReduceWhitePoint .app 번들 + DMG 생성 스크립트

set -e

APP_NAME="Whiteout"
BUNDLE_ID="com.tankjw.whiteout"
VERSION="1.6.1"
DMG_NAME="${APP_NAME}.dmg"
ZIP_NAME="${APP_NAME}.zip"
BUILD_DIR=".build/release"
APP_DIR="${APP_NAME}.app"

echo "🔨 Release 빌드 중..."
swift build -c release

echo "📦 .app 번들 구조 생성 중..."
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

# 실행 파일 복사
cp "${BUILD_DIR}/${APP_NAME}" "${APP_DIR}/Contents/MacOS/${APP_NAME}"
chmod +x "${APP_DIR}/Contents/MacOS/${APP_NAME}"

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
  <string>Whiteout</string>
  <key>CFBundleDisplayName</key>
  <string>Whiteout</string>
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
</dict>
</plist>
EOF

echo "✍️  애드훅 서명 중..."
codesign --force --deep --sign - "${APP_DIR}"

echo "💿 DMG 생성 중..."
rm -f "${DMG_NAME}"

# 임시 DMG 폴더 구성
STAGING_DIR=$(mktemp -d)
cp -r "${APP_DIR}" "${STAGING_DIR}/"
ln -s /Applications "${STAGING_DIR}/Applications"

hdiutil create \
  -volname "Whiteout" \
  -srcfolder "${STAGING_DIR}" \
  -ov \
  -format UDZO \
  "${DMG_NAME}"

rm -rf "${STAGING_DIR}"

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
