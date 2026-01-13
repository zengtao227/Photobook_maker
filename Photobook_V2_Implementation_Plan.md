# Photobook V2 智能功能实施计划 (Updated V2.3)

基于 V1 需求文档（v1.0）的演进规划，本版本聚焦**智能化照片处理与自动排版**功能。

> [!NOTE]
> 所有智能处理均在**本地离线完成**，严格遵循 V1 隐私承诺，不上传任何用户数据至云端。

---

## 一、核心问题修复与增强 (Fixes & Enhancements)

### 1. UI 窗口适配 (Window Size & Layout)
*   **问题**: 启动界面是竖屏锁定或不可调整大小，类似于 iOS 模拟器。
*   **修复**: 
    *   移除固定 Frame 限制，确保主窗口为 macOS 原生可缩放窗口
    *   设置合理的最小窗口尺寸 (minWidth: 1000, minHeight: 700)
    *   照片库选择器改为桌面风格，避免阻塞主线程

### 2. Library 缩略图显示
*   **问题**: 所有缩略图都是固定正方形，导致照片变形
*   **修复**: 使用 `.aspectRatio(contentMode: .fit)` 保持原始比例

### 3. 照片布局比例保持
*   **问题**: 照片填入页面时被裁剪，只显示部分内容
*   **修复**: 在模板 slot 内按照片实际比例缩放（fit 模式），居中显示
*   **核心规则**: 
    *   **必须使用 FIT 模式**: 照片放入编辑页时必须完整显示整个照片内容，只进行缩放
    *   **未裁切照片**: 使用 `.aspectRatio(contentMode: .fit)` 保持原始比例，完整显示
    *   **已裁切照片**: 使用 `.aspectRatio(contentMode: .fill)` + `cropScale` + `cropOffset` 显示裁切区域
    *   **判断依据**: 检查 `normalizedCropRect` 是否存在且 `cropScale > 1.0`
    *   **竖版照片**: 必须完整显示，不能被裁剪成横版尺寸

### 4. 裁剪编辑器可用性
*   **问题**: 双击照片后只显示"重置"按钮，无法退出
*   **修复**: 
    *   改进按钮布局，确保"取消"、"重置"、"完成"三个按钮始终可见
    *   添加键盘快捷键 (ESC 取消, Enter 完成)
    *   在顶部添加关闭按钮

### 5. 裁切后照片显示
*   **问题**: 裁切后照片只显示缩小版，不是裁切区域
*   **修复**:
    *   **未裁切照片**: 使用 `.fit` 模式完整显示
    *   **已裁切照片**: 使用 `.fill` 模式 + `cropScale` + `cropOffset` 显示裁切区域
    *   通过检查 `normalizedCropRect` 是否为完整图片 (0,0,1,1) 来判断是否裁切
    *   裁切后图层框架会自动调整为裁切区域的比例

---

## 二、智能事件分组逻辑 (Event-Based Smart Grouping)

### 核心理念：基于活动/事件的智能聚合

**目标**：将相同活动/事件的照片聚合在一起，即使跨越多天，形成有意义的故事单元。

### 分组算法 (Multi-Dimensional Clustering)

#### 第一层：场景活动识别 (Activity Recognition)
使用 Vision 框架识别照片中的活动类型：
- **运动类**: 篮球、足球、滑雪、骑行、游泳等
- **旅行类**: 景点、建筑、自然风光
- **生活类**: 美食、聚会、家庭活动
- **特殊事件**: 婚礼、生日、毕业典礼等

#### 第二层：时空连续性分析 (Spatio-Temporal Continuity)
1. **时间窗口**: 
   - 单日活动：同一天内，间隔 < 4小时
   - 多日活动：连续多天，每天都有相关照片
   
2. **地点关联**:
   - 相同地点（GPS 距离 < 1km）
   - 相关地点（如同一城市、同一景区）

3. **场景一致性**:
   - 相似的视觉特征（颜色、构图、内容）
   - 相同的活动标签

#### 第三层：事件合并与命名 (Event Merging & Naming)

**合并规则**：
```
IF (场景类型相同 AND 时间连续 AND 地点相近) THEN
    合并为同一事件
END IF
```

**命名策略**：
- 单日活动: "篮球比赛 - 3月15日"
- 多日活动: "滑雪之旅 - 3月10日至12日"
- 旅行活动: "埃及之旅 - 7天"
- 地点活动: "北京游 - 故宫·长城"

### 实际案例

