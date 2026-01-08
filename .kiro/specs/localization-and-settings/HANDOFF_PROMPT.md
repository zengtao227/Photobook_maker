# Photobook App 本地化与设置改进 - AI交接Prompt

## 项目背景

Photobook App 是一个macOS照片书制作应用，支持中文和英文两种语言。用户在使用过程中发现了多个本地化和用户体验问题。

**相关文件位置**：
- 本地化管理：`PhotobookApp/Sources/Core/Localization/LocalizationManager.swift`
- 主题管理：`PhotobookApp/Sources/Core/Theme/ThemeManager.swift`
- 导出设置：`PhotobookApp/Sources/Features/Export/ExportSettingsView.swift`
- 持久化管理：`PhotobookApp/Sources/Core/Data/PersistenceManager.swift`

---

## 核心需求

### 需求1：完整的中文汉化
**问题**：某些UI元素未被完全汉化，仍保留英文术语（如Library、Current Spread等）

**任务**：
- 审查所有UI文本
- 将所有英文术语翻译为合适的中文
- 确保中文用户（特别是不懂英文的用户）能够理解所有功能

**示例翻译**：
- `Library` → `素材库` 或 `图书馆`
- `Current Spread` → `当前页面` 或 `当前跨页`

---

### 需求2：语言切换时的完全一致性
**问题**：用户切换到英文版本后，某些页面仍显示中文内容
- 项目旁边的页面标签（"内页1"、"内页2"等）仍为中文
- 导出PDF页面的所有选项仍为中文

**任务**：
- 确保当用户切换语言时，**所有**UI元素都随之改变
- 验证以下页面的完全本地化：
  - 项目浏览器（ProjectBrowserView）
  - 页面导航器（PageNavigatorView）
  - 导出设置（ExportSettingsView）
  - 所有其他UI组件

**验证方法**：
- 切换到英文，检查所有文本是否为英文
- 切换到中文，检查所有文本是否为中文
- 特别关注动态生成的文本（如页面标签）

---

### 需求3：印刷术语的可理解性
**问题**：导出PDF页面中的专业印刷术语用户无法理解

**当前术语**：
- 剪切线（Crop marks）
- 套准标记（Registration marks）
- 色调页面（Color bars）
- 页面信息（Page information）

**任务**：
- 为每个印刷术语添加清晰的解释
- 实现工具提示（tooltips）功能
- 使用通俗易懂的语言解释每个选项的用途
- 可选：添加图示或示例说明各选项的效果

**示例解释**：
- **剪切线**：打印时用于指示裁剪位置的线条
- **套准标记**：用于对齐多色印刷的参考标记
- **色调页面**：用于检查颜色准确性的参考条
- **页面信息**：包含页码、日期等元数据的信息

---

### 需求4：模糊术语的澄清
**问题**：存在模糊或不清楚的术语，如"初学设置"

**任务**：
- 识别所有模糊术语
- 提供清晰的定义和解释
- 考虑使用更直观的术语替代
- 为英文版本也提供清晰的术语

---

### 需求5：用户设置持久化
**问题**：用户选择的语言设置未被保存，每次打开应用都需要重新选择

**任务**：
- 实现用户语言偏好的持久化存储
- 应用启动时读取并应用上次保存的语言设置
- 设置默认语言为中文（首次启动时）
- 用户更改语言后，该设置应在应用重启后保持

**实现位置**：
- 修改 `PersistenceManager.swift` 以支持语言偏好存储
- 修改 `LocalizationManager.swift` 以在启动时恢复设置
- 修改 `ThemeManager.swift` 或相关UI代码以保存用户选择

---

## 实现优先级

### 第一阶段（高优先级）
1. 修复语言切换时的不一致问题
2. 实现用户设置持久化

### 第二阶段（中优先级）
3. 完成中文汉化
4. 添加术语解释和帮助文本

---

## 技术要求

### 开发环境
- 语言：Swift
- 平台：macOS
- 框架：SwiftUI

### 代码规范
- 遵循现有代码风格
- 使用现有的本地化系统
- 确保向后兼容性

### 测试要求
- 测试所有语言切换场景
- 验证设置持久化功能
- 检查所有UI元素的本地化

---

## 文件结构参考

```
PhotobookApp/
├── Sources/
│   ├── Core/
│   │   ├── Localization/
│   │   │   └── LocalizationManager.swift
│   │   ├── Data/
│   │   │   └── PersistenceManager.swift
│   │   └── Theme/
│   │       └── ThemeManager.swift
│   └── Features/
│       ├── Export/
│       │   └── ExportSettingsView.swift
│       ├── ProjectBrowser/
│       │   └── ProjectBrowserView.swift
│       └── ...
```

---

## 交接检查清单

在开始工作前，请确认：
- [ ] 已阅读本Prompt文档
- [ ] 已查看 `LOCALIZATION_REQUIREMENTS_SUMMARY.md`
- [ ] 已检查现有的本地化实现
- [ ] 已理解所有5个核心需求
- [ ] 已确认实现优先级

---

## 预期成果

完成本项目后，应该实现：
1. ✅ 所有UI元素完全本地化（中文和英文）
2. ✅ 语言切换时所有内容同步更新
3. ✅ 用户语言偏好被保存和恢复
4. ✅ 所有专业术语都有清晰的解释
5. ✅ 用户体验流畅，无语言混乱

---

## 联系和问题

如有任何疑问或需要澄清，请参考：
- 原始需求文档：`LOCALIZATION_REQUIREMENTS_SUMMARY.md`
- 现有代码实现：查看上述文件位置
- 用户反馈：本文档中的所有问题描述

