# macOS 桌面应用开发最佳实践指南

> 本文档记录了在开发 PhotobookPro 过程中积累的关键 macOS 开发经验，特别是解决 SwiftUI 兼容性和焦点问题的方案。

## 1. 解决"幽灵窗口"与键盘输入穿透问题

### 现象
- App 窗口可见，但无法接收键盘输入。
- 输入的字符会直接穿透到 App 背后的 IDE（Xcode/VSCode）或终端中。
- 点击输入框无反应，或无法删除文字。
- App 在 Dock 栏没有图标。

### 原因
通过命令行（`swift build` -> `swift run` 或 Debug 二进制）启动的 App，macOS 默认将其视为 **Accessory Process**（辅助进程）而非标准的 GUI 应用程序。因此，系统不会赋予其 Key Window 状态和键盘焦点。

### 解决方案 ✅
必须在 `AppDelegate` 中显式设置 Activation Policy 为 `.regular`，并强制激活 App。

```swift
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 关键：告诉系统我们是一个正常的 GUI App，需要 Dock 图标和键盘焦点
        NSApp.setActivationPolicy(.regular)
        
        // 强制抢占焦点
        NSApp.activate(ignoringOtherApps: true)
        
        // 确保主窗口成为 Key Window
        DispatchQueue.main.async {
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }
    }
}

@main
struct MyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    // ...
}
```

---

## 2. 也是最稳健的输入框方案：Wrapped NSTextField

### 现象
- 在 SwiftUI 的 `.overlay`、`.sheet` 或自定义 Modal 中，`TextField` 无法聚焦。
- 输入中文时，选词窗口（ViewBridge）崩溃或报错 `RemoteViewService Terminated`。
- `@FocusState` 失效。

### 原因
SwiftUI 的 `TextField` 在 macOS 上的实现依赖于复杂的 ViewBridge 机制，特别是在非标准层级（如 ZStack Overlay）中容易丢失焦点上下文。

### 解决方案 ✅
**绝不犹豫，直接使用 AppKit 的 `NSTextField` 封装。**

1. 创建 `MacTextField` (NSViewRepresentable)。
2. 在 `updateNSView` 中加入自动聚焦逻辑：
```swift
DispatchQueue.main.async {
    if let window = nsView.window, 
       window.firstResponder != nsView.currentEditor() && window.firstResponder != nsView {
        window.makeFirstResponder(nsView)
    }
}
```
3. 这种方案直接绕过 SwiftUI 事件层，直接与 Window Server 通信，稳健性 100%。

---

## 3. 模态弹窗的最佳实践

### 现象
- 使用原生 `.sheet` 时，焦点容易丢失。
- 弹窗背景没有遮罩，UI 层次感差。

### 解决方案 ✅
在 Desktop App 中，使用 **ZStack 全屏 Overlay** 往往比原生 `.sheet` 更可控。

1. **层级**：将 Overlay 放在 `WindowGroup` 的最外层 ZStack，确保覆盖所有内容。
2. **背景**：添加 `Color.black.opacity(0.4)` 阻挡点击。
3. **关闭**：避免在 Overlay 内部使用 `@Environment(\.dismiss)`（会导致崩溃），而是传递 `onCancel` 回调给父视图控制状态。

---

*生成时间：2026-01-07*
