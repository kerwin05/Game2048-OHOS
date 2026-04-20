#!/bin/bash
# ═══════════════════════════════════════════
# 赛博游戏厅 — Release 打包脚本
# 构建后自动重命名输出文件
# 命名格式: CyberArcade_v版本号_release/debug_日期时间.app/.hap
# ═══════════════════════════════════════════

set -e

# ── 配置 ──
APP_NAME="CyberArcade"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_TYPE="${1:-release}"  # 默认 release，可传参 debug
HVIGOR="$PROJECT_DIR/hvigorw"

# 从 app.json5 读取版本号
VERSION_NAME=$(grep -o '"versionName"[[:space:]]*:[[:space:]]*"[^"]*"' "$PROJECT_DIR/AppScope/app.json5" | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
VERSION_CODE=$(grep -o '"versionCode"[[:space:]]*:[[:space:]]*[0-9]*' "$PROJECT_DIR/AppScope/app.json5" | head -1 | sed 's/.*: *//')

# 时间戳
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# 输出目录
OUTPUT_DIR="$PROJECT_DIR/release"
mkdir -p "$OUTPUT_DIR"

echo "══════════════════════════════════════"
echo "  赛博游戏厅 打包脚本"
echo "  版本: v${VERSION_NAME} (${VERSION_CODE})"
echo "  类型: ${BUILD_TYPE}"
echo "  时间: ${TIMESTAMP}"
echo "══════════════════════════════════════"

# ── 构建 ──
echo ""
echo "[1/3] 清理旧构建..."
rm -rf "$PROJECT_DIR/entry/build"

echo "[2/3] 构建 ${BUILD_TYPE} 包..."
cd "$PROJECT_DIR"

# 使用 DevEco Studio 的 hvigor
HVIGOR_BIN="/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js"
NODE_BIN="/Applications/DevEco-Studio.app/Contents/tools/node/bin/node"

if [ -f "$NODE_BIN" ] && [ -f "$HVIGOR_BIN" ]; then
    "$NODE_BIN" "$HVIGOR_BIN" --mode module -p module=entry@default -p product=default assembleHap assembleApp --parallel --daemon
else
    echo "错误: 未找到 DevEco Studio 工具链"
    echo "请确保 DevEco Studio 已安装在 /Applications/DevEco-Studio.app"
    exit 1
fi

# ── 重命名 ──
echo ""
echo "[3/3] 重命名输出文件..."

# 构建产物路径（.hap 在 entry/build，.app 在项目根 build）
HAP_DIR="$PROJECT_DIR/entry/build/default/outputs/default"
APP_DIR="$PROJECT_DIR/build/outputs/default"

# 重命名 .hap 文件
for f in "$HAP_DIR"/*.hap; do
    if [ -f "$f" ]; then
        SIGNED_TYPE="unsigned"
        if echo "$f" | grep -q "signed"; then
            SIGNED_TYPE="signed"
        fi
        NEW_NAME="${APP_NAME}_v${VERSION_NAME}_${BUILD_TYPE}_${SIGNED_TYPE}_${TIMESTAMP}.hap"
        cp "$f" "$OUTPUT_DIR/$NEW_NAME"
        echo "  HAP: $NEW_NAME"
    fi
done

# 重命名 .app 文件
for f in "$APP_DIR"/*.app; do
    if [ -f "$f" ]; then
        SIGNED_TYPE="unsigned"
        if echo "$f" | grep -q "signed"; then
            SIGNED_TYPE="signed"
        fi
        NEW_NAME="${APP_NAME}_v${VERSION_NAME}_${BUILD_TYPE}_${SIGNED_TYPE}_${TIMESTAMP}.app"
        cp "$f" "$OUTPUT_DIR/$NEW_NAME"
        echo "  APP: $NEW_NAME"
    fi
done

echo ""
echo "══════════════════════════════════════"
echo "  打包完成！"
echo "  输出目录: release/"
echo "══════════════════════════════════════"
ls -lh "$OUTPUT_DIR"/*.app "$OUTPUT_DIR"/*.hap 2>/dev/null || echo "  (未找到输出文件，请在 DevEco Studio 中手动构建)"
