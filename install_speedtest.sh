#!/bin/bash

# 获取命令行传参中的 token 和 id
TOKEN=$1
CHAT_ID=$2

# 检查是否传入了 token 和 id 参数
if [ -z "$TOKEN" ] || [ -z "$CHAT_ID" ]; then
    echo "缺少 Telegram Bot Token 或 Chat ID，请提供 token 和 id。"
    echo "使用格式: bash <(wget -qO- https://raw.githubusercontent.com/i-kirito/speedtest/main/install_speedtest.sh) <token> <id>"
    exit 1
fi

# 将 token 和 id 保存到 .bashrc
echo "export TG_BOT_TOKEN=$TOKEN" >> ~/.bashrc
echo "export TG_CHAT_ID=$CHAT_ID" >> ~/.bashrc
source ~/.bashrc

# 更新并安装依赖
echo "安装依赖..."
apt update && apt install -y curl speedtest-cli

# 创建 /root/speedtest.sh 脚本
echo "创建 /root/speedtest.sh 脚本..."
cat <<EOF > /root/speedtest.sh
#!/bin/bash 

# 读取环境变量中的 Telegram 机器人 Token 和 Chat ID
TOKEN=${TOKEN}
CHAT_ID=${CHAT_ID}

# 日志文件
LOG_FILE="/root/speedtest.log"

# 记录日志函数
log() {
    echo "\$(date +"%Y-%m-%d %H:%M:%S") - \$1" | tee -a \$LOG_FILE
}

log "开始测速..."

# 运行 Speedtest 并提取上传速度（单位：Mbps），并通过 tee 显示实时输出
speedtest-cli --secure --simple | tee -a \$LOG_FILE | grep -i 'upload' 

# 如果测速失败，则记录日志并退出
if [ -z "\$SPEED" ]; then
    log "测速失败，SPEED 为空，可能是网络问题或 Speedtest 无法连接服务器。"
    exit 1
fi

log "测速成功，上传速度：\$SPEED Mbps"

# 25MB/s = 250Mbps
THRESHOLD=250

# 判断上传速度是否超过 25MB/s（250Mbps）
if (( \$(echo "\$SPEED < \$THRESHOLD" | bc -l) )); then
    MESSAGE=" 限速未解除，当前上传速度：\$SPEED Mbps（低于 25MB/s）"
else
    MESSAGE=" 限速已解除，当前上传速度：\$SPEED Mbps（高于 25MB/s）"
fi

log "发送 Telegram 通知：\$MESSAGE"

# 发送 Telegram 消息
RESPONSE=\$(curl -s -X POST "https://api.telegram.org/bot\$TOKEN/sendMessage" \
    -d "chat_id=\$CHAT_ID" -d "text=\$MESSAGE")

# 检查是否发送成功
if [[ \$RESPONSE == *'"ok":true'* ]]; then
    log "Telegram 通知发送成功！"
else
    log "Telegram 通知发送失败！响应：\$RESPONSE"
fi

log "测速任务完成。"
EOF

# 给 speedtest.sh 脚本增加可执行权限
chmod +x /root/speedtest.sh

# 创建 /root/speedtest_scheduler.sh 脚本，使用 sleep 定时执行
echo "创建 /root/speedtest_scheduler.sh 脚本..."
cat <<EOF > /root/speedtest_scheduler.sh
#!/bin/bash

while true; do
    # 执行 /root/speedtest.sh 脚本
    echo "开始执行 Speedtest..."
    bash /root/speedtest.sh

    # 每隔 30 分钟执行一次，但每 1 分钟输出一次等待时间
    for ((i=1; i<=30; i++)); do
        echo "等待 \$i 分钟..."
        sleep 60  # 每次休眠 60 秒（1 分钟）
    done
done
EOF

# 给 speedtest_scheduler.sh 脚本增加可执行权限
chmod +x /root/speedtest_scheduler.sh

# 使用 nohup 在后台运行定时任务，并且实时显示输出
echo "使用 nohup 在后台运行定时任务..."
nohup bash /root/speedtest_scheduler.sh | tee -a /root/speedtest_scheduler.log &

# 提示完成
echo "一键安装完成！Speedtest 脚本已创建并已启动定时任务。"
