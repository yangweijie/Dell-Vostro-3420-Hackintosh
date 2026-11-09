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
