# Photobook App 本地化与设置改进 - 实现指南

## 📍 你在这里

这是**第4个文档**，包含具体的代码修改步骤。

**前置文档**：
1. README.md - 了解文档结构
2. LOCALIZATION_REQUIREMENTS_SUMMARY.md - 理解问题
3. HANDOFF_PROMPT.md - 获取实现指导

---

## 🎯 实现顺序

按照以下顺序实现，每个问题都有具体步骤：

### 第一阶段（高优先级）
1. **问题2**：语言切换不一致 ← **从这里开始**
2. **问题5**：设置未保存

### 第二阶段（中优先级）
3. **问题1**：不完整的中文汉化
4. **问题3**：印刷术语不清楚
5. **问题4**：模糊术语

---

## 🔴 第一阶段：高优先级问题

### 问题2：语言切换不一致

#### 问题描述
用户切换到英文版本后，某些页面仍显示中文内容：
- 项目旁边的页面标签（"内页1"、"内页2"）仍为中文
- 导出PDF页面的所有选项仍为中文

#### 实现步骤

**步骤1：检查现有本地化系统**

打开文件：`PhotobookApp/Sources/Core/Localization/LocalizationManager.swift`

查看：
- 是否有 `@Published var currentLanguage` 属性
- 是否有语言切换方法
- 是否使用了 `@EnvironmentObject` 或类似的状态管理

**步骤2：找出所有硬编码的中文字符串**

在以下文件中搜索硬编码的中文：
```
PhotobookApp/Sources/Features/Export/ExportSettingsView.swift
PhotobookApp/Sources/Features/ProjectBrowser/
PhotobookApp/Sources/Features/Main/
```

搜索关键词：
- "内页" - 页面标签
- "页面" - 页面相关文本
- "导出" - 导出相关文本
- 任何其他中文字符

**步骤3：创建本地化字符串**

在本地化文件中添加以下字符串（通常是 Localizable.strings 或类似文件）：

```swift
// 页面标签
"page_label" = "页面 %d";  // 中文
"page_label" = "Page %d";  // 英文

// 导出选项
"export_settings" = "导出设置";
"export_settings" = "Export Settings";

"crop_marks" = "剪切线";
"crop_marks" = "Crop Marks";

"registration_marks" = "套准标记";
"registration_marks" = "Registration Marks";

"color_bars" = "色调页面";
"color_bars" = "Color Bars";

"page_info" = "页面信息";
"page_info" = "Page Information";
```

**步骤4：替换硬编码字符串**

在 `ExportSettingsView.swift` 中，将所有硬编码的中文替换为本地化字符串：

```swift
// 修改前
Text("导出设置")

// 修改后
Text(NSLocalizedString("export_settings", comment: "Export settings title"))
```

**步骤5：确保页面标签使用本地化**

在生成页面标签的代码中（通常在 ProjectBrowserView 或类似文件）：

```swift
// 修改前
let pageLabel = "内页\(pageNumber)"

// 修改后
let pageLabel = String(format: NSLocalizedString("page_label", comment: "Page label"), pageNumber)
```

**步骤6：测试语言切换**

```
1. 打开应用
2. 选择英文
3. 检查所有文本是否为英文
4. 特别检查：
   - 导出页面的所有选项
   - 项目旁边的页面标签
   - 所有按钮和菜单项
5. 切换回中文，检查是否都显示中文
```

**验证清单**：
- [ ] 所有导出选项都显示英文/中文
- [ ] 页面标签随语言切换而改变
- [ ] 没有混合的中英文
- [ ] 所有UI元素都响应语言变化

---

### 问题5：设置未保存

#### 问题描述
用户选择的语言设置未被保存，每次打开应用都需要重新选择。

#### 实现步骤

**步骤1：检查 PersistenceManager**

打开文件：`PhotobookApp/Sources/Core/Data/PersistenceManager.swift`

查看：
- 是否有保存用户偏好的方法
- 是否使用了 UserDefaults 或其他持久化方案
- 现有的保存/读取模式

