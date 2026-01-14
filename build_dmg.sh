#!/bin/bash

# PhotobookPro DMG 打包脚本
# 生成两个独立的 DMG: ARM64 和 x86_64

set -e

echo "🚀 开始构建 PhotobookPro..."

# 清理旧的构建
echo "🧹 清理旧构建..."
rm -rf build
rm -rf PhotobookApp/.build
rm -rf PhotobookPro-ARM64*.dmg
rm -rf PhotobookPro-x86_64*.dmg

# 创建构建目录
mkdir -p build

cd PhotobookApp

# 编译 ARM64 版本 (Apple Silicon)
echo "🔨 编译 ARM64 版本 (Apple Silicon: M1/M2/M3)..."
swift build -c release --arch arm64
cp -f .build/arm64-apple-macosx/release/PhotobookApp ../build/PhotobookApp-arm64

# 编译 x86_64 版本 (Intel)
echo "🔨 编译 x86_64 版本 (Intel)..."
swift build -c release --arch x86_64
cp -f .build/x86_64-apple-macosx/release/PhotobookApp ../build/PhotobookApp-x86_64

cd ..

# 函数：创建应用包
create_app_bundle() {
    local ARCH=$1
    local BINARY_NAME=$2
    local APP_DIR="build/PhotobookPro-${ARCH}.app"
    
    echo "📦 创建 ${ARCH} 应用包..."
    mkdir -p "${APP_DIR}/Contents/MacOS"
    mkdir -p "${APP_DIR}/Contents/Resources"
    
    # 复制可执行文件
    cp "build/${BINARY_NAME}" "${APP_DIR}/Contents/MacOS/PhotobookPro"
    chmod +x "${APP_DIR}/Contents/MacOS/PhotobookPro"
    
    # 创建 Info.plist
    cat > "${APP_DIR}/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>PhotobookPro</string>
    <key>CFBundleIdentifier</key>
    <string>com.photobookpro.app</string>
    <key>CFBundleName</key>
    <string>PhotobookPro</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>2.0.0</string>
    <key>CFBundleVersion</key>
    <string>2</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>© 2026 PhotobookPro</string>
</dict>
</plist>
EOF

    # 复制内置贴纸资源到应用包
    if [ -d "PhotobookApp/Resources/Stickers" ]; then
        echo "📎 复制内置贴纸资源到 ${ARCH} 应用包..."
        cp -R PhotobookApp/Resources/Stickers "${APP_DIR}/Contents/Resources/"
        STICKER_COUNT=$(ls PhotobookApp/Resources/Stickers/*.png 2>/dev/null | wc -l | tr -d ' ')
        echo "✅ 已复制 ${STICKER_COUNT} 个贴纸到 ${ARCH} 应用包"
    fi

    # 复制图标（如果存在）
    if [ -f "PhotobookApp/Resources/Branding/AppIcon.icns" ]; then
        cp PhotobookApp/Resources/Branding/AppIcon.icns "${APP_DIR}/Contents/Resources/"
        # 添加图标配置到 Info.plist
        sed -i '' 's|</dict>|    <key>CFBundleIconFile</key>\n    <string>AppIcon</string>\n</dict>|' "${APP_DIR}/Contents/Info.plist"
    fi
}

# 函数：创建 DMG
create_dmg() {
    local ARCH=$1
    local APP_DIR="build/PhotobookPro-${ARCH}.app"
    local DMG_DIR="build/dmg-${ARCH}"
    local DMG_NAME="PhotobookPro-${ARCH}.v2.dmg"
    
    echo "💿 创建 ${ARCH} DMG..."
    
    # 创建 DMG 临时文件夹
    mkdir -p "${DMG_DIR}"
    cp -R "${APP_DIR}" "${DMG_DIR}/PhotobookPro.app"
    cp PhotobookApp/DMG_README.md "${DMG_DIR}/README.txt"
    
    # 创建 Applications 快捷方式
    ln -s /Applications "${DMG_DIR}/Applications"
    
    # 创建 DMG
    hdiutil create -volname "PhotobookPro-${ARCH}" \
        -srcfolder "${DMG_DIR}" \
        -ov -format UDZO \
        "${DMG_NAME}"
    
    echo "✅ 已创建 ${DMG_NAME}"
}

# 创建 ARM64 应用包和 DMG
create_app_bundle "ARM64" "PhotobookApp-arm64"
create_dmg "ARM64"

# 创建 x86_64 应用包和 DMG
create_app_bundle "x86_64" "PhotobookApp-x86_64"
create_dmg "x86_64"

echo ""
echo "✅ 构建完成！"
echo ""
echo "📦 DMG 文件:"
echo "   - PhotobookPro-ARM64.v2.dmg (Apple Silicon: M1/M2/M3)"
echo "   - PhotobookPro-x86_64.v2.dmg (Intel)"
echo ""
echo "📊 文件大小:"
ls -lh PhotobookPro-ARM64.v2.dmg PhotobookPro-x86_64.v2.dmg
echo ""
echo "📎 内置贴纸数量:"
ls PhotobookApp/Resources/Stickers/*.png 2>/dev/null | wc -l | tr -d ' '
echo ""
echo "🎉 可以分发给用户了！"
