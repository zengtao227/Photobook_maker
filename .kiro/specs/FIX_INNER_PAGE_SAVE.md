# 修复内页保存问题 (Fix Inner Page Save Issue)

## 问题描述 (Problem Description)

**症状**: 内页的照片没有被保存，关闭应用后重新打开，内页的内容都消失了
**封面和封底**: 正常保存和恢复
**内页**: 照片丢失

## 根本原因 (Root Cause)

在保存项目时，没有先调用`editorState.saveCurrentState()`方法。

### 工作流程说明

EditorState维护两个状态：
1. **当前编辑状态**: `leftPage`和`rightPage` - 用户正在编辑的页面
2. **完整书籍结构**: `bookStructure` - 包含所有页面（封面、封底、所有内页）

当用户切换页面时：
- `saveCurrentState()` - 将当前的leftPage/rightPage保存回bookStructure
- `loadCurrentState()` - 从bookStructure加载新页面到leftPage/rightPage

**问题**: 保存项目时直接保存了bookStructure，但没有先调用`saveCurrentState()`，导致：
- 用户正在编辑的页面（leftPage/rightPage）的修改没有被写回bookStructure
- 只有bookStructure被保存到文件
- 结果：当前页面的修改丢失

### 为什么封面和封底正常？

因为用户在测试时可能：
1. 编辑封面 → 切换到内页（此时封面被保存）
2. 编辑封底 → 切换到内页（此时封底被保存）
3. 编辑内页 → 直接关闭应用（内页没有被保存！）

## 解决方案 (Solution)

在保存项目之前，先调用`editorState.saveCurrentState()`确保当前编辑的页面被保存到bookStructure。

### 修改1: saveCurrentProject()

```swift
private func saveCurrentProject() {
    guard let project = currentProject else { return }
    
    // CRITICAL: Save current editing state to bookStructure before persisting
    editorState.saveCurrentState()
    
    PersistenceManager.shared.save(
        project: project,
        bookContext: bookContext,
        editorState: editorState,
        photoStore: photoStore
    )
}
```

### 修改2: closeProject()

```swift
private func closeProject() {
    guard let project = currentProject else { return }
    
    // Save current editing state before closing
    editorState.saveCurrentState()
    saveCurrentProject()
    
    currentProject = nil
    showProjectBrowser = true
    
    // Clear state
    editorState.leftPage = PageModel(pageNumber: 0)
    editorState.rightPage = PageModel(pageNumber: 1)
    photoStore.allPhotos = []
    
    print("Closed project: \(project.name)")
}
```

## 测试步骤 (Testing Steps)

### 测试1: 内页保存
1. 打开或创建一个项目
2. 导航到内页（跨页1）
3. 在左页和右页各放置一张照片
4. 调整照片位置和大小
5. 等待2秒（自动保存）
6. 关闭应用（⌘Q）
7. 重新打开应用
8. 打开同一个项目
9. 导航到跨页1
10. ✅ 确认：两张照片都在，位置和大小正确

### 测试2: 多个内页
1. 创建多个内页（跨页1、跨页2、跨页3）
2. 在每个跨页放置不同的照片
3. 在跨页之间切换（确保每个跨页都被保存）
4. 最后停留在跨页3
5. 关闭应用
6. 重新打开
7. ✅ 确认：所有跨页的照片都保存了，包括跨页3

### 测试3: 封面+内页+封底
1. 封面左页放置照片A
2. 跨页1左页放置照片B
3. 跨页1右页放置照片C
4. 封底右页放置照片D
5. 停留在封底页面
6. 关闭应用
7. 重新打开
8. ✅ 确认：所有照片都在（A、B、C、D）

### 测试4: 自动保存
1. 在内页放置照片
2. 等待2秒（触发自动保存）
3. 控制台应该显示：`🔄 Auto-saved project at ...`
4. 不关闭应用，直接强制退出（模拟崩溃）
5. 重新打开应用
6. ✅ 确认：照片被保存了（因为自动保存）

## 技术细节 (Technical Details)

### EditorState的状态管理

```
用户操作流程：
1. 用户在跨页1编辑 → leftPage/rightPage包含跨页1的内容
2. 用户点击跨页2 → 
   a. saveCurrentState() - 将leftPage/rightPage保存到bookStructure.innerSpreads[0]
   b. loadCurrentState() - 从bookStructure.innerSpreads[1]加载到leftPage/rightPage
3. 用户在跨页2编辑 → leftPage/rightPage包含跨页2的内容
4. 保存项目 →
   a. saveCurrentState() - 将leftPage/rightPage保存到bookStructure.innerSpreads[1]
   b. 保存bookStructure到文件
```

### 保存时机

现在有三个保存时机都会调用`saveCurrentState()`:

1. **切换页面时** - `navigateTo()` → `saveCurrentState()`
2. **自动保存时** - `autoSaveCurrentProject()` → `saveCurrentProject()` → `saveCurrentState()`
3. **关闭项目时** - `closeProject()` → `saveCurrentState()` → `saveCurrentProject()`

这确保了无论用户在哪个页面，当前的修改都会被保存。

### 为什么之前封面和封底能保存？

因为用户在测试时的操作顺序：
1. 编辑封面 → 切换到内页 → `saveCurrentState()`被调用 → 封面保存 ✅
2. 编辑封底 → 切换到内页 → `saveCurrentState()`被调用 → 封底保存 ✅
3. 编辑内页 → 直接关闭 → `saveCurrentState()`没被调用 → 内页丢失 ❌

现在修复后：
3. 编辑内页 → 直接关闭 → `closeProject()`调用`saveCurrentState()` → 内页保存 ✅

## 日志输出 (Log Output)

保存时应该看到：
```
✅ Saved project: test
```

如果是自动保存：
```
🔄 Auto-saved project at 2026-01-08 16:36:57 +0000
✅ Saved project: test
```

打开项目时：
```
✅ Loaded project: test
✅ Opened project: test with X spreads
```

## 相关文件 (Related Files)

- `PhotobookApp/Sources/PhotobookApp.swift` - 添加了`saveCurrentState()`调用
- `PhotobookApp/Sources/Features/Canvas/EditorState.swift` - 定义了`saveCurrentState()`方法
- `PhotobookApp/Sources/Core/Data/PersistenceManager.swift` - 负责实际的文件保存
- `PhotobookApp/Sources/Core/Data/BookStructure.swift` - 定义了bookStructure的编码/解码

## 总结 (Summary)

这是一个经典的"忘记同步状态"问题。修复很简单，但影响很大：
- **修复前**: 只有切换页面后的内容被保存
- **修复后**: 所有页面的内容都被正确保存，包括当前正在编辑的页面

现在用户可以放心编辑任何页面，无论是否切换页面，内容都会被保存。
