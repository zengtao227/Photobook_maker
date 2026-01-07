# 照片书排版软件需求文档

## 1. 项目背景与目标

### 1.1 项目目标

开发一个桌面照片书排版软件，核心解决以下问题：
1. 每年拍摄大量照片，需要高效整理和筛选
2. 将精选照片按时间顺序排版成可印刷的照片书
3. 输出的格式能直接交给印刷厂（如 posterXXL）打印

## 导航
> ⚠️ **注意**：本项目已拆分为两个阶段性版本，请参考具体的需求文档：
> *   [👉 V1 标准版需求文档 (Standard Edition)](./REQUIREMENTS_V1_STANDARD.md) - 稳健、双主题、经典布局
> *   [👉 V2 未来版需求文档 (Spatial Edition)](./REQUIREMENTS_V2_SPATIAL.md) - 无限画布、自由交互
>
> 以下内容为原始背景调查与调研文档。

### 1.2 核心工作流程

```
照片导入 (NAS/本地硬盘)
    ↓
按月份时间轴浏览
    ↓
每月手动筛选照片 (设定每月页数: 3-5页)
    ↓
自动智能排版
    ↓
添加/编辑文案
    ↓
导出印刷级 PDF
    ↓
提交印刷厂打印
```

### 1.3 平台优先级

1. **macOS** (主要开发平台)
2. **Windows** (后续支持)

### 1.5 posterXXL 技术分析结果

通过对 posterXXL.app（版本 17.0.1, Build 816）的逆向分析，获得以下技术信息：

#### 软件架构
- **开发框架**: macOS 原生 Swift/Objective-C 应用
- **最低系统要求**: macOS 11.0+
- **项目代号**: ME-Editor (Memory Editor)
- **所属公司**: Storio Group (前 Albelli)
- **Bundle ID**: `com.posterxxl.photobooks`

#### 依赖库
- Alamofire (网络请求)
- RxSwift (响应式编程)
- SwiftProtobuf (数据序列化)
- SVGKit (SVG 渲染)
- AppAuth (OAuth 认证)

---

## 2. posterXXL 文件格式分析

### 2.1 项目文件格式

| 属性 | 值 |
|------|-----|
| 文件扩展名 | `.albelli_album` |
| UTType | `nl.albelli.album` |
| 文件类型 | macOS Package (目录包) |
| 存储类型 | Binary (NSPersistentStoreTypeKey) |

### 2.2 项目文件内部结构

```
*.albelli_album/
├── ALBUM.ALB              # 主相册数据文件 (二进制序列化)
├── ALBUM_BACKUP.ALB       # 备份文件
├── [Pictures/]            # 图片资源目录 (推测)
└── [Thumbnails/]          # 缩略图目录 (推测)
```

### 2.3 数据模型

核心类结构：

```
APMAlbum                    # 主相册对象
├── APMAlbumDocument        # 文档容器
├── APMAlbumPage[]          # 页面集合
│   ├── APMAlbumPicture     # 图片对象
│   ├── APMAlbumText        # 文本对象
│   └── APMAlbumObject      # 通用对象基类
└── APMSpread[]             # 跨页集合

属性说明：
- APMAlbumOrientation       # 相册方向 (横版/竖版/方形)
- APMAlbumObjectKind        # 对象类型
- APMLayoutKind             # 布局类型
```

### 2.4 序列化方式

- 使用 `NSCoding` / Swift `Codable` 协议
- 使用 `NSFileWrapper` 包装目录结构
- 支持 `CodableAttributedString` (富文本)
- 支持 `CodableColor` (颜色)

---

## 3. 订单提交流程分析

### 3.1 订单处理流程

```
1. OrderPreparationWorker    # 准备订单数据
2. OrderZipGenerationWorker  # 生成订单 ZIP 包
3. PdfDocumentRenderer       # 渲染 PDF 文件
4. OrderUploadWorker         # 上传订单
5. OrderShopWorker           # 提交到商店
```

### 3.2 API 端点

| 用途 | URL |
|------|-----|
| 照片存储 API | `https://storage.organise.photos/api/v1` |
| 配置服务 | `https://s3-eu-west-1.amazonaws.com/me-configuration` |

### 3.3 上传格式

- **Content-Type**: `multipart/form-data`
- **订单包格式**: `application/vnd.app+zip`
- **API 数据格式**: `application/json`
- **临时文件**: `temp.zip`

### 3.4 渲染输出