**步骤2：添加语言偏好保存方法**

在 `PersistenceManager.swift` 中添加：

```swift
// 保存语言偏好
func saveLanguagePreference(_ language: String) {
    UserDefaults.standard.set(language, forKey: "selectedLanguage")
}

// 读取语言偏好
func loadLanguagePreference() -> String? {
    return UserDefaults.standard.string(forKey: "selectedLanguage")
}

// 获取默认语言（中文）
func getDefaultLanguage() -> String {
    return "zh-CN"  // 中文
}
```

**步骤3：修改 LocalizationManager**

打开文件：`PhotobookApp/Sources/Core/Localization/LocalizationManager.swift`

在初始化方法中添加：

```swift
class LocalizationManager: ObservableObject {
    @Published var currentLanguage: String = "zh-CN"
    
    init() {
        // 从持久化存储读取语言偏好
        if let savedLanguage = PersistenceManager.shared.loadLanguagePreference() {
            self.currentLanguage = savedLanguage
        } else {
            // 首次启动，使用默认语言（中文）
            self.currentLanguage = PersistenceManager.shared.getDefaultLanguage()
        }
    }
    
    func setLanguage(_ language: String) {
        self.currentLanguage = language
        // 保存到持久化存储
        PersistenceManager.shared.saveLanguagePreference(language)
    }
}
```

**步骤4：修改语言切换UI**

在语言选择的UI代码中（通常在设置或菜单中）：

```swift
// 修改前
@State var selectedLanguage = "zh-CN"

// 修改后
@ObservedObject var localizationManager = LocalizationManager()

// 在语言选择按钮中
Button(action: {
    localizationManager.setLanguage("en")  // 这会自动保存
}) {
    Text("English")
}
```

**步骤5：测试设置保存**

```
1. 打开应用（默认显示中文）
2. 选择英文
3. 关闭应用
4. 重新打开应用
5. 检查是否仍然显示英文
6. 重复：选择中文 → 关闭 → 打开 → 检查中文
```

**验证清单**：
- [ ] 首次启动显示中文
- [ ] 选择英文后，关闭再打开仍显示英文
- [ ] 选择中文后，关闭再打开仍显示中文
- [ ] 设置在应用重启后保持

---

## 🟡 第二阶段：中优先级问题

### 问题1：不完整的中文汉化

#### 问题描述
某些UI元素未被完全汉化，仍保留英文术语。

#### 实现步骤

**步骤1：审查所有UI文本**

在以下目录中搜索所有英文术语：
```
PhotobookApp/Sources/Features/
PhotobookApp/Sources/Views/
```

特别查找：
- `Library` → 应改为 `素材库`
- `Current Spread` → 应改为 `当前页面`
- 其他未翻译的英文术语

**步骤2：创建完整的本地化字符串文件**

创建或更新本地化文件，包含所有术语：

```swift
// 中文 (Localizable.strings - Chinese)
"library" = "素材库";
"current_spread" = "当前页面";
"canvas" = "画布";
"inspector" = "检查器";
"timeline" = "时间线";
"export" = "导出";
"import" = "导入";
// ... 更多术语

// 英文 (Localizable.strings - English)
"library" = "Library";
"current_spread" = "Current Spread";
"canvas" = "Canvas";
"inspector" = "Inspector";
"timeline" = "Timeline";
"export" = "Export";
"import" = "Import";
// ... 更多术语
```

**步骤3：替换所有硬编码的英文**

在所有Swift文件中，将硬编码的英文替换为本地化字符串：

```swift
// 修改前
Text("Library")

// 修改后
Text(NSLocalizedString("library", comment: "Library panel"))
```

**步骤4：测试中文显示**

```
1. 打开应用
2. 选择中文
3. 检查所有UI文本是否为中文
4. 特别检查：Library、Current Spread等术语
5. 确保没有遗漏的英文术语
```

