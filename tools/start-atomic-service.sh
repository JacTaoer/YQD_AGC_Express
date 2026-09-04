#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLE_NAME="com.atomicservice.6917614461242904059"
ABILITY_NAME="EntryAbility"
HAP_PATH="$ROOT_DIR/products/entry/build/atomic/outputs/default/entry-default-unsigned.hap"

find_hdc() {
  if command -v hdc >/dev/null 2>&1; then command -v hdc; return; fi
  local sdk_root="${DEVECO_SDK_HOME:-$HOME/Library/Huawei/Sdk}"
  find "$sdk_root" -path '*/openharmony/toolchains/hdc' -type f -perm -111 -print -quit 2>/dev/null
}

HDC="$(find_hdc || true)"
if [ -z "$HDC" ]; then
  echo "未找到 hdc。请先启动 DevEco Studio 模拟器，并将 hdc 加入 PATH。" >&2
  exit 1
fi
if [ ! -f "$HAP_PATH" ]; then
  echo "未找到元服务 HAP：$HAP_PATH" >&2
  echo "请在 DevEco Studio 中选择 atomic product 构建后重试。" >&2
  exit 1
fi

echo "安装元服务 HAP..."
"$HDC" install -r "$HAP_PATH"
echo "启动元服务页面..."
"$HDC" shell aa start -b "$BUNDLE_NAME" -a "$ABILITY_NAME"
echo "已启动 $BUNDLE_NAME。系统胶囊只有从模拟器的元服务/服务中心入口拉起时才会显示。"
