# 坐标系统和窗口状态修复计划

## 问题总结

### 问题1：封底两页都不能编辑 ✅ 已定位
**根本原因**：
- 封底的pageNumber是-1
- dropDestination检查`pageNumber >= 0`
- 导致封底被误判为不可编辑

**解决方案**：
- 修改判断逻辑：`pageNumber == -98 || pageNumber == -99` 才是空白页
- 封底(-1)和封面(0)都应该可以编辑

---

### 问题2：竖图左上角缩放有问题 ✅ 已定位
**根本原因**：
- 当前算法使用平均拖动距离：`(drag.width + drag.height) / 2`
- 对于竖图（高>宽），这个算法不够精确

**解决方案**：
- 使用对角线距离计算缩放比例
- 或者使用主要拖动方向（宽度或高度中较大的那个）

---

### 问题3：图片位置在重新打开后偏移 ⚠️ 核心问题
**根本原因**：
- 图层的frame是相对于Canvas的**显示尺寸**（geometry.size）
- Canvas的显示尺寸会随窗口大小变化
- 保存的是显示坐标，加载时显示尺寸不同，导致位置偏移

**当前流程**：
```
编辑时：
1. 窗口大小：1200x800
2. Canvas显示尺寸：800x600（自动计算）
3. 页面逻辑尺寸：148x105mm
4. 图片frame：CGRect(x: 100, y: 100, width: 200, height: 150)
   ↑ 这是相对于800x600的显示坐标

保存：
- 保存frame: (100, 100, 200, 150)

重新打开：
1. 窗口大小：1000x700（不同了！）
2. Canvas显示尺寸：600x450（变小了！）
3. 页面逻辑尺寸：148x105mm（不变）
4. 加载frame：(100, 100, 200, 150)
   ↑ 但现在Canvas只有600x450，位置就错了！
```

**解决方案A：使用逻辑坐标系统**（推荐）
```swift
// 定义：页面逻辑尺寸（固定，不随窗口变化）
let logicalPageSize = CGSize(width: 148, height: 105) // mm
// 或转换为points: 148mm * 2.83465 = 419.5pt

// 编辑时：
// 1. 用户拖动图片到Canvas上的位置(100, 100)
// 2. 计算Canvas的缩放比例
let scale = canvasDisplaySize.width / logicalPageSize.width
// scale = 800 / 419.5 = 1.907

// 3. 转换为逻辑坐标
let logicalX = 100 / scale = 52.4
let logicalY = 100 / scale = 52.4
let logicalFrame = CGRect(x: 52.4, y: 52.4, width: 104.8, height: 78.6)

// 4. 保存逻辑坐标
save(logicalFrame) // 相对于419.5x297.6pt的逻辑页面

// 加载时：
// 1. 加载逻辑坐标
let logicalFrame = load() // (52.4, 52.4, 104.8, 78.6)

// 2. 计算当前Canvas的缩放比例
let scale = canvasDisplaySize.width / logicalPageSize.width
// scale = 600 / 419.5 = 1.430

// 3. 转换为显示坐标
let displayX = logicalFrame.x * scale = 74.9
let displayY = logicalFrame.y * scale = 74.9
let displayFrame = CGRect(x: 74.9, y: 74.9, width: 149.9, height: 112.4)

// 4. 显示图片
// 图片在页面上的相对位置保持不变！
```

**解决方案B：保存窗口状态**（辅助）
```swift
// 保存窗口状态到UserDefaults
struct WindowState: Codable {
    var windowSize: CGSize
    var leftPanelWidth: CGFloat
    var rightPanelWidth: CGFloat
}

// 重新打开时恢复窗口状态
// 这样Canvas的显示尺寸也会恢复
// 但这只是辅助方案，核心还是要用逻辑坐标
```

---

## 实施计划

### 第一步：修复问题1（封底编辑）
文件：`PhotobookApp/Sources/Features/Canvas/CanvasView.swift`
```swift
// 修改dropDestination的判断
.dropDestination(for: URL.self) { items, location in
    // 只有-98和-99是空白占位页
    guard pageModel.pageNumber != -98 && pageModel.pageNumber != -99 else {
        print("DEBUG: Cannot drop on blank placeholder page")
        return false
    }
    // ... rest of code
}
```

### 第二步：修复问题2（竖图缩放）
文件：`PhotobookApp/Sources/Features/Canvas/CanvasView.swift`
```swift
// 修改SelectionBorder的updateFrame方法
case .topLeading:
    // 使用对角线距离
    let diagonal = sqrt(drag.width * drag.width + drag.height * drag.height)
    let direction = (drag.width + drag.height) < 0 ? -1.0 : 1.0
    let change = diagonal * direction
    let newW = max(minSize, startFrame.width - change)
    // ... rest of code
```

### 第三步：实现逻辑坐标系统（核心）
需要修改多个文件：

