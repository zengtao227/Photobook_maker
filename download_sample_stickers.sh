#!/bin/bash

# 下载示例贴纸脚本
# 这个脚本会从免费资源网站下载一些示例贴纸到你的Stickers文件夹

STICKER_DIR="$HOME/Library/Application Support/PhotobookPro/Stickers"

# 创建文件夹
mkdir -p "$STICKER_DIR"

echo "📌 开始下载示例贴纸..."
echo "目标文件夹: $STICKER_DIR"
echo ""

# 由于无法直接从这些网站批量下载，这里提供手动下载指南
echo "请手动访问以下网站下载贴纸："
echo ""
echo "1. Flaticon (最推荐):"
echo "   https://www.flaticon.com/free-stickers/cute"
echo "   - 点击喜欢的贴纸包"
echo "   - 选择 PNG 格式"
echo "   - 下载后拖入: $STICKER_DIR"
echo ""
echo "2. StickPNG (完全免费):"
echo "   https://www.stickpng.com/"
echo "   - 搜索: holiday, decorative, cute"
echo "   - 右键保存图片"
echo "   - 保存到: $STICKER_DIR"
echo ""
echo "3. 快速开始包 (推荐下载):"
echo "   - 心形: https://www.stickpng.com/search?q=heart"
echo "   - 星星: https://www.stickpng.com/search?q=star"
echo "   - 花朵: https://www.stickpng.com/search?q=flower"
echo "   - 气球: https://www.stickpng.com/search?q=balloon"
echo ""
echo "✅ 下载完成后，重启 PhotobookPro 即可在'自定义'分类中看到贴纸"
echo ""
echo "💡 提示: 确保下载的是 PNG 格式，且有透明背景"

# 打开Stickers文件夹
open "$STICKER_DIR"
