#!/bin/bash

# 简化测试所有角色
echo "测试所有角色简化启动..."
echo "========================================="

ROLES=("leader" "thinker" "executor" "coordinator")
DISPLAY_NAMES=("领航者" "哲思者" "实干家" "和谐者")

for i in "${!ROLES[@]}"; do
    ROLE="${ROLES[$i]}"
    DISPLAY_NAME="${DISPLAY_NAMES[$i]}"
    
    echo ""
    echo "测试 $DISPLAY_NAME..."
    echo "-----------------------------------------"
    
    # 检查配置文件
    CONFIG_FILE="config/roles/$ROLE-config.json"
    if [ -f "$CONFIG_FILE" ]; then
        PORT=$(jq -r '.gateway.port' "$CONFIG_FILE")
        echo "✅ 配置文件正常 (端口: $PORT)"
        
        # 检查认证文件
        AUTH_FILE="$HOME/.clawdbot-$ROLE/agents/main/agent/auth-profiles.json"
        if [ -f "$AUTH_FILE" ]; then
            echo "✅ 认证文件正常"
        else
            echo "⚠️  认证文件缺失"
        fi
    else
        echo "❌ 配置文件缺失"
    fi
    
    echo "启动命令："
    echo "  ./scripts/start-$ROLE-simple.sh"
    echo "-----------------------------------------"
done

echo ""
echo "========================================="
echo "简化测试完成"
echo "========================================="
echo ""
echo "下一步："
echo "1. 逐个启动角色测试：./scripts/start-<role>-simple.sh"
echo "2. 测试消息发送功能"
echo "3. 验证多实例独立运行"
echo "========================================="
