#!/bin/bash

# 修复anthropic API key问题
# 方案B：修改配置明确指定deepseek，禁用不必要的fallback

echo "========================================="
echo "修复anthropic API key问题 - 方案B"
echo "========================================="

# 角色列表
ROLES=("leader" "thinker" "executor" "coordinator")

echo "修复角色配置..."
for ROLE in "${ROLES[@]}"; do
    CONFIG_FILE="config/roles/$ROLE-config.json"
    
    if [ -f "$CONFIG_FILE" ]; then
        echo "修复 $ROLE 配置..."
        
        # 更新agents配置，明确指定deepseek
        jq '.agents.defaults.model = {
            "primary": "deepseek/deepseek-coder",
            "fallbacks": ["deepseek/deepseek-chat"]
        }' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        
        echo "✅ $ROLE 配置修复完成"
    else
        echo "⚠️  未找到 $ROLE 配置文件"
    fi
done

echo ""
echo "创建修复后测试脚本..."
cat > "scripts/test-after-fix.sh" << 'EOF'
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
EOF

chmod +x scripts/test-after-fix.sh

echo ""
echo "========================================="
echo "方案B实施完成！"
echo "========================================="
echo ""
echo "立即测试："
echo "1. 检查配置：./scripts/test-after-fix.sh"
echo "2. 测试启动：clawdbot --profile leader agent --channel feishu --to \"ou_8924c5894c324474511b00980af769ee\" --message \"测试领航者\" --local"
echo "========================================="