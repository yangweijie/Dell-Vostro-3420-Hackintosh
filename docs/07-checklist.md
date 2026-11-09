# 装后自检清单

按顺序跑，每项都能自己判断对错。全部通过说明配置在这台机器上是完整的。

也可以一条命令跑完：`bash scripts/verify.sh`

---

## 1. 系统与引导

```bash
sw_vers
# 期望 ProductVersion: 26.x，BuildVersion: 25Gxxx

sysctl -n kern.boottime
# 确认是本次开机时间

shasum -a 256 /Volumes/EFI/EFI/OC/config.plist
# 和仓库对比，确认没被改过
```

## 2. 核显

```bash
system_profiler SPDisplaysDataType | grep -E "Chipset|VRAM|Metal|Resolution"
```

期望：

```text
Chipset Model: Intel Iris Xe Graphics
VRAM (Dynamic, Max): 1536 MB
Metal Support: Metal 2
Resolution: 1920 x 1080
```

## 3. 有线网络

```bash
networksetup -listallhardwareports | grep -A2 Ethernet
ifconfig en0 | grep "inet "
```

## 4. Wi-Fi

```bash
networksetup -listallhardwareports | grep -A2 Wi-Fi     # 应有 en1
networksetup -getairportpower en1                       # Wi-Fi Power (en1): On
ifconfig en1 | grep -E "status|inet "
```

真实传输测试（别只看"已连接"）：

```bash
curl --interface en1 -o /tmp/wifi-test.bin -L https://raw.githubusercontent.com/acidanthera/Lilu/master/README.md
ls -l /tmp/wifi-test.bin     # 非 0 字节
```

## 5. 蓝牙

```bash
system_profiler SPBluetoothDataType | grep -E "State|Address|Chipset|Firmware"
```

期望：`State: On`、`Address` 是真实 MAC（不是 NULL）、`Firmware Version` 不是 `v0 c0`。

```bash
kmutil showloaded | grep -iE "BlueToolFixup|RealtekBluetoothFirmware"
```

最后**实际配对一次**设备才算过。

## 6. 声音

```bash
system_profiler SPAudioDataType | grep -E "内建输出|内建输入|Default Output|Output Source"
ioreg -rc AppleHDAEngineInput -w0 | head -2
```

功能测试：

```bash
afplay /System/Library/Sounds/Glass.aiff     # 要真的听到
# 录音用「语音备忘录」或 QuickTime，确认能录到自己的声音
```

## 7. 睡眠

```bash
# 先确认平台暴露了 S3
log show --style compact --predicate 'eventMessage CONTAINS "sleep states"' | tail -1
# 期望：ACPI: sleep states S3 S4 S5
```

然后合盖 20 秒再开盖，检查：

```bash
pmset -g log | grep -E "Entering Sleep|Wake from" | tail -4
sysctl kern.sleeptime kern.waketime
```

期望看到 `Entering Sleep state due to 'Clamshell Sleep'` 和 `Wake from Normal Sleep`。

## 8. 内置键盘

```bash
kmutil showloaded | grep -i ps2
hidutil list --matching '{"PrimaryTransport":"PS2"}'
```

功能测试：拔掉外接键盘，用内置键盘打字，**仍然可用**才算过（这是本机的关键回归点）。

## 9. 触控板

```bash
kmutil showloaded | grep -iE "voodooi2c|voodoogpio|voodooinput"
ioreg -rc VoodooI2CPrecisionTouchpadHIDEventDriver -w0 | head -2
hidutil list --matching '{"PrimaryUsagePage":13}'
```

期望 `hidutil` 里出现 `I2C ... AppleMultitouchDevice`，且光标可动、点击与双指手势正常。

## 10. 存储

```bash
diskutil list
df -h /
```

## 11. 电源管理

```bash
pmset -g
pmset -g batt
```

期望 `hibernatemode 0`、`standby 0`（本仓库的设置），电池百分比正常。

---

## 出问题时的顺序

1. 先看这一项在 `04-fixes-explained.md` 里对应哪一节，照"诊断"命令重跑
2. 确认相关 kext 是否真的加载（`kmutil showloaded | grep <名字>`）——
   注入成功 ≠ 加载成功
3. 确认 ACPI 补丁是否还匹配（`ioreg` / 内核日志）
4. 一次只改一个变量，改完重启验证
