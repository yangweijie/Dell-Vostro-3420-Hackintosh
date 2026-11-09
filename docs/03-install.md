# 安装流程

> 假设你已经在 Windows 里做好了 U 盘安装盘（macrecovery 或完整 InstallAssistant 均可）。
> 本仓库提供的是**装好之后**用的运行时 EFI；安装阶段可以直接用它，也可以先用最简 EFI 装完再换。

## 0. 准备

- 关闭 BitLocker（否则改分区后要恢复密钥）
- 备份重要数据
- 记下 Windows 分区位置；**只抹你要装 macOS 的那个分区，不要动整块盘**

## 1. 做安装盘

U 盘 ≥ 16 GB，GPT + FAT32。两种方式：

**A. 恢复镜像（体积小，安装时联网下载完整系统）**

```bash
# 在能联网的 macOS 或 Linux 上
python3 macrecovery.py -b Mac-E43C1C25D4880AD6 -m 00000000000000000 download
# 得到 BaseSystem.dmg + BaseSystem.chunklist，放到 U 盘
```

注意：恢复环境**必须有线网络**（本仓库 install 用 `RealtekRTL8111.kext`），Wi-Fi 栈在安装阶段不可用。

**B. 完整安装包（体积大，但离线可装）**

在 macOS 上下载 `InstallAssistant.pkg`，展开后把 `SharedSupport/` 放到 U 盘的 `Installers/` 下，
配合 `install-offline.sh` 使用（本机实测 FAT32 单文件 4 GB 限制需要分卷，见下）。

> FAT32 单文件上限 4 GB。`BaseSystem.dmg` 通常小于 4 GB；完整安装包的 `SharedSupport.dmg`
> 会超限，需要切成若干卷再在安装环境里合并。

## 2. 抹盘

进 macOS 恢复环境 → 磁盘工具：

1. 选**目标分区**（不是整块物理盘）
2. 抹成 `APFS`，名称建议 `macOS`
3. 记下大小，避免误抹 Windows 分区

## 3. 安装

「重新安装 macOS」→ 选刚抹的盘。过程中会重启数次，**每次都要从 U 盘启动**，
在 OpenCore 菜单里选 `macOS Installer` 或 `macOS`（不要选带 `external` / `dmg` 的 U 盘恢复项）。

## 4. 装后把 EFI 写到硬盘

装完第一次进桌面后（此时仍需 U 盘引导）：

```bash
diskutil list                       # 找内置盘的 EFI 分区，通常是 disk0s1
sudo diskutil mount disk0s1
# 挂载点是 /Volumes/EFI 或 /Volumes/NO NAME

# 备份原有 EFI
mkdir -p ~/efi-backup
sudo ditto /Volumes/EFI ~/efi-backup/original

# 拷贝本仓库的 EFI
sudo ditto /path/to/repo/EFI /Volumes/EFI
```

再设置启动项：

```bash
sudo bless --mount /Volumes/EFI --setBoot --file /Volumes/EFI/EFI/BOOT/BOOTx64.efi
```

如果报 `Could not set boot device property: 0xe00002e2`（SIP 的 NVRAM 保护），
改用 OpenCore 自带的注册方式：`Misc → Boot → LauncherOption = Full`（仓库已设），
从硬盘启动一次，OpenCore 会把自己写成第一启动项。

## 5. 首次启动检查

拔掉 U 盘重启。能进桌面就说明写入成功。然后：

```bash
bash scripts/verify.sh
```

对照输出逐项确认。如果某项不过，去 `04-fixes-explained.md` 找对应小节。

## 6. 收尾

- **生成自己的 SMBIOS**（见 README）——不做这步 iMessage/FaceTime 用不了
- 系统设置 → 锁定屏幕 → 开启「进入睡眠或屏幕保护程序后立即要求输入密码」
- 备份整个 EFI 分区（这是你今后系统升级失败时的救命盘）

## 常见安装期问题

| 现象 | 原因 | 处理 |
|---|---|---|
| 恢复环境提示无网络 | 网线没插 / 用了 Wi-Fi | 插网线；确认 `RealtekRTL8111.kext` 已启用 |
| 卡在 `EXITBS:START` | 这是正常交棒，不是失败 | 继续等，或看 OpenCore DEBUG 日志 |
| 重启后无限循环 | 菜单里选了错误项 | 只选 `macOS` / `macOS Installer`，别选 external |
| 键盘在安装界面能用、装完不能用 | PS/2 端口事件通道问题 | 见 `04-fixes-explained.md` 第 4 节 |
| 第一次进桌面没有声音 | AppleHDA 在 Tahoe 已被移除 | 见第 3 节，需要 SimpleHDA |
