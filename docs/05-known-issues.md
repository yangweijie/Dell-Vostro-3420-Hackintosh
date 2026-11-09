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

## 8. Fn 快捷键：亮度不可调，F8 / F10 没有对应功能

### 8.1 Fn+F6 / F7（亮度）—— 信号到了，背光没跟上

现象：按 Fn+F6/F7 无任何反应；控制中心里**有**亮度滑块，但拖到底屏幕不变；
系统设置 → 显示器里干脆没有滑块。

这不是键位映射问题。实测证据：

| 环节 | 结果 |
| --- | --- |
| ACPI 链路 | `DSDT: _Q66 → NEVT() → EV3() → GFX0.BRT6() → Notify(LCD, 0x86/0x87)` |
| 通知是否到达 macOS | **到达了**。`BrightnessKeys` 的实例属性 `BrightnessPanel = LCD` 只在收到 0x86/0x87 后才写入 |
| 按键是否产生 HID 事件 | 否（30 秒 `HIDIdleTime` 采样零重置，外接键盘对照为 10 次）——因为它走 ACPI 通知而非扫描码 |
| 系统亮度值 | `bklt` 恒为 `65535/65535`（100%），90 个采样点无变化 |
| 背光驱动 | `AppleBacklight 180.12` + `AppleBacklightExpert` 已加载，`AppleBacklightDisplay` 挂在 `IGPU@2/AppleIntelFramebuffer@0/display0` |
| 内核告警 | `(AppleIntelTGLGraphicsFramebuffer) [IGFB][ERROR][DISPLAY] EFI using a different backlight frequency` |

**真正的断点在背光硬件控制**：本机背光走 DSDT 的 `LCD._BCM`（BIOS/EC 经 SMI 控制），
而不是 PCH 的 PWM 寄存器。WhateverXe 文档把「某些背光方式」列为已知限制，
同平台的 Tiger Lake 开源方案也多把 Brightness 列为 Not Working。

已试过无效：给 iGPU 加 `applbkl = <01000000>`（强制 AppleBacklight 走 PWM）并重启，
属性确认已生效（`ioreg -l -w0 -n IGPU` 可见 `"applbkl" = <01000000>`），但 `bklt` 仍恒为 65535。

自检命令：

```bash
# 当前背光值：第 2 个 value 是 bklt，恒 65535 说明背光没被接管
ioreg -c AppleBacklightDisplay -l -w0 | tr ',' '\n' | grep -oE 'value"=[0-9]+' | head -4

# 非空（如 "LCD"）= ACPI 亮度通知确实到达了 macOS，问题不在按键
ioreg -l -w0 | grep -oE '"BrightnessPanel" = [^,]*'

# 检查 applbkl 是否注入成功
ioreg -l -w0 -n IGPU | grep -oE '"applbkl" = <[0-9a-f]*>'
```

如果将来 WhateverXe 支持了这台机器的背光方式，Fn+F6/F7 **不需要再改任何配置**就会跟着好，
因为按键到 `BrightnessKeys` 这一段已经是通的。

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

### 8.4 想让屏幕暗一点，能用什么（亮度不可调时的替代）

先说明一个坑：**网上常见的「系统设置 → 辅助功能 → 显示 → 降低白点值」在 macOS 26 上已经没有了**。
导出 Tahoe 辅助功能面板的搜索索引可以看到，显示类只剩这些：

```
色彩滤镜 / 滤镜类型 / 显示对比度 / 增强对比度 / 反转显示颜色 / 降低透明度 / 高对比度
```

`Reduce White Point` 这个字符串在系统里只出现在「语音控制」的命令名清单中，设置界面已移除。
（另外显示器设置页的搜索索引里有「显示器亮度」这一项，说明 Tahoe 本来有亮度控件，
只是本机上报不出背光能力，所以没有显示——和 8.1 是同一个根因。）

不依赖背光、实测可用的替代方案：

| 方案 | 路径 | 效果 | 备注 |
| --- | --- | --- | --- |
| 夜览 | 系统设置 → 显示器 → 夜览 | 整体偏暖，夜间刺眼感明显下降 | 本机实测可用，可按时段自动开启，可加到控制中心 |
| 色彩滤镜（色彩色调） | 系统设置 → 辅助功能 → 显示 → 色彩滤镜 | 选深灰/深色 + 调高强度，等效于给整屏叠一层暗色 | 走 GPU 色彩滤镜，不需要背光，一定能用 |
| 显示器校准 | 系统设置 → 显示器 → 颜色描述文件 → 校准… | 校准过程中压低亮度/对比度，写入 ColorSync 配置 | 属于 GPU 查找表层面的调整，同样不依赖背光 |
