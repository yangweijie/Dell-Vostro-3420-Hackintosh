# 第三方组件与致谢

本仓库**没有修改任何 kext 的二进制**。唯一的改动是 `VoodooI2C.kext/Contents/Info.plist`
里增加了一个 PCI ID（纯文本 plist 编辑，附带一键脚本 `scripts/apply-voodooi2c-tgl.sh`）。

各组件版权归各自作者所有，本仓库不重新授权它们。**准确的许可条款请以各上游仓库的 LICENSE 为准**
（下表标注的许可证仅作参考，如有出入以上游为准）。

## 引导与核心

| 组件 | 版本 | 作者 / 上游 | 许可 |
|---|---|---|---|
| OpenCore | 1.0.8 | [Acidanthera](https://github.com/acidanthera/OpenCorePkg) | BSD-3-Clause |
| Lilu | 1.7.3 | [Acidanthera](https://github.com/acidanthera/Lilu) | BSD-3-Clause |
| VirtualSMC + SMCProcessor / SMCSuperIO / SMCBatteryManager / SMCLightSensor / SMCDellSensors | 1.3.x | [Acidanthera](https://github.com/acidanthera/VirtualSMC) | BSD-3-Clause |
| AMFIPass | 1.4.1 | [dortania](https://github.com/dortania/OpenCore-Legacy-Patcher) 生态 | 见上游 |
| HfsPlus / OpenRuntime / OpenCanopy / ResetNvramEntry | 随 OpenCore 1.0.8 | Acidanthera | BSD-3-Clause |
| apfs_aligned.efi | 社区变体 | 用于 APFS 驱动对齐问题，见上游 | 见上游 |

## 显卡

| 组件 | 版本 | 上游 | 许可 |
|---|---|---|---|
| WhateverXe | 0.8.0 | [WhateverXe 项目](https://github.com/)（实验性 Iris Xe 驱动路线） | 见上游 |
| WhateverXe-Graphics（pkg） | 0.4.1 | 同上 | 见上游 |
| WhateverGreen | — | [Acidanthera](https://github.com/acidanthera/WhateverGreen) | BSD-3-Clause |

> `WhateverGreen.kext` 在 `Kexts/` 里保留但**未启用**（与 WhateverXe 冲突）。

## 网络

| 组件 | 版本 | 上游 | 许可 |
|---|---|---|---|
| RealtekRTL8111 | 2.4.2 | [Mieze](https://github.com/Mieze/RTL8111_driver_for_OS_X) | GPL-2.0 |
| AirPortRTW | 1.2.0 | [JoMei9019-real/AirPort-RTW](https://github.com/JoMei9019-real/AirPort-RTW) | 见上游 |
| IOSkywalkFamily | 1.2.0 | 社区 Tahoe legacy 无线栈 | 见上游 |
| IO80211FamilyLegacy | 1.0.0 | [OCLP](https://github.com/dortania/OpenCore-Legacy-Patcher) 生态 | 见上游 |
| BlueToolFixup | 2.7.2 | [Acidanthera/BrcmPatchRAM](https://github.com/acidanthera/BrcmPatchRAM) | 见上游 |
| RealtekBluetoothFirmware | 1.0.2 | [thegwchr](https://github.com/thegwchr) 的 Realtek Bluetooth 固件注入 | 见上游 |

## 音频

| 组件 | 版本 | 上游 | 许可 |
|---|---|---|---|
| AppleALC | 1.9.8 | [Acidanthera](https://github.com/acidanthera/AppleALC) | BSD-3-Clause |
| SimpleHDA | 1.0.1 | [laobamac/SimpleHDA](https://github.com/laobamac/SimpleHDA) | 见上游 |

## 输入

| 组件 | 版本 | 上游 | 许可 |
|---|---|---|---|
| VoodooPS2Controller + VoodooPS2Keyboard | 2.3.8 | [Acidanthera/VoodooPS2](https://github.com/acidanthera/VoodooPS2) | 见上游 |
| VoodooI2C（含 GPIO / HID / Services / Input 插件） | 2.9.1 | [VoodooI2C](https://github.com/VoodooI2C/VoodooI2C) | 见上游（GPL 系列） |
| BrightnessKeys | — | [Acidanthera](https://github.com/acidanthera/BrightnessKeys) | BSD-3-Clause |
| USBInjectAll | — | [RehabMan 衍生](https://github.com/Sniki/OS-X-USB-Inject-All) | 见上游 |
| XHCI-unsupported | — | 社区 | 见上游 |

## 本仓库自己的内容

- `EFI/OC/config.plist` 的配置、ACPI 选择与补丁
- `docs/` 全部文档
- `scripts/` 脚本

以 MIT 发布（见仓库根目录 `LICENSE`）。这部分**不覆盖**上表中的第三方组件。

---

## 特别感谢

- **Acidanthera** —— OpenCore、Lilu、VirtualSMC、AppleALC、VoodooPS2、BrcmPatchRAM，
  整个黑苹果生态的地基
- **Alexandred / VoodooI2C 团队** —— I2C 触控板支持
- **laobamac** —— SimpleHDA，让 Tahoe 上还能有声音
- **JoMei9019** —— AirPort-RTW，Realtek 无线网卡
- **thegwchr** —— Realtek Bluetooth 固件注入
- **Dortania / OCLP** —— 文档与 legacy 无线栈
- **OpenCore 中文社区** —— 大量中文排错资料

以及所有在论坛里留下排错记录的人 —— 这份文档里的每一条"坑"，几乎都来自别人踩过的痕迹。

## 关于"验收证据"

本仓库的每项结论都来自实机测量，不是"我猜应该可以"。
如果你在自己的机器上结果不同，**以你的测量为准**，并欢迎提 issue 说明差异。
