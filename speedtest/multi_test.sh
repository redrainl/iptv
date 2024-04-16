#!/bin/bash
time=$(date +%m%d%H%M)
i=0

echo "请选择城市："
echo "1. Shanghai_103"
echo "2. Beijing_liantong_145"
echo "3. Sichuan_333"
echo "4. Zhejiang_120"
echo "5. Beijing_dianxin_186"
echo "6. Jieyang_129(no)"
read -p "输入选择（1-5）: " city_choice

# 根据用户选择设置城市和相应的stream
case $city_choice in
    1)
        city="Shanghai_103"
        stream="udp/239.45.3.209:5140"
        ;;
    2)
        city="Beijing_liantong_145"
        stream="rtp/239.3.1.159:8000"
        ;;
    3)
        city="Sichuan_333"
        stream="udp/239.93.1.9:2192"
        ;;
    4)
        city="Zhejiang_120"
        stream="rtp/233.50.200.191:5140"
        ;;
    5)
        city="Beijing_dianxin_186"
        stream="udp/225.1.8.37:8002"
        ;;
    6)
        city="Jieyang_129"
        stream="/38/index.m3u8"
        ;;

    *)
        echo "错误：无效的选择。"
        exit 1
        ;;
esac

# 使用城市名作为默认文件名，格式为 CityName.ip
filename="${city}.ip"

# 检查文件是否存在
if [ ! -f "$filename" ]; then
    echo "错误：文件 $filename 不存在。"
    exit 1
fi

lines=$(cat "$filename" | wc -l)
echo "文件内ip共计$lines个"

while read line; do
    i=$(($i + 1))
    ip=$line
    url="http://$ip/$stream"
    echo $url
    curl $url --connect-timeout 3 --max-time 10 -o /dev/null >zubo.tmp 2>&1
    a=$(head -n 3 zubo.tmp | awk '{print $NF}' | tail -n 1)
    echo "第$i/$lines个：$ip    $a"
    echo "$ip    $a" >> "speedtest_${city}_$time.log"
done < "$filename"

rm -f zubo.tmp
cat "speedtest_${city}_$time.log" | grep -E 'M|k' | awk '{print $2"  "$1}' | sort -n -r >"result_${city}.txt"
cat "result_${city}.txt"
ip1=$(head -n 1 result_${city}.txt | awk '{print $2}')
ip2=$(head -n 2 result_${city}.txt | tail -n 1 | awk '{print $2}')
ip3=$(head -n 3 result_${city}.txt | tail -n 1 | awk '{print $2}')

sed "s/ipipip/$ip1/g" template/template_${city}.txt >tmp1.txt
sed "s/ipipip/$ip2/g" template/template_${city}.txt >tmp2.txt
sed "s/ipipip/$ip3/g" template/template_${city}.txt >tmp3.txt
cat tmp1.txt tmp2.txt tmp3.txt >txt/${city}.txt

rm -rf tmp1.txt tmp2.txt tmp3.txt


echo "上海电信,#genre#" >zubo.txt
cat txt/Shanghai_103.txt >>zubo.txt
echo "四川电信,#genre#" >>zubo.txt
cat txt/Sichuan_333.txt >>zubo.txt
echo "浙江电信,#genre#" >>zubo.txt
cat txt/Zhejiang_120.txt >>zubo.txt
echo "北京电信,#genre#" >>zubo.txt
cat txt/Beijing_dianxin_186.txt >>zubo.txt
echo "北京联通,#genre#" >>zubo.txt
cat txt/Beijing_liantong_145.txt >>zubo.txt
