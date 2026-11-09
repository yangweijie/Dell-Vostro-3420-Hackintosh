# 系统升级注意事项

本机在 **macOS 26.7.2 (25G332)** 上完成验收。之后的小版本/大版本升级请先读这一页。

## 最大的坑：BlueToolFixup 会让增量更新校验失败

`BlueToolFixup` 通过 Lilu 在内存里 patch `bluetoothd`。系统更新时，
更新器会校验 `/usr/sbin/bluetoothd` 的内容是否与 bom 一致 ——
它读到的是**已被 patch 的版本**，于是报：

```text
Failed to prepare the software update. Please try again.
```

`/var/log/install.log` 里能看到 `bluetoothd` 内容不匹配 / `FullReplacementRequired`。

**结论：不要用「系统设置 → 软件更新」做增量更新。**

## 推荐做法

### 方式 A：完整安装包（推荐）

```bash
softwareupdate --list-full-installers
caffeinate -dims softwareupdate --fetch-full-installer --full-installer-version <版本号>
```

下载完在「应用程序」里运行 `Install macOS ...`。完整安装包会替换整个系统卷，
不做逐文件校验，因此不受 BlueToolFixup 影响。

### 方式 B：临时禁用 BlueToolFixup

1. 编辑 `config.plist`，把 `Kernel → Add → BlueToolFixup.kext` 的 `Enabled` 改为 `false`
2. 重启，再做增量更新
3. 更新完再改回 `true`

（本机未实测这条路径，风险自负。）

## 升级前必做的三件事

1. **备份 EFI 分区**（整份拷出来），这是升级失败后唯一的救命绳
2. **保留可启动 U 盘**，且 U 盘里的 EFI 与当前硬盘 EFI 一致
3. 记录当前 `config.plist` 的 SHA256，方便比对升级后是否被系统改动

```bash
shasum -a 256 /Volumes/EFI/EFI/OC/config.plist
```

## 升级后可能需要重新适配的地方

| 组件 | 风险 |
|---|---|
| `IOSkywalkFamily` + `IO80211FamilyLegacy` | 大版本若再次改动无线栈，这套 legacy 方案需要跟进上游（OCLP 通常最先适配） |
| `SimpleHDA` | 依赖 Tahoe 移除 AppleHDA 的现状；若 Apple 恢复 AppleHDA，需要改回 AppleALC 常规用法 |
| `WhateverXe` | 实验性项目，新系统可能需要等上游更新 |
| `AirPortRTW` | 同上 |
| DSDT 的 SS3 补丁 | 只要 Dell 不更新 BIOS 就长期有效；**如果更新了 BIOS，补丁偏移和字节模式都可能变，必须重新确认** |

## 升级后自检

```bash
bash scripts/verify.sh
```

对照 `07-checklist.md` 逐项确认。任何一项回退，优先怀疑：
kext 是否被新系统拦、`Kernel → Block` 是否还生效、ACPI 补丁是否还匹配。
