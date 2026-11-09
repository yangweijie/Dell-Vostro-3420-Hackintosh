# Dell Vostro 3420 · macOS Tahoe 26 Hackintosh

Dell Vostro 3420（i5-1135G7 / Iris Xe / 无独显）上可日常使用的 OpenCore 配置，系统为 **macOS Tahoe 26.7.2（25G332）**。

内屏、Wi-Fi、蓝牙、声音、睡眠、内置键盘、触控板全部可用，**不依赖 U 盘启动**。  
唯一无法实现的是接力 / AirDrop —— 那要求 Apple 原厂 Wi-Fi+蓝牙组合卡，第三方 Realtek 卡物理上做不到。

> 这不是一个"能装上"的仓库，是一个"验收完"的仓库：每一项都附了判断依据（命令、日志、截图级别的输出），
> 以及踩过的坑。硬件不同的机器请当作参考而不是照抄。

---

## 硬件配置

| 部件 | 型号 | macOS 状态 |
|---|---|---|
| 机型 | Dell Vostro 3420 | — |
| CPU | Intel Core i5-1135G7（Tiger Lake-U，4C/8T） | ✅ 原生 |
| 核显 | Intel Iris Xe（`8086:9A49`） | ✅ 1536 MB / Metal 2 |
| 独显 | 无 | — |
| 硬盘 | SK hynix BC901 NVMe 256 GB | ✅ 原生 |
| 有线 | Realtek RTL8168（`10ec:8168`） | ✅ 原生 |
| 无线 | Realtek RTL8821CE（`10ec:c821`） | ✅ AirPortRTW + OCLP legacy 栈 |
| 蓝牙 | RTL8821CE 的 BT 部分（`0bda:c829`） | ✅ BlueToolFixup + RealtekBluetoothFirmware |
| 声卡 | Realtek ALC236（layout-id 7） | ✅ SimpleHDA + AppleALC |
| 键盘 | PS/2 | ✅ VoodooPS2（`ps2kbdonly=1`） |
| 触控板 | I2C HID（`DELL0B6A`，挂在 `8086:a0e8`） | ✅ VoodooI2C + 轮询模式 |
| 屏幕 | 1920×1080 内屏 | ✅ 30-bit / 60 Hz |
| SMBIOS | `MacBookPro16,1` | 需自行生成序列号 |

## 功能验收

| 功能 | 状态 | 说明 |
|---|---|---|
| 内屏 / 核显加速 | ✅ | Metal 2，亮度调节可用 |
| 有线网络 | ✅ | 原生驱动 |
| Wi-Fi | ✅ | 2.4/5 GHz、WPA2，睡眠唤醒后自动重连 |
| 蓝牙 | ✅ | 可搜索、可配对、可连接 |
| 声音 | ✅ | 扬声器 + 内置麦克风（含录音） |
| 睡眠 | ✅ | 合盖进 S3，开盖约 1.3 秒唤醒 |
| 内置键盘 | ✅ | 外接键盘插拔均不影响 |
| 触控板 | ✅ | 光标、点击、双指手势 |
| 接力 / AirDrop | ❌ | 需 Apple 原厂卡 |
| iMessage / FaceTime | ⚠️ | 填入你自己生成的 SMBIOS 后可尝试，不保证 |

---

## 这份 EFI 和实机跑的是同一份

不是"整理过的另一个版本"。发布前做过逐文件比对：

| 对比项 | 结果 |
|---|---|
| `EFI/OC` 文件数 | 实机 183 / 仓库 183 |
| 文件内容 | 除 `config.plist` 外 **183 个文件逐字节一致** |
| `config.plist` 差异 | 仅 4 处，全部是 SMBIOS 身份字段（序列号 / MLB / UUID / ROM）被替换为占位符 |
| `ocvalidate` | `No issues found` |
| 配置引用完整性 | 102 个引用（ACPI / kext / driver / tool）全部存在 |

也就是说：填上你自己的 SMBIOS 之后，这份 EFI 与验收通过的那份**完全等价**。

## 快速开始

### 1. 生成你自己的 SMBIOS（**必做**）

