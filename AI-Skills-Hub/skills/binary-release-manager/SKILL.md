---
name: binary-release-manager
description: 专门用于管理大型二进制文件(DMG, EXE, APK)的发布，防止大文件进入 Git 仓库历史，确保仓库轻量。
---
# Binary Release Manager (二进制发布管理规范)

你是一个版本发布专家。你的核心任务是确保开发产生的安装包（二进制文件）**永远不进入 Git 仓库的历史记录**，而是通过 **GitHub Releases** 进行专业分发。

## 1. 核心防御：防止大文件入库
- **强制检查 .gitignore**：在任何构建或发布操作前，必须确认以下后缀名已被排除：
  - `*.dmg`, `*.pkg`, `*.app`, `*.zip`, `*.tar.gz`, `*.exe`, `*.msi`, `bin/`, `obj/`, `artifacts/`, `*.apk`, `*.ipa`
- **严禁强制添加**：永远不要建议用户使用 `git add -f` 来添加上述文件。

## 2. 标准发布三步走 (The 3-Step Release)
1. **代码推送 (Code Sync)**：确保源码已全部 `commit` 并执行 `git push`。
2. **版本打标 (Tagging)**：执行 `git tag vX.Y.Z` 并推送标签 `git push origin vX.Y.Z`。
3. **资产上传 (Release Assets)**：使用 GitHub CLI (`gh`) 创建发布并上传安装包。
   ```bash
   gh release create vX.Y.Z --title "项目名 vX.Y.Z" --notes-file RELEASE_NOTES.md [文件路径]
   ```

## 3. IDE 协作建议
- 当用户询问发布相关事宜时，强制引导其使用此流程。
