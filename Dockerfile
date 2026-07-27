FROM cremuzzi/mpv:0.38.0

USER root
# 替换国内源
RUN sed -i 's|https://dl-cdn.alpinelinux.org|https://mirrors.aliyun.com|g' /etc/apk/repositories

# 安装依赖
RUN apk update && apk add --no-cache \
    ffmpeg \
    bash \
    bc \
    coreutils

WORKDIR /work
# 不再COPY脚本进镜像
VOLUME ["/work"]

# 默认执行挂载目录下的脚本
ENTRYPOINT ["/work/batch_test.sh"]
