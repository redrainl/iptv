<?php
error_reporting(0);
header('Content-Type:text/json;charset=UTF-8');
$id = $_GET['id'];
if (empty($_GET['id'])) $id = 'gdws';
$n = [
    'gdws' => 43, //广东卫视
    'gdzj' => 44, //广东珠江
    'gdxw' => 45, //广东新闻
    'gdgg' => 48, //广东公共
    'gdty' => 47, //广东体育
    'nfws' => 51, //大湾区卫视
    'jjkj' => 49, //经济科教
    'gdys' => 53, //广东影视
    'gdzy' => 16, //广东综艺
    'gdgj' => 46, //广东国际
    'gdse' => 54, //广东少儿
    'jjkt' => 66, //嘉佳卡通
    'nfgw' => 42, //南方购物
    'lnxq' => 15, //岭南戏曲
    'gdfc' => 67, //广东房产
    'xdjy' => 13, //现代教育
    'gdyd' => 74, //广东移动
    'gdjk' => 99, //GRTN健康频道
    'gdwh' => 75, //GRTN文化频道
    ];

$ts = time();
$headers = [
      "referer: https://www.gdtv.cn/",
      "origin: https://www.gdtv.cn",
      "user-agent: Mozilla/5.0 (Windows NT 10.0; WOW64",
      "x-itouchtv-ca-key: 89541443007807288657755311869534",
      "x-itouchtv-ca-timestamp: $ts",
      "x-itouchtv-client: WEB_PC",
      "x-itouchtv-device-id: WEB_0"
      ];

$bstrURL = "https://tcdn-api.itouchtv.cn/getParam";
$sign = base64_encode(hash_hmac("SHA256","GET\n$bstrURL\n$ts\n","dfkcY1c3sfuw0Cii9DWjOUO3iQy2hqlDxyvDXd1oVMxwYAJSgeB6phO8eW1dfuwX",true));
$headers[] = "x-itouchtv-ca-signature: $sign";

$ch = curl_init($bstrURL);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, FALSE);
curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, FALSE);
curl_setopt($ch, CURLOPT_HTTPHEADER,$headers);
$data = curl_exec($ch);
curl_close($ch);
$json = json_decode($data);
$node = $json -> node;

// 进入wss取串
$contextOptions = ['ssl' => ["verify_peer"=>false,"verify_peer_name"=>false]];
$context = stream_context_create($contextOptions);
$sock = stream_socket_client("ssl://tcdn-ws.itouchtv.cn:3800",$errno,$errstr,1,STREAM_CLIENT_CONNECT,$context);
stream_set_timeout($sock,1);
$wssData = json_encode(['route' => 'getwsparam','message' => $node]);

$key = base64_encode(substr(md5(mt_rand(1,999)),0,16));
$header .= "GET /connect HTTP/1.1\r\n";
$header .= "Host: tcdn-ws.itouchtv.cn:3800\r\n";
$header .= "Upgrade: websocket\r\n";
$header .= "Sec-WebSocket-Key: $key\r\n";
fwrite($sock,$header."\r\n");
$handshake = stream_get_contents($sock);
if(strstr($handshake,'Sec-Websocket-Accept')) {
fwrite($sock, encode($wssData));
$param = stream_get_contents($sock);
$param = substr($param,4);
$json =json_decode($param);
$wsnode = $json->wsnode;
}
// wss 取串结束.

$bstrURL = "https://gdtv-api.gdtv.cn/api/tv/v2/tvChannel/$n[$id]?tvChannelPk=$n[$id]&node=".base64_encode($wsnode);
$sign = base64_encode(hash_hmac("SHA256","GET\n$bstrURL\n$ts\n","dfkcY1c3sfuw0Cii9DWjOUO3iQy2hqlDxyvDXd1oVMxwYAJSgeB6phO8eW1dfuwX",true));

$ch = curl_init($bstrURL);
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, "OPTIONS");  
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, FALSE);
curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, FALSE);
curl_setopt($ch, CURLOPT_HTTPHEADER,["referer: https://www.gdtv.cn"]);
$data = curl_exec($ch);
curl_close($ch);

array_pop($headers);
$headers[] = "x-itouchtv-ca-signature: $sign";
        
$ch = curl_init($bstrURL);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, FALSE);
curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, FALSE);
curl_setopt($ch, CURLOPT_HTTPHEADER,$headers);
$data = curl_exec($ch);
curl_close($ch);
$json = json_decode($data);
$playURL = json_decode($json -> playUrl) -> hd;

// m3u8加referer校验。
$ch = curl_init($playURL);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, FALSE);
curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, FALSE);
curl_setopt($ch, CURLOPT_HTTPHEADER,["Referer: https://www.gdtv.cn"]);
$data = curl_exec($ch);
curl_close($ch);
print_r($data);

function encode($data) {
  $len = strlen($data);
  $head[0] = 129;
  $mask = [];
  for ($j = 0; $j < 4; $j ++) {
     $mask[] = mt_rand(1, 128);
     }
  $split = str_split(sprintf('%016b', $len), 8);
  $head[1] = 254;
  $head[2] = bindec($split[0]);
  $head[3] = bindec($split[1]);
  $head = array_merge($head, $mask);
  foreach ($head as $k => $v) {
    $head[$k] = chr($v);
    }
  $mask_data = '';
  for ($j = 0; $j < $len; $j ++) {
     $mask_data .= chr(ord($data[$j]) ^ $mask[$j % 4]);
     }
  return implode('', $head).$mask_data;
  }

?>
