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
- [x] **图片裁剪 (Crop)**
    - [x] 全屏裁剪编辑器 (CropEditor)
    - [x] 裁剪状态持久化 (normalizedCropRect)
    - [x] 裁剪内旋转独立于画布旋转 (cropRotation)
    - [x] 等比例缩放手柄
- [x] **图片滤镜 (Filters)**
    - [x] 基础滤镜 (黑白, 复古, 铬黄, 褪色, 即时, 黑色电影, 冲印, 单色调, 转印)
    - [x] 调整参数 (亮度, 对比度, 饱和度)
    - [x] 实时预览
- [x] **边框与阴影**
    - [x] 可调节边框宽度/颜色
    - [x] 阴影设置 (半径/透明度)
    - [x] Inspector 面板实时控制

### 2.2 文字编辑功能
- [x] **添加文字图层**
    - [x] Inspector 面板添加文字按钮 (左页/右页)
    - [x] Canvas 渲染文字图层
    - [x] 支持拖拽、移动、删除
- [x] **文字属性**
    - [x] 字体、字号、颜色
    - [x] 加粗、斜体
    - [x] 对齐方式 (左/中/右)
    - [x] 双击进入内联编辑模式
    - [x] Inspector 面板实时属性调整

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