| 格式 | 用途 |
|------|------|
| PDF | 打印订单主文件 (`APMPdfDocumentRenderer`) |
| JPEG | 预览图/交叉销售图片 (`XSellJPGCreator`) |

---

## 4. 印刷商研究

### 4.1 重要发现：posterXXL 不支持 PDF 上传

经过调研发现，**posterXXL 的照片书服务不接受用户上传 PDF**：
- 只接受图片格式：JPG, TIF, BMP, JP2
- 必须使用他们的官方软件编辑后提交
- 无公开 API

### 4.2 支持 PDF 上传的印刷商（德国）

| 印刷商 | A6 支持 | 最大页数 | 纸张 | 价格（100页）| PDF 上传 |
|--------|---------|----------|------|--------------|----------|
| **Fotofabrik** | ✅ | 100页 | 200g | ~€30 | ✅ 任意软件 |
| **epubli** | ✅ | 600+页 | 170g | ~€20 | ✅ 任意软件 |
| **CEWE** | ✅ | 300页 | - | ~€25 | ⚠️ 需 InDesign |

### 4.3 推荐印刷商：Fotofabrik

**选择理由**：
1. **A6 Hardcover** 最多 100 页，符合需求
2. **200g 纸张** — 比 epubli (170g) 更厚实，照片质感更好
3. **德国自有工厂** — 质量可控
4. **接受任意软件生成的 PDF** — 无需 InDesign

**Fotofabrik A6 Hardcover 规格**：
- 尺寸：14.8 × 10.5 cm
- 页数：24-100 页
- 基础价：€11.24（含 24 页，促销价）
- 加页：€0.25/页
- 100 页总价：约 €30

**参考链接**：
- Fotofabrik A6 Hardcover: https://www.fotofabrik.de/produkte/fotobuecher/hardcover/a6-querformat/
- epubli A6: https://www.epubli.com/buch/din-a6
- CEWE PDF 上传: https://www.cewe.de/cewe-fotobuch-von-pdf-bestellen.html

---

## 5. 兼容性策略

### 5.1 方案评估

#### 方案 A: 完全兼容 .albelli_album 格式
- **优点**: 可直接用 posterXXL 应用打开编辑
- **缺点**: 需要完全逆向二进制格式，工作量大，版本兼容风险高

#### 方案 B: 生成 PDF 直接上传 (推荐)
- **优点**: PDF 是标准格式，posterXXL 明确支持 PDF 生成
- **缺点**: 可能需要手动通过 posterXXL 应用导入

#### 方案 C: 使用 posterXXL Web API
- **优点**: 官方支持，稳定性好
- **缺点**: 需要认证，可能有 API 限制

### 6.2 推荐方案

**采用 PDF 导出 + Fotofabrik 上传**：
1. 生成符合 Fotofabrik 规格的 PDF（300 DPI，A6 尺寸）
2. 手动上传到 Fotofabrik 网站下单
3. 备选：epubli（页数更多）或 CEWE（需 InDesign）

---

## 6. 软件需求规格

### 6.1 核心功能需求

#### 6.1.1 照片导入与浏览

**照片来源**:
- [ ] 本地硬盘文件夹
- [ ] NAS 网络存储（SMB/AFP）
- [ ] 支持格式: JPEG, PNG, HEIC, TIFF, RAW

**时间轴浏览**:
- [ ] 自动读取照片 EXIF 拍摄时间
- [ ] 按月份分组显示照片
- [ ] 显示每月照片数量统计
- [ ] 支持年度视图切换

#### 6.1.2 照片筛选

**手动筛选**:
- [ ] 点击选择/取消选择照片
- [ ] 批量选择（框选、全选当月）
- [ ] 显示已选照片数量
- [ ] 预览已选照片集合

**AI 辅助功能**（可选，需要 API）:
- [ ] 场景分类（风景、人物、美食、建筑等）
- [ ] 人脸识别与分组（识别同一人）
- [ ] 智能推荐（避免重复、模糊照片）

#### 6.1.3 智能排版

**页数设定**:
- [ ] 为每月指定页数（如 3-5 页）
- [ ] 自动根据选中照片数量和页数进行排版
- [ ] 支持调整单张照片大小和位置

**布局模板**:
- [ ] 预设多种布局模板（1图/2图/3图/4图/6图等）
- [ ] 智能选择最佳布局组合
- [ ] 支持手动切换布局

**跨页支持**:
- [ ] 左右页联动显示
- [ ] 跨页大图支持

