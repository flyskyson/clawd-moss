#!/bin/bash

# 修复后测试脚本
echo "测试修复后的配置..."
echo "========================================="

ROLES=("leader" "thinker" "executor" "coordinator")
DISPLAY_NAMES=("领航者" "哲思者" "实干家" "和谐者")

for i in "${!ROLES[@]}"; do
    ROLE="${ROLES[$i]}"
    DISPLAY_NAME="${DISPLAY_NAMES[$i]}"
    
    echo ""
    echo "测试 $DISPLAY_NAME ($ROLE)..."
    echo "-----------------------------------------"
    
    # 检查配置
    CONFIG_FILE="config/roles/$ROLE-config.json"
    if [ -f "$CONFIG_FILE" ]; then
        PRIMARY_MODEL=$(jq -r '.agents.defaults.model.primary // "未设置"' "$CONFIG_FILE")
        echo "✅ 主模型：$PRIMARY_MODEL"
    fi
    
    echo "测试命令："
    echo "clawdbot --profile $ROLE agent --channel feishu --to \"ou_8924c5894c324474511b00980af769ee\" --message \"测试$DISPLAY_NAME\" --local"
    echo "-----------------------------------------"
done

echo ""
echo "========================================="
echo "配置检查完成"
echo "========================================="
