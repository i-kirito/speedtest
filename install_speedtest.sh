#!/bin/bash

# 检查是否传递了 Token, Chat ID 和时间间隔
if [ $# -lt 3 ]; then
    echo "缺少参数，请提供 Telegram Bot Token、Chat ID 和定时器间隔时间（秒）。"
    echo "用法: bash <(wget -qO- https://raw.githubusercontent.com/i-kirito/speedtest/main/install_speedtest.sh) <token> <id> <time>"
    exit 1
fi

# 获取命令行参数
TOKEN=$1
CHAT_ID=$2
TIME_INTERVAL=$3

# 检查依赖是否已安装
echo "检查依赖..."

# 检查 curl 是否已安装
if ! command -v curl &> /dev/null; then
    echo "curl 未安装，正在安装..."
    apt update && apt install -y curl
else
    echo "curl 已安装"
fi

# 检查 speedtest-cli 是否已安装
if ! command -v speedtest-cli &> /dev/null; then
    echo "speedtest-cli 未安装，正在安装..."
    apt install -y speedtest-cli
else
    echo "speedtest-cli 已安装"
fi

# 创建 /root/speedtest.sh 脚本
echo "创建 /root/speedtest.sh 脚本..."
cat <<EOF > /root/speedtest.sh
#!/bin/bash 

# 读取传递的 Telegram 机器人 Token 和 Chat ID
TOKEN=${TOKEN}
CHAT_ID=${CHAT_ID}

# 日志文件
LOG_FILE="/root/speedtest.log"

# 记录日志函数
log() {
    echo "\$(date +"%Y-%m-%d %H:%M:%S") - \$1" | tee -a \$LOG_FILE
}

log "开始测速..."

# 运行 Speedtest 并提取上传速度（单位：Mbps）
SPEED=\$(speedtest-cli --secure --simple | grep "Upload" | awk '{print \$2}')

# 如果测速失败，则记录日志并退出
if [ -z "\$SPEED" ]; then
    log "测速失败，SPEED 为空，可能是网络问题或 Speedtest 无法连接服务器。"
    exit 1
fi

# 保留3位小数精度
SPEED=$(echo "scale=3; \$SPEED" | bc)

log "测速成功，上传速度：\$SPEED Mbps"

# 25MB/s = 250Mbps
THRESHOLD=250

# 判断上传速度是否超过 25MB/s（250Mbps）
COMPARE_RESULT=$(echo "\$SPEED < \$THRESHOLD" | bc)

if [ "\$COMPARE_RESULT" -eq 1 ]; then
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

# 创建 systemd 服务文件
echo "创建 systemd 服务文件..."
cat <<EOF > /etc/systemd/system/speedtest.service
[Unit]
Description=Speedtest Script
After=network.target

[Service]
ExecStart=/bin/bash /root/speedtest.sh
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
EOF

# 创建 systemd 定时器文件，并使用传递的时间间隔
echo "创建 systemd 定时器文件..."
cat <<EOF > /etc/systemd/system/speedtest.timer
[Unit]
Description=Run Speedtest every ${TIME_INTERVAL} seconds

[Timer]
OnBootSec=10sec
OnUnitActiveSec=${TIME_INTERVAL}sec

[Install]
WantedBy=timers.target
EOF

# 重新加载 systemd，启用并启动定时器
echo "重新加载 systemd，启用并启动定时器..."
systemctl daemon-reload
systemctl enable speedtest.timer
systemctl start speedtest.timer

# 提示完成
echo "一键安装完成！Speedtest 脚本已创建并已配置 systemd 定时器，每 ${TIME_INTERVAL} 秒执行一次。手动执行输入 bash /root/speedtest.sh"
