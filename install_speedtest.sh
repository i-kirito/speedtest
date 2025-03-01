#!/bin/bash

# 提示用户输入 Telegram Bot Token 和 Chat ID
echo "请输入 Telegram Bot Token（例如 123456789:ABCDEF1234567890ABCDEF1234567890）："
read TOKEN

echo "请输入 Telegram Chat ID（例如 123456789）："
read CHAT_ID

# 更新并安装依赖
echo "安装依赖..."
apt update && apt install -y curl speedtest-cli

# 创建 speedtest.sh 脚本
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
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a $LOG_FILE
}

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
EOF

# 给 speedtest.sh 脚本增加可执行权限
chmod +x /root/speedtest.sh

# 写入 .bashrc 环境变量
echo "export TG_BOT_TOKEN=$TOKEN" >> ~/.bashrc
echo "export TG_CHAT_ID=$CHAT_ID" >> ~/.bashrc
source ~/.bashrc

# 设置定时任务，每小时的 0 分和 30 分执行一次
echo "设置定时任务..."
(crontab -l ; echo "0,30 * * * * /bin/bash /root/speedtest.sh") | crontab -

# 执行一次 speedtest 脚本
echo "执行一次 speedtest 脚本..."
bash /root/speedtest.sh

# 提示完成

echo "一键安装完成！Speedtest 脚本已创建并已配置定时任务。输入 bash /root/speedtest.sh 执行"
