# 已知问题

## 1. 接力 / AirDrop / 通用剪贴板 不可用

**这是硬件限制，不是配置问题。**

这些功能依赖 Apple 的 AWDL（Apple Wireless Direct Link）协议，由原厂 Broadcom 组合卡在
Wi-Fi 与蓝牙之间协同实现。本机是 Realtek RTL8821CE（Wi-Fi）+ 同一颗芯片的蓝牙，
两者都不可能实现该协议。

唯一出路是换 macOS 原生组合卡（如 BCM94360NG，M.2 2230）。换卡前需要确认：

- 主板 M.2 插槽类型与尺寸（2230）
- 天线接口数量（2 根）
- BIOS 是否有网卡白名单
- 换卡后 Wi-Fi 会变成原生驱动，可以移除 `AirPortRTW` / `IOSkywalkFamily` / `IO80211FamilyLegacy`
  三个 kext 以及 `Kernel → Block` 那条屏蔽项（届时蓝牙驱动也要相应换成 BrcmPatchRAM 系列）

## 2. iMessage / FaceTime 需要你自己的 SMBIOS

仓库里的序列号是占位符。填入自己生成的 SMBIOS 后可以尝试登录，
但不保证一定能激活（Apple 对黑苹果的限制时紧时松）。

## 3. 触控板是轮询模式，略耗电

Tiger Lake 的 GPIO 中断在 `VoodooGPIO` 里没有可靠实现，因此用 `-vi2c-force-polling` 走轮询。
功能全部正常（含手势），代价是空闲功耗比中断模式略高。

如果你的机器是 Ice Lake 及更早，可以去掉这个参数，走中断模式。

## 4. 睡眠唤醒后 Wi-Fi 需要几秒重连

正常现象：S3 会切断网卡供电，唤醒后驱动重新初始化（日志里能看到 `en1 driver DidChangeState`
约 450 ms 的延迟）。几秒内会自动连回原网络。

如果长时间不恢复，检查 `04-fixes-explained.md` 第 2 节的三个 kext 是否都在。

## 5. 蓝牙偶发需要重新配对

第三方蓝牙控制器在系统大版本升级后可能丢失配对信息，重新配对即可。

## 6. 系统更新会打断

详见 [`06-upgrade.md`](06-upgrade.md)。简单说：`BlueToolFixup` 会导致增量更新校验失败，
优先用完整安装包。

## 7. 首次开机菜单需要手动选择

`Misc → Boot → Timeout = 0` 是为了排错时能停在菜单（本仓库保持验收时的值）。
希望自动进系统的话，把 `Timeout` 改成 `3`～`5` 即可。


## 8. Fn 快捷键

### 8.1 亮度（已解决）

Fn+F6 / F7 与控制中心亮度滑块现在都正常工作。这一条曾经是"背光由 EC 控制、macOS 接管不了"的
死结，最终靠两部分改掉：

1. `SSDT-PNLF.aml` 的 `_UID` 从 `Zero` 改为 `0x13`（19）
2. 自编译 `WhateverXe`，让它在 `ApplePanels` 里注入产品级 16-bit PWM 曲线 `F19Ta95`

完整诊断链、验证命令和踩过的坑见 [`04-fixes-explained.md`](04-fixes-explained.md) 第 8 节。

如果你用的是别处的 EFI（没有这两处改动），会看到：控制中心有滑块但拖动无效、
系统设置 → 显示器没有滑块、Fn+F6/F7 无反应。

### 8.2 Fn+F8（投屏）/ Fn+F10（PrtSc）

`VoodooPS2Keyboard` 自带的 `Dell-Keys` profile 里写得很直接：

```
e020=3b  e02e=3c  e030=3d  e022=3e
;Fn+f5 macro  ;Fn+f6 macro  ;Fn+f7 macro  ;Fn+f8 macro  ;Fn+f9 macro  ;Fn+f10 no code
```

Fn+F5–F9 是 macro 序列，**Fn+F10 干脆 `no code`**（硬件不发码）。
同时 macOS 本身也没有「切换显示模式」和「截屏」这两个系统动作
（截屏是 `Cmd+Shift+3/4`，外接显示走系统设置或显示器菜单栏），所以这两个键即使映射成功也无处可去。

### 8.3 正常工作的是 Fn+F1–F4

音量减 / 音量加 / 静音 / 播放暂停走标准 PS/2 媒体扫描码，`VoodooPS2Keyboard` 原生支持。

### 8.4 关于「降低白点值」

macOS 26 已把这个选项从辅助功能里移除（导出 Tahoe 的辅助功能搜索索引可以看到，
显示类只剩 色彩滤镜 / 对比度 / 反转颜色 / 降低透明度 / 高对比度）。
现在亮度本身已经可调，不再需要它；若仍想进一步降低刺眼感，可用
`系统设置 → 辅助功能 → 显示 → 色彩滤镜` 的「色彩色调」。
