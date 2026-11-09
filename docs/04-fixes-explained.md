# 七项关键修复：现象、诊断、根因、改法

> 本文所有命令都在实机上跑过，输出是真实截取（已隐去 MAC / IP / 序列号）。
> 顺序按"踩坑难度"排，**睡眠和触控板两节最值得看** —— 这两处最容易走错方向。

---

## 1. Iris Xe 核显：黑屏 / 无加速 / 显存 7 MB

**现象**：能进系统但只有基础帧缓冲，显存显示 7 MB，`Metal` 不可用，动画卡顿。

**诊断**

```bash
system_profiler SPDisplaysDataType | grep -E "Chipset|VRAM|Metal"
# 修复前：VRAM 7 MB，无 Metal 行
```

**根因**：Tiger Lake 的 Iris Xe 在 macOS 上没有 Apple 官方驱动，只能走社区实验路线。

**改法**

- `WhateverXe.kext` **0.8.0**（0.7.0 在 Tiger Lake 上有已知回归，别用）
- 配合 `WhateverXe-Graphics` 安装包（0.4.1），通过它自带的 pkg 安装图形组件
- **禁用** `WhateverGreen.kext`（两者冲突）
- `AMFIPass.kext` 1.4.1 处理签名，boot-args 带 `-allow3d -disablegfxfirmware`

**验证**

```bash
system_profiler SPDisplaysDataType | grep -E "Chipset|VRAM|Metal|Resolution"
# Chipset Model: Intel Iris Xe Graphics
# VRAM (Dynamic, Max): 1536 MB
# Metal Support: Metal 2
# Resolution: 1920 x 1080
```

**坑**：这条路线是实验性的，接受它就意味着接受它的限制（见 `05-known-issues.md`）。

---

## 2. Wi-Fi：RTL8821CE 完全不出现

**现象**：`networksetup -listallhardwareports` 里没有 Wi-Fi 端口。

**诊断**

```bash
networksetup -listallhardwareports | grep -A2 Wi-Fi    # 无输出
ioreg -l | grep -i "10ec,c821"                         # 能查到 PCI 设备
```

**根因**：Tahoe 26 移除了旧的 `IO80211` 无线栈，第三方 Realtek 驱动失去宿主。

**改法**

三层缺一不可：

1. `AirPortRTW.kext` **1.2.0** —— 驱动本体（本项目对应的上游是 AirPort-RTW）
2. `IOSkywalkFamily.kext` **1.2.0** —— 注入新版，提供 AirPortRTW 依赖的接口
3. `IO80211FamilyLegacy.kext` **1.0.0** + **`Kernel → Block` 屏蔽原版 `com.apple.iokit.IOSkywalkFamily`**

```text
Kernel → Block:
  Identifier      com.apple.iokit.IOSkywalkFamily
  Enabled         true
```

顺序必须是：`Lilu` → `IOSkywalkFamily` → `IO80211FamilyLegacy` → `AirPortRTW`。

**验证**

```bash
networksetup -listallhardwareports | grep -A2 Wi-Fi   # 出现 en1
ifconfig en1 | grep -E "status|inet "
# status: active / inet 192.168.x.x
```

再做一个**绑定接口**的真实传输测试（不要只看到"已连接"就算过）：

```bash
curl --interface en1 -o /tmp/t.bin https://example.com/somefile
shasum -a 256 /tmp/t.bin    # 与预期值比对
```

**坑**：只装 `AirPortRTW` 不屏蔽 IOSkywalkFamily，会出现"驱动加载了但网卡不工作"。

---

## 3. 声音：设备列表空的

**现象**：`系统设置 → 声音` 里没有任何输出/输入设备，`SPAudioDataType` 的 `Devices:` 为空。

**诊断**

```bash
system_profiler SPAudioDataType | head -20
kmutil showloaded | grep -iE "applehda|applealc|simplehda"
ioreg -l | grep -E "layout-id|alc-layout-id" | head -4
# layout-id = <07000000>  alc-layout-id = <03000000>
```

**根因**：**Tahoe 26 直接删掉了 `AppleHDA.kext`**。AppleALC 本身只是补丁集，没有 AppleHDA
它无处施展 —— 所以会看到 AppleALC 已加载但 `!registered, !matched`。

**改法**

- `SimpleHDA.kext` **1.0.1**（Tahoe 专用，把 AppleHDA 的音频引擎补回来）
- 加载顺序：`Lilu` → `AppleALC` → `SimpleHDA`
- `layout-id = 7`（本机 ALC236 对应），boot-args 里保留 `alcid=3` 作为兜底
- `Kernel → Quirks → DisableLinkeditJettison = true`

**验证**

