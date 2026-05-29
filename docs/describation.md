# macOS Finder 右键增强工具需求文档

## 1. 项目概述

本项目是一个 macOS Finder 右键菜单增强工具，用于补齐 Finder 默认右键菜单中缺失的常用功能。

软件的核心目标是：

* 在 Finder 中右键任意对象时，可以快速复制路径。
* 在 Finder 空白区域或文件夹上右键时，可以快速用 iTerm 或 VSCode 打开当前目录。
* 在 Finder 空白区域右键时，可以快速新建常见类型文件。
* 所有右键菜单项都可以在软件设置界面中开启、关闭和配置。

该软件不需要替代 Finder，也不需要做成文件管理器。主应用只负责设置、模板管理、权限提示和诊断；真正高频使用入口是 Finder 右键菜单。

---

## 2. 技术目标

推荐技术方案：

* 主 App：SwiftUI macOS App
* Finder 扩展：Finder Sync Extension
* 模板文件存储：Application Support 或 App Group 共享目录
* 配置存储：UserDefaults 或 App Group UserDefaults
* 路径复制：NSPasteboard
* 打开 VSCode：`open -a "Visual Studio Code"`
* 打开 iTerm：AppleScript 控制 iTerm2

推荐项目名称暂定为：

```text
FinderRightTool
```

也可以后续改名。

---

## 3. 核心右键菜单功能

Finder 右键菜单中需要增加以下功能：

```text
新建 >
复制路径 >
用 iTerm 打开
用 VSCode 打开
```

不同右键场景下，显示的菜单项不同。

---

# 4. 右键场景与菜单行为

## 4.1 在 Finder 空白区域右键

当用户在 Finder 当前文件夹的空白区域右键时，应显示：

```text
新建 >
  新建 Markdown 文件
  新建 Word 文档
  新建 Excel 表格
  新建 PowerPoint 演示
  新建空白文件

复制路径 >
  复制当前文件夹路径
  复制所在目录路径

用 iTerm 打开
用 VSCode 打开
```

### 行为说明

#### 新建 Markdown 文件

在当前 Finder 文件夹中创建一个 `.md` 文件。

默认文件名：

```text
新建 Markdown 文件.md
```

如果文件已存在，则自动递增：

```text
新建 Markdown 文件 2.md
新建 Markdown 文件 3.md
```

#### 新建 Word 文档

从内置或用户配置的 Word 模板复制一个 `.docx` 文件到当前 Finder 文件夹。

默认文件名：

```text
新建 Word 文档.docx
```

#### 新建 Excel 表格

从内置或用户配置的 Excel 模板复制一个 `.xlsx` 文件到当前 Finder 文件夹。

默认文件名：

```text
新建 Excel 表格.xlsx
```

#### 新建 PowerPoint 演示

从内置或用户配置的 PowerPoint 模板复制一个 `.pptx` 文件到当前 Finder 文件夹。

默认文件名：

```text
新建 PowerPoint 演示.pptx
```

#### 新建空白文件

在当前 Finder 文件夹中创建一个没有后缀的空白文件。

默认文件名：

```text
新建文件
```

如果文件已存在，则自动递增：

```text
新建文件 2
新建文件 3
```

用户后续可以自己重命名并添加任意后缀。

#### 复制当前文件夹路径

复制当前 Finder 文件夹路径。

例如当前 Finder 文件夹为：

```text
/Users/xuziao/Downloads
```

复制结果为：

```text
/Users/xuziao/Downloads
```

#### 复制所在目录路径

在空白区域右键时，当前对象就是当前文件夹，因此该功能也复制当前 Finder 文件夹路径。

#### 用 iTerm 打开

在 iTerm2 中打开当前 Finder 文件夹，并执行：

```bash
cd 当前文件夹路径
```

#### 用 VSCode 打开

用 Visual Studio Code 打开当前 Finder 文件夹。

---

## 4.2 右键文件夹

当用户选中某个文件夹并右键时，应显示：

```text
复制路径 >
  复制所选文件夹路径
  复制父目录路径

用 iTerm 打开
用 VSCode 打开
```

### 行为说明

假设用户右键的文件夹是：

```text
/Users/xuziao/Downloads/project
```

#### 复制所选文件夹路径

复制该文件夹本身的路径：

```text
/Users/xuziao/Downloads/project
```

#### 复制父目录路径

