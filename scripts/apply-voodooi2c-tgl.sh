#!/bin/bash
# 给 VoodooI2C 的 Ice Lake 控制器匹配表追加 Tiger Lake 的 PCI ID (8086:a0e8)。
#
# 背景：VoodooI2C 2.9.1 的 VoodooI2CPCIIceLakeController 只匹配 0x34e8xxx，
#       Tiger Lake 的 I2C0/I2C1 是 8086:a0e8/a0e9，不在表里 → VoodooI2C 不加载。
#
# 用法:
#   bash scripts/apply-voodooi2c-tgl.sh                       # 自动找 /Volumes/EFI
#   bash scripts/apply-voodooi2c-tgl.sh /Volumes/EFI          # 指定 EFI 挂载点
#   bash scripts/apply-voodooi2c-tgl.sh /path/to/VoodooI2C.kext   # 直接指定 kext
#
# 只改 Info.plist（纯文本），不动二进制。改完会破坏代码签名，
# 需要 SecureBootModel=Disabled + AMFIPass 才能加载（本仓库已满足）。

set -euo pipefail

TGL_ID="0xa0e88086&0xFFFCFFFF"
PERS=":IOKitPersonalities:VoodooI2CPCIIceLakeController:IOPCIMatch"
PB=/usr/libexec/PlistBuddy

if [ "$(uname)" != "Darwin" ]; then
    echo "这个脚本要在 macOS 上跑（需要 PlistBuddy）。" >&2
    exit 1
fi

TARGET="${1:-}"

if [ -z "$TARGET" ]; then
    for m in /Volumes/EFI /Volumes/NO\ NAME; do
        if [ -d "$m/EFI/OC/Kexts/VoodooI2C.kext" ]; then
            TARGET="$m"
            break
        fi
    done
fi

if [ -z "$TARGET" ]; then
    echo "找不到 EFI 分区。请先 sudo diskutil mount disk0s1，然后把挂载点作为参数传进来。" >&2
    exit 1
fi

case "$TARGET" in
    *.kext) KEXT="$TARGET" ;;
    *)      KEXT="$TARGET/EFI/OC/Kexts/VoodooI2C.kext" ;;
esac

INFO="$KEXT/Contents/Info.plist"

if [ ! -f "$INFO" ]; then
    echo "找不到 $INFO" >&2
    exit 1
fi

echo "目标: $INFO"

CUR=$("$PB" -c "Print $PERS" "$INFO" 2>/dev/null || echo "")
if [ -z "$CUR" ]; then
    echo "读不到 $PERS —— 这个 VoodooI2C 版本可能没有 Ice Lake personality。" >&2
    exit 1
fi

echo "当前: $CUR"

case "$CUR" in
    *"0xa0e8"*)
        echo "已经包含 Tiger Lake ID，无需修改。"
        exit 0
        ;;
esac

cp -p "$INFO" "$INFO.bak"
echo "已备份到: $INFO.bak"

"$PB" -c "Set $PERS $CUR $TGL_ID" "$INFO"

NEW=$("$PB" -c "Print $PERS" "$INFO")
echo "修改后: $NEW"

case "$NEW" in
    *"0xa0e8"*)
        echo
        echo "✓ 完成。还需要确认两件事："
        echo "  1) config.plist 的 boot-args 里有 -vi2c-force-polling"
        echo "  2) Kernel → Add 里 VoodooI2C / VoodooGPIO / VoodooI2CHID / VoodooInput 均已启用"
        echo "  改完重启，用 bash scripts/verify.sh 的第 8 节确认。"
        ;;
    *)
        echo "✗ 写入失败，请还原 $INFO.bak" >&2
        exit 1
        ;;
esac