```bash
system_profiler SPAudioDataType | grep -E "内建输出|内建输入|Default Output|Output Source"
# 内建输出 / 默认输出设备 / 内置扬声器
# 内建输入 / 默认输入设备 / 内置麦克风

ioreg -rc AppleHDAEngineInput -w0 | head -2
# +-o AppleHDAEngineInput@1F,3,0,1,0 ... registered, matched, active
```

**真的要确认能用，必须放声音 + 录音**：

```bash
afplay /System/Library/Sounds/Glass.aiff        # 听得到才算过
# 录音没有系统自带 CLI，用「语音备忘录」或 QuickTime 新建音频录制
```

**坑**：`afrecord` 是 Linux/sox 的工具，macOS 上不存在；`say -v <中文语音>` 如果只生成
4 KB 左右的文件，那是语音包没下载（Tahoe 里很多中文语音是占位包），不是音频故障。

---

## 4. 内置键盘：能进登录界面，进桌面就废

**现象**：登录界面能用内置键盘输密码；进桌面后按什么都没反应。
拔掉外接 USB 键盘 → 内置键盘立刻失效，插回去也不恢复。Caps Lock 灯不亮。

**诊断（关键：用客观指标，别靠感觉）**

`HIDIdleTime` 会在任何 HID 事件发生时归零，可以当"按键有没有被系统收到"的探针：

```bash
# 1 Hz 采样 30 秒，期间只按内置键盘、不碰鼠标
while true; do date +%T; ioreg -c IOHIDSystem | grep HIDIdleTime | head -1; sleep 1; done
```

- 修复前：数值单调递增（110 s → 141 s），**零重置** → 系统一个事件都没收到
- 对照（按外接键盘）：数值被重置 4 次 → 证明测量方法有效

再看驱动栈：

```bash
kmutil showloaded | grep -i ps2
ioreg -rc ApplePS2Controller -w0 | head -2
ioreg -rc ApplePS2Keyboard -w0 | head -2
hidutil list --matching '{"PrimaryTransport":"PS2"}'
```

结果会是"全部正常"：`ApplePS2Controller` / `ApplePS2KeyboardDevice(Port 0)` /
`ApplePS2Keyboard` 都 registered+matched+active，ACPI 的 `PS2K` 也是标准
`IO 0x60/0x64 + IRQ1`、`_STA=0x0F`。

**根因**：VoodooPS2 会同时探测 **AUX（触控板）端口**，PS2M 侧的复位会把键盘端口的事件通道一起弄丢。
所以"驱动都在、就是没事件"。

**改法**：boot-args 加一个参数——

```text
ps2kbdonly=1
```

它让 VoodooPS2 只初始化键盘端口，完全跳过 AUX 探测。

**验证**：三种场景都要过

1. 外接键盘插着 → 内置键盘可用
2. 运行中拔掉外接键盘 → 内置键盘仍可用（`HIDIdleTime` 在按键时归零）
3. 开机时就不插外接键盘 → 登录、桌面都能输入

**坑**：一开始会怀疑是键位映射、是焦点被抢、是 Secure Input。
但 `HIDIdleTime` 零重置直接排除了这些可能 —— **先证明事件有没有到达系统，再谈映射**。

---

## 5. 触控板：VoodooI2C 装了却完全不加载

**现象**：光标不动、无点击。`kmutil showloaded` 里只有 `VoodooI2CServices`，
`VoodooI2C` / `VoodooI2CHID` / `VoodooGPIO` / `VoodooInput` 一个都没加载。
但 OpenCore 日志里它们的注入全是 `Success`。

**诊断**

```bash
# 1) 注入成功 ≠ 加载成功
grep -i "VoodooI2C" /Volumes/EFI/opencore-*.txt | tail -6
#   OC: Prelinked injection VoodooI2C.kext () - Success

kmutil showloaded | grep -i voodooi2c
#   只有 VoodooI2CServices

# 2) 控制器在 PCI 上吗？
ioreg -w0 -rc IOPCIDevice | grep -E "I2C0@|I2C1@"
#   +-o I2C0@15  / +-o I2C1@15,1

ioreg -rc IOPCIDevice -l -w0 | grep -A6 "I2C0@15"
#   "device-id" = <e8a00000>   → 8086:a0e8（Tiger Lake）
#   "class-code" = <00800c00>  → I2C 控制器

# 3) 有驱动绑上去吗？
ioreg -rc AppleIntelLpssI2CController -w0     # 空 → 没人接
```

**根因**：`VoodooI2C 2.9.1` 的控制器匹配表只到 **Ice Lake `0x34e8`**，
Tiger Lake 的 `a0e8/a0e9` 不在表里 —— 它等不到宿主，自然不会加载。

