#!/bin/bash

# 读取传递的 Telegram 机器人 Token 和 Chat ID
TOKEN=$1
CHAT_ID=$2

# 日志文件
LOG_FILE="/root/speedtest.log"

# 记录日志函数
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a $LOG_FILE
}

# 定义函数执行测速和发送通知
run_speedtest() {
    log "开始测速..."

    # 运行 Speedtest 并提取上传速度（单位：Mbps）
    SPEED=$(speedtest-cli --secure --simple | grep "Upload" | awk '{print $2}')

    # 如果测速失败，则记录日志并退出
    if [ -z "$SPEED" ]; then
        log "测速失败，SPEED 为空，可能是网络问题或 Speedtest 无法连接服务器。"
        exit 1
    fi

    log "测速成功，上传速度：$SPEED Mbps"

    # 25MB/s = 250Mbps
    THRESHOLD=250

    # 判断上传速度是否超过 25MB/s（250Mbps）
    if (( $(echo "$SPEED < $THRESHOLD" | bc -l) )); then
        MESSAGE=" 限速未解除，当前上传速度：$SPEED Mbps（低于 25MB/s）"
    else
        MESSAGE=" 限速已解除，当前上传速度：$SPEED Mbps（高于 25MB/s）"
    fi

    log "发送 Telegram 通知：$MESSAGE"

    # 发送 Telegram 消息
    RESPONSE=$(curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
        -d "chat_id=$CHAT_ID" -d "text=$MESSAGE")

    # 检查是否发送成功
    if [[ $RESPONSE == *'"ok":true'* ]]; then
        log "Telegram 通知发送成功！"
    else
        log "Telegram 通知发送失败！响应：$RESPONSE"
    fi

    log "测速任务完成。"
}

# 设置每次测速任务间隔的时间（秒）
interval=1800  # 30分钟

# 后台任务循环，实时显示倒计时
while true; do
    # 获取当前时间戳和下次执行时间
    current_time=$(date +%s)
    next_run_time=$(( ( (current_time / interval) + 1 ) * interval ))  # 向上取整到下一个30分钟
    remaining_seconds=$(( next_run_time - current_time ))  # 剩余时间（秒）
    remaining_minutes=$(( remaining_seconds / 60 ))  # 转换为分钟

    # 清屏，显示倒计时
    clear
    echo "正在执行测速任务..."
    echo "距离下次任务执行还有：$remaining_minutes 分钟"

    # 执行测速任务
    run_speedtest

    # 等待到下一次执行时间
    sleep $remaining_seconds
done
