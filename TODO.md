# PhotobookPro 开发任务清单 (Roadmap)

## ✅ Phase 1: 核心架构与基础编辑 (当前阶段)

### 1.1 项目架构
- [x] **基础 UI 框架** (NavigationSplitView: Library, Canvas, Inspector)
- [x] **数据持久化系统** (PersistenceManager)
- [x] **多项目管理架构**
    - [x] 项目数据结构升级 (ProjectMetadata)
    - [x] 项目浏览器 UI (ProjectBrowserView)
    - [x] 项目创建/打开/关闭流程
- [x] **自动保存系统**
    - [x] 实时编辑节流保存 (每分钟)
    - [x] App 生命周期保存 (切后台/关闭)
    - [x] 项目切换保存
    - [x] 移除会导致歧义的手动保存按钮

### 1.2 画布与图片编辑
- [x] **基础拖拽** (从 Library 拖入 Canvas)
- [x] **图片操作**
    - [x] 选中 (SelectionBorder)
    - [x] 移动 (DragGesture)
    - [x] 缩放 (Resize Handles)
    - [x] 旋转 (Rotation Handle)
- [x] **图层管理**
    - [x] 删除图层 (快捷键/右键)
    - [x] 图层层级调整 (移到最前/最后/上下移动)

### 1.3 macOS 兼容性适配
- [x] **输入系统修复**
    - [x] 解决命令行启动导致的焦点丢失 (NSApp Activation Policy)
    - [x] 封装原生 NSTextField (MacTextField) 解决中文输入法崩溃问题
- [x] **窗口管理**
    - [x] 强制应用激活 (NSApp.activate)

---

## 🚧 Phase 2: 内容丰富与细节完善 (进行中)

### 2.1 高级图片编辑
- [ ] **图片裁剪 (Crop)**
    - [ ] 遮罩裁剪 (Masking) 或 原图裁剪
    - [ ] 裁剪模式 UI
- [ ] **图片滤镜 (Filters)**
    - [ ] 基础滤镜 (黑白, 复古等)
    - [ ] 调整参数 (亮度, 对比度)
- [ ] **边框与阴影**
    - [ ] 可调节边框宽度/颜色
    - [ ] 阴影设置

### 2.2 文字编辑功能
- [ ] **添加文字图层**
    - [ ] 文本框工具
    - [ ] 双击编辑文字 (需复用 MacTextField 经验)
- [ ] **文字属性**
    - [ ] 字体、字号、颜色
    - [ ] 对齐方式

---

## 📅 Phase 3: 导出与生产
- [ ] **PDF 导出**
    - [ ] 高分辨率渲染
    - [ ] 打印出血线支持
- [ ] **项目归档**
    - [ ] 导出项目包 (.photobook 文件)

---

## 🐛 已知问题 (Bugs)
- [ ] 旋转后的图片在某些极端尺寸下，缩放手柄位置可能有微小偏差 (需复核)
- [ ] 时间轴 (Timeline) 目前仅为占位符，尚未实现具体功能

---

*上次更新: 2026-01-07*
