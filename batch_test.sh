#!/bin/bash
set -o pipefail

# ============ 配置常量 ============
WARM_SEC=3
TEST_SEC=10
INPUT_FILE="/work/sh.ip"
OUTPUT_FILE="/work/result"
TMP_RESULT_RAW="/work/.tmp_raw_result"
# 固定后缀
SUFFIX="/udp/233.18.204.57:5140"
# ==================================

# 清空临时文件
> "${TMP_RESULT_RAW}"
> "${OUTPUT_FILE}"

echo "======================================"
echo "批量IPTV测速启动"
echo "输入列表: ${INPUT_FILE}"
echo "拼接后缀: ${SUFFIX}"
echo "筛选条件: 平均帧率 > 22"
echo "======================================"

if [ ! -f "${INPUT_FILE}" ];then
    echo "错误：找不到输入文件 ${INPUT_FILE}"
    exit 1
fi

# 第一步：筛选有效行，存入数组（剔除注释、空行）
VALID_LINES=()
while IFS= read -r line; do
    line=$(echo "$line" | xargs)
    if [ -n "$line" ] && [[ "$line" != \#* ]]; then
        VALID_LINES+=("$line")
    fi
done < "${INPUT_FILE}"

TOTAL_NUM=${#VALID_LINES[@]}
if [ "${TOTAL_NUM}" -eq 0 ]; then
    echo "错误：ips_shanghai 无有效待检测地址！"
    exit 1
fi
echo "总共需要检测地址数量：${TOTAL_NUM}"
echo "======================================"

# 逐行遍历
CUR_INDEX=1
for ip_port in "${VALID_LINES[@]}"; do
    FULL_URL="http://${ip_port}${SUFFIX}"
    echo -e "\n【进度：${CUR_INDEX}/${TOTAL_NUM}】正在测速: ${ip_port}"
    echo "完整地址: ${FULL_URL}"

    # 预热
    timeout $((WARM_SEC + 2)) ffmpeg \
        -user_agent "VLC/3.0.20 LibVLC/3.0.20" \
        -timeout 8000000 \
        -rw_timeout 6000000 \
        -probesize 4000000 \
        -analyzeduration 6000000 \
        -flags low_delay \
        -i "${FULL_URL}" \
        -t ${WARM_SEC} \
        -an \
        -f null - >/dev/null 2>&1 || true

    # 采集帧数
    FRAME_COUNT=$(timeout ${TEST_SEC} ffmpeg \
        -user_agent "VLC/3.0.20 LibVLC/3.0.20" \
        -timeout 8000000 \
        -rw_timeout 6000000 \
        -probesize 4000000 \
        -analyzeduration 6000000 \
        -flags low_delay \
        -i "${FULL_URL}" \
        -t ${TEST_SEC} \
        -an \
        -f framehash - 2>/dev/null | wc -l)

    FRAME_COUNT=$(echo "${FRAME_COUNT}" | tr -d '\n\r ' | sed 's/[^0-9]//g')
    [ -z "${FRAME_COUNT}" ] && FRAME_COUNT=0
    AVG_FPS=$(echo "scale=2; ${FRAME_COUNT}/${TEST_SEC}" | bc)

    echo "帧数:${FRAME_COUNT} | 帧率:${AVG_FPS}"
    echo "${AVG_FPS},${FRAME_COUNT},${ip_port}" >> "${TMP_RESULT_RAW}"

    CUR_INDEX=$((CUR_INDEX + 1))
done

echo -e "\n========================"
echo "全部测速完成，开始排序与筛选"

# 帧率降序，筛选>22输出ip:port
cat "${TMP_RESULT_RAW}" \
    | sort -t',' -k1 -g -r \
    | awk -F',' '{if($1>22) print $3}' > "${OUTPUT_FILE}"

# 输出完整排名日志
cat "${TMP_RESULT_RAW}" | sort -t',' -k1 -g -r > /work/full_rank.log

echo "筛选完成，达标IP:端口已写入 ${OUTPUT_FILE}"
echo "符合条件地址总数：$(wc -l < ${OUTPUT_FILE})"
echo "完整测速排名日志：/work/full_rank.log"



echo "======本次$region组播ip搜索结果============="
cat "result"

# 生成最终文件
program="template/template_Shanghai_103.txt"
> "Shanghai_103.txt"
while read -r ip; do
  sed "s/ipipip/$ip/g" "$program" >> "Shanghai_103.txt"
done <result


current_date=$(date +%m-%d)

# 使用sed命令在第一行前插入指定内容
sed -i "1i更新日期：$current_date,http://test" "Shanghai_103.txt"
