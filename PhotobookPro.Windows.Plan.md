# PhotobookPro Windows 客户端规划

## 第一性原理分析

### 1. 问题本质
- **现状**：当前 PhotobookPro 是基于 macOS 专有框架构建的桌面应用。
- **根本矛盾**：平台壁垒（SwiftUI/AppKit vs Windows）与开发环境矛盾（Mac 主力 vs Windows 目标）。
- **本质需求**：在 Windows 上提供功能一致的桌面客户端，产出 `.exe`。

### 2. 现有机制审查
- **可复用资产**：领域模型、排版算法逻辑、Swift 项目作为「算法标准」。
- **潜在风险**：绝对路径数据不兼容；CoreLocation/Vision 依赖；字体与渲染差异。

### 3. 约束条件
- **硬约束**：Windows 原生执行；不引入复杂运行时；离线优先。
- **软约束**：优先保证 macOS 开发体验；分阶段交付；保持 Mac/Win 渲染一致性。

---

## 项目总体目标

- **核心目标**：构建功能对齐的 Windows 客户端（导入 -> 布局 -> 编辑 -> 导出 PDF）。
- **交付物**：Windows 安装包 (Inno Setup / MSIX) 或便捷版 (Portable `.zip`)。

### 非目标 (Out of Scope for v1)
为了确保 v1 版本按时交付，以下功能明确列为 **v1 不做**：
- **AI 高级功能**：本地离线人脸识别、聚类、智能美学评分（v1 仅基于时间/位置聚类）。
- **复杂模板编辑器**：不支持自定义设计器，仅支持内置模板库。
- **云端实时同步**：不承诺 iCloud 类实时同步，仅支持文件级迁移。
- **自动更新**：v1 不包含内置自动更新引擎，需手动下载覆盖。

---

## 跨平台数据规范 (Schema & Data)

### 1. Project JSON Schema 规范
为防止 Mac/Win 实现漂移，必须定义严格的 Schema：
- **格式标准**：
  - JSON 采用 `camelCase` 命名风格（与 Swift 默认一致）。
  - 版本号字段 `schemaVersion`: integer (e.g., `1`)。
- **类型定义**：
  - `UUID`: 标准字符串格式（Windows `Guid` 与 Swift `UUID` 互通）。
  - `Date`: ISO 8601 标准字符串 (`yyyy-MM-ddTHH:mm:ssZ`)。
  - `Color`: Hex 字符串 (`#RRGGBB` 或 `#AARRGGBB`)，不存储平台特定对象。
- **兼容策略**：
  - **向前兼容**：遇到未知字段应忽略（非崩溃）。
  - **向后兼容**：新版必须能读取旧版 `schemaVersion`，必要时执行升级逻辑。

### 2. 路径迁移与归档
- **Portable 结构**：推荐使用相对路径 `./Images/photo1.jpg`。
- **迁移向导**：Windows 打开旧 Mac 项目时，检测 `file:///` 绝对路径，引导用户指定新的媒体根目录，自动“重链接”并转换为 Portable 模式。

### 3. 资源与版权 (Resources)
- **字体策略**：
  - **问题**：macOS 默认字体（San Francisco/Helvetica）在 Windows 上不存在，会导致排版严重错乱。
  - **解决方案**：应用内 **Bundle 开源字体**（如 Inter, Roboto, 或 Noto Sans CJK），在渲染引擎中强制加载该字体文件，确保跨平台排版 100% 一致。
- **贴纸/素材**：
  - 资源文件统一打包在 Application 目录下，禁止硬编码路径。
  - 暂时不支持用户导入自定义贴纸（涉及文件管理复杂性）。

---

## 渲染一致性定义 (Rendering Specs)

为了保证 QuestPDF (Win) 与 PDFKit (Mac) 输出结果一致，定义以下物理标准：
- **坐标系**：统一使用 **Point (pt)** 作为逻辑单位。
  - 换算标准：`1 inch = 72 pt`，`1 mm = 2.83465 pt`。
- **DPI 标准**：
  - 屏幕预览：96 DPI (Windows 标准) / 72 DPI (Mac 逻辑)。
  - 印刷导出：**300 DPI**。
- **排版规则**：
  - **出血线 (Bleed)**：默认 3mm (8.5 pt)。
  - **图片处理**：
    - **裁切 (Check)**：Center Crop 策略在两端必须一致。
    - **旋转**：必须正确解析 EXIF `Orientation` 标签。
    - **色彩空间**：v1 导出 sRGB，暂不支持 CMYK 转换（通常由印刷厂通过 RIP 软件处理）。

---

## 性能与技术实施策略 (Performance Strategy)

### 量化指标与技术手段
| 指标 | 目标值 | 技术手段 (Technical Implementation) |
|-----|-------|-------------------------------|
| **冷启动** | < 3s | 延迟加载非核心 DLL；主窗口骨架优先渲染。 |
| **列表滚动** | 60fps | 采用 Avalonia `VirtualizingStackPanel`；缩略图异步解码。 |
| **内存占用** | < 800MB | **虚拟化**：只加载视口内图片；**LRU 缓存**：缩略图缓存池；**大图分级加载**。 |
| **PDF导出** | < 30s | **流式处理**：不一次性加载所有大图进内存；**并行编码**：利用多核 CPU 处理图片压缩。 |

