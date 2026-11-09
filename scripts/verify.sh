#!/bin/bash
# Dell Vostro 3420 Hackintosh - 装后自检
# 用法: bash scripts/verify.sh
# 只读脚本，不修改任何东西。

set -u

PASS=0
FAIL=0
WARN=0

c_ok()   { printf "  \033[32m✓\033[0m %s\n" "$1"; PASS=$((PASS+1)); }
c_bad()  { printf "  \033[31m✗\033[0m %s\n" "$1"; FAIL=$((FAIL+1)); }
c_warn() { printf "  \033[33m!\033[0m %s\n" "$1"; WARN=$((WARN+1)); }
sect()   { printf "\n\033[1m%s\033[0m\n" "$1"; }

have() { command -v "$1" >/dev/null 2>&1; }

# 单行输出某个命令的首个匹配
grab() { "$@" 2>/dev/null | head -1; }

sect "0. 系统"
sw_vers
echo "  内核启动时间: $(sysctl -n kern.boottime 2>/dev/null)"
[ -d /System/Library/Extensions ] && c_ok "系统卷可读" || c_bad "系统卷异常"

sect "1. 核显（WhateverXe）"
GPU=$(system_profiler SPDisplaysDataType 2>/dev/null)
echo "$GPU" | grep -q "Intel Iris Xe" && c_ok "识别为 Intel Iris Xe" || c_bad "未识别 Iris Xe"
echo "$GPU" | grep -q "1536 MB"        && c_ok "VRAM 1536 MB"         || c_warn "VRAM 不是 1536 MB（$(echo "$GPU" | grep 'VRAM' | head -1 | sed 's/^ *//')）"
echo "$GPU" | grep -q "Metal 2"        && c_ok "Metal 2 可用"        || c_bad "Metal 不可用"

sect "2. 有线网络"
if networksetup -listallhardwareports 2>/dev/null | grep -q "Device: en0"; then
    c_ok "en0 存在"
    IP=$(ipconfig getifaddr en0 2>/dev/null)
    [ -n "${IP:-}" ] && c_ok "en0 已获取地址 ${IP%%.*}.*" || c_warn "en0 未获取 IP"
else
    c_bad "未找到 en0"
fi

sect "3. Wi-Fi（AirPortRTW + legacy 栈）"
if networksetup -listallhardwareports 2>/dev/null | grep -q "Device: en1"; then
    c_ok "en1 存在"
    PW_STATE=$(networksetup -getairportpower en1 2>/dev/null | awk '{print $NF}')
    [ "$PW_STATE" = "On" ] && c_ok "Wi-Fi 电源已开" || c_warn "Wi-Fi 电源为 $PW_STATE"
    if ifconfig en1 2>/dev/null | grep -q "status: active"; then
        c_ok "en1 已关联"
    else
        c_warn "en1 未关联（如果是有线在用可以忽略）"
    fi
else
    c_bad "未找到 en1（检查 AirPortRTW / IOSkywalkFamily / IO80211FamilyLegacy 与 Kernel Block）"
fi

sect "4. 蓝牙"
BT=$(system_profiler SPBluetoothDataType 2>/dev/null)
echo "$BT" | grep -q "State: On" && c_ok "蓝牙已开启" || c_bad "蓝牙未开启"
echo "$BT" | grep -q "Address: NULL" && c_bad "没有分配 MAC（固件未注入）" || c_ok "已分配 MAC"
if echo "$BT" | grep -q "Firmware Version: v0 c0"; then
    c_bad "固件版本 v0 c0（未注入）"
else
    c_ok "固件已注入"
fi
kmutil showloaded 2>/dev/null | grep -q "BlueToolFixup" && c_ok "BlueToolFixup 已加载" || c_bad "BlueToolFixup 未加载"
kmutil showloaded 2>/dev/null | grep -q "RealtekBluetoothFirmware" && c_ok "RealtekBluetoothFirmware 已加载" || c_bad "RealtekBluetoothFirmware 未加载"

