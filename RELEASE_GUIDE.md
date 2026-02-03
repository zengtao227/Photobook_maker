# GitHub Release 创建指南

## 当前待发布的文件

### v2.0.0 版本
- `PhotobookPro-ARM64.v2.dmg` (4.2MB) - Apple Silicon 版本
- `PhotobookPro-x86_64.v2.dmg` (4.2MB) - Intel 版本

---

## 方法一：通过 GitHub 网页创建 Release（推荐）

### 步骤：

1. **访问 Releases 页面**
   - 打开浏览器访问：https://github.com/zengtao227/Photobook_maker/releases
   - 或者在仓库页面点击右侧的 "Releases"

2. **创建新 Release**
   - 点击 "Draft a new release" 按钮

3. **填写 Release 信息**
   - **Tag**: 选择 `v2.0.0`（已创建）
   - **Release title**: `PhotobookPro v2.0.0 - 智能分组与跨平台支持`
   - **Description**: 复制下面的内容

```markdown
## 🎉 PhotobookPro v2.0.0

### ✨ 主要功能

#### 智能分组
- 📅 **时间优先排序**：照片按时间线展开，最早的照片在最前面
- 🎯 **场景识别**：在时间线上自动识别连续的活动和事件
- 🔄 **兼容场景组合**：户外/旅行、人物/活动等智能分组

#### 编辑功能
- ✂️ **单页删除**：支持删除单个页面，自动重组后续页面
- 🖼️ **裁剪优化**：使用绝对几何映射法，确保裁剪区域精确显示
- 🎯 **缩放修复**：左侧角拖拽不再跳动，所有角落缩放流畅

#### 跨平台支持
- 🍎 **macOS 客户端**：支持 Apple Silicon (ARM64) 和 Intel (x86_64)
- 🪟 **Windows 客户端**：基础架构已完成（即将推出）

### 📦 下载

#### macOS 版本
- **Apple Silicon (M1/M2/M3)**: `PhotobookPro-ARM64.v2.dmg`
- **Intel 处理器**: `PhotobookPro-x86_64.v2.dmg`

#### 系统要求
- macOS 11.0 (Big Sur) 或更高版本
- 建议 8GB 内存以上

### 🔧 安装说明

1. 下载对应你 Mac 芯片的 DMG 文件
2. 双击打开 DMG
3. 将 PhotobookPro 拖到 Applications 文件夹
4. 首次打开时，右键点击应用选择"打开"（绕过 Gatekeeper）

### 📝 更新日志

#### 新增功能
- 智能分组按时间线排序，解决照片顺序混乱问题
- 单页删除功能，支持向上取整的跨页计算
- 裁剪显示优化，使用绝对几何映射确保精确度
- Windows 客户端项目架构（开发中）

#### 修复问题
- 修复左侧角拖拽时的跳动问题
- 修复裁剪后缩放导致显示错误的问题
- 修复删除页面后空白页不消失的问题

#### 技术改进
- 添加布局模板 Fixtures 生成器
- 完善跨平台数据迁移向导
- 优化 .gitignore，排除构建产物

### 🐛 已知问题
- Windows 版本尚未发布（开发中）
- 部分场景识别准确度有待提升

### 💬 反馈
如有问题或建议，请在 [Issues](https://github.com/zengtao227/Photobook_maker/issues) 中反馈。
```

4. **上传文件**
   - 在页面底部的 "Attach binaries" 区域
   - 拖拽或点击上传以下文件：
     - `PhotobookPro-ARM64.v2.dmg`
     - `PhotobookPro-x86_64.v2.dmg`

5. **发布**
   - 检查 "Set as the latest release" 已勾选
   - 点击 "Publish release" 按钮

---

## 方法二：使用 GitHub CLI（需要先安装）

### 安装 GitHub CLI

```bash
# macOS
brew install gh

# 登录
gh auth login
```

### 创建 Release 并上传文件

```bash
# 创建 Release
gh release create v2.0.0 \
  --title "PhotobookPro v2.0.0 - 智能分组与跨平台支持" \
  --notes-file RELEASE_NOTES.md \
  PhotobookPro-ARM64.v2.dmg \
  PhotobookPro-x86_64.v2.dmg
```

---

## 方法三：使用 Git LFS（大文件存储）

如果你的 DMG 文件超过 100MB，建议使用 Git LFS：

```bash
# 安装 Git LFS
brew install git-lfs
git lfs install

# 跟踪 DMG 文件
git lfs track "*.dmg"
git add .gitattributes
git commit -m "chore: add Git LFS for DMG files"
git push
```

---

## 未来版本发布流程

### 1. 构建新版本
```bash
# 运行构建脚本
./build_dmg.sh
```

### 2. 创建标签
```bash
git tag -a v2.1.0 -m "Release v2.1.0"
git push origin v2.1.0
```

### 3. 上传到 Release
- 访问 GitHub Releases 页面
- 创建新 Release
- 上传新的 DMG 文件

---

## 注意事项

1. **版本号规范**：遵循语义化版本 (Semantic Versioning)
   - `v2.0.0` - 主版本.次版本.修订号
   - 主版本：不兼容的 API 修改
   - 次版本：向下兼容的功能性新增
   - 修订号：向下兼容的问题修正

2. **文件命名**：保持一致的命名规范
   - `PhotobookPro-{架构}.v{版本}.dmg`
   - 例如：`PhotobookPro-ARM64.v2.0.0.dmg`

3. **Release Notes**：每次发布都应包含
   - 新增功能
   - 修复问题
   - 已知问题
   - 安装说明

4. **Pre-release**：测试版本可以标记为 "Pre-release"
   - 勾选 "This is a pre-release" 选项
   - 用户可以选择是否下载测试版

---

## 当前状态

✅ Git 标签 `v2.0.0` 已创建并推送
⏳ 等待在 GitHub 网页上创建 Release 并上传 DMG 文件

**下一步**：访问 https://github.com/zengtao227/Photobook_maker/releases/new
