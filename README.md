<div align="center">

<img src="https://img.shields.io/badge/platform-macOS%2013%2B-blue?style=flat-square&logo=apple" alt="macOS 13+">
<img src="https://img.shields.io/badge/Swift-5.9-orange?style=flat-square&logo=swift" alt="Swift 5.9">
<img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="MIT License">
<img src="https://img.shields.io/badge/status-active-brightgreen?style=flat-square" alt="Active">

# RightPlus

**让 macOS Finder 的右键菜单真正好用。**

新建文件、复制路径、用终端或编辑器打开 —— 一次右键，全部搞定。

[English](README_EN.md) · [报告问题](https://github.com/xzagit/RightPlus/issues) · [功能建议](https://github.com/xzagit/RightPlus/issues)

</div>

---

## 为什么需要 RightPlus？

macOS 的 Finder 在文件管理上一直存在几个令人抓狂的缺失：

- 无法在当前文件夹直接**新建文件**（只能新建文件夹）
- 无法方便地**复制文件/文件夹路径**
- 无法直接**用终端打开当前目录**
- 无法直接**用代码编辑器打开当前文件夹**

RightPlus 通过 macOS 原生的 **Finder Sync Extension** 机制，将这些功能无缝集成到右键菜单中，不替换 Finder、不注入进程，轻量、稳定、可配置。

---

## 功能一览

### 新建文件

在 Finder 空白区域右键，即可快速新建：

| 类型 | 扩展名 | 说明 |
|------|--------|------|
| Markdown 文件 | `.md` | 创建空白 Markdown 文件 |
| Word 文档 | `.docx` | 从内置模板复制 |
| Excel 表格 | `.xlsx` | 从内置模板复制 |
| PowerPoint 演示 | `.pptx` | 从内置模板复制 |
| 空白文件 | 无后缀 | 创建无后缀空文件，可自行重命名 |
| 新建文件夹 | — | 快捷新建文件夹 |
| 自定义模板 | 任意 | 支持添加自己的模板文件 |

> 文件名自动处理重名冲突，例如 `新建 Word 文档.docx` → `新建 Word 文档 2.docx`

### 复制路径

右键任何对象均可复制路径，菜单文字随场景自动调整：

| 场景 | 菜单项 |
|------|--------|
| 空白区域 | 复制当前文件夹路径 / 复制所在目录路径 |
| 选中文件夹 | 复制文件夹路径 / 复制父目录路径 |
| 选中文件 | 复制文件路径 / 复制所在文件夹路径 |
| 多选 | 批量复制，每行一条路径 |

> 两项都开启时以二级菜单展示，只开启一项时直接显示为一级菜单，保持简洁。

### 用终端打开

右键文件夹或空白区域，直接在终端中 `cd` 到当前目录。支持：

- iTerm2
- Terminal（macOS 自带）
- Warp
- 或任意你选择的终端 App

### 用编辑器打开

右键文件夹或空白区域，直接用代码编辑器打开当前目录。支持：

- Visual Studio Code
- Cursor
- PyCharm
- IntelliJ IDEA
- Sublime Text
- 或任意你选择的编辑器 App

---

## 设置界面

RightPlus 提供一个完整的设置 App，使用侧边栏布局：

```
RightPlus
├── 总览          — 扩展状态、权限状态、已安装应用检测
├── 右键菜单       — 控制每个菜单项的显示/隐藏
├── 打开方式       — 选择终端和编辑器 App
├── 模板管理       — 管理 Office 模板、添加自定义模板
├── 权限与诊断     — 权限检测、重启 Finder、查看日志
└── 关于          — 版本信息
```

所有设置实时生效，修改后下次打开右键菜单即可看到变化，无需重启 Finder。

---

## 安装与使用

### 系统要求

- macOS 13 Ventura 或更高版本
- Xcode 15+（从源码构建）

### 从源码构建

```bash
git clone https://github.com/xzagit/RightPlus.git
cd RightPlus
open RightPlus.xcodeproj
```

在 Xcode 中选择 `RightPlus` Scheme，构建并运行（`⌘R`）。

> 注意：首次运行需要在 **系统设置 → 隐私与安全性 → 扩展 → Finder** 中启用 RightPlus 扩展。

### 首次启动

1. 打开 RightPlus App
2. 进入「总览」页面，按提示开启 Finder 扩展
3. 如需使用「用终端打开」，还需在系统设置中授予自动化权限
4. 在 Finder 中右键，即可看到 RightPlus 菜单

---

## 技术架构

```
RightPlus
├── RightPlus/                    # 主 App（设置 UI）
│   ├── Views/                    # SwiftUI 页面
│   ├── Shared/                   # 与 Extension 共享的代码
│   │   ├── Constants.swift       # 路径常量（使用 getpwuid 获取真实 home 目录）
│   │   ├── SettingsManager.swift # 设置读写（plist 文件）
│   │   └── TemplateConfig.swift  # 自定义模板数据模型
│   └── RightPlusApp.swift
│
└── FinderSyncExtension/          # Finder Sync Extension
    ├── FinderSync.swift          # 菜单构建与动态响应
    ├── Actions/
    │   ├── NewFileAction.swift   # 新建文件逻辑
    │   ├── CopyPathAction.swift  # 复制路径逻辑
    │   ├── OpenTerminalAction.swift  # 打开终端（.command 脚本方式）
    │   └── OpenEditorAction.swift    # 打开编辑器
    ├── Templates/                # 内置 Office 模板
    │   ├── 未命名.docx
    │   ├── 未命名.xlsx
    │   └── 未命名.pptx
    ├── SettingsManager.swift     # 只读版，每次菜单构建时重新加载
    ├── TemplateConfig.swift
    └── Constants.swift
```

### 关键设计决策

**跨进程设置同步**：主 App 和 Extension 运行在独立的沙盒进程中，通过 `~/Library/Application Support/RightPlus/settings.plist` 共享配置。Extension 在每次 `menu()` 调用时重新加载配置文件，确保设置实时生效。

**真实 home 目录**：macOS 沙盒会将 `FileManager.homeDirectoryForCurrentUser` 重定向到容器路径。通过 `getpwuid(getuid())` 获取系统级真实 home 目录（`/Users/用户名`），确保两个进程读写同一份配置文件。

**终端打开方式**：使用 `.command` 脚本文件 + `open -a appName` 的方式打开终端，避开 AppleScript TCC 授权的限制（macOS 13+ 上 AppleScript 控制 iTerm2 会弹出权限请求）。

---

## 自定义模板

除了内置的 Office 模板外，你可以添加任意格式的模板文件：

1. 打开 RightPlus → 模板管理
2. 点击「添加模板...」，选择任意文件作为模板
3. 设置显示名称（会显示在右键菜单中）
4. 在「右键菜单」设置中可以单独开启/关闭每个自定义模板

模板文件存储在 `~/Library/Application Support/RightPlus/Templates/`，你也可以直接在该目录下替换内置的 Word/Excel/PowerPoint 模板为自己的版本。

---

## 权限说明

| 权限 | 用途 | 是否必须 |
|------|------|----------|
| Finder 扩展 | 显示右键菜单 | 必须 |
| 完全磁盘访问 | 在任意目录创建文件 | 推荐 |
| 自动化 (Finder) | 新建文件后自动选中 | 可选 |

---

## 参与贡献

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建你的功能分支：`git checkout -b feature/your-feature`
3. 提交更改：`git commit -m 'feat: add your feature'`
4. 推送到分支：`git push origin feature/your-feature`
5. 提交 Pull Request

---

## 开源协议

本项目基于 [MIT License](LICENSE) 开源。

---

<div align="center">

如果 RightPlus 对你有帮助，欢迎给个 Star ⭐

</div>
