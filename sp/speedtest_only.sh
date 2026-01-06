#!/bin/bash
ipfile=$1
region=$2
city=$(awk -v target="$2" '$1 == target {print $2}' province_list.txt)
stream=$(awk -v target="$2" '$1 == target {print $3}' province_list.txt)

TIMEOUT=11
VIDEO_DURATION=10
FRAME_LIMIT=200

#将不重复的ip分别单独保存只tmpip目录下
line_i=0
lines=$(wc -l $ipfile)
mkdir -p tmpip
rm -f tmpip/*
while read -r line; do
    ip=$(echo "$line" | sed 's/^[ \t]*//;s/[ \t]*$//')  # 去除首尾空格
    
    # 如果行不为空，则写入临时文件
    if [ -n "$ip" ]; then
        echo "$ip" > "tmpip/ip_$line_i.txt"  # 保存为 tmpip 目录下的临时文件
        ((line_i++))
    fi
done < "$ipfile"

sleep 1
rm -f "speedtest_${city}.log"


line_i=0
result_no=0
for temp_file in tmpip/ip_*.txt; do
    ip=$(<"$temp_file")  # 从临时文件中读取 IP 地址

    echo -n "$((++line_i))/$lines "
    url="http://${ip}/${stream}"
    echo -n "url: $url"

    ip_nc=$(echo "${ip}"| awk -F: '{print $1,$2}')
    output=$(nc -w 2 -z ${ip_nc} 2>&1)
    # 如果连接成功，且输出包含 "succeeded"
    if [[ $output != *"succeeded"* ]]; then
        echo " 端口测试不可用！"
       continue
    fi

    
    
    # 输出文件名
    OUTPUT_FILE="temp_video.mp4"

    # 开始时间
    START_TIME=$(date +%s)

    # 使用 ffmpeg 下载视频并保存 300 秒
    timeout $TIMEOUT ffmpeg -i "$url" -t $VIDEO_DURATION -c copy "$OUTPUT_FILE" -y >ffmpeg.log 2>&1 </dev/null

    # 检查 ffmpeg 的退出状态
    if [ $? -eq 0 ]; then
        echo ffmpeg命令返回:"$?"
        # echo "链接可用: $ip"

        # 结束时间
        END_TIME=$(date +%s)

        # 计算下载时长
        DURATION=$((END_TIME - START_TIME))

        # 获取文件大小（以字节为单位）
        FILE_SIZE=$(stat -c%s "$OUTPUT_FILE")
        Frames=$(tail -n 2 ffmpeg.log |head -n 1| grep -oE 'frame=[ ]*[0-9]+'  | tail -1 | awk -F'=' '{print $2}' | tr -d ' ')
        if [ "$FILE_SIZE" -eq 0 ]; then
            echo "下载文件为空：$ip"
            DOWNLOAD_SPEED_MBPS=0
        else
            cat ffmpeg.log
            echo "Frames:  "$Frames
            # 计算下载速度（字节/秒）
            DOWNLOAD_SPEED=$(echo "scale=2; $FILE_SIZE / $DURATION" | bc)
            # 将下载速度转换为 Mb/s
            DOWNLOAD_SPEED_MBPS=$(echo "scale=2; $DOWNLOAD_SPEED * 8 / 1000000" | bc)

            # 判断 DOWNLOAD_SPEED_MBPS 是否小于 3，速度太慢的节点不要也罢
            if (( $(echo "$DOWNLOAD_SPEED_MBPS < 3" | bc -l) )); then
                echo "-------下载速度慢：$DOWNLOAD_SPEED_MBPS  下载帧数：$Frames-------"
                DOWNLOAD_SPEED_MBPS=0
               else
                if (( Frames < $FRAME_LIMIT ));then
                    echo "-------下载速度可($DOWNLOAD_SPEED_MBPS)，但测试帧数低:" $Frames"------------"
                    DOWNLOAD_SPEED_MBPS=0
                fi
            fi
            
            echo -e  "\n\033[32mDownload speed: $DOWNLOAD_SPEED_MBPS Mb/s   Frames:$Frames\033[0m"
            echo "$ip $DOWNLOAD_SPEED_MBPS Mb/s  Frames:$Frames no:$((++result_no))" >> "speedtest_${city}.log"

        fi

    else
        echo "  ffmpeg命令返回: $?  链接下载测速不可用!"
    fi

done

# 清理 tmp 目录下的临时文

echo "删除${OUTPUT_FILE},  删除 tmpip/*"
rm -rf ${OUTPUT_FILE}
rm -rf tmpip/*


# 结果处理
if [ -f "speedtest_${city}.log" ]; then
  awk '/M/ && ($2+0) > 6 {print $2"  "$1}' "speedtest_${city}.log" | sort -nr > "sum/tmp/result_fofa_${city}.txt"
else
  echo "未生成测速文件"
fi

echo "======本次$region组播ip搜索结果============="
cat "sum/tmp/result_fofa_${city}.txt"

# 生成最终文件
program="template/template_${city}.txt"
> "sum/${city}.txt"
while read -r speed ip; do
  sed "s/ipipip/$ip/g" "$program" >> "sum/${city}.txt"
done < "sum/tmp/result_fofa_${city}.txt"

# 清理操作
rm -f ffmpeg.log tmpip/ip_part_* temp_*.mp4
