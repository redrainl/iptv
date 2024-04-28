#!/bin/bash

time=$(date +%m%d%H%M)
i=0

if [ $# -eq 0 ]; then
  echo "请选择城市："
  echo "1. 上海电信（Shanghai_103）"
  echo "2. 北京联通（Beijing_liantong_145）"
  echo "3. 四川电信（Sichuan_333）"
  echo "4. 浙江电信（Zhejiang_120）"
  echo "5. 北京电信（Beijing_dianxin_186）"
  echo "6. 揭阳酒店（Jieyang_129）"
  echo "7. 广东电信（Guangdong_332）"
  echo "8. 河南电信（Henan_327）"
  echo "9. 山西电信（Shanxi_117）"
  echo "10. 天津联通（Tianjin_160）"
  echo "11. 湖北电信（Hubei_90）"
  echo "12. 福建电信（Fujian_114）"
  echo "13. 湖南电信（Hunan_282）"
  echo "14. 甘肃电信（Gansu_105）"
  echo "15. 河北联通（Hebei_313）"
  echo "0. 全部"
  read -t 15 -p "输入选择或在10秒内无输入将默认选择全部: " city_choice

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
        city="Shanghai_103"
        stream="udp/239.45.1.4:5140"
	channel_key="上海电信"
        ;;
    2)
        city="Beijing_liantong_145"
        stream="rtp/239.3.1.236:2000"
        channel_key="北京联通"
        ;;
    3)
        city="Sichuan_333"
        stream="udp/239.93.42.33:5140"
        channel_key="四川电信"
        ;;
    4)
        city="Zhejiang_120"
        stream="rtp/233.50.201.63:5140"
        channel_key="浙江电信"
        ;;
    5)
        city="Beijing_dianxin_186"
        stream="udp/225.1.8.80:2000"
        channel_key="北京电信"
        ;;
    6)
        city="Jieyang_129"
        stream="hls/38/index.m3u8"
        channel_key="揭西"
        ;;
    7)
        city="Guangdong_332"
        stream="udp/239.77.1.98:5146"
        channel_key="广东电信"
        ;;
    8)
        city="Henan_327"
        stream="rtp/239.16.20.1:10010"
        channel_key="河南电信"
        ;;
    9)
        city="Shanxi_117"
        stream="udp/239.1.1.7:8007"
        channel_key="山西电信"
        ;;
    10)
        city="Tianjin_160"
        stream="udp/225.1.2.190:5002"
        channel_key="天津联通"
        ;;
    11)
        city="Hubei_90"
        stream="rtp/239.69.1.141:10482"
        channel_key="湖北电信"
        ;;
    12)
        city="Fujian_114"
        stream="rtp/239.61.2.183:9086"
        channel_key="福建电信"
        ;;
    13)
        city="Hunan_282"
        stream="udp/239.76.252.35:9000"
        channel_key="湖南电信"
        ;;
    14)
        city="Gansu_105"
        stream="udp/239.255.30.123:8231"
        channel_key="甘肃电信"
        ;;
    15)
        city="Hebei_313"
        stream="rtp/239.253.93.134:6631"
        channel_key="河北联通"
        ;;
    0)
        # 如果选择是“全部选项”，则逐个处理每个选项
        for option in {1..15}; do
          bash  ./multi_test.sh $option  # 假定script_name.sh是当前脚本的文件名，$option将递归调用
        done
        exit 0
        ;;

    *)
        echo "错误：无效的选择。"
        exit 1
        ;;
esac

# 使用城市名作为默认文件名，格式为 CityName.ip
filename="ip/${city}.ip"

# 搜索最新ip

echo "===============从tonkiang检索最新ip================="
python3 hoteliptv.py $channel_key  >test.html
grep -o "href='hotellist.html?s=[^']*'"  test.html>temp.txt
# sed -n "s/.*href='hotellist.html?s=\([^']*\)'.*/\1/p" temp.txt > $filename
sed -n "s/^.*href='hotellist.html?s=\([^:]*:[0-9]*\).*/\1/p" temp.txt | sort | uniq > $filename
rm -f test.html 


echo "===============检索完成================="

# 检查文件是否存在
if [ ! -f "$filename" ]; then
    echo "错误：文件 $filename 不存在。"
    exit 1
fi

