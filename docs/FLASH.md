# 刷机与验证

## 0. 备份原厂 boot（必做）

```bash
adb devices
adb shell su -c "dd if=/dev/block/by-name/boot of=/sdcard/boot_stock.img"
adb pull /sdcard/boot_stock.img
```

拿到 boot_stock.img 后 `ls -l` 应为 100663296 字节（96 MiB）。不等就重来。

## 1. 刷入内核

**A. fastboot（最稳）**

```bash
adb reboot bootloader
fastboot devices
fastboot flash boot AK3_Ace5Pro_SukiSU_CO16.zip
fastboot reboot
```

**B. SukiSU 管理器 / KernelFlasher**
把 zip 传到手机，管理器里选「安装」→ 选该 zip。

## 2. 刷入 16G zram 模块

开机进系统、拿到 root 之后：

- SukiSU 管理器 → 模块 → 从本地安装 → 选 `ZRAM16G_Ace5Pro.zip`
- 重启

验证：

```bash
su -c 'cat /data/local/tmp/zram16g.log'
su -c 'cat /sys/block/zram0/disksize'   # 应为 17179869184
su -c 'free -m'                          # Swap 应约 16384 MB
```

## 3. 功能验证

```bash
su -c id
su -c 'uname -r'
# 期望: 6.6.118-android15-8-g93e223c276e7-abogki500782043-4k

su -c 'cat /proc/config.gz | gunzip | grep -E "HMBIRD_SCHED|SLIM_SCHED"'
su -c 'cat /proc/config.gz | gunzip | grep KSU_SUSFS'
su -c 'cat /proc/config.gz | gunzip | grep "^CONFIG_KPM"'
su -c 'cat /sys/kernel/security/lsm'
su -c 'sysctl -w net.ipv4.tcp_congestion_control=bbr'

# 最关键的健康指标：厂商模块有没有加载失败
su -c 'lsmod | wc -l'
su -c 'dmesg | grep -i "disagrees about version" | head'
```

## 4. 回退

```bash
fastboot flash boot boot_stock.img
fastboot reboot
```

## 5. 现象对照

| 现象 | 原因 | 处理 |
|---|---|---|
| 开机卡 logo | vermagic 或 CRC 不匹配 | 回退，看 workflow 的 vermagic 断言 |
| 能开机但无信号 | 基带模块未加载 | 关掉 enable_bbg 重编 |
| 相机崩溃 | 相机模块 CRC 不匹配 | 回退，确认 TRIM_UNUSED_KSYMS 保持原厂 y |
| 16G zram 没生效 | hybridswap 抢占 | 看 /data/local/tmp/zram16g.log |
| 管理器显示未安装 | KSU 未编进去 | 查 /proc/config.gz 里 CONFIG_KSU=y |
