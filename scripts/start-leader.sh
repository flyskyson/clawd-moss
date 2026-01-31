#!/bin/bash

# 启动��色
echo "启动领航者 (🚀)..."

# 设置环境变量
export CLAWDBOT_PROFILE=leader
export CLAWDBOT_CONFIG_PATH="/Users/lijian/clawd/config/roles/leader-config.json"

# 启动Clawdbot
clawdbot --profile leader agent --channel feishu --message "我是领航者 ��已上线并加入群组"

echo "领航者 启动完成"
echo "配置环境: --profile leader"
echo "工作空间: /Users/lijian/clawd/workspaces/leader"
echo "网关端口: 18800"
