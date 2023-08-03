#!/bin/bash

read -p "确定要运行脚本吗？(y/n): " choice

# 判断用户的选择，如果不是"y"则退出脚本,默认使用文件bestv.ip，带参数则以参数为ip文件名
if [ "$choice" != "y" ]; then
    echo "脚本已取消."
        exit 0
fi

time=$(date +%m%d%H%M)
i=0

if [ $# -gt 0 ]; then
    filename="$1"
    else
        filename="bestv.ip"
fi

while read line; do

 i=$(($i+1));
 ip=$line
 date1=$(date +%Y%m%d%H)
 a=$(date +%s)
 a=${a:0:9}
 a=`expr $a - 7`
 url2="$date1/$a.ts"
#  url="http://$ip/liveplay-kk.rtxapp.com/live/program/live/cctv1hd8m/8000000/$url2"
 
 url="http://$ip/liveplay-kk.rtxapp.com/live/program/live/gswshd8m/8000000/$url2"
 echo $url
 curl $url  --connect-timeout 2 --max-time 15 -o /dev/null >bestv.tmp 2>&1
 a=$(tail -n 1 bestv.tmp|awk '{print $NF}')
 echo "第$i个： $ip    $a" 
 echo "$ip    $a">> speedtest_bestv$time.log
   
	    
done  <"$filename"
rm -f bestv.tmp
cat speedtest_bestv$time.log |grep -E  'M|k'|awk '{print $2"  " $1}'|sort -n -r
