#!/system/bin/sh
# 等待 zram0 就绪（原厂 hybridswap 会先初始化）
MODDIR=${0%/*}
LOG=/data/local/tmp/zram16g.log
: > "$LOG"
echo "[$(date)] zram16g start" >> "$LOG"

i=0
while [ ! -e /sys/block/zram0/disksize ]; do
  i=$((i+1)); [ $i -gt 120 ] && { echo "timeout waiting zram0" >> "$LOG"; exit 1; }
  sleep 1
done

# 等 system 起来，避免和 oplus_bsp_hybridswap_zram 抢初始化
sleep 25

SWAPIO=$(cat /sys/block/zram0/stat 2>/dev/null | awk '{print $1}')
echo "current disksize: $(cat /sys/block/zram0/disksize)" >> "$LOG"
echo "swap in pages: $SWAPIO" >> "$LOG"

# 原厂已在用 zram 时，先关闭挂在它上面的 swap
swapoff /dev/block/zram0 2>>"$LOG"
echo 1 > /sys/block/zram0/reset 2>>"$LOG"

# 选压缩算法：优先 lz4（速度），退化 lzo-rle / zstd
ALG=""
for a in lz4 lz4hc lzo-rle lzo zstd; do
  if grep -qw "$a" /sys/block/zram0/comp_algorithm 2>/dev/null; then ALG="$a"; break; fi
done
[ -n "$ALG" ] && echo "$ALG" > /sys/block/zram0/comp_algorithm 2>>"$LOG"
echo "comp_algorithm: $(cat /sys/block/zram0/comp_algorithm 2>/dev/null)" >> "$LOG"

# 16G
echo 17179869184 > /sys/block/zram0/disksize 2>>"$LOG" \
  || { echo "set disksize FAILED" >> "$LOG"; exit 1; }

mkswap /dev/block/zram0 >>"$LOG" 2>&1
swapon -p 32767 /dev/block/zram0 >>"$LOG" 2>&1

echo "final disksize: $(cat /sys/block/zram0/disksize)" >> "$LOG"
echo "swap total: $(free -m | awk '/Swap/{print $2}') MB" >> "$LOG"
echo "[$(date)] done" >> "$LOG"
