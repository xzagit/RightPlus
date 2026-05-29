#!/bin/bash
set -e

# ============================================================
# RightPlus 自动打包发布脚本
# 用法: ./scripts/release.sh [版本号]
# 示例: ./scripts/release.sh 1.0.0
# ============================================================

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="RightPlus"
PROJECT="$PROJECT_DIR/RightPlus.xcodeproj"
ARCHIVE_PATH="$PROJECT_DIR/build/RightPlus.xcarchive"
EXPORT_PATH="$PROJECT_DIR/build/export"
DMG_DIR="$PROJECT_DIR/build"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ============================================================
# 1. 获取版本号
# ============================================================

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
    echo -n "请输入版本号 (例如 1.0.0): "
    read VERSION
fi

if [ -z "$VERSION" ]; then
    error "版本号不能为空"
fi

# 确保格式 vX.X.X
TAG="v$VERSION"
DMG_NAME="RightPlus_${VERSION}.dmg"
DMG_PATH="$DMG_DIR/$DMG_NAME"

info "版本: $VERSION  标签: $TAG"

# ============================================================
# 2. 检查依赖
# ============================================================

command -v xcodebuild >/dev/null || error "未找到 xcodebuild，请安装 Xcode"
command -v gh >/dev/null || error "未找到 gh，请运行: brew install gh"
command -v hdiutil >/dev/null || error "未找到 hdiutil"

# 检查 gh 登录状态
gh auth status >/dev/null 2>&1 || error "gh 未登录，请运行: gh auth login"

# 检查工作区是否干净
cd "$PROJECT_DIR"
if [ -n "$(git status --porcelain)" ]; then
    warn "工作区有未提交的更改:"
    git status --short
    echo ""
    echo -n "是否继续? (y/N): "
    read CONTINUE
    if [ "$CONTINUE" != "y" ] && [ "$CONTINUE" != "Y" ]; then
        exit 0
    fi
fi

# 检查 tag 是否已存在
if git rev-parse "$TAG" >/dev/null 2>&1; then
    error "标签 $TAG 已存在，请使用其他版本号"
fi

# ============================================================
# 3. 清理旧产物
# ============================================================

info "清理旧的构建产物..."
rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH" "$DMG_PATH"
mkdir -p "$DMG_DIR" "$EXPORT_PATH"

# ============================================================
# 4. Archive
# ============================================================

info "正在 Archive (Release 配置)..."
xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -quiet \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM=6FMDB5TQT5

if [ ! -d "$ARCHIVE_PATH" ]; then
    error "Archive 失败"
fi
info "Archive 完成"

# ============================================================
# 5. 导出 .app
# ============================================================

info "正在导出 App..."

# 创建 ExportOptions.plist
EXPORT_OPTIONS="$PROJECT_DIR/build/ExportOptions.plist"
cat > "$EXPORT_OPTIONS" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>6FMDB5TQT5</string>
</dict>
</plist>
EOF

# 尝试用 exportArchive 导出；如果没有 Developer ID 证书则直接从 archive 拷贝
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    -exportPath "$EXPORT_PATH" \
    -quiet 2>/dev/null || {
    warn "exportArchive 失败（可能缺少 Developer ID 证书），直接从 Archive 拷贝 .app"
    cp -R "$ARCHIVE_PATH/Products/Applications/RightPlus.app" "$EXPORT_PATH/"
}

APP_PATH="$EXPORT_PATH/RightPlus.app"
if [ ! -d "$APP_PATH" ]; then
    error "导出 App 失败"
fi
info "App 导出成功: $APP_PATH"

# 显示 App 大小
APP_SIZE=$(du -sh "$APP_PATH" | cut -f1)
info "App 大小: $APP_SIZE"

# ============================================================
# 6. 打包 DMG
# ============================================================

info "正在打包 DMG..."
hdiutil create \
    -volname "RightPlus" \
    -srcfolder "$APP_PATH" \
    -ov \
    -format UDZO \
    "$DMG_PATH" \
    -quiet

if [ ! -f "$DMG_PATH" ]; then
    error "DMG 打包失败"
fi

DMG_SIZE=$(du -sh "$DMG_PATH" | cut -f1)
info "DMG 打包完成: $DMG_PATH ($DMG_SIZE)"

# ============================================================
# 7. 创建 Git Tag
# ============================================================

info "创建 Git 标签: $TAG"
git tag -a "$TAG" -m "Release $VERSION"

# ============================================================
# 8. 推送 Tag 并创建 Release
# ============================================================

info "推送标签到 GitHub..."
GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no" git push origin "$TAG"

info "创建 GitHub Release 并上传 DMG..."
gh release create "$TAG" \
    "$DMG_PATH" \
    --title "RightPlus $VERSION" \
    --notes "## RightPlus $VERSION

### 安装方式

1. 下载 \`$DMG_NAME\`
2. 双击挂载 DMG
3. 将 RightPlus 拖入「应用程序」文件夹
4. 打开 RightPlus，按引导页提示开启 Finder 扩展

### 系统要求

- macOS 13 Ventura 或更高版本"

# ============================================================
# 9. 完成
# ============================================================

echo ""
info "========================================"
info "发布完成!"
info "版本: $VERSION"
info "标签: $TAG"
info "DMG:  $DMG_PATH"
info "Release: https://github.com/xzagit/RightPlus/releases/tag/$TAG"
info "========================================"