> 注意：`AppleIntelLpssI2C.kext` 的 `IOPCIMatch` 是 `0x80608086&0xc278ffff`，
> `a0e8` 落在掩码之外，所以指望 Apple 的驱动先接管也走不通。

**改法**（两处，缺一不可）

**① 给 VoodooI2C 加 Tiger Lake 的 PCI ID**

编辑 `EFI/OC/Kexts/VoodooI2C.kext/Contents/Info.plist`，
在 `IOKitPersonalities → VoodooI2CPCIIceLakeController → IOPCIMatch` 里追加一段：

```text
0x34e88086&0xFFFCFFFF 0xa0e88086&0xFFFCFFFF
```

仓库里已附一键脚本：

```bash
bash scripts/apply-voodooi2c-tgl.sh /Volumes/EFI/EFI/OC/Kexts/VoodooI2C.kext
```

**② boot-args 加 `-vi2c-force-polling`**

Tiger Lake 的 GPIO 中断在 `VoodooGPIO` 里没有可靠实现，只能走轮询模式
（手势仍然正常，代价是略耗电）。

**验证**

```bash
kmutil showloaded | grep -iE "voodooi2c|voodooinput|voodoogpio"
#  VoodooI2C 2.9.1 / VoodooGPIO 1.1 / VoodooI2CHID / VoodooInput 1.1.7 全部加载

ioreg -rc VoodooI2CPCIController -w0 | head -2          # registered/matched/active
ioreg -rc VoodooI2CHIDDevice -w0 | head -2              # registered/matched/active
ioreg -rc VoodooI2CPrecisionTouchpadHIDEventDriver -w0 | head -2

hidutil list --matching '{"PrimaryUsagePage":13}'
#  I2C  AppleMultitouchDevice  "Magic Trackpad 2"  Built-In 1
```

**坑**：改 `Info.plist` 会破坏 kext 的代码签名。本机 `SecureBootModel=Disabled` + `AMFIPass`
的情况下仍能加载；如果加载失败，表现就是回到"只有 VoodooI2CServices"，不会更糟。

---

## 6. 睡眠：只熄屏，永远不进 S3（本项目最隐蔽的一处）

**现象**：Apple 菜单 → 睡眠、`pmset sleepnow`、合盖，三种方式都只是屏幕黑掉，
风扇停一会儿又转，机身一直是温的，唤醒后**不需要输密码**（因为根本没睡）。

**诊断第一步：区分"没睡"和"睡了又醒"**

```bash
pmset -g log | grep -c "Entering Sleep"     # 0  → 从来没进过睡眠
sysctl kern.sleeptime                        # epoch 0 → 一次都没睡过
pmset -g log | grep "Sleep/Wakes since boot" # :0
```

**诊断第二步：谁在阻止？**

```bash
pmset -g assertions
#   PreventUserIdleSystemSleep  1  bluetoothd "com.apple.bluetooth.bluetool.script"
#   Kernel Assertions: com.apple.pci.hostBridge.preventSleep
```

把 U 盘卸载（消除 `ExternalMedia`）、`killall bluetoothd`（会被 launchd 重建）、
改成纯 S3 策略，全都试过 —— **仍然不睡**。说明不是"被断言拦"，而是**平台没有 S3**。

**诊断第三步：平台到底有没有 S3**

```bash
log show --style compact --predicate 'eventMessage CONTAINS "sleep states"' | tail -3
#   (AppleACPIPlatform) ACPI: sleep states S4 S5      ← 只有 S4/S5，没有 S3！
```

交叉验证 FADT 标志：

```text
FADT flags = 0x20C4F5
bit21 = LOW_POWER_S0_IDLE_CAPABLE = 1   → 这是一台 S0ix（Modern Standby）机型
```

再看 DSDT 里 `_S3` 是怎么定义的：

```asl
Name (SS3, Zero)      // 第 615 行：BIOS 把它置 0

If (SS3)              // 第 74590 行
{
    Name (_S3, Package (0x04) { 0x05, 0x00, 0x00, 0x00 })
}
```

**根因**：Dell 在固件里把 S3 关掉、只保留 S0ix（Windows 的 Modern Standby）。
`_S3` 的定义其实一直在 DSDT 里，只是被 `SS3` 这个开关挡住了。
macOS 的 Intel 电源管理**只认 S3**，不支持 S0ix —— 所以它只能熄屏。

BIOS 里也没有 `Sleep Mode` 选项（F2 翻过，确认没有），所以只能从 ACPI 层面改。

**改法**：把 `SS3` 从 `Zero` 改成 `One`，让 DSDT 自己把 `_S3` 建出来。

先确认字节模式在整张表里唯一：

