<?php
header('Content-Type:application/json;charset=utf-8');
$id = $_GET['id'];
$playseek = $_GET['playseek'];

$user = '13917328994';//改成你的名字
$pw = strtoupper(md5h('123456')); //123456改成你的密码
$pserialnumber ='15704d6d454268e5'; //改成你的设备ID
$t = time();
$nonce = rand(100000,999999);
$str = 'sumasalt-app-portalpVW4U*FlS'.$t.$nonce.$user;
$hmac = substr(sha1($str),0,10);

$ptoken = 'ewhbMByrU7X53BQvntkmfA=='; //失效时抓包登录信息，修改值
$newtoken = $ptoken;

$url="http://portal.gcable.cn:8080/PortalServer-App/new/aaa_aut_aut002?ptype=1&plocation=001&puser=$user&ptoken=$ptoken&pversion=030107&pserverAddress=portal.gcable.cn&pserialNumber=$pserialnumber&pkv=1&ptn=Y29tLnN1bWF2aXNpb24uc2FucGluZy5ndWRvdQ&DRMtoken=&epgID=&authType=0&secondAuthid=&t=$ptoken&pid=&cid=364&u=$user&p=1&l=001&d=$pserialnumber&n=$id&v=2&ot=0&pappName=GoodTV&hmac=$hmac&timestamp=$t&nonce=$nonce";


get($url,$id,$playseek,$newtoken);

function get($url,$id,$playseek,$newtoken){
    $useragent = 'Apache-HttpClient/UNAVAILABLE (java 1.4)';
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_USERAGENT, $useragent);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, false);
    curl_setopt($ch, CURLOPT_TIMEOUT, 3);//设置超时时间为3s
    $res = curl_exec($ch);
    curl_close($ch);
    //preg_match('|aaa?(.*?)&ip|',$res, $tk);
    //$live="http://gslb.gcable.cn:8070/live/".$id.".m3u8?".$tk[1];
    //修改
    $uas=parse_url($res);
    parse_str($uas["query"]);
    $token="t=".$newtoken."&u=".$u."&p=".$p."&pid=&cid=".$cid."&d=".$d."&sid=".$sid."&r=".$r."&e=".$e."&nc=".$nc."&a=".$a."&v=".$v;
    $playurl = "http://gslb.gcable.cn:8070/live/".$id.".m3u8?".$token;
    if($playseek !== null){
        $t = explode('-',$playseek);
        $st=strtotime($t[0]);
        $et=strtotime($t[1]);
        $playurl=$playurl."&starttime=".$st."&endtime=".$et."";
    }
    header('Location: '.$playurl);
}
