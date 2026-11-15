# OnePlus Ace 5 Pro (PKR110) — ColorOS 16 自编译内核

SukiSU-Ultra + SUSFS + KPM + Baseband-Guard + 风驰(hmbird) + BBR，Android 15/16 KMI 6.6.118。

## 刷机包信息

| 项 | 值 |
|---|---|
| 机型 | OnePlus Ace 5 Pro (PKR110 / OP60EBL1) |
| ROM | ColorOS 16.0.10.500(CN01) / V16.1.0 |
| OTA ID | PKR110_11.C.29_1290_202608112008 |
| 原厂内核 | 6.6.118-android15-8-g93e223c276e7-abogki500782043-4k |
| vermagic | `6.6.118-android15-8-g93e223c276e7-abogki500782043-4k SMP preempt mod_unload modversions aarch64` |
| 分区 | boot (header v4, 96 MiB, kernel 36866560 B) |

## 源码

- manifest: `OnePlusOSS/kernel_manifest` → 分支 `oneplus/sm8750` → `oneplus_ace5_pro_b.xml`
- common: `oneplus/sm8750_b_16.0.0_oneplus_ace5_pro` (6.6.118)
- msm-kernel: 同分支

## 特性实现

| 特性 | 实现 |
|---|---|
| SukiSU | `SukiSU-Ultra/SukiSU-Ultra` 分支 `builtin`（内置 KPM + SUSFS 配置项） |
| SUSFS | `susfs4ksu` `gki-android15-6.6` 内核补丁 + `CONFIG_KSU_SUSFS_*` |
| KPM | `CONFIG_KPM=y`（builtin 自带 `kernel/extension`） |
| 风驰 hmbird | `Numbersf/SCHED_PATCH` → `fengchi_oneplus_ace5_pro_b.patch` |
| BBG | `vc-teahouse/Baseband-guard` setup.sh |
| BBR | `CONFIG_TCP_CONG_BBR=y` + `CONFIG_NET_SCH_FQ=y`（原厂已开） |
| 16G zram | 内核 `CONFIG_ZRAM=y` 内建；容量由用户层模块脚本写 `disksize` |

## 关键坑（已在 workflow 中处理）

1. **必须打风驰补丁**。开源 defconfig 默认 `SLIM_SCHED + SCHED_CLASS_EXT`，原厂是 `HMBIRD_SCHED`。
   调度器不同 → `task_struct` 布局不同 → 所有导出符号 CRC 变化 → 1398 个厂商模块全部拒绝加载 → bootloop。
2. **ABI 导出表要删**。`abi_gki_protected_exports_*` 会导致编译期 ABI 检查失败。
3. **版本串不能带 `-dirty`**，否则 vermagic 与原厂不一致，模块不加载。
4. `CONFIG_TRIM_UNUSED_KSYMS` 保持原厂值（y），不要动，否则厂商模块依赖的符号被裁掉。
5. `CONFIG_LTO_NONE=y` 与原厂一致，不要开 LTO。

## 使用

Actions → `Build Ace5Pro SukiSU Kernel (COS16)` → Run workflow。

产物：
- `AK3_Ace5Pro_SukiSU_CO16.zip` — 可直刷
- `Image` — 裸内核
- `.config` / `Module.symvers` — 校验用

## 刷入

```bash
adb reboot bootloader
fastboot flash boot AK3_Ace5Pro_SukiSU_CO16.zip
fastboot reboot
```

或用 KernelFlasher / SukiSU 管理器刷 zip。

**刷前务必备份原厂 boot：**

```bash
adb shell su -c "dd if=/dev/block/by-name/boot of=/sdcard/boot_stock.img"
```

回退：

```bash
fastboot flash boot boot_stock.img
```

## 16G zram 配置（刷完后手动设）

```bash
su
swapoff /dev/block/zram0
echo 1 > /sys/block/zram0/reset
echo lz4 > /sys/block/zram0/comp_algorithm   # 或 lzo-rle / zstd
echo 16G > /sys/block/zram0/disksize
mkswap /dev/block/zram0
swapon -p 32767 /dev/block/zram0
```
