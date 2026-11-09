# BIOS 设置

进 F2（开机出现 Dell 徽标时按），需要确认的项：

| 项目 | 设置 | 说明 |
|---|---|---|
| Boot Mode | **UEFI** | 不能是 Legacy |
| Secure Boot | **Disabled** | OpenCore 未签名，必须关 |
| SATA Operation | AHCI | NVMe 机型此项影响不大，但保持一致 |
| Fast Boot | 建议 Disabled | 排错时省事 |
| VT for Direct I/O | 可 Disabled | 本配置已开 `DisableIoMapper`，无论开关都能用 |
| Wake on LAN / WLAN | 建议 Disabled | 减少误唤醒 |
| USB Wake Support | 建议 Disabled | 同上 |
| Sign of Life（POST 显示） | 可 Disabled | 同类 Dell 机型上它会影响唤醒 |
| Block Sleep | **确保未勾选** | 勾了会直接禁止睡眠 |

## 本机 BIOS 没有的选项

**`Sleep Mode`（Modern Standby / S3 切换）不存在。** 本机固件是 S0ix 机型，Dell 没有提供切回 S3 的开关，
所以睡眠得从 ACPI 层面解决（见 `04-fixes-explained.md` 第 6 节）。

如果你的同型号机器 BIOS 里**有** `Sleep Mode`，优先把它设成 `S3` / `Linux` ——
那样就不需要那个 DSDT 补丁了，这是更干净的做法。

## 启动顺序

装好 EFI 到硬盘后有两种方式：

1. 开机按 **F12**，在 `UEFI BOOT` 里选你的硬盘
2. 让 OpenCore 自己注册为第一启动项：`Misc → Boot → LauncherOption = Full`（本仓库已设好），
   从该盘启动一次即生效

Windows 双系统：OpenCore 菜单里会列出 `Windows`；也可以开机 F12 直接选 `Windows Boot Manager`
（本仓库**没有**改动 `EFI/Microsoft`，两条路都保留）。
