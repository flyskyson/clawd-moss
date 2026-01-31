#!/bin/bash

# 简化启动脚本：和谐者
echo "启动 和谐者..."

# 设置环境
export CLAWDBOT_PROFILE=coordinator
export CLAWDBOT_CONFIG_PATH="/Users/lijian/clawd/config/roles/coordinator-config.json"

# 先运行setup确保状态目录
clawdbot --profile coordinator setup

echo "和谐者 环境准备完成"
echo "使用以下命令测试："
echo "clawdbot --profile coordinator agent --channel feishu --to \"ou_8924c5894c324474511b00980af769ee\" --message \"我是��测试启动\" --local"