#### 6.1.4 文案编辑

- [ ] 每页添加文本框
- [ ] AI 生成文案建议（基于时间、地点、场景）
- [ ] 手动编辑/修改文案
- [ ] 字体、大小、颜色设置
- [ ] 月份/日期自动标注

#### 6.1.5 导出功能

- [ ] 导出印刷级 PDF（300 DPI）
- [ ] 导出预览 PDF（72 DPI，小文件）
- [ ] 项目文件保存/加载（.photobook 格式）
- [ ] 导出 JPEG 单页预览

### 6.2 非功能需求

#### 6.2.1 打印规格兼容

| 参数 | 值 |
|------|-----|
| 分辨率 | 300 DPI（印刷标准）|
| 色彩空间 | sRGB / Adobe RGB |
| 出血 | 3mm |
| PDF 版本 | PDF 1.5+ |

#### 6.2.2 自定义尺寸支持

用户可自定义任意尺寸，常见预设：

| 名称 | 尺寸 (mm) | 适用场景 |
|------|-----------|----------|
| A4 横版 | 297 x 210 | 大型精装相册 |
| A4 竖版 | 210 x 297 | 大型精装相册 |
| A5 横版 | 210 x 148 | 中型相册（常用） |
| A5 竖版 | 148 x 210 | 中型相册（常用） |
| A6 横版 | 148 x 105 | 便携小册子 |
| 方形 (L) | 300 x 300 | 正方形大本 |
| 方形 (M) | 210 x 210 | 正方形中本 |
| 方形 (S) | 150 x 150 | 正方形小本 |
| 自定义 | 用户输入 | 任意尺寸 |

### 6.3 技术选型分析

#### 方案对比

| 方案 | 优点 | 缺点 | AI 依赖 |
|------|------|------|---------|
| **Swift (原生 macOS)** | 性能最佳，系统集成好 | 仅限 Mac，需重写 Windows 版 | 可选 |
| **Tauri (Rust + Web)** | 跨平台，体积小 | Rust 学习曲线高 | 可选 |
| **Electron** | 跨平台，Web 技术栈 | 体积大，内存占用高 | 可选 |
| **Python + PyQt** | 跨平台，开发快速 | 分发复杂，性能一般 | 可选 |

#### 推荐方案: Swift 原生 (macOS 优先)

由于你主要使用 Mac，且需要处理大量照片，**Swift 原生应用**是最佳选择：

| 组件 | 推荐技术 | 说明 |
|------|----------|------|
| UI 框架 | SwiftUI | 现代声明式 UI |
| PDF 生成 | PDFKit / Core Graphics | 原生高性能 |
| 图像处理 | Core Image | GPU 加速 |
| EXIF 读取 | ImageIO | 原生支持 |
| 文件监控 | FSEvents | 实时同步 NAS |

### 6.4 AI 功能说明

#### 哪些功能需要 AI API？

| 功能 | 是否需要 AI | 说明 |
|------|-------------|------|
| 照片时间轴排序 | **否** | 读取 EXIF 元数据即可 |
| 照片筛选 | **否** | 手动点选 |
| 自动排版 | **否** | 基于规则的布局算法 |
| PDF 导出 | **否** | 系统 API |
| 场景分类 | **是** | 需要视觉 AI 模型 |
| 人脸识别 | **是/否** | macOS 有内置 Vision 框架 |
| 文案生成 | **是** | 需要 LLM API |

#### 无 AI 的最小可用版本

**核心功能不需要任何 AI API**，以下功能完全可以本地实现：

1. ✅ 照片导入和时间轴浏览
2. ✅ 按月份筛选照片
3. ✅ 基于模板的自动排版
4. ✅ 手动调整布局
5. ✅ 添加/编辑文字
6. ✅ 导出印刷级 PDF

#### 可选的 AI 增强功能

如需 AI 功能，可后续添加：

| 功能 | 实现方式 | 成本 |
|------|----------|------|
| 场景分类 | Apple Vision 框架 | 免费（本地） |
| 人脸识别 | Apple Vision 框架 | 免费（本地） |
| 智能推荐 | Core ML 本地模型 | 免费（本地） |
| 文案生成 | Claude/GPT API | 按量付费 |

---

## 7. 开发路线图

### Phase 1: MVP（最小可用版本）

**目标**: 能用、能导出

1. 照片文件夹导入
2. 读取 EXIF 并按月份分组显示
3. 点击选择照片
4. 固定模板自动排版（每页 2-4 张）
5. 导出 PDF

