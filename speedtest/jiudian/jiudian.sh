#!/bin/bash
# cd /root/iptv/jiudian
# read -p "确定要运行脚本吗？(y/n): " choice

# 判断用户的选择，如果不是"y"则退出脚本
# if [ "$choice" != "y" ]; then
#     echo "脚本已取消."
#     exit 0
# fi

time=$(date +%m%d%H%M)
i=0

if [ $# -eq 0 ]; then
  echo "请选择城市："
  echo "1. 智慧光迅"
  echo "2. 智慧桌面"
  echo "3. 华视美达"
  echo "0. 全部"
  read -t 10 -p "输入选择或在10秒内无输入将默认选择全部: " city_choice

  if [ -z "$city_choice" ]; then
      echo "未检测到输入，自动选择全部选项..."
      city_choice=0
  fi

else
  city_choice=$1
fi

# 根据用户选择设置城市和相应的stream
case $city_choice in
    1)
        city="智慧光迅平台"
        stream="hls/1/index.m3u8"
	channel_key="上海"
        url_fofa=$(echo  'body="ZHGXTV" && country="CN"' | base64 |tr -d '\n')
        #url_fofa=$(echo  'body="ZHGXTV" && country="CN" && region="Shanghai" && org="China Telecom Group" && protocol="http"' | base64 |tr -d '\n')
        url_fofa="https://fofa.info/result?qbase64="$url_fofa
        ;;
    2)
        city="智慧桌面"
        stream="tsfile/live/0001_1.m3u8"
        channel_key="北京联通"
        url_fofa=$(echo  'body="/iptv/live/zh_cn.js" && country="CN"' | base64 |tr -d '\n')
        url_fofa="https://fofa.info/result?qbase64="$url_fofa
        ;;
    3)
        city="华视美达"
        stream="newlive/live/hls/1/live.m3u8"
        channel_key="四川电信"
        url_fofa=$(echo  'body="华视美达" && country="CN"' | base64 |tr -d '\n')
        url_fofa="https://fofa.info/result?qbase64="$url_fofa
        ;;
    0)
        # 如果选择是“全部选项”，则逐个处理每个选项
        for option in {1..3}; do
          bash  "$0" $option  # 假定fofa.sh是当前脚本的文件名，$option将递归调用
        done
        exit 0
        ;;

    *)
        echo "错误：无效的选择。"
        exit 1
        ;;
esac



# 使用城市名作为默认文件名，格式为 CityName.ip
ipfile="ip/${city}.ip"
only_good_ip="ip/${city}.onlygood.ip"
rm -f $only_good_ip
# 搜索最新 IP
echo "===============从 fofa 检索 ip+端口================="
curl -o test.html "$url_fofa"
#echo $url_fofa
echo "$ipfile"
grep -E '^\s*[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$' test.html | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+' > "$ipfile"

# 遍历文件 A 中的每个 IP 地址
while IFS= read -r ip; do
    # 尝试连接 IP 地址和端口号，并将输出保存到变量中
    tmp_ip=$(echo "$ip" | sed 's/:/ /')
    echo "nc -w 1 -z $tmp_ip 2>&1"
    output=$(nc -w 1 -z $tmp_ip 2>&1)
    # 如果连接成功，且输出包含 "succeeded"，则将结果保存到输出文件中
    if [[ $output == *"succeeded"* ]]; then
        # 使用 awk 提取 IP 地址和端口号对应的字符串，并保存到输出文件中
        echo "$output" | grep "succeeded" | awk -v ip="$ip" '{print ip}' >> "$only_good_ip"
    fi
done < "$ipfile"

echo "===============检索完成================="

# 检查文件是否存在
if [ ! -f "$only_good_ip" ]; then
    echo "错误：文件 $only_good_ip 不存在。"
    exit 1
fi

lines=$(wc -l < "$only_good_ip")
echo "【$only_good_ip】内 ip 共计 $lines 个"

i=0
time=$(date +%Y%m%d%H%M%S) # 定义 time 变量
while IFS= read -r line; do
    i=$((i + 1))
    ip="$line"
    url="http://$ip/$stream"
    echo "$url"


 output=$(/usr/local/bin/yt-dlp --ignore-config --no-cache-dir --output "output.ts" --download-archive new-archive.txt --external-downloader ffmpeg --external-downloader-args "-t 5" "$url" 2>&1)
        a=$(echo "$output" | grep -oP 'at \K[0-9.]+M')
        rm -f  new-archive.txt output.ts

#    curl "$url" --connect-timeout 3 --max-time 10 -o /dev/null >zubo.tmp 2>&1
#    a=$(head -n 3 zubo.tmp | awk '{print $NF}' | tail -n 1)

    echo "第 $i/$lines 个：$ip $a"
    echo "$ip $a" >> "speedtest_${city}_$time.log"
done < "$only_good_ip"

rm -f zubo.tmp
awk '/M|k/{print $2"  "$1}' "speedtest_${city}_$time.log" | sort -n -r >"result/result_fofa_${city}.txt"
cat "result/result_fofa_${city}.txt"
ip1=$(awk 'NR==1{print $2}' result/result_fofa_${city}.txt)
ip2=$(awk 'NR==2{print $2}' result/result_fofa_${city}.txt)
ip3=$(awk 'NR==3{print $2}' result/result_fofa_${city}.txt)
cp result/result_fofa_${city}.txt result/result_fofa_${city}_$time.txt
rm -f "speedtest_${city}_$time.log"

# 用 3 个最快 ip 生成对应城市的 txt 文件
#program="template/template_${city}.txt"

#sed "s/ipipip/$ip1/g" "$program" > tmp1.txt
#sed "s/ipipip/$ip2/g" "$program" > tmp2.txt
#sed "s/ipipip/$ip3/g" "$program" > tmp3.txt
#cat tmp1.txt tmp2.txt tmp3.txt > "txt/${city}.txt"

#rm -rf tmp1.txt tmp2.txt tmp3.txt



#for a in result/*.txt; do echo "";echo "========================= $(basename "$a") ==================================="; cat $a; done

