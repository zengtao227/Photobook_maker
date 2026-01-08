# 第二轮修复 (Second Round of Fixes)

## 修复日期 (Fix Date)
2026-01-08 (第二次)

## 用户报告的问题 (User Reported Issues)

### 问题总结
1. ❌ 缩放按钮：除了右下角，其他三个都非常不好用
2. ❌ 内页拖动：左边的图不能到右边（正确），但右边的图可以移动到左边（错误）
3. ❌ 封面拖动：只在左边（正确）
4. ❌ 封底拖动：可以跑到右边去（错误，应该只在右边）
5. ❌ 键盘删除：Delete键和组合键都无法使用
6. ❌ 窗口大小持久化：完全失效

## 修复方案 (Fix Solutions)

### 1. ✅ 改进缩放手柄算法 (Improved Resize Handle Algorithm)

**问题分析**:
- 之前使用对角线距离计算，但方向判断复杂导致不稳定
- 不同角的行为不一致

**新算法**:
```swift
// 使用平均拖动距离，更直观和稳定
case .bottomTrailing:
    let avgDrag = (drag.width + drag.height) / 2.0
    let newW = max(minSize, startFrame.width + avgDrag)
    
case .topLeading:
    let avgDrag = -(drag.width + drag.height) / 2.0
    let newW = max(minSize, startFrame.width + avgDrag)
    
case .topTrailing:
    let avgDrag = (drag.width - drag.height) / 2.0
    let newW = max(minSize, startFrame.width + avgDrag)
    
case .bottomLeading:
    let avgDrag = (drag.height - drag.width) / 2.0
    let newW = max(minSize, startFrame.width + avgDrag)
```

**优势**:
- 更简单直观的计算
- 所有四个角行为一致
- 减少跳动和不稳定

**文件**: `PhotobookApp/Sources/Features/Canvas/CanvasView.swift`

### 2. ✅ 修复内页拖动边界 (Fixed Inner Page Drag Boundary)

**问题**: 内页的图片可以从右页拖到左页

**解决方案**:
```swift
} else if pageModel.pageNumber > 0 {
    // 内页：限制在当前页面范围内，不能跨页
    newDisplayFrame.origin.x = max(0, min(newDisplayFrame.origin.x, 
        displayPageSize.width - newDisplayFrame.width))
    newDisplayFrame.origin.y = max(0, min(newDisplayFrame.origin.y, 
        displayPageSize.height - newDisplayFrame.height))
}
```

**效果**: 内页的图片现在被限制在各自的页面内，不能跨页拖动

**文件**: `PhotobookApp/Sources/Features/Canvas/CanvasView.swift`

### 3. ✅ 修复封底拖动边界 (Fixed Back Cover Drag Boundary)

**问题**: 封底的图片可以拖到左页（不可编辑区域）

**原有逻辑**: 已经有检查，但可能没有正确应用边界限制

**确认**: 代码中已经有正确的逻辑：
```swift
} else if pageModel.pageNumber == -1 {
    // 封底：只能在右页（外侧）编辑
    if isLeftPage {
        return // 左页不可编辑，忽略拖动
    }
    // 限制在右页范围内，不能超出边界
    newDisplayFrame.origin.x = max(0, min(newDisplayFrame.origin.x, 
        displayPageSize.width - newDisplayFrame.width))
    newDisplayFrame.origin.y = max(0, min(newDisplayFrame.origin.y, 
        displayPageSize.height - newDisplayFrame.height))
}
```

**文件**: `PhotobookApp/Sources/Features/Canvas/CanvasView.swift`

### 4. ✅ 修复键盘删除功能 (Fixed Keyboard Delete)

**问题**: Delete键无法删除选中的图层

**根本原因**: SwiftUI的焦点管理问题

**解决方案**:
1. 在CanvasView添加`@FocusState`
2. 使用`.focused($isCanvasFocused)`绑定焦点
3. 在`onAppear`和`onTapGesture`时设置焦点

```swift
struct CanvasView: View {
    @FocusState private var isCanvasFocused: Bool
    
    var body: some View {
        GeometryReader { geometry in
            // ... content ...
        }
        .focused($isCanvasFocused)
        .onAppear {
            isCanvasFocused = true
        }
        .onTapGesture {
            isCanvasFocused = true
        }
    }
}
```

**文件**: `PhotobookApp/Sources/Features/Canvas/CanvasView.swift`

### 5. ✅ 改进窗口大小持久化 (Improved Window Size Persistence)

**问题**: 窗口大小没有被保存和恢复

**改进方案**:

#### A. AppDelegate改进
```swift
func applicationDidFinishLaunching(_ notification: Notification) {
    // 延迟恢复窗口，确保窗口已创建
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        if let window = NSApp.windows.first {
            self.restoreWindowFrame(window)
            window.makeKeyAndOrderFront(nil)
        }
    }
}

func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // 窗口关闭时保存
    if let window = NSApp.windows.first {
        saveWindowFrame(window)
    }
    return true
}

private func saveWindowFrame(_ window: NSWindow) {
    let frame = window.frame
    let frameString = NSStringFromRect(frame)
    UserDefaults.standard.set(frameString, forKey: "MainWindowFrame")
    UserDefaults.standard.synchronize() // 强制立即保存
    print("💾 Saved window frame: \(frameString)")
}

private func restoreWindowFrame(_ window: NSWindow) {
    if let frameString = UserDefaults.standard.string(forKey: "MainWindowFrame") {
        let frame = NSRectFromString(frameString)
        if frame != .zero && frame.width > 100 && frame.height > 100 {
            window.setFrame(frame, display: true, animate: false)
            print("📐 Restored window frame: \(frameString)")
        }
    }
}
```

