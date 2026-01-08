# Photobook App 本地化与设置改进 - 使用说明

## 📁 文档位置

所有相关文档都在以下目录中：
```
.kiro/specs/localization-and-settings/
├── README.md                              ← 你正在读这个文件
├── LOCALIZATION_REQUIREMENTS_SUMMARY.md   ← 需求总结
├── HANDOFF_PROMPT.md                      ← AI交接Prompt
└── IMPLEMENTATION_GUIDE.md                ← 实现指南（本文档后面会创建）
```

---

## 🚀 如何使用这些文档

### 步骤1：理解需求（5分钟）
**打开文件**：`.kiro/specs/localization-and-settings/LOCALIZATION_REQUIREMENTS_SUMMARY.md`

**这个文件告诉你**：
- 用户遇到了什么问题
- 有5个主要问题需要解决
- 每个问题的优先级是什么
- 哪些文件需要修改

**你需要做的**：
- 阅读"问题概述"部分
- 理解"优先级和实现顺序"
- 记住"相关文件和组件"的位置

---

### 步骤2：获取详细指导（10分钟）
**打开文件**：`.kiro/specs/localization-and-settings/HANDOFF_PROMPT.md`

**这个文件告诉你**：
- 每个需求的具体任务是什么
- 如何验证你的工作是否正确
- 代码应该在哪里修改
- 测试应该如何进行

**你需要做的**：
- 按照"核心需求"部分逐个理解
- 查看"实现优先级"确定工作顺序
- 使用"交接检查清单"确保没有遗漏

---

### 步骤3：开始实现（根据需求时间不同）
**参考文件**：`.kiro/specs/localization-and-settings/IMPLEMENTATION_GUIDE.md`（待创建）

**这个文件会告诉你**：
- 具体的代码修改步骤
- 每个文件应该如何修改
- 测试方法和验证步骤

---

## 📊 问题优先级速查表

| 优先级 | 问题 | 文件位置 | 预计工作量 |
|------|------|--------|---------|
| 🔴 高 | 语言切换不一致 | `ExportSettingsView.swift` | 2-3小时 |
| 🔴 高 | 设置未保存 | `PersistenceManager.swift` | 1-2小时 |
| 🟡 中 | 不完整的中文汉化 | 本地化字符串文件 | 1-2小时 |
| 🟡 中 | 印刷术语不清楚 | `ExportSettingsView.swift` | 1-2小时 |
| 🟡 中 | 模糊术语 | 各个UI文件 | 1小时 |

---

## 🎯 快速开始指南

### 如果你是第一次接手这个项目：

1. **第一步**（5分钟）
   ```
   打开：LOCALIZATION_REQUIREMENTS_SUMMARY.md
   阅读：第1-6部分
   ```

2. **第二步**（10分钟）
   ```
   打开：HANDOFF_PROMPT.md
   阅读：项目背景 + 核心需求1-5
   ```

3. **第三步**（开始编码）
   ```
   打开：IMPLEMENTATION_GUIDE.md（待创建）
   按照优先级逐个实现
   ```

### 如果你已经了解项目背景：

1. **直接打开**：`HANDOFF_PROMPT.md`
2. **查看**："实现优先级"部分
3. **开始编码**

---

## 📝 文档内容速览

### LOCALIZATION_REQUIREMENTS_SUMMARY.md 包含：
- ✅ 问题概述
- ✅ 5个具体问题的详细描述
- ✅ 每个问题的需求
- ✅ 优先级和实现顺序
- ✅ 相关文件位置
- ✅ 关键要点总结表

### HANDOFF_PROMPT.md 包含：
- ✅ 项目背景
- ✅ 5个核心需求的详细任务
- ✅ 验证方法
- ✅ 实现优先级
- ✅ 技术要求
- ✅ 文件结构参考
- ✅ 交接检查清单

---

## 🔍 如何找到需要修改的代码

### 问题1：不完整的中文汉化
**查看文件**：
```
PhotobookApp/Sources/Core/Localization/
```
**需要修改**：本地化字符串文件（通常是 .strings 或 .json 文件）