sect "5. 音频（SimpleHDA）"
AUD=$(system_profiler SPAudioDataType 2>/dev/null)
echo "$AUD" | grep -q "内建输出" && c_ok "内建输出存在" || c_bad "无内建输出"
echo "$AUD" | grep -q "内建输入" && c_ok "内建输入存在" || c_bad "无内建输入"
kmutil showloaded 2>/dev/null | grep -q "SimpleHDA" && c_ok "SimpleHDA 已加载" || c_bad "SimpleHDA 未加载"
kmutil showloaded 2>/dev/null | grep -q "AppleALC"  && c_ok "AppleALC 已加载"  || c_bad "AppleALC 未加载"

sect "6. 睡眠（S3 是否暴露）"
STATES=$(/usr/bin/log show --style compact --predicate 'eventMessage CONTAINS "sleep states"' 2>/dev/null | grep "ACPI: sleep states" | tail -1)
if [ -n "$STATES" ]; then
    echo "  $STATES"
    case "$STATES" in
        *"S3"*) c_ok "平台暴露了 S3" ;;
        *)      c_bad "没有 S3（检查 ACPI 的 SS3 补丁）" ;;
    esac
else
    c_warn "读不到启动时的 sleep states 日志"
fi
HIB=$(pmset -g 2>/dev/null | awk '/hibernatemode/{print $2}')
[ "${HIB:-x}" = "0" ] && c_ok "hibernatemode=0（纯 S3）" || c_warn "hibernatemode=${HIB:-?}（本仓库期望 0）"

sect "7. 内置键盘（ps2kbdonly=1）"
kmutil showloaded 2>/dev/null | grep -qi "voodoo.driver.PS2Keyboard" && c_ok "VoodooPS2Keyboard 已加载" || c_bad "VoodooPS2Keyboard 未加载"
if nvram -p 2>/dev/null | grep -q "ps2kbdonly=1"; then
    c_ok "boot-args 含 ps2kbdonly=1"
else
    c_warn "boot-args 里没有 ps2kbdonly=1"
fi

sect "8. 触控板（VoodooI2C + 轮询）"
kmutil showloaded 2>/dev/null | grep -q "VoodooI2C (" && c_ok "VoodooI2C 已加载" || c_bad "VoodooI2C 未加载"
kmutil showloaded 2>/dev/null | grep -q "VoodooGPIO"      && c_ok "VoodooGPIO 已加载" || c_warn "VoodooGPIO 未加载"
kmutil showloaded 2>/dev/null | grep -q "VoodooI2CHID"    && c_ok "VoodooI2CHID 已加载" || c_bad "VoodooI2CHID 未加载"
if ioreg -rc VoodooI2CPrecisionTouchpadHIDEventDriver -w0 2>/dev/null | grep -q "matched"; then
    c_ok "触控板 HID 驱动已匹配"
else
    c_bad "触控板 HID 驱动未匹配"
fi
if hidutil list --matching '{"PrimaryUsagePage":13}' 2>/dev/null | grep -q "I2C"; then
    c_ok "hidutil 可见 I2C 数字化设备"
else
    c_bad "hidutil 看不到 I2C 数字化设备"
fi

sect "9. 存储与电源"
diskutil list 2>/dev/null | grep -q "Apple_APFS" && c_ok "APFS 容器存在" || c_bad "未见 APFS 容器"
pmset -g batt 2>/dev/null | grep -q "%" && c_ok "电池读数正常" || c_warn "无电池读数"

printf "\n\033[1m=== 汇总: 通过 %d, 失败 %d, 提示 %d ===\033[0m\n" "$PASS" "$FAIL" "$WARN"
if [ "$FAIL" -gt 0 ]; then
    echo "有失败项。请对照 docs/04-fixes-explained.md 中对应小节排查。"
    exit 1
fi
echo "全部关键项通过。"
