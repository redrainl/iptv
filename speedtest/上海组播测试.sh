#!/bin/bash

read -p "确定要运行脚本吗？(y/n): " choice

# 判断用户的选择，如果不是"y"则退出脚本,默认使用文件zubo.ip，带参数则以参数为ip文件名
if [ "$choice" != "y" ]; then
    echo "脚本已取消."
    exit 0
fi

time=$(date +%m%d%H%M)
i=0

if [ $# -gt 0 ]; then
    filename="$1"
    else
        filename="zubo.ip"
fi
lines=$(cat $filename|wc -l)

echo "文件内ip共计$lines个"
while read line; do
 i=$(($i+1));
 ip=$line
 url="http://$ip/udp/239.45.3.209:5140"
 echo $url
 curl $url  --connect-timeout 3 --max-time 10 -o /dev/null >zubo.tmp 2>&1
 a=$(head -n 3 zubo.tmp|awk '{print $NF}'|tail -n 1)
 echo "第$i/$lines个： $ip    $a" 
 echo "$ip    $a">> speedtest_zubo$time.log
done  <"$filename"

rm -f zubo.tmp
cat speedtest_zubo$time.log |grep -E  'M|k'|awk '{print $2"  " $1}'|sort -n -r >result_zubo.txt
cat result_zubo.txt