复制该文件夹所在目录路径：

```text
/Users/xuziao/Downloads
```

#### 用 iTerm 打开

在 iTerm2 中打开该文件夹，并执行：

```bash
cd /Users/xuziao/Downloads/project
```

#### 用 VSCode 打开

用 Visual Studio Code 打开该文件夹：

```text
/Users/xuziao/Downloads/project
```

---

## 4.3 右键普通文件

当用户选中普通文件并右键时，应显示：

```text
复制路径 >
  复制所选文件路径
  复制所在文件夹路径
```

### 行为说明

假设用户右键的文件是：

```text
/Users/xuziao/Downloads/report.docx
```

#### 复制所选文件路径

复制该文件本身路径：

```text
/Users/xuziao/Downloads/report.docx
```

#### 复制所在文件夹路径

复制该文件所在文件夹路径：

```text
/Users/xuziao/Downloads
```

普通文件右键时，第一版不要求显示：

```text
用 iTerm 打开
用 VSCode 打开
新建
```

后续版本可以扩展。

---

## 4.4 右键应用程序

当用户右键某个应用程序 `.app` 时，应显示：

```text
复制路径 >
  复制所选应用路径
  复制所在文件夹路径
```

### 行为说明

假设用户右键的是：

```text
/Applications/Visual Studio Code.app
```

#### 复制所选应用路径

复制：

```text
/Applications/Visual Studio Code.app
```

#### 复制所在文件夹路径

复制：

```text
/Applications
```

---

## 4.5 右键任意其他对象

对于图片、PDF、压缩包、PPT、Word、Excel、代码文件、隐藏文件等任意对象，都应至少显示：

```text
复制路径 >
  复制所选项路径
  复制所在目录路径
```

---

# 5. 右键菜单命名优化

为了让菜单更自然，建议采用以下命名。

## 5.1 空白区域右键

```text
复制路径 >
  复制当前文件夹路径
  复制所在目录路径
```

## 5.2 文件夹右键

```text
复制路径 >
  复制文件夹路径
  复制父目录路径
```

## 5.3 文件右键

```text
复制路径 >
  复制文件路径
  复制所在文件夹路径
```

## 5.4 通用兜底命名

当无法准确判断对象类型时，使用：

```text
复制路径 >
  复制所选项路径
  复制所在目录路径
```

---

# 6. 新建文件功能

## 6.1 新建菜单结构

新建功能只需要在 Finder 空白区域右键时显示。

菜单结构：

```text
新建 >
  新建 Markdown 文件
  新建 Word 文档
  新建 Excel 表格
  新建 PowerPoint 演示
  新建空白文件
```

## 6.2 支持的新建文件类型

| 类型            | 扩展名     | 创建方式    | 默认文件名                 |
| ------------- | ------- | ------- | --------------------- |
| Markdown 文件   | `.md`   | 创建空文本文件 | 新建 Markdown 文件.md     |
| Word 文档       | `.docx` | 复制模板文件  | 新建 Word 文档.docx       |
| Excel 表格      | `.xlsx` | 复制模板文件  | 新建 Excel 表格.xlsx      |
| PowerPoint 演示 | `.pptx` | 复制模板文件  | 新建 PowerPoint 演示.pptx |
| 空白文件          | 无后缀     | 创建空文件   | 新建文件                  |

## 6.3 重名处理

创建文件时，如果目标文件已经存在，需要自动递增编号。

示例：

```text
新建 Markdown 文件.md
新建 Markdown 文件 2.md
新建 Markdown 文件 3.md
```

无后缀空白文件：

```text
新建文件
新建文件 2
新建文件 3
```

## 6.4 Office 模板机制

Word、Excel、PowerPoint 文件不能通过创建空文件的方式生成，必须通过模板复制。

模板目录：

```text
~/Library/Application Support/FinderRightTool/Templates/
```

模板文件：

```text
未命名.docx
未命名.xlsx
未命名.pptx
```

创建 Office 文件时：

1. 找到对应模板文件。
2. 复制到当前 Finder 文件夹。
3. 使用默认文件名。
4. 如果重名，则自动递增。
5. 创建完成后，在 Finder 中选中新文件。

---

# 7. 路径复制功能

## 7.1 功能范围

复制路径功能应该在 Finder 中右键任何对象时都可用。

包括但不限于：

