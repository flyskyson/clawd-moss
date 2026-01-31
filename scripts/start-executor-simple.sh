#!/bin/bash

# 简化启动脚本：实干家
echo "启动 实干家..."

# 设置环境
export CLAWDBOT_PROFILE=executor
export CLAWDBOT_CONFIG_PATH="/Users/lijian/clawd/config/roles/executor-config.json"

# 先运行setup确保状态目录
clawdbot --profile executor setup

echo "实干家 环境准备完成"
echo "使用以下命令测试："
echo "clawdbot --profile executor agent --channel feishu --to \"ou_8924c5894c324474511b00980af769ee\" --message \"我是��测试启动\" --local"
