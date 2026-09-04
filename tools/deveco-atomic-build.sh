#!/bin/zsh

# Keep the atomic-service build on the shared SSD DevEco installation.
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
DEVECO_APP="/Volumes/SSD/DevEco-Studio.app/Contents"
NODE_BIN="$DEVECO_APP/tools/node/bin/node"
HVIGOR="$DEVECO_APP/tools/hvigor/bin/hvigorw.js"
HDC="$DEVECO_APP/sdk/default/openharmony/toolchains/hdc"
PACKAGE_NAME="com.atomicservice.6917614461242904059"
HAP="$PROJECT_DIR/products/entry/build/atomic/outputs/default/entry-default-signed.hap"

for required in "$NODE_BIN" "$HVIGOR" "$HDC"; do
  [[ -x "$required" || -f "$required" ]] || { print -u2 "Missing DevEco tool: $required"; exit 1; }
done

cd "$PROJECT_DIR"
"$NODE_BIN" "$HVIGOR" --mode module \
  -p module=entry@default \
  -p product=atomic \
  -p requiredDeviceType=phone \
  assembleHap --analyze=normal --parallel --incremental --daemon

if (( ${+commands[hdc]} )) && [[ "$HDC" != "${commands[hdc]}" ]]; then
  : # Prefer the SSD hdc below even when another hdc is on PATH.
fi

if "$HDC" list targets | grep -q .; then
  "$HDC" shell aa force-stop "$PACKAGE_NAME" || true
  TEMP_DIR="data/local/tmp/expressmeta_atomic"
  "$HDC" shell rm -rf "$TEMP_DIR"
  "$HDC" shell mkdir "$TEMP_DIR"
  "$HDC" file send "$HAP" "$TEMP_DIR"
  INSTALL_OUTPUT=$("$HDC" shell bm install -r -p "$TEMP_DIR" 2>&1 || true)
  print "$INSTALL_OUTPUT"
  if [[ "$INSTALL_OUTPUT" == *"9568332"* || "$INSTALL_OUTPUT" == *"install sign info inconsistent"* ]]; then
    print "Existing simulator package uses another signature; reinstalling with the SSD DevEco signature."
    "$HDC" shell bm uninstall -n "$PACKAGE_NAME" || true
    "$HDC" shell bm install -p "$TEMP_DIR"
  elif [[ "$INSTALL_OUTPUT" != *"install bundle successfully"* ]]; then
    print -u2 "Failed to install atomic-service HAP."
    exit 1
  fi
  "$HDC" shell rm -rf "$TEMP_DIR"
  "$HDC" shell aa start -a EntryAbility -b "$PACKAGE_NAME" -m entry
else
  print "Build complete. No HarmonyOS device/emulator is connected; skipping install and launch."
fi
