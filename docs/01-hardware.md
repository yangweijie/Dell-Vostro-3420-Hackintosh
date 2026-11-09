# 硬件清单

| 项目 | 规格 | 备注 |
|---|---|---|
| 机型 | Dell Vostro 3420 | 2021 年机型，Tiger Lake 平台 |
| BIOS | Dell 1.x（UEFI，GPT） | 无 `Sleep Mode` 选项（重要，见 `04-fixes-explained.md` 第 6 节） |
| CPU | Intel Core i5-1135G7 | 4 核 8 线程，Tiger Lake-U，基础 2.4 GHz |
| 核显 | Intel Iris Xe Graphics | PCI `8086:9A49`，子系统 `1028:0B6A` |
| 独显 | 无 | — |
| 内存 | 16 GB DDR4-2667 | 本仓库未对内存做特殊配置 |
| 硬盘 | SK hynix BC901 NVMe 256 GB | PCIe NVMe，GPT |
| 有线网卡 | Realtek RTL8168 | `10ec:8168`，子系统 `1028:0b6a` |
| 无线网卡 | Realtek RTL8821CE | `10ec:c821`，Wi-Fi 5（802.11ac） |
| 蓝牙 | RTL8821CE 的 BT 部分 | USB `0bda:c829`，BT 4.2 |
| 声卡 | Realtek ALC236 | `VEN_10EC&DEV_0236`，layout-id 7 / alc-layout-id 3 |
| 键盘 | PS/2 | ACPI `PS2K`，IO 0x60/0x64 + IRQ1 |
| 触控板 | I2C HID | ACPI `DELL0B6A`，挂在 `8086:a0e8` |
| 屏幕 | 1920×1080 | 内屏，30-bit，60 Hz |
| 摄像头 | Integrated Webcam HD | USB，UVC 免驱 |

## PCI 拓扑（本机）

```text
00:02.0  IGPU  8086:9a49   Iris Xe
00:04.0  TCPU  8086:9a03   温度监控
00:08.0  GNA0  8086:9a11
00:14.0  XHCI  8086:a0ed   USB 控制器
00:15.0  I2C0  8086:a0e8   ← 触控板挂在这里
00:15.1  I2C1  8086:a0e9
00:16.0  IMEI  8086:a0e0
00:17.0  SAT0  8086:a0d3
00:1c.0  RP05  PCIe 根端口
00:1d.0  RP09  PCIe 根端口  ← Wi-Fi 卡
00:1d.1  RP10  PCIe 根端口
00:1f.0  LPCB  8086:a082
00:1f.3  HDEF  8086:a0c8   ALC236
00:1f.4  SBUS  8086:a0a3
```

## 兼容性判断要点

想套用到别的机器，先核对这四处：

1. **核显必须同代**：本配置用 WhateverXe，只针对 Tiger Lake / Ice Lake 的 Xe 核显。
   换 10 代及更早，应改用 WhateverGreen + `device-id` 伪装。
2. **Wi-Fi/BT 芯片**：`AirPortRTW` 支持 RTL8821CE；换 Intel 网卡就要换 `AirportItlwm`，
   换 Broadcom 则要 OCLP 补丁，完全是另一套。
3. **声卡 layout-id 会不同**：ALC236 用 7，别的 codec 要查 AppleALC 的 layout 表。
4. **睡眠那一条依赖 DSDT 结构**：本机的 `SS3` 变量在 DSDT 第 615 行、`_S3` 在第 74590 行。
   别的机型位置完全不同，**必须自己从导出 DSDT 里找，字节模式也会不一样**。
   如果你的机器启动日志里 `ACPI: sleep states` 已经包含 S3，就完全不需要这一条。
