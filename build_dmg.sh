#!/bin/bash

# PhotobookPro DMG 打包脚本
# 支持 Apple Silicon (M1/M2/M3) 和 Intel (x86_64)

set -e

echo "🚀 开始构建 PhotobookPro..."

# 清理旧的构建
echo "🧹 清理旧构建..."
rm -rf build
rm -rf PhotobookPro.dmg

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

# 合并为 Universal Binary
echo "🔗 合并为 Universal Binary..."
lipo -create \
    build/PhotobookApp-arm64 \
    build/PhotobookApp-x86_64 \
    -output build/PhotobookApp

# 验证架构
echo "📋 验证支持的架构:"
lipo -info build/PhotobookApp

# 创建 .app 包结构
echo "📦 创建应用包..."
mkdir -p build/PhotobookPro.app/Contents/MacOS
mkdir -p build/PhotobookPro.app/Contents/Resources

# 复制可执行文件
cp build/PhotobookApp build/PhotobookPro.app/Contents/MacOS/PhotobookPro
chmod +x build/PhotobookPro.app/Contents/MacOS/PhotobookPro

# 创建 Info.plist
cat > build/PhotobookPro.app/Contents/Info.plist << 'EOF'
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
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>© 2026 PhotobookPro</string>
</dict>
</plist>
EOF

# 复制图标（如果存在）
if [ -f "PhotobookApp/Resources/Branding/AppIcon.icns" ]; then
    cp PhotobookApp/Resources/Branding/AppIcon.icns build/PhotobookPro.app/Contents/Resources/
    echo '<key>CFBundleIconFile</key>' >> build/PhotobookPro.app/Contents/Info.plist
    echo '<string>AppIcon</string>' >> build/PhotobookPro.app/Contents/Info.plist
fi

# 创建 DMG 临时文件夹
echo "📦 准备 DMG 内容..."
mkdir -p build/dmg
cp -R build/PhotobookPro.app build/dmg/
cp PhotobookApp/DMG_README.md build/dmg/README.txt

# 创建 Applications 快捷方式
ln -s /Applications build/dmg/Applications

# 创建 DMG
echo "💿 创建 DMG 安装包..."
hdiutil create -volname "PhotobookPro" \
    -srcfolder build/dmg \
    -ov -format UDZO \
    PhotobookPro.dmg

echo ""
echo "✅ 构建完成！"
echo "📦 DMG 文件: PhotobookPro.dmg"
echo ""
echo "支持的架构:"
lipo -info build/PhotobookPro.app/Contents/MacOS/PhotobookPro
echo ""
echo "🎉 可以分发给用户了！"
echo ""
echo "📊 文件大小:"
ls -lh PhotobookPro.dmg

