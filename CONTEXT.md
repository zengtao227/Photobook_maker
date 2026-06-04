# Photobooks Context

## 项目定位

这是照片书编辑与排版软件项目，包含 macOS 客户端、Windows 客户端规划和智能照片处理方案。

核心目标是本地离线完成照片导入、智能分组、布局、编辑和 PDF 导出，强调隐私和跨平台渲染一致性。

## 关键结构

- `PhotobookApp/`: macOS 应用相关目录。
- `PhotobookPro.Windows/`: Windows 客户端主目录。
- `PhotobookPro.Windows.POC/`: Windows POC。
- `AI-Skills-Hub/`: 相关技能或辅助资料。
- `Photobook_V2_Implementation_Plan.md`: V2 智能功能实施计划。
- `PhotobookPro.Windows.Plan.md`: Windows 客户端规划。
- `RELEASE_GUIDE.md`、`RELEASE_NOTES_v2.0.0.md`: 发布说明。
- `*.dmg`: macOS 发布产物。

## 工作规则

- 产品强调本地离线处理，不应上传用户照片、文件名、EXIF 或位置数据。
- 处理布局时优先保证照片完整显示和裁切区域准确。
- Windows 和 macOS 的 project schema、字体、坐标、DPI 和 PDF 输出应保持一致。
- 不要把构建产物、安装包或用户照片纳入无关代码提交。

## 验证要求

- macOS 客户端改动后实际构建或打开应用验证窗口、缩略图、裁剪和 PDF 导出。
- Windows 客户端改动后运行对应 `.sln` 或 `.csproj` 构建。
- PDF/布局相关修改必须导出样例并做视觉检查。
