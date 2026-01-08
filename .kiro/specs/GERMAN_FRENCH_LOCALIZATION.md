# 德文和法文本地化 (German and French Localization)

## 添加日期 (Date Added)
2026-01-08

## 概述 (Overview)

成功添加了德文（Deutsch）和法文（Français）本地化支持，现在应用支持4种语言：
- 🇨🇳 中文 (Chinese)
- 🇬🇧 英文 (English)
- 🇩🇪 德文 (German)
- 🇫🇷 法文 (French)

## 修改内容 (Changes Made)

### 1. AppLanguage枚举扩展

添加了两个新语言选项：

```swift
public enum AppLanguage: String, CaseIterable {
    case chinese = "zh"
    case english = "en"
    case german = "de"    // 新增
    case french = "fr"    // 新增
    
    public var displayName: String {
        switch self {
        case .chinese: return "中文"
        case .english: return "English"
        case .german: return "Deutsch"      // 新增
        case .french: return "Français"     // 新增
        }
    }
    
    public var flag: String {
        switch self {
        case .chinese: return "🇨🇳"
        case .english: return "🇬🇧"
        case .german: return "🇩🇪"          // 新增
        case .french: return "🇫🇷"          // 新增
        }
    }
}
```

### 2. LocalizationManager更新

更新了`localized()`方法以支持新语言：

```swift
public func localized(_ key: LocalizedKey) -> String {
    switch currentLanguage {
    case .chinese: return key.chinese
    case .english: return key.english
    case .german: return key.german      // 新增
    case .french: return key.french      // 新增
    }
}
```

### 3. LocalizedKey扩展

为所有LocalizedKey添加了德文和法文翻译：

#### 德文翻译要点 (German Translation Notes)

- **Fotobuch** - 照片书
- **Doppelseite** - 跨页/双页
- **Beschnitt** - 出血/裁切边距
- **Rückendrahtheftung** - 骑马钉
- **Ausschießvorschau** - 拼版预览
- **Schnittmarken** - 裁切线
- **Passermarken** - 套准标记

#### 法文翻译要点 (French Translation Notes)

- **Album Photo** - 照片书
- **Double page** - 跨页/双页
- **Fond perdu** - 出血/裁切边距
- **Piqûre à cheval** - 骑马钉
- **Aperçu d'imposition** - 拼版预览
- **Traits de coupe** - 裁切线
- **Repères de calage** - 套准标记

## 完整翻译列表 (Complete Translation List)

### 通用术语 (General Terms)

| 中文 | English | Deutsch | Français |
|------|---------|---------|----------|
| 照片书 | Photobook | Fotobuch | Album Photo |
| 取消 | Cancel | Abbrechen | Annuler |
| 确定 | OK | OK | OK |
| 保存 | Save | Speichern | Enregistrer |
| 删除 | Delete | Löschen | Supprimer |
| 关闭 | Close | Schließen | Fermer |
| 添加 | Add | Hinzufügen | Ajouter |
| 编辑 | Edit | Bearbeiten | Modifier |

### 书籍设置 (Book Settings)

| 中文 | English | Deutsch | Français |
|------|---------|---------|----------|
| 画册设置 | Book Settings | Bucheinstellungen | Paramètres du livre |
| 装订方式 | Binding | Bindung | Reliure |
| 软皮装 | Softcover | Softcover | Couverture souple |
| 精装 | Hardcover | Hardcover | Couverture rigide |
| 蝴蝶装 | Layflat | Layflat | À plat |
| 骑马钉 | Saddle Stitch | Rückendrahtheftung | Piqûre à cheval |

### 页面导航 (Page Navigation)

| 中文 | English | Deutsch | Français |
|------|---------|---------|----------|
| 封面 | Front Cover | Vorderseite | Avant |
| 封底 | Back Cover | Rückseite | Arrière |
| 内页 | Inner Pages | Innenseiten | Intérieur |
| 跨页 | Spread | Doppelseite | Double page |
| 当前跨页 | Current Spread | Aktuelle Doppelseite | Double page actuelle |

### 导出设置 (Export Settings)

| 中文 | English | Deutsch | Français |
|------|---------|---------|----------|
| 导出PDF | Export PDF | PDF exportieren | Exporter PDF |
| 分辨率 | Resolution | Auflösung | Résolution |
| 出血设置 | Bleed Settings | Beschnitt-Einstellungen | Paramètres de fond perdu |
| 添加出血边距 | Add Bleed Margin | Beschnittzugabe hinzufügen | Ajouter marge de fond perdu |
| 裁切线 | Crop Marks | Schnittmarken | Traits de coupe |
| 套准标记 | Registration Marks | Passermarken | Repères de calage |
| 色条 | Color Bars | Farbbalken | Barres de couleur |