```text
空白区域
文件夹
普通文件
应用程序
图片
PDF
Office 文件
隐藏文件
外接硬盘中的文件
iCloud Drive 中的文件
```

## 7.2 复制路径菜单

基础结构：

```text
复制路径 >
  复制所选项路径
  复制所在目录路径
```

根据场景优化命名：

```text
复制当前文件夹路径
复制文件夹路径
复制文件路径
复制应用路径
复制父目录路径
复制所在文件夹路径
```

## 7.3 多选行为

如果用户多选多个文件或文件夹并右键：

```text
复制路径 >
  复制所选项路径
  复制所在目录路径
```

行为：

* 复制所选项路径：复制所有选中项路径，每行一个。
* 复制所在目录路径：复制所有选中项的所在目录路径，每行一个。
* 如果多个选中项位于同一个目录，可以只复制一次该目录路径。
* 第一版可以直接每行输出一个目录路径，允许重复；后续版本再去重。

示例：

```text
/Users/xuziao/Downloads/a.pdf
/Users/xuziao/Downloads/b.docx
/Users/xuziao/Desktop/test.png
```

---

# 8. 用 iTerm 打开

## 8.1 显示场景

以下场景显示：

```text
用 iTerm 打开
```

* Finder 空白区域右键
* 文件夹右键

以下场景第一版不显示：

* 普通文件右键
* 应用程序右键
* 多选文件右键

## 8.2 行为

### 空白区域右键

在 iTerm2 中打开当前 Finder 文件夹。

### 文件夹右键

在 iTerm2 中打开选中的文件夹。

## 8.3 实现建议

通过 AppleScript 控制 iTerm2：

```applescript
tell application "iTerm2"
    activate
    create window with default profile
    tell current session of current window
        write text "cd '目标路径'"
    end tell
end tell
```

需要处理路径中的空格、引号和特殊字符。

---

# 9. 用 VSCode 打开

## 9.1 显示场景

以下场景显示：

```text
用 VSCode 打开
```

* Finder 空白区域右键
* 文件夹右键

以下场景第一版不显示：

* 普通文件右键
* 应用程序右键
* 多选文件右键

## 9.2 行为

### 空白区域右键

用 Visual Studio Code 打开当前 Finder 文件夹。

### 文件夹右键

用 Visual Studio Code 打开选中的文件夹。

## 9.3 实现建议

优先使用 macOS 自带 open 命令，不依赖用户是否安装了 `code` 命令行工具：

```bash
open -a "Visual Studio Code" "目标路径"
```

---

# 10. 软件设置界面

主 App 需要提供设置界面，用来管理 Finder 右键菜单。

推荐使用 SwiftUI 实现。

## 10.1 设置界面整体结构

推荐使用侧边栏布局：

```text
FinderRightTool
├── 总览
├── 右键菜单
├── 新建文件
├── 打开方式
├── 模板管理
├── 作用范围
├── 权限与诊断
└── 关于
```

---

## 10.2 总览页面

总览页面显示软件当前状态。

需要显示：

```text
Finder 扩展状态：已启用 / 未启用
完全磁盘访问：已授权 / 未授权
自动化权限：已授权 / 未授权
模板目录：正常 / 缺失
iTerm2：已检测到 / 未安装
VSCode：已检测到 / 未安装
```

需要提供按钮：

```text
打开系统扩展设置
打开隐私与安全性设置
重启 Finder
打开模板文件夹
```

---

## 10.3 右键菜单设置页面

该页面用于控制右键菜单项是否显示。

需要支持以下开关：

```text
[√] 显示复制路径菜单
    [√] 复制所选项路径
    [√] 复制所在目录路径

[√] 显示用 iTerm 打开
[√] 显示用 VSCode 打开

[√] 显示新建菜单
    [√] 新建 Markdown 文件
    [√] 新建 Word 文档
    [√] 新建 Excel 表格
    [√] 新建 PowerPoint 演示
    [√] 新建空白文件
```

每一个子功能都应该可以独立开启或关闭。

---

## 10.4 新建文件设置页面

该页面用于配置新建文件功能。

每个新建类型都应该支持：

```text
启用 / 禁用
菜单显示名称
默认文件名
扩展名
创建方式
模板路径
```

示例配置：

```text
Markdown 文件
启用：是
菜单显示名称：新建 Markdown 文件
默认文件名：新建 Markdown 文件
扩展名：md
创建方式：空文件
```