**验证清单**：
- [ ] 所有UI元素都显示中文
- [ ] 没有混合的中英文
- [ ] Library 显示为 "素材库"
- [ ] Current Spread 显示为 "当前页面"

---

### 问题3：印刷术语不清楚

#### 问题描述
导出PDF页面中的专业印刷术语用户无法理解。

#### 实现步骤

**步骤1：找到导出设置UI**

打开文件：`PhotobookApp/Sources/Features/Export/ExportSettingsView.swift`

找到以下选项：
- 剪切线（Crop marks）
- 套准标记（Registration marks）
- 色调页面（Color bars）
- 页面信息（Page information）

**步骤2：添加工具提示**

在SwiftUI中添加 `.help()` 修饰符：

```swift
Toggle("剪切线", isOn: $showCropMarks)
    .help("打印时用于指示裁剪位置的线条。启用此选项可在PDF中显示裁剪标记。")

Toggle("套准标记", isOn: $showRegistrationMarks)
    .help("用于对齐多色印刷的参考标记。启用此选项可在PDF中显示套准标记。")

Toggle("色调页面", isOn: $showColorBars)
    .help("用于检查颜色准确性的参考条。启用此选项可在PDF中显示色调条。")

Toggle("页面信息", isOn: $showPageInfo)
    .help("包含页码、日期等元数据的信息。启用此选项可在PDF中显示页面信息。")
```

**步骤3：添加帮助文本到本地化文件**

```swift
// 中文
"crop_marks_help" = "打印时用于指示裁剪位置的线条。启用此选项可在PDF中显示裁剪标记。";
"registration_marks_help" = "用于对齐多色印刷的参考标记。启用此选项可在PDF中显示套准标记。";
"color_bars_help" = "用于检查颜色准确性的参考条。启用此选项可在PDF中显示色调条。";
"page_info_help" = "包含页码、日期等元数据的信息。启用此选项可在PDF中显示页面信息。";

// 英文
"crop_marks_help" = "Lines that indicate where to crop when printing. Enable this to show crop marks in the PDF.";
"registration_marks_help" = "Reference marks for aligning multi-color printing. Enable this to show registration marks in the PDF.";
"color_bars_help" = "Reference bars for checking color accuracy. Enable this to show color bars in the PDF.";
"page_info_help" = "Metadata information including page numbers and dates. Enable this to show page information in the PDF.";
```

**步骤4：在UI中使用帮助文本**

```swift
Toggle("剪切线", isOn: $showCropMarks)
    .help(NSLocalizedString("crop_marks_help", comment: "Help text for crop marks"))
```

**步骤5：测试帮助文本**

```
1. 打开导出设置
2. 悬停在每个选项上
3. 检查是否显示清晰的解释
4. 理解每个术语的含义
```

**验证清单**：
- [ ] 所有印刷术语都有帮助文本
- [ ] 帮助文本清晰易懂
- [ ] 中文和英文都有相应的解释
- [ ] 悬停时能看到完整的说明

---

### 问题4：模糊术语

#### 问题描述
存在模糊或不清楚的术语，如"初学设置"。

#### 实现步骤

**步骤1：找出所有模糊术语**

在代码中搜索以下术语：
- "初学设置"
- "高级设置"
- "快速设置"
- 其他不清楚的术语

**步骤2：重新定义术语**

将模糊术语改为清晰的术语：

```swift
// 修改前
"初学设置" → "基础设置" 或 "简单模式"
"高级设置" → "高级选项" 或 "专业模式"
"快速设置" → "快速导出" 或 "默认设置"
```

**步骤3：添加清晰的定义**

在本地化文件中添加：

```swift
// 中文
"basic_settings" = "基础设置";
"basic_settings_help" = "使用预设的基础选项进行快速设置。";
"advanced_settings" = "高级选项";
"advanced_settings_help" = "自定义所有导出参数以获得完全控制。";

// 英文
"basic_settings" = "Basic Settings";
"basic_settings_help" = "Quick setup using preset basic options.";
"advanced_settings" = "Advanced Options";
"advanced_settings_help" = "Customize all export parameters for full control.";
```

