#!/bin/bash

# 启动��色
echo "启动哲思者 (💡)..."

# 设置环境变量
export CLAWDBOT_PROFILE=thinker
export CLAWDBOT_CONFIG_PATH="/Users/lijian/clawd/config/roles/thinker-config.json"

# 启动Clawdbot
clawdbot --profile thinker agent --channel feishu --message "我是哲思者 ��已上线并加入群组"

echo "哲思者 启动完成"
echo "配置环境: --profile thinker"
echo "工作空间: /Users/lijian/clawd/workspaces/thinker"
echo "网关端口: 18801"