```text
Word 文档
启用：是
菜单显示名称：新建 Word 文档
默认文件名：新建 Word 文档
扩展名：docx
创建方式：模板复制
模板路径：~/Library/Application Support/FinderRightTool/Templates/blank.docx
```

---

## 10.5 模板管理页面

模板管理页面用于管理 Office 文件模板。

需要支持：

```text
查看当前模板路径
更换 Word 模板
更换 Excel 模板
更换 PowerPoint 模板
恢复默认模板
打开模板文件夹
检测模板是否存在
```

模板文件必须可以被 Finder Extension 访问。

建议使用 App Group 或共享的 Application Support 路径。

---

## 10.6 打开方式页面

该页面用于配置外部应用打开方式。

需要支持：

```text
iTerm2
启用：是
应用名称：iTerm2
打开方式：AppleScript
路径：自动检测

Visual Studio Code
启用：是
应用名称：Visual Studio Code
打开方式：open -a
路径：自动检测
```

后续可以扩展：

```text
Terminal
Warp
Cursor
Sublime Text
PyCharm
IntelliJ IDEA
```

第一版只需要 iTerm2 和 Visual Studio Code。

---

## 10.7 作用范围页面

Finder Sync Extension 需要设置生效目录。

该页面用于配置右键增强在哪些目录下生效。

默认建议：

```text
/Users/当前用户名
/Volumes
```

需要支持：

```text
添加目录
移除目录
启用 / 禁用某个目录
恢复默认目录
```

示例：

```text
已启用的 Finder 右键增强目录：
[√] /Users/xuziao
[√] /Volumes
[ ] /Users/xuziao/Library/Mobile Documents/com~apple~CloudDocs
```

---

## 10.8 权限与诊断页面

该页面用于排查软件是否正常工作。

需要显示：

```text
Finder Extension：已启用 / 未启用
Full Disk Access：已授权 / 未授权
Automation - Finder：已授权 / 未授权
Automation - iTerm2：已授权 / 未授权
Templates：正常 / 缺失
配置文件：正常 / 缺失
```

需要提供按钮：

```text
打开系统设置
重启 Finder
重新加载扩展
查看日志
复制诊断信息
```

---

# 11. 配置要求

所有菜单项都必须可配置。

配置至少包括：

```text
是否启用复制路径菜单
是否启用复制所选项路径
是否启用复制所在目录路径

是否启用用 iTerm 打开
是否启用用 VSCode 打开

是否启用新建菜单
是否启用新建 Markdown 文件
是否启用新建 Word 文档
是否启用新建 Excel 表格
是否启用新建 PowerPoint 演示
是否启用新建空白文件
```

配置需要在主 App 和 Finder Sync Extension 之间共享。

推荐使用：

```text
App Group UserDefaults
```

---

# 12. Finder Sync Extension 行为要求

Finder Sync Extension 需要能够判断以下情况：

```text
当前右键是否发生在 Finder 空白区域
当前右键是否选中了文件夹
当前右键是否选中了普通文件
当前右键是否选中了应用程序
当前是否多选
当前 Finder 目标目录是什么
```

需要根据不同场景动态生成菜单。

伪逻辑：

```text
如果是空白区域右键：
    显示新建菜单
    显示复制路径菜单
    显示用 iTerm 打开
    显示用 VSCode 打开

如果是文件夹右键：
    显示复制路径菜单
    显示用 iTerm 打开
    显示用 VSCode 打开

如果是普通文件右键：
    显示复制路径菜单

如果是应用程序右键：
    显示复制路径菜单

如果是多选：
    显示复制路径菜单
```

---

# 13. 权限要求

软件需要提示用户开启以下权限：

```text
Finder Extension
Full Disk Access
Automation 权限
```

说明：

* Finder Extension 用于显示 Finder 右键菜单。
* Full Disk Access 用于减少访问目录时的权限问题。
* Automation 权限用于控制 iTerm2。
* VSCode 打开功能优先使用 `open -a`，通常不需要 Automation 权限。

软件不需要自动绕过系统权限，也不需要静默申请最高权限。用户可以手动授权。

---

# 14. 错误处理

需要处理以下错误：

```text
模板文件不存在
目标目录不可写
目标文件已存在
iTerm2 未安装
VSCode 未安装
Finder Extension 未启用
权限不足
AppleScript 执行失败
路径中包含特殊字符
```

