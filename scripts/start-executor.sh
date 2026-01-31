#!/bin/bash

# 启动��色
echo "启动实干家 (⚡)..."

# 设置环境变量
export CLAWDBOT_PROFILE=executor
export CLAWDBOT_CONFIG_PATH="/Users/lijian/clawd/config/roles/executor-config.json"

# 启动Clawdbot
clawdbot --profile executor agent --channel feishu --message "我是实干家 ��已上线并加入群组"

echo "实干家 启动完成"
echo "配置环境: --profile executor"
echo "工作空间: /Users/lijian/clawd/workspaces/executor"
echo "网关端口: 18802"