### 问题2：语言切换不一致
**查看文件**：
```
PhotobookApp/Sources/Features/Export/ExportSettingsView.swift
PhotobookApp/Sources/Features/ProjectBrowser/
```
**需要修改**：确保所有UI元素都使用本地化字符串

### 问题3：印刷术语不清楚
**查看文件**：
```
PhotobookApp/Sources/Features/Export/ExportSettingsView.swift
```
**需要修改**：添加工具提示和帮助文本

### 问题4：模糊术语
**查看文件**：
```
PhotobookApp/Sources/Features/
```
**需要修改**：所有包含模糊术语的UI文件

### 问题5：设置未保存
**查看文件**：
```
PhotobookApp/Sources/Core/Data/PersistenceManager.swift
PhotobookApp/Sources/Core/Localization/LocalizationManager.swift
```
**需要修改**：添加语言偏好的保存和恢复逻辑

---

## ✅ 验证你的工作

完成每个问题后，使用以下方法验证：

### 验证问题1（中文汉化）
```
1. 打开应用
2. 选择中文
3. 检查所有UI文本是否为中文
4. 特别检查：Library、Current Spread等术语
```

### 验证问题2（语言切换一致性）
```
1. 打开应用
2. 切换到英文
3. 检查所有页面是否都显示英文
4. 特别检查：导出页面、页面标签
5. 切换回中文，检查是否都显示中文
```

### 验证问题3（印刷术语）
```
1. 打开导出设置
2. 悬停在印刷术语上
3. 检查是否显示清晰的解释
4. 理解每个术语的含义
```

### 验证问题4（模糊术语）
```
1. 搜索"初学设置"等模糊术语
2. 检查是否有清晰的定义
3. 理解每个术语的含义
```

### 验证问题5（设置保存）
```
1. 打开应用，选择英文
2. 关闭应用
3. 重新打开应用
4. 检查是否仍然显示英文
5. 重复：选择中文 → 关闭 → 打开 → 检查中文
```

---

## 📞 需要帮助？

### 如果你不清楚某个问题：
→ 查看 `LOCALIZATION_REQUIREMENTS_SUMMARY.md` 的相应部分

### 如果你不知道如何实现某个需求：
→ 查看 `HANDOFF_PROMPT.md` 的"核心需求"部分

### 如果你需要具体的代码修改步骤：
→ 查看 `IMPLEMENTATION_GUIDE.md`（待创建）

---

## 🎓 学习路径

### 推荐阅读顺序：
1. **本文件**（README.md）- 了解文档结构和使用方法
2. **LOCALIZATION_REQUIREMENTS_SUMMARY.md** - 理解所有问题
3. **HANDOFF_PROMPT.md** - 获取详细的实现指导
4. **IMPLEMENTATION_GUIDE.md** - 开始编码（待创建）

### 预计总时间：
- 阅读文档：20-30分钟
- 理解需求：10-15分钟
- 实现代码：4-6小时
- 测试验证：1-2小时

---

## 📌 重要提示

### ⚠️ 开始前必读：
- [ ] 已阅读本README.md
- [ ] 已理解5个主要问题
- [ ] 已知道实现优先级
- [ ] 已知道相关文件位置

### ⚠️ 实现时注意：
- 按照优先级顺序实现（高优先级先做）
- 每完成一个问题就进行验证
- 不要跳过任何步骤
- 如有疑问，参考相关文档

### ⚠️ 完成后检查：
- [ ] 所有5个问题都已解决
- [ ] 所有验证步骤都已通过
- [ ] 代码符合现有风格
- [ ] 没有引入新的问题

---

## 🔗 文档导航

```
你在这里 → README.md（使用说明）
           ↓
        LOCALIZATION_REQUIREMENTS_SUMMARY.md（需求总结）
           ↓
        HANDOFF_PROMPT.md（实现指导）
           ↓
        IMPLEMENTATION_GUIDE.md（代码步骤）
```

---

**最后更新**：2026年1月8日
**项目**：Photobook App 本地化与设置改进
**状态**：准备就绪，等待实现