```python
# Name (SS3_, Zero) 的 AML 编码
b"\x08SS3_\x00"        # 08 53 53 33 5F 00
```

然后加一条 OpenCore ACPI 补丁（`ACPI → Patch`）：

| 字段 | 值 |
|---|---|
| Comment | `SS3=One: expose _S3 for S3 sleep` |
| TableSignature | `DSDT` (`44534454`) |
| Find | `085353335F00` |
| Replace | `085353335F01` |
| Count | 1 |
| Enabled | true |

等长替换（6 → 6 字节），偏移 `0x2360`，全表唯一匹配。

**上机前可以先离线验证**：

```bash
# 把补丁打到 DSDT 副本上再反编译
python3 - <<'PY'
d = bytearray(open("DSDT.aml","rb").read())
i = d.find(bytes.fromhex("085353335F00"))
d[i:i+6] = bytes.fromhex("085353335F01")
open("DSDT-patched.aml","wb").write(d)
PY
iasl -d DSDT-patched.aml
grep -n "Name (SS3" DSDT-patched.dsl     # → Name (SS3, One)
```

**验证**

```bash
log show --style compact --predicate 'eventMessage CONTAINS "sleep states"' | tail -1
#   ACPI: sleep states S3 S4 S5        ← S3 出现了

# 合盖睡 20 秒，再开盖，然后看：
pmset -g log | grep -E "Entering Sleep|Wake from"
#   01:59:51 Sleep  Entering Sleep state due to 'Clamshell Sleep' ... 20 secs
#   02:00:11 Wake   Wake from Normal Sleep : due to /UserActivity
sysctl kern.sleeptime kern.waketime
```

本机实测：S3 持续约 20 秒，唤醒耗时 **1.271 秒**，唤醒后 Wi-Fi 数秒内自动重连。

**坑**：

- 别被 `bluetoothd` 的 `PreventUserIdleSystemSleep` 带偏 —— 那只影响**空闲**睡眠，不拦强制睡眠
- 别被 `com.apple.pci.hostBridge.preventSleep` 带偏 —— 它是结果不是原因（某次启动出现过，后来自己消失，睡眠依然不行）
- **先证明平台有没有 S3，再改任何参数**。判断依据就是启动时那一行 `ACPI: sleep states`
- 强制 S3 在个别 S0ix 机型上可能睡下去唤不醒；改之前准备好 U 盘和 EFI 备份

---

## 7. 蓝牙：`0bda:c829` 状态 Off、固件 `v0 c0`

**现象**

```bash
system_profiler SPBluetoothDataType
#   Address: NULL           ← 连 MAC 都没分到
#   State: Off
#   Chipset: BCM_4350C2     ← 占位值
#   Firmware Version: v0 c0
```

**诊断**

```bash
ioreg -l -w0 | grep -A6 'Bluetooth Radio' | grep -E 'idVendor|idProduct'
#   idVendor  = 3034 (0x0BDA)
#   idProduct = 51241 (0xC829)   → Realtek RTL8821CE 的蓝牙部分
```

**根因**：Realtek 的 USB 蓝牙需要**固件注入**才能被 `bluetoothd` 接管；
Tahoe 12+ 还需要 `BlueToolFixup` 打掉系统对非 Apple 控制器的限制。

**改法**

1. `BlueToolFixup.kext` **2.7.2**（来自 BrcmPatchRAM 项目）
2. `RealtekBluetoothFirmware.kext` **1.0.2**
3. `NVRAM → Delete` 里**不要**删这两个变量（删了会让控制器反复失败）：

```text
bluetoothExternalDongleFailed
bluetoothInternalControllerInfo
```

**验证**

```bash
system_profiler SPBluetoothDataType
#   Address: xx:xx:xx:xx:xx:xx      ← 不再是 NULL，且与 Wi-Fi 的 MAC 连续（同一颗组合卡）
#   State: On
#   Chipset: THIRD_PARTY_DONGLE
#   Firmware Version: v61592 c30136

ioreg -rc IOBluetoothHCIController -l -w0 | grep -E "BluetoothTransportConnected|BTAddress"
#   "BluetoothTransportConnected" = Yes
#   "BTAddress" = <xxxxxxxxxxxx>
```

真正的验收还是**配对一次**：能搜到设备并连上。

**坑（我自己踩的）**：`RTLBluetoothFirmware` 的 README 写着
"Not compatible with Wi-Fi + Bluetooth combos"，我据此排除了它；
但它的 `Info.plist` 里明确有 `RealtekBluetoothFirmware_0bda_c829` 这一项，实测完全可用。
**判断一个 kext 支不支持你的设备，看它的匹配表，别只看 README。**