lines=$(cat "$filename" | wc -l)
echo "【$filename文件】内ip共计$lines个"

while read line; do
    i=$(($i + 1))
    ip=$line
    url="http://$ip/$stream"
    if [ "$city" == "Jieyang_129" ]; then
        echo $url
        # 使用yt-dlp下载并解析下载速度
        output=$(yt-dlp --ignore-config --no-cache-dir --output "output.ts" --download-archive new-archive.txt --external-downloader ffmpeg --external-downloader-args "-t 5" "$url" 2>&1)
        a=$(echo "$output" | grep -oP 'at \K[0-9.]+M')
        rm -f  new-archive.txt output.ts
    else
        echo $url
        curl $url --connect-timeout 3 --max-time 10 -o /dev/null >zubo.tmp 2>&1
        a=$(head -n 3 zubo.tmp | awk '{print $NF}' | tail -n 1)
    fi  




    echo "第$i/$lines个：$ip    $a"
    echo "$ip    $a" >> "speedtest_${city}_$time.log"
done < "$filename"

rm -f zubo.tmp
cat "speedtest_${city}_$time.log" | grep -E 'M|k' | awk '{print $2"  "$1}' | sort -n -r >"result/result_${city}.txt"
cat "result/result_${city}.txt"
ip1=$(head -n 1 result/result_${city}.txt | awk '{print $2}')
ip2=$(head -n 2 result/result_${city}.txt | tail -n 1 | awk '{print $2}')
ip3=$(head -n 3 result/result_${city}.txt | tail -n 1 | awk '{print $2}')
rm -f speedtest_${city}_$time.log
sed "s/ipipip/$ip1/g" template/template_${city}.txt >tmp1.txt
sed "s/ipipip/$ip2/g" template/template_${city}.txt >tmp2.txt
sed "s/ipipip/$ip3/g" template/template_${city}.txt >tmp3.txt
cat tmp1.txt tmp2.txt tmp3.txt >txt/${city}.txt

rm -rf tmp1.txt tmp2.txt tmp3.txt


echo "上海电信,#genre#" >zubo.txt
cat txt/Shanghai_103.txt >>zubo.txt
echo "北京电信,#genre#" >>zubo.txt
cat txt/Beijing_dianxin_186.txt >>zubo.txt
echo "北京联通,#genre#" >>zubo.txt
cat txt/Beijing_liantong_145.txt >>zubo.txt
echo "天津联通,#genre#" >>zubo.txt
cat txt/Tianjin_160.txt >>zubo.txt
echo "河南电信,#genre#" >>zubo.txt
cat txt/Henan_327.txt >>zubo.txt
echo "山西电信,#genre#" >>zubo.txt
cat txt/Shanxi_117.txt >>zubo.txt
echo "广东电信,#genre#" >>zubo.txt
cat txt/Guangdong_332.txt >>zubo.txt
echo "四川电信,#genre#" >>zubo.txt
cat txt/Sichuan_333.txt >>zubo.txt
echo "浙江电信,#genre#" >>zubo.txt
cat txt/Zhejiang_120.txt >>zubo.txt
echo "湖北电信,#genre#" >>zubo.txt
cat txt/Hubei_90.txt >>zubo.txt
echo "福建电信,#genre#" >>zubo.txt
cat txt/Fujian_114.txt >>zubo.txt
echo "湖南电信,#genre#" >>zubo.txt
cat txt/Hunan_282.txt >>zubo.txt
echo "甘肃电信,#genre#" >>zubo.txt
cat txt/Gansu_105.txt >>zubo.txt
echo "河北联通,#genre#" >>zubo.txt
cat txt/Hebei_313.txt >>zubo.txt
echo "揭西凤凰,#genre#" >>zubo.txt
cat txt/Jieyang_129.txt >>zubo.txt

scp root@你的服务器:/iptv/mylist.txt .
# sed -i '/^上海电信/,$d' mylist.txt
sed -i '/^上海电信/,/^上海IPV6/{/^上海IPV6/!d;}' mylist.txt
cat zubo.txt  mylist.txt >temp.txt  && mv -f  temp.txt mylist.txt
scp mylist.txt root@你的服务器:/iptv/mylist.txt

for a in result/*.txt; do echo "";echo "========================= $(basename "$a") ==================================="; cat $a; done