#### 3.1 在BookContext中添加逻辑尺寸（points）
文件：`PhotobookApp/Sources/Core/Data/BookContext.swift`
```swift
public var logicalPageSizeInPoints: CGSize {
    let mm = currentSize
    // 1mm = 2.83465 points
    return CGSize(
        width: mm.width * 2.83465,
        height: mm.height * 2.83465
    )
}
```

#### 3.2 在BookPage中计算缩放比例
文件：`PhotobookApp/Sources/Features/Canvas/CanvasView.swift`
```swift
struct BookPage: View {
    // ...
    var body: some View {
        GeometryReader { geometry in
            // 计算缩放比例
            let logicalSize = bookContext.logicalPageSizeInPoints
            let displaySize = geometry.size
            let scale = displaySize.width / logicalSize.width
            
            // 传递给InteractiveLayer
            // ...
        }
    }
}
```

#### 3.3 在InteractiveLayer中使用缩放比例
文件：`PhotobookApp/Sources/Features/Canvas/CanvasView.swift`
```swift
struct InteractiveLayer: View {
    let scale: CGFloat // 新增参数
    
    var body: some View {
        // 将逻辑坐标转换为显示坐标
        let displayFrame = CGRect(
            x: photoLayer.frame.x * scale,
            y: photoLayer.frame.y * scale,
            width: photoLayer.frame.width * scale,
            height: photoLayer.frame.height * scale
        )
        
        // 使用displayFrame显示
        // 但保存时仍然保存photoLayer.frame（逻辑坐标）
    }
}
```

#### 3.4 在EditorState中使用逻辑坐标
文件：`PhotobookApp/Sources/Features/Canvas/EditorState.swift`
```swift
// addPhotoLayer方法
func addPhotoLayer(photo: Photo, isLeftPage: Bool, center: CGPoint, scale: CGFloat) {
    // center是显示坐标，需要转换为逻辑坐标
    let logicalCenter = CGPoint(
        x: center.x / scale,
        y: center.y / scale
    )
    
    // 使用逻辑坐标创建frame
    let logicalFrame = CGRect(...)
    
    // 保存逻辑坐标
    let newLayer = PhotoLayer(photoId: photo.id, photoUrl: photo.url, frame: logicalFrame)
}
```

### 第四步：保存窗口状态（可选）
文件：新建`PhotobookApp/Sources/Core/Data/WindowStateManager.swift`
```swift
struct WindowState: Codable {
    var windowFrame: CGRect
    var leftPanelWidth: CGFloat
    var rightPanelWidth: CGFloat
}

class WindowStateManager {
    static func save(_ state: WindowState) {
        // 保存到UserDefaults
    }
    
    static func load() -> WindowState? {
        // 从UserDefaults加载
    }
}
```

---

## 测试计划

### 测试1：封底编辑
1. 打开封底页面
2. 拖动图片到右页（封底外面）- 应该成功
3. 拖动图片到左页（空白内页）- 应该失败并提示

### 测试2：竖图缩放
1. 添加一张竖图（高>宽）
2. 拖动左上角手柄缩小 - 应该流畅
3. 拖动左上角手柄放大 - 应该流畅
4. 对比横图缩放 - 应该一致

### 测试3：位置保存
1. 添加多张图片到不同位置
2. 调整窗口大小（变大或变小）
3. 关闭应用
4. 重新打开应用（窗口大小可能不同）
5. 检查图片位置 - 应该与关闭前相对位置一致

### 测试4：窗口状态
1. 调整窗口大小和三列宽度
2. 关闭应用
3. 重新打开应用
4. 检查窗口大小和布局 - 应该恢复到关闭前的状态

---

## 风险评估

### 高风险：坐标系统改动
- 影响范围：所有图层操作（拖动、缩放、旋转）
- 需要仔细测试所有交互
- 可能影响现有项目的兼容性

### 中风险：缩放算法改动
- 只影响左上角手柄
- 容易测试和验证

### 低风险：封底编辑判断
- 只改一行代码
- 影响范围小

---

## 兼容性考虑

### 旧项目兼容
- 旧项目的frame可能是显示坐标
- 需要检测并转换
- 或者添加版本号标记

### 建议方案：
```swift
// 在ProjectData中添加版本号
struct ProjectData: Codable {
    var version: Int = 2 // 新版本使用逻辑坐标
    // ...
}

// 加载时检查版本
if data.version < 2 {
    // 转换旧坐标到新坐标
    convertOldCoordinates(data)
}
```

---

## 实施优先级

1. **问题1（封底）** - 简单，立即修复
2. **问题2（竖图缩放）** - 中等，优先修复
3. **问题3（坐标系统）** - 复杂，需要仔细实施
4. **窗口状态** - 可选，最后实施

---

**预计工作量**：
- 问题1：5分钟
- 问题2：15分钟
- 问题3：2-3小时（需要仔细测试）
- 窗口状态：30分钟

**总计**：约3-4小时