**步骤4：在UI中使用新术语**

```swift
Section(header: Text(NSLocalizedString("basic_settings", comment: "Basic settings"))) {
    Text(NSLocalizedString("basic_settings_help", comment: "Help text"))
    // 基础设置选项
}

Section(header: Text(NSLocalizedString("advanced_settings", comment: "Advanced settings"))) {
    Text(NSLocalizedString("advanced_settings_help", comment: "Help text"))
    // 高级选项
}
```

**步骤5：测试术语清晰度**

```
1. 打开应用
2. 查找所有之前模糊的术语
3. 检查是否已被替换为清晰的术语
4. 理解每个术语的含义
```

**验证清单**：
- [ ] 所有模糊术语都已被替换
- [ ] 新术语清晰易懂
- [ ] 每个术语都有清晰的定义
- [ ] 中文和英文都一致

---

## ✅ 完成检查清单

### 问题2：语言切换不一致
- [ ] 所有导出选项都显示正确的语言
- [ ] 页面标签随语言切换而改变
- [ ] 没有混合的中英文
- [ ] 所有UI元素都响应语言变化

### 问题5：设置未保存
- [ ] 首次启动显示中文
- [ ] 选择英文后，关闭再打开仍显示英文
- [ ] 选择中文后，关闭再打开仍显示中文
- [ ] 设置在应用重启后保持

### 问题1：不完整的中文汉化
- [ ] 所有UI元素都显示中文
- [ ] 没有混合的中英文
- [ ] Library 显示为 "素材库"
- [ ] Current Spread 显示为 "当前页面"

### 问题3：印刷术语不清楚
- [ ] 所有印刷术语都有帮助文本
- [ ] 帮助文本清晰易懂
- [ ] 中文和英文都有相应的解释
- [ ] 悬停时能看到完整的说明

### 问题4：模糊术语
- [ ] 所有模糊术语都已被替换
- [ ] 新术语清晰易懂
- [ ] 每个术语都有清晰的定义
- [ ] 中文和英文都一致

---

## 🐛 常见问题和解决方案

### 问题：语言切换后某些文本仍未改变
**解决方案**：
1. 检查是否使用了硬编码的字符串
2. 确保使用了 `NSLocalizedString()` 或类似的本地化方法
3. 检查是否需要刷新UI（使用 `@Published` 或 `@State`）

### 问题：设置保存后仍未生效
**解决方案**：
1. 检查 `UserDefaults` 的键名是否正确
2. 确保在应用启动时读取了保存的设置
3. 检查是否需要重新启动应用才能生效

### 问题：本地化字符串未显示
**解决方案**：
1. 检查本地化文件是否正确配置
2. 确保字符串键名与代码中使用的键名一致
3. 检查是否需要清理构建缓存

### 问题：帮助文本未显示
**解决方案**：
1. 检查是否使用了 `.help()` 修饰符
2. 确保在macOS上测试（某些修饰符可能不支持iOS）
3. 检查是否需要在系统设置中启用帮助文本

---

## 📞 需要帮助？

### 如果你遇到问题：
1. 查看"常见问题和解决方案"部分
2. 检查相关的代码文件
3. 参考 HANDOFF_PROMPT.md 中的详细说明

### 如果你需要更多信息：
1. 查看 README.md 中的"文档导航"
2. 查看 LOCALIZATION_REQUIREMENTS_SUMMARY.md 中的相关部分
3. 查看 HANDOFF_PROMPT.md 中的"核心需求"部分

---

## 🎯 下一步

完成所有实现后：
1. ✅ 运行所有测试
2. ✅ 验证所有功能
3. ✅ 检查代码质量
4. ✅ 提交代码审查

---

**最后更新**：2026年1月8日
**项目**：Photobook App 本地化与设置改进
**状态**：实现指南完成，准备开始编码