本仓库的 `EFI/OC/config.plist` 里序列号、MLB、UUID、ROM 都是占位符，直接引导不会有什么问题，
但 **iMessage / FaceTime / App Store 需要真实且唯一的身份**。用 [GenSMBIOS](https://github.com/corpnewt/GenSMBIOS) 生成一套：

```text
机型选择：MacBookPro16,1
```

把生成的 `Serial` / `MLB` / `SystemUUID` 填进 `PlatformInfo → Generic`，
`ROM` 填成你网卡 `en0` 的 MAC（去掉冒号，12 位十六进制）。

> 不要在网上抄别人的序列号：一是可能已被 Apple 封禁，二是会和别人的 iCloud 冲突。

### 2. 写入 EFI 分区

macOS 下：

```bash
# 找到内置硬盘的 EFI 分区（通常是 disk0s1）
diskutil list
sudo diskutil mount disk0s1

# 备份原有 EFI（重要，尤其是有 Windows 的双系统）
sudo cp -R /Volumes/EFI /Volumes/EFI.backup 2>/dev/null || true
sudo ditto ./EFI /Volumes/EFI
```

Windows 下：用 [DiskGenius](https://www.diskgenius.cn/) 或 `mountvol X: /S` 挂载 EFI 分区后拷贝。

### 3. 设置启动项

```bash
sudo bless --mount /Volumes/EFI --setBoot --file /Volumes/EFI/EFI/BOOT/BOOTx64.efi
```

如果返回 `Could not set boot device property: 0xe00002e2`（SIP 的 NVRAM 保护在拦），
不要紧 —— 改用 OpenCore 自带的启动项注册：把 `Misc → Boot → LauncherOption` 设为 `Full`，
从这块盘启动一次，OpenCore 会把自己写成第一启动项。

开机进 F12 选择 `EFI`/`UEFI: <你的硬盘>` 即可。

---

## 和"默认配置"不一样的六个地方

这些是本机真正的价值所在，每一项都在 [`docs/04-fixes-explained.md`](docs/04-fixes-explained.md) 里写了现象、诊断命令、根因和改法：

| # | 问题 | 关键改动 |
|---|---|---|
| 1 | Iris Xe 无加速 | WhateverXe 0.8.0 + Graphics 0.4.1，禁用 WhateverGreen，AMFIPass 处理签名 |
| 2 | Wi-Fi 不识别 | AirPortRTW 1.2.0 + OCLP Tahoe legacy 栈（IOSkywalkFamily 注入 + Kernel Block 原版） |
| 3 | 声音全空 | Tahoe 26 移除了 AppleHDA → **SimpleHDA 1.0.1**（须排在 AppleALC 之后） |
| 4 | 内置键盘失效 | boot-args `ps2kbdonly=1`：只初始化键盘端口，绕开 AUX 复位 |
| 5 | 触控板无反应 | VoodooI2C 匹配表加 Tiger Lake `0xa0e8` + `-vi2c-force-polling` |
| 6 | 睡眠只熄屏 | DSDT 打补丁把 `SS3` 从 `0` 改 `1`，让 `_S3` 真正存在 |
| 7 | 蓝牙不工作 | BlueToolFixup 2.7.2 + RealtekBluetoothFirmware 1.0.2 + 调整 NVRAM Delete |

其中第 6 条（睡眠）最容易被误判成"配置问题"，实际上是 **S0ix 机型 + BIOS 把 S3 关掉**，
`docs/04` 里有完整的判断链条。

---

## 目录结构

```text
EFI/
├── BOOT/BOOTx64.efi          OpenCore 引导器
└── OC/
    ├── ACPI/                 16 个 SSDT（含 PNLF / EC-USBX / GPI0 / SleepHook 等）
    ├── Drivers/              HfsPlus / OpenRuntime / OpenCanopy / ResetNvramEntry / apfs_aligned
    ├── Kexts/                24 个 kext
    ├── Resources/            OpenCanopy 主题资源
    ├── Tools/                
    └── config.plist          已脱敏，含 DSDT 的 SS3 补丁
docs/                         说明文档
scripts/                      自检脚本、VoodooI2C 补丁脚本
```

## 自检

装好之后跑一遍：

```bash
bash scripts/verify.sh
```

输出各子系统状态（核显、Wi-Fi、蓝牙、声卡、睡眠状态、键盘/触控板、kext 加载情况），
和本仓库验收时的检查项一致。

## 已知问题

见 [`docs/05-known-issues.md`](docs/05-known-issues.md)。要点：

- 接力 / AirDrop 不可用（硬件限制）
- 触控板为轮询模式，比中断模式略耗电
- 升级系统前必须看 [`docs/06-upgrade.md`](docs/06-upgrade.md)：`BlueToolFixup` 会让增量更新校验失败

## 致谢

所有 kext 均来自各自上游，本仓库未修改任何二进制，仅调整了 `VoodooI2C.kext` 的 `Info.plist`
（增加一个 PCI ID，附一键脚本）。完整清单与许可见 [`docs/08-credits.md`](docs/08-credits.md)。

特别感谢 Acidanthera（OpenCore / Lilu / VirtualSMC / AppleALC / BrcmPatchRAM）、
Alexandred（VoodooI2C / VoodooPS2）、laobamac（SimpleHDA）、JoMei9019（AirPort-RTW）、
thegwchr（RealtekBluetoothFirmware）、WhateverXe 项目，以及 OpenCore 中文社区的文档。

## License

本仓库的配置与文档以 MIT 发布；`EFI/` 内的第三方组件遵循各自许可，详见 `docs/08-credits.md`。

---

## English summary

Working OpenCore EFI for **Dell Vostro 3420 (i5-1135G7, Iris Xe)** running **macOS Tahoe 26.7.2**.
Internal display, Ethernet, Wi-Fi, Bluetooth, audio, S3 sleep, built-in keyboard and the I2C
touchpad all work; no USB stick required to boot. AirDrop/Handoff is **not** available — it needs
genuine Apple Wi-Fi/BT hardware.

Highlights: WhateverXe for Iris Xe, AirPortRTW + OCLP legacy Wi-Fi stack, SimpleHDA for the
AppleHDA-less Tahoe audio stack, `ps2kbdonly=1` for the PS/2 keyboard, a Tiger Lake PCI-ID patch
plus `-vi2c-force-polling` for the touchpad, and a DSDT byte patch flipping `SS3` so that ACPI
actually exposes `_S3` (this machine ships S0ix-only).

Generate your own SMBIOS before using. See `docs/` for the full diagnosis of each fix.
