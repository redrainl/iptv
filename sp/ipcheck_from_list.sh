#!/bin/bash
cd /root/iptv
ipfile=$1
region=$2
port=$3
city=$(awk -v target="$region" '$1 == target {print $2}' province_list.txt)
stream=$(awk -v target="$region" '$1 == target {print $3}' province_list.txt)
ipfile_sum="sum/${city}_sum.ip"
ipfile_uniq="sum/${city}_uniq.ip"

processed_file=$(mktemp)  # 创建临时文件
 > "$processed_file"     # 清空内容
total=$(wc -l < "$ipfile")  # 要处理的ip文件总行数
(
  while true; do
    processed=$(wc -l < "$processed_file")  # 已处理数
    percent=$(awk "BEGIN {printf \"%.1f\", $processed/$total*100}")
    printf "进度: %s/%s (%.1f%%)\r" "$processed" "$total" "$percent"
    if [[ "$processed" -ge "$total" ]]; then
      break  # 处理完成时退出
    fi
    sleep 2  # 刷新间隔（秒）
  done
) &
progress_pid=$!  # 记录后台进程PID

# 新增并发控制参数
CONCURRENCY=1000  # 根据CPU核心数调整
FFMPEG_CONCURRENCY=10  # 视频测速并发数

# 清空旧文件
# > "$ipfile_sum"

echo "============ip端口检测(并发数:$CONCURRENCY)，可用结果保存至$ipfile_sum==========="

# 使用xargs实现并行检测 (修改点1)
xargs -P $CONCURRENCY -a "$ipfile" -I {} sh -c '
  ip="{}"
   tmp_ip=$(echo "$ip" | sed "s/:/ /")
  if  nc -v -w 2 -z $tmp_ip >/dev/null 2>&1; then
         echo "$tmp_ip"| sed "s/ /:/" >> "'"$ipfile_sum"'"
        ip_checked=$(wc -l < "'"$ipfile_sum"'")
          echo "Found ip $ip_checked:" $tmp_ip
  fi
 echo >> "'"$processed_file"'"  # 每处理完一行，追加到临时文件计数
 '

echo "===============检索完成================="
cat  $ipfile_sum|sort|uniq  > $ipfile_uniq
