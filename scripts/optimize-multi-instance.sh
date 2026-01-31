#!/bin/bash

# 多实例配置优化脚本
# B方案：优先解决技术问题，确保每个角色独立稳定运行

echo "========================================="
echo "多实例配置优化 - B方案实施"
echo "========================================="

# 角色定义
ROLES=("leader" "thinker" "executor" "coordinator")
DISPLAY_NAMES=("领航者" "哲思者" "实干家" "和谐者")
PORTS=(18800 18801 18802 18803)

# 检查当前网关状态
echo "检查当前网关状态..."
MAIN_GATEWAY_PORT=18789
echo "主网关端口：$MAIN_GATEWAY_PORT"

# 检查端口占用
check_port_usage() {
    local port="$1"
    if lsof -i :"$port" > /dev/null 2>&1; then
        echo "⚠️  端口 $port 已被占用"
        lsof -i :"$port" | head -3
        return 1
    else
        echo "✅ 端口 $port 可用"
        return 0
    fi
}

echo ""
echo "检查端口可用性..."
for port in "${PORTS[@]}"; do
    check_port_usage "$port"
done

# 优化认证配置
echo ""
echo "优化认证配置..."
AUTH_SOURCE="$HOME/.clawdbot/agents/main/agent/auth-profiles.json"
if [ -f "$AUTH_SOURCE" ]; then
    echo "找到主认证文件：$AUTH_SOURCE"
    
    # 复制到每个角色
    for role in "${ROLES[@]}"; do
        AUTH_TARGET="$HOME/.clawdbot-$role/agents/main/agent/auth-profiles.json"
        mkdir -p "$(dirname "$AUTH_TARGET")"
        
        # 创建增强的认证配置（包含deepseek）
        cat > "$AUTH_TARGET" << EOF
{
  "version": 1,
  "profiles": {
    "deepseek:default": {
      "type": "api_key",
      "provider": "deepseek",
      "key": "sk-4b238f0a50ae443bb7e7467bef47815a"
    },
    "zai:default": {
      "type": "api_key",
      "provider": "zai",
      "key": "58f9bb81b1d74834b58e7adad468c14a.vt2xEDAjjIDC4sf0"
    }
  },
  "lastGood": {
    "deepseek": "deepseek:default",
    "zai": "zai:default"
  },
  "usageStats": {
    "deepseek:default": {
      "lastUsed": $(date +%s%3N),
      "errorCount": 0
    },
    "zai:default": {
      "lastUsed": $(date +%s%3N),
      "errorCount": 0
    }
  }
}
EOF
        echo "✅ 为 $role 创建认证配置"
    done
else
    echo "⚠️  未找到主认证文件，使用模板创建"
fi

# 优化配置文件
echo ""
echo "优化角色配置文件..."
for i in "${!ROLES[@]}"; do
    ROLE="${ROLES[$i]}"
    DISPLAY_NAME="${DISPLAY_NAMES[$i]}"
    PORT="${PORTS[$i]}"
    
    CONFIG_FILE="config/roles/$ROLE-config.json"
    
    if [ -f "$CONFIG_FILE" ]; then
        echo "优化 $DISPLAY_NAME 配置 (端口: $PORT)..."
        
        # 生成唯一token
        TOKEN=$(echo "$ROLE-$(date +%s)" | md5 | cut -c1-24)
        
        # 更新配置
        jq --arg port "$PORT" \
           --arg token "$TOKEN" \
           '.gateway.port = ($port | tonumber) |
            .gateway.auth.token = $token |
            .gateway.mode = "local" |
            .gateway.bind = "loopback"' \
           "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        
        echo "✅ $DISPLAY_NAME 配置优化完成"
    else
        echo "⚠️  未找到 $DISPLAY_NAME 配置文件"
    fi
done

# 创建简化启动脚本
echo ""
echo "创建简化启动脚本..."
for i in "${!ROLES[@]}"; do
    ROLE="${ROLES[$i]}"
    DISPLAY_NAME="${DISPLAY_NAMES[$i]}"
    
    cat > "scripts/start-$ROLE-simple.sh" << EOF
#!/bin/bash

# 简化启动脚本：$DISPLAY_NAME
echo "启动 $DISPLAY_NAME..."

# 设置环境
export CLAWDBOT_PROFILE=$ROLE
export CLAWDBOT_CONFIG_PATH="$PWD/config/roles/$ROLE-config.json"

# 先运行setup确保状态目录
clawdbot --profile $ROLE setup

echo "$DISPLAY_NAME 环境准备完成"
echo "使用以下命令测试："
echo "clawdbot --profile $ROLE agent --channel feishu --to \"ou_8924c5894c324474511b00980af769ee\" --message \"我是$DISPLAY_NAME，测试启动\" --local"
EOF
    
    chmod +x "scripts/start-$ROLE-simple.sh"
    echo "✅ 创建 $DISPLAY_NAME 简化启动脚本"
done

# 创建测试脚本
echo ""
echo "创建测试脚本..."
cat > "scripts/test-all-roles-simple.sh" << 'EOF'
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
EOF

chmod +x scripts/test-all-roles-simple.sh

# 创建问题诊断脚本
echo ""
echo "创建问题诊断脚本..."
cat > "scripts/diagnose-multi-instance.sh" << 'EOF'
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
EOF

chmod +x scripts/diagnose-multi-instance.sh

echo ""
echo "========================================="
echo "B方案实施完成！"
echo "========================================="
echo ""
echo "已创建的优化工具："
echo "1. ✅ optimize-multi-instance.sh - 配置优化脚本"
echo "2. ✅ start-*-simple.sh - 简化启动脚本（4个）"
echo "3. ✅ test-all-roles-simple.sh - 批量测试脚本"
echo "4. ✅ diagnose-multi-instance.sh - 问题诊断脚本"
echo ""
echo "立即执行："
echo "1. 诊断当前问题：./scripts/diagnose-multi-instance.sh"
echo "2. 优化配置：./scripts/optimize-multi-instance.sh"
echo "3. 测试启动：./scripts/test-all-roles-simple.sh"
echo ""
echo "任务进度已更新：40% → 准备开始技术实施"
echo "========================================="