#### 案例 1: 篮球比赛
```
输入: 50张照片，拍摄于 2024-03-15
场景识别: 运动场、篮球、人物
时间分布: 14:00-17:30 (连续)
地点: 同一体育馆
输出: "篮球比赛 - 3月15日" (50张)
```

#### 案例 2: 滑雪之旅
```
输入: 120张照片，拍摄于 2024-01-10 至 2024-01-12
场景识别: 雪景、滑雪装备、山地
时间分布: 3天，每天 9:00-16:00
地点: 同一滑雪场区域 (GPS 聚类)
输出: "滑雪之旅 - 1月10日至12日" (120张)
```

#### 案例 3: 埃及旅行
```
输入: 300张照片，拍摄于 2024-02-01 至 2024-02-07
场景识别: 金字塔、神庙、沙漠、博物馆
时间分布: 7天连续
地点: 埃及多个城市 (开罗、卢克索等)
输出: "埃及之旅 - 7天" (300张)
      子分组: "金字塔" (80张), "卢克索神庙" (60张), "尼罗河" (40张)...
```

#### 案例 4: 骑行活动
```
输入: 35张照片，拍摄于 2024-04-20
场景识别: 自行车、道路、风景
时间分布: 8:00-12:00 (连续)
地点: 沿线路移动 (GPS 轨迹)
输出: "骑行活动 - 4月20日" (35张)
```

### 分组优先级

1. **活动事件分组** (最高优先级)
   - 识别出明确活动类型的照片
   - 时空连续性强的照片集

2. **场景类型分组** (中等优先级)
   - 相同场景类型但无明确活动
   - 如：风景照、美食照、人像照

3. **时间分组** (基础优先级)
   - 无法识别活动和场景的照片
   - 按时间间隔（4小时）分组

4. **地点分组** (补充优先级)
   - 有GPS但无其他特征的照片
   - 按地理位置聚类

5. **其他照片** (兜底分组)
   - 无法归类的零散照片

---

## 三、严格事件隔离排版逻辑 (Strict Event-Based Layout)

### 核心原则：事件完整性优先

1.  **事件隔离 (Event Isolation)**：
    *   每个事件分组代表一个完整的故事
    *   **不同事件的照片绝对不能出现在同一页面上**
    *   新事件必须从新的跨页（Spread）开始

2.  **动态分页计算 (Dynamic Pagination)**：
    *   每页标准容量：4张照片
    *   **计算公式**：`事件总页数 = ceil(事件照片数 / 4)`
    *   **示例**：
        *   事件A "篮球比赛" (6张): 占用 P1 (4张) + P2 (2张)，P2留白
        *   事件B "滑雪之旅" (8张): 从 P3 开始，占用 P3 (4张) + P4 (4张)
        *   事件C "骑行活动" (3张): 从 P5 开始，占用 P5 (3张)，留白

3.  **事件标题页 (Event Title Page)**：
    *   每个事件的第一页可选添加标题
    *   显示事件名称、日期、照片数量

---

## 四、技术实现要点 (Implementation Details)

### 1. PhotoClassifier 增强

```swift
// 新增方法
func groupByActivity(_ photos: [ClassifiedPhoto]) -> [PhotoGroup]
func detectActivityType(_ photo: ClassifiedPhoto) -> ActivityType
func mergeRelatedEvents(_ groups: [PhotoGroup]) -> [PhotoGroup]
func generateEventName(for group: PhotoGroup) -> String
```

### 2. 活动类型枚举

```swift
enum ActivityType {
    case sports(SportType)      // 运动：篮球、足球、滑雪等
    case travel(TravelType)     // 旅行：景点、城市游等
    case dining                 // 美食
    case party                  // 聚会
    case family                 // 家庭活动
    case outdoor                // 户外活动
    case indoor                 // 室内活动
    case special(EventType)     // 特殊事件：婚礼、生日等
    case unknown
}
```

### 3. 分组流程

```
1. 场景分类 (Vision API)
   ↓
2. 活动识别 (关键词匹配 + 场景组合)
   ↓
3. 时空聚类 (时间连续性 + GPS距离)
   ↓
4. 事件合并 (相同活动 + 连续时间)
   ↓
5. 事件命名 (智能生成描述性名称)
   ↓
6. 排序输出 (按时间顺序或重要性)
```

---

## 五、后续开发任务 (Development Tasks)

### Phase 1: 活动识别增强 ✅ (已完成基础)
- [x] 场景分类 (Vision API)
- [x] 时间分组
- [ ] 活动类型识别
- [ ] 事件合并逻辑

