#!/bin/bash

# 启动��色
echo "启动和谐者 (🤝)..."

# 设置环境变量
export CLAWDBOT_PROFILE=coordinator
export CLAWDBOT_CONFIG_PATH="/Users/lijian/clawd/config/roles/coordinator-config.json"

# 启动Clawdbot
clawdbot --profile coordinator agent --channel feishu --message "我是和谐者 ��已上线并加入群组"

echo "和谐者 启动完成"
echo "配置环境: --profile coordinator"
echo "工作空间: /Users/lijian/clawd/workspaces/coordinator"
echo "网关端口: 18803"
