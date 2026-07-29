>更新：
>  run.sh 生成播放列表文件
>    调用docker镜像运行batch_test.sh脚本，测试sh.ip列表内的地址可用性，根据获取视频帧率排序，生成可用的组播ip列表文件result
>    根据上一步检测ip、template模板，组合生成Shanghai——103.txt播放列表文件
>  scanip
>    scan.sh  扫描活跃ip端口
>       脚本内直接构建docker镜像，运行scan.py,检测ips_Shanghai列表中活跃的ip+端口,生成alive.txt, 实际上也就是run.sh中使用的sh.ip文件。ips_Shanghai为要扫描的自定义范围的ip:port。 