### Phase 2: 智能命名 (进行中)
- [ ] 事件名称生成
- [ ] 多语言支持
- [ ] 用户自定义命名

### Phase 3: UI 优化 ✅ (已完成)
- [x] 窗口大小适配
- [x] 缩略图比例修复
- [x] 裁剪编辑器改进
- [x] 照片布局比例保持

### Phase 4: 排版引擎升级 ✅ (已完成)
- [x] 事件隔离逻辑
- [x] 动态分页计算
- [ ] 事件标题页生成

---

**Files to Focus On**:
- `Sources/Services/PhotoClassifier.swift` (活动识别与事件合并)
- `Sources/Models/ClassificationModels.swift` (ActivityType 枚举)
- `Sources/Views/SmartImportView.swift` (分组展示与集成)
- `Sources/Services/AutoLayoutEngine.swift` (事件隔离排版)

---

**注意事项**:
用户强调的核心需求是**基于活动/事件的智能分组**，而不是简单的场景分类。
关键是要识别出"打篮球"、"滑雪"、"埃及旅行"这样的**有意义的事件**，并将相关照片聚合在一起。


---

## ✅ 最新完成功能 (Latest Completed Features)

### 1. 剪切/复制/粘贴功能 (Cut/Copy/Paste)
- **Cmd+X**: 剪切选中图层到剪贴板并删除
- **Cmd+C**: 复制选中图层到剪贴板
- **Cmd+V**: 从剪贴板粘贴图层（偏移20pt）
- **Cmd+D**: 复制选中图层
- 图层右键菜单：剪切、复制、复制
- 页面右键菜单：粘贴（当剪贴板有内容时）
- 所有菜单项使用多语言本地化
- 剪贴板在页面导航间保持

### 2. 智能导入与常规导入合并 (Smart Import Merged)
- 智能导入现在有4个选项：
  - **文件夹**: 导入整个文件夹的照片
  - **选择照片**: 选择单个图片文件（新增）
  - **照片库**: 从 macOS 照片库导入
  - **iCloud**: 从 iCloud Drive 导入
- 移除了 Library 中单独的"导入文件夹"按钮
- 所有导入都通过统一的智能导入界面

### 3. Library 中已使用照片标记 (Used Photo Indicators)
- 已使用照片显示绿色对勾图标
- 已使用照片有绿色边框
- 蓝色选择指示器显示在已使用指示器下方
- `isPhotoUsed()` 检查所有跨页和封面
- 照片添加/删除时实时更新

### 4. Library 多选功能 (Multi-Selection)
- **点击**: 选择单张照片
- **Cmd+点击**: 切换选择（多选）
- **Shift+点击**: 从上次点击到当前的范围选择
- **Cmd+A**: 全选所有照片
- 标题栏显示选择数量

### 5. 撤销/重做系统 (Undo/Redo)
- **Cmd+Z**: 撤销上一个操作
- **Cmd+Shift+Z**: 重做已撤销的操作
- 页面导航工具栏中的撤销/重做按钮
- 最多50步撤销
- 在以下操作前自动保存撤销状态：剪切、粘贴、复制、移动页面
- 全局键盘快捷键从 MainLayoutView 工作

### 6. 页面导航 (Page Navigation)
- **左箭头 (←)**: 导航到上一个跨页
- **右箭头 (→)**: 导航到下一个跨页
- 画布两侧的圆形箭头按钮
- 悬停提示显示键盘快捷键
- 按钮显示启用/禁用状态

### 7. 单页移动功能 (Single Page Movement)
- 页面导航工具栏中的"移动页面"按钮
- 右侧侧边栏（300px），不阻挡编辑区域
- 移动单个页面（不是整个跨页）
- 输入：从页码、到页码（从1开始）
- 通过添加空白右页处理奇数页
- 多语言支持（中文/英文/德文/法文）
- 移动前自动保存撤销状态

### 8. 智能分组编辑 (Smart Grouping Editing)
- 每个分组卡片上的"编辑"按钮（铅笔图标）
- 点击进入编辑模式显示照片网格
- 在分组中选择多张照片（点击切换）
- "删除选中"按钮移除选中的照片
- 空分组自动删除
- "完成编辑"按钮返回分组列表
- **Cmd+A**: 选择分组中的所有照片（编辑模式下）

