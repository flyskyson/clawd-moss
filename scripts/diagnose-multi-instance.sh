#!/bin/bash

# 多实例问题诊断脚本
echo "多实例配置问题诊断..."
echo "========================================="

echo "1. 检查系统环境..."
echo "操作系统：$(uname -s) $(uname -r)"
echo "Bash版本：$(bash --version | head -1)"
echo "jq版本：$(jq --version 2>/dev/null || echo "未安装")"
echo ""

echo "2. 检查Clawdbot安装..."
which clawdbot && clawdbot --version
echo ""

echo "3. 检查主配置状态..."
if [ -f "$HOME/.clawdbot/clawdbot.json" ]; then
    echo "✅ 主配置文件存在"
    MAIN_PORT=$(jq -r '.gateway.port // "未设置"' "$HOME/.clawdbot/clawdbot.json")
    echo "主网关端口：$MAIN_PORT"
else
    echo "⚠️  主配置文件缺失"
fi
echo ""

echo "4. 检查角色配置..."
ROLES=("leader" "thinker" "executor" "coordinator")
for ROLE in "${ROLES[@]}"; do
    echo "检查 $ROLE..."
    
    # 检查配置文件
    CONFIG_FILE="config/roles/$ROLE-config.json"
    if [ -f "$CONFIG_FILE" ]; then
        PORT=$(jq -r '.gateway.port // "未设置"' "$CONFIG_FILE")
        MODE=$(jq -r '.gateway.mode // "未设置"' "$CONFIG_FILE")
        echo "  ✅ 配置文件：端口=$PORT, 模式=$MODE"
    else
        echo "  ❌ 配置文件缺失"
    fi
    
    # 检查状态目录
    STATE_DIR="$HOME/.clawdbot-$ROLE"
    if [ -d "$STATE_DIR" ]; then
        echo "  ✅ 状态目录存在"
    else
        echo "  ⚠️  状态目录缺失"
    fi
    
    # 检查认证文件
    AUTH_FILE="$STATE_DIR/agents/main/agent/auth-profiles.json"
    if [ -f "$AUTH_FILE" ]; then
        echo "  ✅ 认证文件存在"
    else
        echo "  ⚠️  认证文件缺失"
    fi
    echo ""
done

echo "5. 检查端口占用..."
PORTS=(18789 18800 18801 18802 18803)
for PORT in "${PORTS[@]}"; do
    if lsof -i :"$PORT" > /dev/null 2>&1; then
        PROCESS=$(lsof -i :"$PORT" | awk 'NR==2 {print $1}')
        PID=$(lsof -i :"$PORT" | awk 'NR==2 {print $2}')
        echo "  ⚠️  端口 $PORT 被占用：$PROCESS (PID: $PID)"
    else
        echo "  ✅ 端口 $PORT 可用"
    fi
done
echo ""

echo "6. 常见问题诊断..."
echo "a) 端口冲突：确保每个角色使用不同端口"
echo "b) 认证缺失：检查auth-profiles.json文件"
echo "c) 状态目录：运行clawdbot --profile <role> setup"
echo "d) 网关模式：确保gateway.mode设置为local"
echo ""

echo "========================================="
echo "诊断完成"
echo "========================================="
echo ""
echo "建议解决方案："
echo "1. 运行优化脚本：./scripts/optimize-multi-instance.sh"
echo "2. 逐个测试启动：./scripts/start-<role>-simple.sh"
echo "3. 查看详细日志：运行命令时添加 --verbose"
echo "========================================="
