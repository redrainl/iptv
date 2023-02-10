rm -f speedtest_bestv.log
while read line; do
 ip=$line
 date1=$(date +%Y%m%d%H)
 a=$(date +%s)
 a=${a:0:9}
 a=`expr $a - 7`
 url2="$date1/$a.ts"
 url="http://$ip/liveplay-kk.rtxapp.com/live/program/live/cctv1hd8m/8000000/$url2"
 echo $url
 curl $url  --connect-timeout 2 --max-time 15 -o /dev/null >dl.log 2>&1
 a=$(tail -n 1 dl.log|awk '{print $NF}')
  echo "$ip    $a">> speedtest_bestv.log
   
	    
done
cat speedtest_bestv.log |grep M|awk '{print $2"  " $1}'|sort
