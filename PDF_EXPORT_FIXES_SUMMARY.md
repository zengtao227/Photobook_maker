# PDF 导出修复总结

## 问题 1：旋转后图片大幅下移（已修复）

### 根本原因
当图层旋转 90 度时，`cropOffset` 是在旋转后的坐标系中应用的，导致偏移方向错乱。

**问题流程：**
1. `ctx.translateBy(x: centerX, y: centerY)` - 移动到中心
2. `ctx.rotate(by: layer.rotation)` - 旋转坐标系 90 度
3. `ctx.translateBy(x: layer.cropOffset.width, y: layer.cropOffset.height)` - 此时 Y 轴已经指向水平方向！

### 修复方案
在应用 `cropOffset` 之前，先将其反向旋转 `layer.rotation`，使其在旋转后的坐标系中保持正确方向。

```swift
// 关键修复：cropOffset 需要反向旋转 layer.rotation
let rotationRadians = -layer.rotation * .pi / 180  // 反向旋转
let adjustedOffsetX = layer.cropOffset.width * Darwin.cos(rotationRadians) - layer.cropOffset.height * Darwin.sin(rotationRadians)
let adjustedOffsetY = layer.cropOffset.width * Darwin.sin(rotationRadians) + layer.cropOffset.height * Darwin.cos(rotationRadians)

ctx.translateBy(x: adjustedOffsetX, y: adjustedOffsetY)
ctx.scaleBy(x: layer.cropScale, y: layer.cropScale)
ctx.rotate(by: Angle(degrees: layer.cropRotation))
```

**修改文件：** `SpreadPDFExporter.swift` - `drawPhotoLayer` 方法

---

## 问题 2：中缝补偿（已实现）

### 背景
胶装（Perfect Binding）时，中缝处会有 3-5mm 的内容被"吞掉"。为了防止人物面部或重要内容掉进装订缝，需要在 PDF 导出时进行中缝补偿。

### 实现方案
在 `ExportableSpreadView` 中添加 3mm 的中缝补偿：

```swift
// 中缝补偿：胶装时中缝处会有 3-5mm 的内容被吞掉
private var spineCompensation: CGFloat { 3 * 2.83465 } // 3mm in points

// 左页向左移动 spineCompensation/2
drawLayer(wrapper, filteredImages: leftFilteredImages, in: context, offsetX: bleed - spineCompensation/2, offsetY: bleed)

// 右页向右移动 spineCompensation/2
drawLayer(wrapper, filteredImages: rightFilteredImages, in: context, offsetX: bleed + trimWidth + spineCompensation/2, offsetY: bleed)
```

**修改文件：** `SpreadPDFExporter.swift` - `ExportableSpreadView` 结构体

---

## 问题 3：页码显示错误（已改进）

### 问题
PDF 页码显示 "Page 8 of 7" 等错误信息。

### 原因
`totalPages` 的计算可能包含了不应该计算的页面。

### 改进
在 `exportBook` 方法中添加更详细的调试日志：

```swift
print("📊 PDF配置:")
print("   pageSize: \(config.pageSize)")
print("   fullPageSize: \(config.fullPageSize)")
print("   includeBleed: \(config.includeBleed)")
print("   总跨页数: \(spreads.count)")  // 新增
```

**修改文件：** `SpreadPDFExporter.swift` - `exportBook` 方法

---

## 技术细节

### 坐标系变换顺序（Canvas 中）

正确的变换顺序应该是：

```
1. translateBy(centerX, centerY)      // 移动到中心点
2. rotate(layer.rotation)              // 图层旋转
3. clip(clipRect)                      // 裁剪
4. translateBy(adjustedOffset)         // 裁剪偏移（已反向旋转）
5. scaleBy(cropScale)                  // 裁剪缩放
6. rotate(cropRotation)                // 裁剪旋转
7. draw(imageRect)                     // 绘制图片
```

### Aspect Fill 逻辑

使用更清晰的计算方式：

```swift
let horizontalScale = frame.width / imageSize.width
let verticalScale = frame.height / imageSize.height
let scale = max(horizontalScale, verticalScale)  // Aspect Fill

let drawWidth = imageSize.width * scale
let drawHeight = imageSize.height * scale
let imageRect = CGRect(x: -drawWidth/2, y: -drawHeight/2, width: drawWidth, height: drawHeight)
```

---

## 测试建议

1. **旋转测试**
   - 在封底添加竖照片
   - 旋转 90 度
   - 导出 PDF 并检查位置是否正确

2. **中缝补偿测试**
   - 在跨页中缝附近放置重要内容（如人物面部）
   - 导出 PDF 并检查内容是否向外侧移动了 3mm

3. **页码测试**
   - 导出多页 PDF
   - 检查页码显示是否正确（Page X of Y）

---

## 相关文件修改

- `PhotobookApp/Sources/Services/SpreadPDFExporter.swift`
  - `drawPhotoLayer` 方法：修复 cropOffset 坐标转换
  - `ExportableSpreadView` 结构体：添加中缝补偿
  - `exportBook` 方法：改进调试日志

