rm -f speedtest_bestv.log
i=0
while read line; do
 i=$(($i+1));
 ip=$line
 date1=$(date +%Y%m%d%H)
 a=$(date +%s)
 a=${a:0:9}
 a=`expr $a - 7`
 url2="$date1/$a.ts"
 url="http://$ip/liveplay-kk.rtxapp.com/live/program/live/cctv1hd8m/8000000/$url2"
 curl $url  --connect-timeout 2 --max-time 15 -o /dev/null >dl.log 2>&1
 a=$(tail -n 1 dl.log|awk '{print $NF}')
 echo "第$i个： $ip    $a" 
 echo "$ip    $a">> speedtest_bestv.log
     
done
cat speedtest_bestv.log |grep M|awk '{print $2"  " $1}'|sort -r |head -n 10
