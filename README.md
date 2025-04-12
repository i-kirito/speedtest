>因为NC月底那个双倍鸡超过2T流量就会限速至200 MBit/s， 自己用AI写了一个检测限速脚本，定时测速当超过限速的速度通知TG。

### 脚本依赖
- 使用speedtest-cli，curl，bc
- 系统定时任务

### 使用方法
- 一键安装脚本（重新设计）

- `bash install.sh <token> <id> <time>`
- <token>为TG机器人token，@BotFather创建
- <id>为TG用户ID，@get_id_bot获取
- <time>为定时间隔时间，单位为秒

[upl-image-preview url=https://www.invites.fun/assets/files/2025-03-01/1740856878-588100-image.png]

[upl-image-preview url=https://www.invites.fun/assets/files/2025-03-01/1740856905-186583-image.png]

~~代码由AI生成，由我进行修改，不保证测速准确性（基本都是正常能测）建议看到限速解除通知还是查看一下SCP吧~~

- 相关代码

`
systemctl start speedtest.timer   # 启动定时任务
systemctl stop speedtest.timer    # 停止定时任务
systemctl restart speedtest.timer # 重启定时任务
systemctl status speedtest.timer  # 查看定时任务状态
`
`systemctl list-timers --all | grep speedtest.timer #查看下一次执行的时间`

> 建议解除限速后关闭定时任务，上传速度会影响脚本测速，以后有时间我看能不能优化一下