**预计工作量**: 基础版本

### Phase 2: 完善排版

**目标**: 好用

1. 多种布局模板
2. 拖拽调整照片位置和大小
3. 添加文本框
4. 自定义页面尺寸
5. 项目保存/加载

### Phase 3: AI 增强

**目标**: 智能化

1. 场景分类（Vision 框架）
2. 人脸识别分组
3. 文案生成建议
4. 智能布局推荐

### Phase 4: 跨平台

**目标**: Windows 支持

1. 评估迁移方案（Tauri/Electron）
2. 开发 Windows 版本
3. 云同步功能（可选）

---

## 8. 附录

### 8.1 posterXXL 软件分析文件

分析过程中提取的关键字符串和类名保存在：
- 应用路径：`posterXXL.app/Contents/MacOS/posterXXL`
- Bundle ID：`com.posterxxl.photobooks`
- 版本：17.0.1 (Build 816)

### 8.2 GitHub 开源项目参考

| 项目 | 语言 | 描述 | 适用性 |
|------|------|------|--------|
| [PhotobookCreator](https://github.com/SwiftProgrammingCookbook/PhotobookCreator) | Swift | 将照片转为 PDF 照片书，演示长时间操作的响应式处理 | ⭐⭐⭐ 可参考 |
| [photo-book](https://github.com/justincwatt/photo-book) | - | 生成 5x7" PDF 照片书用于印刷 | ⭐⭐ 布局硬编码 |
| [THEphotobook](https://github.com/an-dr-eas-k/THEphotobook) | LaTeX + PowerShell | 按拍摄时间排序照片，自动生成 PDF | ⭐⭐ 思路可参考 |
| [photobook](https://github.com/gborgonovo/photobook) | HTML/CSS + Smarty | 基于 paper-css 生成 PDF，用 Puppeteer 渲染 | ⭐⭐ Web 方案 |
| [photo-album-maker](https://github.com/sillsdevarchive/photo-album-maker) | Python + Scribus | 驱动 Scribus 创建相册 | ⭐ 依赖 Scribus |
| [pdfme](https://github.com/pdfme/pdfme) | TypeScript + React | 开源 PDF 生成库，WYSIWYG 模板设计器 | ⭐⭐⭐ 可用于 Web 版 |

**最相关的项目**：
1. **PhotobookCreator (Swift)** — 最接近我们需求，可作为起点
2. **THEphotobook** — 按时间排序的思路可参考
3. **pdfme** — 如果后续做 Web/Electron 版本可用

### 8.3 相关资源

- posterXXL 官网：https://www.posterxxl.de
- Storio Group (母公司)
- 存储 API：https://storage.organise.photos/api/v1

### 8.4 待确认事项

1. [x] posterXXL 是否提供公开 API 文档？ → **否，不支持 PDF 上传**
2. [ ] Fotofabrik PDF 上传的具体技术要求
3. [ ] 封面和书脊的具体尺寸计算公式
4. [ ] 不同纸张类型对应的色彩配置

---

## 9. 常见问题解答

### Q1: 核心功能需要联网吗？
**不需要**。照片导入、排版、PDF 导出都是本地完成的。只有可选的 AI 文案生成功能需要联网。

### Q2: 为什么选择 Swift 而不是 Tauri？
1. 处理大量照片时，原生性能更好
2. 系统 Vision 框架可免费提供人脸识别和场景分类
3. NAS 访问更稳定（原生 SMB/AFP 支持）
4. 你主要使用 Mac，优先保证 Mac 体验

### Q3: Windows 版怎么办？
Phase 4 会评估跨平台方案。届时可以：
- 用 Tauri/Electron 重写一个跨平台版本
- 或者用 Swift Playgrounds for Windows（如果支持）

### Q4: 能直接上传到 posterXXL 吗？
目前的策略是生成印刷级 PDF，手动上传到 posterXXL 或其他印刷厂。
posterXXL 没有公开 API，自动上传需要逆向工程（复杂且可能违反 ToS）。

### Q5: 我的照片很多，软件会卡吗？
Swift 原生应用配合：
- 缩略图缓存
- 懒加载（只加载可见区域）
- 后台线程处理
可以流畅处理数万张照片。

---

*文档版本: 1.2*
*创建日期: 2026-01-06*
*更新日期: 2026-01-06*
*基于 posterXXL.app v17.0.1 分析*
*新增：印刷商研究、GitHub 开源项目参考*