---

## 安全与发布 (Security & Distribution)

### 安全与隐私
- **离线原则**：Windows 客户端完全离线运行，不上传用户照片或元数据到云端。
- **日志脱敏**：Crash Log 中禁止记录照片文件名、路径、Exif 位置信息等敏感数据。

### 发布与安装
- **分发形式**：
  - **v1 交付**：使用 **Inno Setup** 生成标准安装包 (`setup.exe`)。
  - **Beta 交付**：绿色版 ZIP 压缩包。
- **代码签名 (Code Signing)**：
  - **计划**：正式发布前需购买 OV 代码签名证书；测试阶段提供“保留”操作指引。

---

## 开发工作流与跨平台协作

### 1. 技术栈
- **UI**：**Avalonia UI** (首选) / WPF (备选)。
- **PDF**：**QuestPDF** (首选) / PDFsharp (备选)。
- **v0.4 POC**：必须进行 PDF 引擎性能与中文支持的实测竞优。

### 2. 标准开发流程
- **本地开发 (macOS)**：
  - `dotnet run`：主力开发 UI、调试业务逻辑。
  - `dotnet test`：运行核心算法单元测试。
- **验证与 CI (Windows)**：
  - **CI 门禁**：GitHub Actions 必须配置 Windows Runner，执行 Build 和 Test。
  - **人工验证**：发布前必须在真实 Windows 10/11 物理机上测试。

---

## 工程实施细则 (Implementation Guidelines)

为了避免落地过程中的混乱，定义以下具体的工程执行标准：

### 1. 资产同步自动化 (Assets Pipeline)
- **单一数据源**：明确 `PhotobookApp/Resources` (macOS) 为图标与贴纸的唯一源。
- **自动化同步**：
  - 编写 `tools/sync_assets.sh` 脚本。
  - 在 `.csproj` 中配置 `<Target Name="PreBuild" ...>`，构建前自动同步资源，杜绝人工复制导致的版本不一致。

### 2. 遗留数据兼容逻辑
- **无版本号策略**：在解析 JSON 时，若 `schemaVersion` 字段缺失，**强制**按 "Legacy Mac v1.0" 格式处理（使用绝对路经解析逻辑），并触发迁移向导。

### 3. 测试数据共享 (Shared Fixtures)
- **物理位置**：在仓库根目录新建 `Shared/Fixtures/`。
- **读写权限**：
  - Swift 工具 (`GenerateFixtures`) -> **Write** -> `Shared/Fixtures/`
  - C# 测试 (`FixtureLoader`) -> **Read** -> `Shared/Fixtures/`
- **版本控制**：该目录下的 JSON 文件应提交到 Git，作为快照基准 (Snapshot Baseline)。

### 4. 日志标准 (Logging)
- **技术选型**：直接锁定 **Serilog**。
- **配置要求**：
  - 本地开发：Console Sink (控制台高亮输出)。
  - 生产环境：File Sink (按天滚动轮转，保留 7 天)。

### 5. 仓库卫生 (.gitignore)
- **混合规则**：项目根目录 `.gitignore` 必须立即合并标准的 Visual Studio / .NET 规则（忽略 `/bin`, `/obj`, `.vs/`, `*.user` 等），防止第一次提交污染仓库。

---

## 详细工作计划 (Roadmap)

### 阶段 0：技术验证与 POC
1.  **POC 开发 (v0.4)**：Avalonia 原型 + QuestPDF/PDFsharp 竞优（中文、性能）。
2.  **基建**：Swift 生成 Fixtures 工具；C# 测试框架与比较器（Epsilon）。

### 阶段 1：核心模型与数据迁移
3.  初始化 .NET 项目结构与 Log/Git 配置。
4.  **项目格式规范**：实现符合 JSON Schema 的序列化逻辑。
5.  **迁移向导**：开发绝对路径转 Portable 相对路径功能。

### 阶段 2：业务逻辑与测试
6.  移植 `AutoLayoutEngine` 并通过 Fixtures 验证。
7.  实现无 CoreLocation 依赖的几何计算。

### 阶段 3：UI 交互 (Avalonia)
8.  `CanvasView` 开发：虚拟化画布、拖拽交互。
9.  集成 Bundle 字体，确保渲染一致。

### 阶段 4：PDF 导出与发布
10. 实现基于 QuestPDF 的 300 DPI 导出。
11. **打包工程**：编写 Inno Setup 脚本。
12. 真实环境验收与内存泄漏检查。

---

## 风险清单 (Risk Register)

| 风险点 | 影响 | 缓解思路/预案 |
|-------|------|--------------|
| **字体渲染不一致** | 排版错位 | 强制应用内绑定 Google Fonts (如 Inter)，不依赖系统字体。 |
| **代码签名缺失** | 安装包被拦截 | 申请正式证书；测试期提供详细安装指引。 |
| **内存溢出 (OOM)** | 生成大画册 PDF 崩溃 | 采用流式写入 (Streaming) 和分批处理。 |
| **QuestPDF 授权** | 社区版限制商用 | 预留接口层 (IPdfService)，必要时切换引擎。 |