处理方式：

* 尽量不弹出复杂错误窗口。
* 可以使用 macOS 通知或简单 alert。
* 日志写入本地日志文件，方便诊断。
* 设置界面提供“复制诊断信息”。

---

# 15. 默认配置

软件首次启动时，使用以下默认配置：

```text
复制路径菜单：开启
复制所选项路径：开启
复制所在目录路径：开启

用 iTerm 打开：开启
用 VSCode 打开：开启

新建菜单：开启
新建 Markdown 文件：开启
新建 Word 文档：开启
新建 Excel 表格：开启
新建 PowerPoint 演示：开启
新建空白文件：开启

默认作用范围：
/Users/当前用户名
/Volumes
```

---

# 16. 第一版 MVP 范围

第一版只需要实现以下功能：

```text
1. Finder 空白区域右键显示菜单
2. 文件夹右键显示菜单
3. 文件右键显示复制路径菜单
4. 应用程序右键显示复制路径菜单
5. 复制所选项路径
6. 复制所在目录路径
7. 用 iTerm 打开文件夹
8. 用 VSCode 打开文件夹
9. 新建 Markdown 文件
10. 新建 Word 文档
11. 新建 Excel 表格
12. 新建 PowerPoint 演示
13. 新建空白文件
14. 设置界面中可以控制所有菜单项开关
15. 模板目录可以管理 Office 模板
16. 权限与诊断页面
```

---

# 17. 暂不实现的功能

第一版暂不实现：

```text
批量重命名
压缩 / 解压
图片格式转换
AI 功能
云同步
文件管理器
复杂快捷键系统
复杂主题系统
菜单图标自定义
```

这些功能会让项目复杂化，不属于第一版核心需求。

---

# 18. 验收标准

## 18.1 空白区域右键

在 Finder 文件夹空白处右键时，应看到：

```text
新建 >
复制路径 >
用 iTerm 打开
用 VSCode 打开
```

并且每个功能正常执行。

## 18.2 文件夹右键

右键文件夹时，应看到：

```text
复制路径 >
用 iTerm 打开
用 VSCode 打开
```

并且：

* 可以复制文件夹路径。
* 可以复制父目录路径。
* 可以在 iTerm 中打开该文件夹。
* 可以在 VSCode 中打开该文件夹。

## 18.3 文件右键

右键普通文件时，应看到：

```text
复制路径 >
```

并且：

* 可以复制文件路径。
* 可以复制所在文件夹路径。

## 18.4 应用程序右键

右键 `.app` 应用程序时，应看到：

```text
复制路径 >
```

并且：

* 可以复制应用程序路径。
* 可以复制所在文件夹路径。

## 18.5 新建文件

在 Finder 空白区域右键新建文件时，应可以创建：

```text
.md
.docx
.xlsx
.pptx
无后缀空白文件
```

并且：

* 文件名不冲突。
* Office 文件可以被 Microsoft Office 或 WPS 正常打开。
* 新建完成后 Finder 自动选中新文件。

## 18.6 设置界面

设置界面中关闭某个功能后，Finder 右键菜单中对应功能应消失。

重新开启后，功能应恢复显示。

---

# 19. 推荐开发顺序

建议按以下顺序开发：

```text
1. 创建 SwiftUI macOS App
2. 添加 Finder Sync Extension
3. 设置 Finder Extension 生效目录
4. 在 Finder 右键菜单中显示测试菜单
5. 实现复制当前路径
6. 实现复制所选项路径
7. 实现复制所在目录路径
8. 实现用 VSCode 打开
9. 实现用 iTerm 打开
10. 实现新建 Markdown 文件
11. 实现新建空白文件
12. 实现 Office 模板复制
13. 实现设置界面开关
14. 实现模板管理
15. 实现权限与诊断页面
16. 打包测试
```

---

# 20. 最终产品定位

本软件是一个轻量级 macOS Finder 右键增强工具，主要解决以下痛点：

```text
Finder 不能方便地右键新建文件
Finder 不能方便地复制文件路径
Finder 不能方便地复制所在目录路径
Finder 不能方便地用 iTerm 打开当前目录
Finder 不能方便地用 VSCode 打开当前目录
```

软件应保持轻量、稳定、可配置，不做文件管理器，不引入无关复杂功能。