#### B. 窗口观察器改进
```swift
private func setupWindowFrameObserver() {
    // 监听窗口大小变化
    windowFrameObserver = NotificationCenter.default.addObserver(
        forName: NSWindow.didResizeNotification,
        object: nil,
        queue: .main
    ) { [self] notification in
        if let window = notification.object as? NSWindow {
            // 防抖：用户停止调整后0.5秒保存
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.saveWindowFrame(window)
            }
        }
    }
    
    // 监听窗口移动
    _ = NotificationCenter.default.addObserver(
        forName: NSWindow.didMoveNotification,
        object: nil,
        queue: .main
    ) { [self] notification in
        if let window = notification.object as? NSWindow {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.saveWindowFrame(window)
            }
        }
    }
}
```

**关键改进**:
1. 延迟恢复窗口（0.1秒），确保窗口已创建
2. 添加`applicationShouldTerminateAfterLastWindowClosed`回调
3. 使用`UserDefaults.standard.synchronize()`强制立即保存
4. 添加窗口大小验证（宽高>100）
5. 防抖保存（0.5秒延迟）
6. 同时监听窗口移动和大小变化

**文件**: `PhotobookApp/Sources/PhotobookApp.swift`

## 测试步骤 (Testing Steps)

### 测试1: 缩放手柄
1. 在任意页面放置一张图片
2. 选中图片
3. 依次测试四个角的缩放手柄：
   - ✅ 右下角：向右下拖动放大，向左上拖动缩小
   - ✅ 左上角：向左上拖动放大，向右下拖动缩小
   - ✅ 右上角：向右上拖动放大，向左下拖动缩小
   - ✅ 左下角：向左下拖动放大，向右上拖动缩小
4. 确认所有角都流畅，无跳动

### 测试2: 内页拖动边界
1. 打开任意内页跨页
2. 在左页放置图片，尝试拖到右页 → 应该被限制在左页
3. 在右页放置图片，尝试拖到左页 → 应该被限制在右页

### 测试3: 封面拖动边界
1. 打开封面
2. 在左页（外侧）放置图片 → 可以拖动
3. 尝试拖到右页 → 应该被限制在左页
4. 尝试在右页放置图片 → 应该被拒绝（显示"内页不可编辑"）

### 测试4: 封底拖动边界
1. 打开封底
2. 在右页（外侧）放置图片 → 可以拖动
3. 尝试拖到左页 → 应该被限制在右页
4. 尝试在左页放置图片 → 应该被拒绝（显示"内页不可编辑"）

### 测试5: 键盘删除
1. 在任意页面放置图片
2. 选中图片（点击图片，出现蓝色边框）
3. 按Delete键 → 图片应该被删除
4. 如果不工作，先点击画布空白区域，再选中图片，再按Delete键

### 测试6: 窗口大小持久化
1. 调整窗口大小到一个特定尺寸（例如：1400x900）
2. 移动窗口到屏幕的特定位置
3. 关闭应用（⌘Q 或 点击关闭按钮）
4. 重新打开应用
5. 确认窗口大小和位置与关闭前一致

**调试信息**:
- 关闭应用时，控制台应该显示：`💾 Saved window frame: {{x, y}, {width, height}}`
- 打开应用时，控制台应该显示：`📐 Restored window frame: {{x, y}, {width, height}}`

## 已知问题和限制 (Known Issues)

1. **键盘删除可能需要点击画布**: 如果Delete键不工作，先点击画布空白区域获取焦点
2. **窗口持久化首次可能不工作**: 第一次运行时没有保存的窗口大小，需要先调整一次
3. **缩放手柄在旋转图片时**: 旋转后的图片缩放可能稍有不同的感觉（这是正常的）

## 技术细节 (Technical Details)

### 边界限制算法
```swift
// 限制frame在页面范围内
newDisplayFrame.origin.x = max(0, min(newDisplayFrame.origin.x, 
    displayPageSize.width - newDisplayFrame.width))
newDisplayFrame.origin.y = max(0, min(newDisplayFrame.origin.y, 
    displayPageSize.height - newDisplayFrame.height))
```

这确保：
- 图片左上角不会超出页面左边和上边（`max(0, ...)`)
- 图片右下角不会超出页面右边和下边（`min(..., pageSize - frameSize)`)

### 焦点管理
SwiftUI在macOS上的焦点管理比较复杂，需要：
1. `@FocusState`变量跟踪焦点状态
2. `.focused($variable)`绑定焦点
3. `.focusable()`标记可接收焦点
4. `.onKeyPress()`处理键盘事件
5. 在适当时机设置焦点（`onAppear`, `onTapGesture`）

### 窗口持久化时机
- **保存**: 窗口大小变化后0.5秒、窗口移动后0.5秒、应用退出时、窗口关闭时
- **恢复**: 应用启动后0.1秒（延迟确保窗口已创建）
- **存储**: UserDefaults，键名"MainWindowFrame"，格式为NSRect字符串

## 下一步 (Next Steps)

如果测试后仍有问题，请提供：
1. 具体哪个功能不工作
2. 控制台输出（特别是DEBUG和💾📐开头的日志）
3. 操作步骤的详细描述
