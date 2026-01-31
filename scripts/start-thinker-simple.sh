#!/bin/bash

# 简化启动脚本：哲思者
echo "启动 哲思者..."

# 设置环境
export CLAWDBOT_PROFILE=thinker
export CLAWDBOT_CONFIG_PATH="/Users/lijian/clawd/config/roles/thinker-config.json"

# 先运行setup确保状态目录
clawdbot --profile thinker setup

echo "哲思者 环境准备完成"
echo "使用以下命令测试："
echo "clawdbot --profile thinker agent --channel feishu --to \"ou_8924c5894c324474511b00980af769ee\" --message \"我是��测试启动\" --local"