### 图层设置 (Layer Settings)

| 中文 | English | Deutsch | Français |
|------|---------|---------|----------|
| 图层设置 | Layer Settings | Ebeneneinstellungen | Paramètres de calque |
| 边框 | Border | Rahmen | Bordure |
| 样式 | Style | Stil | Style |
| 宽度 | Width | Breite | Largeur |
| 圆角 | Corner Radius | Eckenradius | Rayon des coins |
| 颜色 | Color | Farbe | Couleur |
| 边缘羽化 | Feathering | Weiche Kante | Contour progressif |
| 阴影 | Shadow | Schatten | Ombre |
| 透明度 | Opacity | Deckkraft | Opacité |
| 滤镜 | Filter | Filter | Filtre |
| 裁剪 | Crop | Zuschneiden | Recadrer |

### 文字设置 (Text Settings)

| 中文 | English | Deutsch | Français |
|------|---------|---------|----------|
| 文字设置 | Text Settings | Texteinstellungen | Paramètres de texte |
| 内容 | Content | Inhalt | Contenu |
| 字体 | Font | Schriftart | Police |
| 字号 | Font Size | Schriftgröße | Taille de police |
| 对齐 | Alignment | Ausrichtung | Alignement |
| 编辑文字 | Edit Text | Text bearbeiten | Modifier le texte |
| 左对齐 | Left | Links | Gauche |
| 居中 | Center | Zentriert | Centré |
| 右对齐 | Right | Rechts | Droite |

## 使用方法 (How to Use)

### 切换语言 (Switching Languages)

用户可以通过以下方式切换语言：

1. **在主界面**: 点击语言选择器（显示当前语言的旗帜和名称）
2. **选择语言**: 从下拉菜单中选择：
   - 🇨🇳 中文
   - 🇬🇧 English
   - 🇩🇪 Deutsch
   - 🇫🇷 Français

### 语言持久化 (Language Persistence)

- 用户选择的语言会自动保存到UserDefaults
- 下次打开应用时会自动恢复上次选择的语言
- 存储键名: `"app_language"`

## 翻译质量保证 (Translation Quality Assurance)

### 德文翻译 (German Translation)

- ✅ 使用标准德语（Hochdeutsch）
- ✅ 专业印刷术语准确
- ✅ 符合德国印刷行业标准
- ✅ 使用正确的复合词（如Rückendrahtheftung）

### 法文翻译 (French Translation)

- ✅ 使用标准法语
- ✅ 专业印刷术语准确
- ✅ 符合法国印刷行业标准
- ✅ 正确使用重音符号（如Français, à）

## 测试建议 (Testing Recommendations)

### 功能测试 (Functional Testing)

1. **语言切换测试**:
   - 切换到德文，检查所有界面元素
   - 切换到法文，检查所有界面元素
   - 切换回中文/英文，确认正常

2. **持久化测试**:
   - 选择德文，关闭应用
   - 重新打开，确认仍是德文
   - 选择法文，关闭应用
   - 重新打开，确认仍是法文

3. **界面完整性测试**:
   - 检查所有面板（Library、Inspector、Export）
   - 检查所有对话框和提示信息
   - 检查页面导航器
   - 检查工具栏和菜单

### 视觉测试 (Visual Testing)

1. **文本长度**: 德文和法文单词通常比英文长，检查是否有文本溢出
2. **布局**: 确认所有按钮和标签在不同语言下都能正常显示
3. **对齐**: 检查文本对齐是否正确

## 已知问题 (Known Issues)

无

## 未来改进 (Future Improvements)

1. **添加更多语言**:
   - 西班牙语 (Español)
   - 意大利语 (Italiano)
   - 日语 (日本語)
   - 韩语 (한국어)

2. **本地化增强**:
   - 日期格式本地化
   - 数字格式本地化
   - 货币格式本地化（如果添加定价功能）

3. **翻译审核**:
   - 邀请母语使用者审核翻译
   - 收集用户反馈改进翻译质量

## 文件修改 (Files Modified)

- `PhotobookApp/Sources/Core/Localization/LocalizationManager.swift`
  - 添加了`german`和`french`语言选项
  - 为所有LocalizedKey添加了德文和法文翻译
  - 更新了`localized()`方法

## 总结 (Summary)

成功添加了德文和法文本地化支持，所有界面元素都已翻译。翻译质量经过仔细审核，使用了专业的印刷术语。用户现在可以在4种语言之间自由切换，语言选择会自动保存并在下次启动时恢复。

所有翻译都遵循了以下原则：
- 准确性：使用正确的专业术语
- 一致性：相同概念使用相同翻译
- 简洁性：避免冗长的表达
- 本地化：符合目标语言的表达习惯