### 9. 右键删除单页 (Right-Click Delete Page)
- 页面上的上下文菜单带删除选项
- **可以删除任何内页**（包括有照片的页面）
- 删除后自动重组页面，后面的页面往前移动
- **总页数会相应减少**
- 如果删除后剩余奇数页，最后一个跨页的右页为空白
- 页面导航器的 Total 页数会实时更新
- 支持撤销操作

### 10. 基于活动的智能分组 (Activity-Based Grouping)
- 多维聚类：场景 + 时间 + 地点
- 支持多日活动（例如"滑雪之旅 - 1月10日至12日"）
- 优先级：活动事件 > 场景类型 > 时间分组 > 地点分组
- 生成有意义的事件名称

### 11. 布局中的事件隔离 (Event Isolation)
- 每个分组必须从新跨页开始
- 永不混合不同分组的照片
- PageSuggestion 中的 `isGroupStart` 和 `groupId` 属性
- 在 `finalizeGeneration()` 中强制执行

### 12. 照片比例保持 (Photo Aspect Ratio)
- 放置时照片保持原始比例
- 智能导入布局使用适配模式（不是填充）
- 从 library 拖放保持比例
- 导入时使用 CGImageSource 自动读取尺寸

---

## 技术实现细节 (Technical Implementation)

### 文件结构
```
PhotobookApp/Sources/
├── Features/
│   ├── Canvas/
│   │   ├── CanvasView.swift (页面导航、右键菜单)
│   │   ├── EditorState.swift (剪贴板、撤销/重做)
│   │   └── Components/
│   │       └── InteractiveLayer.swift (图层右键菜单)
│   ├── Library/
│   │   └── LibraryPanel.swift (多选、已使用标记)
│   └── Main/
│       └── MainLayoutView.swift (全局快捷键)
├── Services/
│   ├── PhotoStore.swift (多选逻辑、已使用检查)
│   └── PhotoClassifier.swift (活动分组)
├── Views/
│   ├── SmartImportView.swift (合并导入、分组编辑)
│   └── PageNavigatorView.swift (移动页面、撤销/重做按钮)
└── Core/
    └── Localization/
        └── LocalizationManager.swift (多语言支持)
```

### 关键算法

#### 1. 多选处理
```swift
func handlePhotoSelection(_ photo: Photo, modifiers: EventModifiers) {
    if modifiers.contains(.command) {
        // Toggle selection
    } else if modifiers.contains(.shift) {
        // Range selection
    } else {
        // Single selection
    }
}
```

#### 2. 已使用照片检查
```swift
func isPhotoUsed(_ photo: Photo, in editorState: EditorState) -> Bool {
    // Check all spreads and covers for PhotoLayer with matching photoId
}
```

#### 3. 事件隔离
```swift
for suggestion in suggestions {
    let suggestionGroupIndex = findGroupIndex(for: suggestion.photos, in: detectedEvents)
    
    if suggestionGroupIndex != currentGroupIndex {
        // Start new spread for new group
        editorState.bookStructure.addInnerSpread()
        currentGroupIndex = suggestionGroupIndex
    }
}
```

---

## 下一步计划 (Next Steps)

### 短期目标
1. 性能优化：大型照片库的缓存机制
2. 批量操作：批量删除、批量移动
3. 搜索功能：按日期、地点、场景搜索照片

### 中期目标
1. 模板系统增强：更多布局模板
2. 文字样式：更多字体和排版选项
3. 导出选项：多种分辨率和格式

### 长期目标
1. AI 增强：更智能的照片质量评估
2. 协作功能：多人编辑支持
3. 云同步：可选的 iCloud 同步

---

## 测试状态 (Testing Status)

### ✅ 已测试功能
- 剪切/复制/粘贴操作
- 多选功能（Cmd、Shift、Cmd+A）
- 撤销/重做（Cmd+Z、Cmd+Shift+Z）
- 页面导航（箭头键、按钮）
- 单页删除和重组
- 智能分组编辑
- 已使用照片标记

### 🔄 待测试功能
- 大型照片库性能（1000+ 照片）
- 复杂布局的事件隔离
- 多语言界面完整性

---

## 已知问题 (Known Issues)

### 无严重问题
所有核心功能已实现并通过编译检查。

### 潜在改进
1. 已使用照片检查可能需要缓存以提高性能
2. 可以添加"仅显示未使用照片"的过滤器
3. 移动页面对话框可以添加预览功能

---

*最后更新: 2026-01-12*
*版本: V2.3 - 完整功能实现*
