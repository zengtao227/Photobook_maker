# PhotobookPro 开发任务清单 (Roadmap)

## ✅ Phase 1: 核心架构与基础编辑

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

## ✅ Phase 2: 内容丰富与细节完善

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

### 2.3 细节完善与新特性
- [x] **高级滤镜增强**
    - [x] 暗角 (Vignette)
    - [x] 锐化 (Sharpen)
    - [x] 色温 (Temperature)
- [x] **边缘羽化 (Feathering)**
    - [x] Inspector 面板控制
    - [x] Canvas 实时渲染 (Soft Mask)
- [x] **字体优化**
    - [x] 动态加载系统字体
    - [x] 中文字体优先展示
- [x] **贴纸系统 (Stickers)**
    - [x] StickerLayer 数据模型
    - [x] 导入自定义图片作为贴纸
    - [x] 贴纸渲染与交互 (移动/缩放/旋转)

---

## ✅ Phase 3: 图层样式增强

- [x] **边框样式扩展**
    - [x] 实线/虚线/点线/双线
    - [x] 邮票边框 (StampShape)
    - [x] 圆角控制
- [x] **贴纸系统完善**
    - [x] 统一贴纸面板 (Quick Emoji + Modal Picker)
    - [x] 关闭按钮修复
- [x] **代码质量**
    - [x] 消除所有 Color(hex:) 可选值警告

---

## 🚧 Phase 4: 封面、导出与印刷标准 (进行中)

### 4.1 数据结构重构
- [x] **BookStructure 模型**
    - [x] 区分封面 (Front/Back Cover) 与内页 (Inner Pages)
    - [x] 书脊宽度计算 (Spine Width = 页数 × 纸张厚度)
    - [x] 装订类型支持 (软皮/精装/蝴蝶装/骑马钉)
- [x] **EditorState 升级**
    - [x] 导航目标 (EditorNavigationTarget)
    - [x] 封面/内页切换逻辑

### 4.2 导出功能
- [x] **导出 UI**
    - [x] 工具栏导出按钮
    - [x] 导出设置 Modal (ExportSettingsView)
    - [x] DPI 选择 (72/150/300/600)
    - [x] 出血设置 (开/关, 2mm/3mm/5mm)
    - [x] 导出模式 (单页/跨页/印刷全包)
- [x] **印刷标记**
    - [x] 裁切线 (Crop Marks)
    - [x] 套准标记 (Registration Marks)
    - [x] 色条 (Color Bars)
    - [x] 页面信息

### 4.3 页面导航器重构
- [x] **PageNavigatorView 升级**
    - [x] 封面/封底缩略图
    - [x] 书脊指示器
    - [x] 内页与封面视觉分区

### 4.4 待完成
- [ ] **精装全包封面画布**
    - [ ] 全包封面编辑模式 (Back + Spine + Front 连体)
    - [ ] 书脊区域可视化
- [ ] **项目归档**
    - [ ] 导出项目包 (.photobook 文件)

---

## 📅 Phase 5: 打包与发布 (计划中)

### 5.1 应用打包
- [ ] **App 图标**
    - [x] 图标资源准备 (`Resources/Branding/AppIcon.png`)
    - [ ] Asset Catalog 配置 (AppIcon.appiconset)
- [ ] **DMG 打包**
    - [ ] 签名与公证 (Code Signing & Notarization)
    - [ ] DMG 背景图设计
    - [ ] 安装向导

### 5.2 发布准备
- [ ] **文档**
    - [ ] 用户手册
    - [ ] 快捷键参考
- [ ] **测试**
    - [ ] 完整功能测试
    - [ ] 性能优化

---

## 🐛 已知问题 (Bugs)
- [ ] 旋转后的图片在某些极端尺寸下，缩放手柄位置可能有微小偏差 (需复核)
- [ ] 时间轴 (Timeline) 目前仅为占位符，尚未实现具体功能

---

## 📁 资源文件

| 路径 | 说明 |
|------|------|
| `PhotobookApp/Resources/Branding/AppIcon.png` | 应用图标源文件 |

---

*上次更新: 2026-01-08*
