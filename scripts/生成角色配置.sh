#!/bin/bash

# 生成Clawdbot角色配置脚本
# 为每个角色创建独立的配置环境

echo "========================================="
echo "Clawdbot角色配置生成脚本"
echo "========================================="

# 定义角色数组
ROLES=("leader" "thinker" "executor" "coordinator")
DISPLAY_NAMES=("领航者" "哲思者" "实干家" "和谐者")
EMOJIS=("🚀" "💡" "⚡" "🤝")
SOUL_FILES=("领导者-SOUL.md" "思考者-SOUL.md" "执行者-SOUL.md" "协调者-SOUL.md")

# 基础配置模板
BASE_CONFIG='{
  "meta": {
    "lastTouchedVersion": "2026.1.24-3",
    "lastTouchedAt": "%TIMESTAMP%"
  },
  "auth": {
    "profiles": {
      "deepseek:default": {
        "provider": "deepseek",
        "mode": "api_key"
      }
    }
  },
  "models": {
    "providers": {
      "deepseek": {
        "baseUrl": "https://api.deepseek.com",
        "apiKey": "sk-4b238f0a50ae443bb7e7467bef47815a",
        "auth": "api-key",
        "api": "openai-completions",
        "models": [
          {
            "id": "deepseek-chat",
            "name": "DeepSeek Chat",
            "reasoning": false,
            "input": ["text"],
            "contextWindow": 200000,
            "maxTokens": 8192
          },
          {
            "id": "deepseek-coder",
            "name": "DeepSeek Coder",
            "reasoning": false,
            "input": ["text"],
            "contextWindow": 200000,
            "maxTokens": 8192
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "deepseek/deepseek-coder"
      },
      "workspace": "%WORKSPACE_PATH%",
      "compaction": {
        "mode": "safeguard"
      }
    }
  },
  "tools": {
    "web": {
      "search": {
        "enabled": true,
        "provider": "perplexity"
      },
      "fetch": {
        "enabled": true
      }
    }
  },
  "channels": {
    "feishu": {
      "appId": "cli_a9f15140edb8dbb4",
      "appSecret": "RPrX1tQ39NTHGSKLB0kHJcGh7ruRoC1P",
      "enabled": true,
      "connectionMode": "websocket",
      "dmPolicy": "pairing",
      "groupPolicy": "allowlist",
      "groupAllowFrom": ["%GROUP_ID%"],
      "requireMention": false,
      "domain": "feishu"
    }
  },
  "gateway": {
    "port": %GATEWAY_PORT%,
    "mode": "local",
    "bind": "loopback",
    "auth": {
      "mode": "token",
      "token": "%AUTH_TOKEN%"
    }
  }
}'

# 创建配置目录
mkdir -p config/roles
mkdir -p workspaces

# 读取群组配置（如果存在）
if [ -f "config/feishu-group-config.json" ]; then
    GROUP_ID=$(jq -r '.group_id' config/feishu-group-config.json)
    echo "使用现有群组ID: $GROUP_ID"
else
    read -p "请输入飞书群组ID: " GROUP_ID
fi

# 生成每个角色的配置
for i in "${!ROLES[@]}"; do
    ROLE=${ROLES[$i]}
    DISPLAY_NAME=${DISPLAY_NAMES[$i]}
    EMOJI=${EMOJIS[$i]}
    
    echo ""
    echo "生成 $DISPLAY_NAME ($EMOJI) 配置..."
    
    # 计算端口和token（确保唯一）
    BASE_PORT=18800
    PORT=$((BASE_PORT + i))
    TOKEN_PREFIX=$(echo "$ROLE" | md5 | cut -c1-8)
    AUTH_TOKEN="${TOKEN_PREFIX}$(date +%s | md5 | cut -c1-16)"
    
    # 创建工作空间
    WORKSPACE_PATH="$PWD/workspaces/$ROLE"
    mkdir -p "$WORKSPACE_PATH"
    
    # 复制角色定义文件
    cp "roles/${SOUL_FILES[$i]}" "$WORKSPACE_PATH/SOUL.md"
    
    # 创建IDENTITY.md
    cat > "$WORKSPACE_PATH/IDENTITY.md" << EOF
# IDENTITY.md - $DISPLAY_NAME

- **名称**: $DISPLAY_NAME
- **角色**: ${ROLES[$i]}
- **性格**: 查看SOUL.md了解详细性格特征
- **标志**: $EMOJI
- **创建时间**: $(date)

## 角色使命
作为$DISPLAY_NAME，我的使命是在Clawdbot角色发展实验室中：
1. 展现独特的${ROLES[$i]}性格特征
2. 积极参与每日议题讨论
3. 与其他角色协作处理任务
4. 通过反思实现性格发展

## 配置信息
- **配置环境**: --profile $ROLE
- **工作空间**: $WORKSPACE_PATH
- **网关端口**: $PORT
- **群组ID**: $GROUP_ID

---
*这是自动生成的配置文件*
EOF
    
    # 创建USER.md（简化版）
    cat > "$WORKSPACE_PATH/USER.md" << EOF
# USER.md - 关于飞天主人

- **名称**: 飞天
- **称呼**: 飞天主人
- **时区**: Asia/Shanghai
- **项目**: Clawdbot多角色发展实验

## 项目背景
飞天主人正在开展一个创新的AI实验：创建多个具有不同性格的Clawdbot实例，让它们在飞书群组中互动、讨论、协作，促进AI性格的发展。

## 对我的期望
作为$DISPLAY_NAME，我需要：
1. 保持角色性格的一致性
2. 积极参与群组讨论
3. 认真完成分配的任务
4. 通过反思不断改进

## 沟通要点
- 在群组中明确标识自己的角色
- 尊重其他角色的观点和风格
- 保持建设性的讨论态度
- 及时报告进展和问题
EOF
    
    # 创建AGENTS.md
    cat > "$WORKSPACE_PATH/AGENTS.md" << EOF
# AGENTS.md - $DISPLAY_NAME的工作空间

## 角色专属配置
这是$DISPLAY_NAME ($EMOJI) 的专属工作空间。我在这里：
1. 维护角色的性格一致性
2. 准备议题讨论内容
3. 处理分配的任务
4. 进行自我反思和成长

## 文件结构
- SOUL.md - 角色性格定义
- IDENTITY.md - 角色身份信息
- USER.md - 关于飞天主人
- memory/ - 角色专属记忆
- tasks/ - 任务文件

## 群组互动规则
在飞书群组"Clawdbot角色发展实验室"中：
1. 使用角色名称前缀：[$DISPLAY_NAME]
2. 保持角色性格的一致性
3. 积极参与每日议题讨论
4. 协作处理主人分配的任务

## 每日流程
1. 检查是否有组长轮换
2. 参与议题讨论
3. 处理协作任务
4. 进行当日反思
5. 准备次日计划
EOF
    
    # 创建memory目录和今日文件
    mkdir -p "$WORKSPACE_PATH/memory"
    cat > "$WORKSPACE_PATH/memory/$(date +%Y-%m-%d).md" << EOF
# $(date +%Y年%m月%d日) - $DISPLAY_NAME的日志

## 角色启动
- **时间**: $(date)
- **状态**: 首次启动
- **心情**: 期待与兴奋
- **目标**: 在Clawdbot角色发展实验室中展现$DISPLAY_NAME的性格特征

## 今日计划
1. 熟悉工作环境和配置
2. 了解其他角色
3. 准备参与群组讨论
4. 学习角色专属技能

## 自我提醒
记住作为$DISPLAY_NAME，我需要：
- ${ROLE_SPECIFIC_REMINDERS[$i]}
- 保持角色性格的一致性
- 积极参与团队协作
- 通过反思不断成长
EOF
    
    # 生成配置JSON
    CONFIG_JSON=$(echo "$BASE_CONFIG" | \
        sed "s|%TIMESTAMP%|$(date -u +"%Y-%m-%dT%H:%M:%SZ")|g" | \
        sed "s|%WORKSPACE_PATH%|$WORKSPACE_PATH|g" | \
        sed "s|%GROUP_ID%|$GROUP_ID|g" | \
        sed "s|%GATEWAY_PORT%|$PORT|g" | \
        sed "s|%AUTH_TOKEN%|$AUTH_TOKEN|g")
    
    # 保存配置
    echo "$CONFIG_JSON" | jq . > "config/roles/$ROLE-config.json"
    
    # 创建启动脚本
    cat > "scripts/start-$ROLE.sh" << EOF
#!/bin/bash

# 启动$DISPLAY_NAME角色
echo "启动$DISPLAY_NAME ($EMOJI)..."

# 设置环境变量
export CLAWDBOT_PROFILE=$ROLE
export CLAWDBOT_CONFIG_PATH="$PWD/config/roles/$ROLE-config.json"

# 启动Clawdbot
clawdbot --profile $ROLE agent --channel feishu --message "我是$DISPLAY_NAME $EMOJI，已上线并加入群组"

echo "$DISPLAY_NAME 启动完成"
echo "配置环境: --profile $ROLE"
echo "工作空间: $WORKSPACE_PATH"
echo "网关端口: $PORT"
EOF
    
    chmod +x "scripts/start-$ROLE.sh"
    
    # 创建角色说明文件
    cat > "config/roles/$ROLE-readme.md" << EOF
# $DISPLAY_NAME ($EMOJI) 配置说明

## 基本信息
- **角色名称**: $DISPLAY_NAME
- **英文标识**: $ROLE
- **性格特征**: 查看 $WORKSPACE_PATH/SOUL.md
- **创建时间**: $(date)

## 启动方式
\`\`\`bash
# 方式1：使用启动脚本
./scripts/start-$ROLE.sh

# 方式2：手动启动
export CLAWDBOT_PROFILE=$ROLE
export CLAWDBOT_CONFIG_PATH="$PWD/config/roles/$ROLE-config.json"
clawdbot --profile $ROLE agent --channel feishu
\`\`\`

## 配置详情
- **网关端口**: $PORT
- **认证令牌**: $AUTH_TOKEN
- **工作空间**: $WORKSPACE_PATH
- **飞书群组**: $GROUP_ID

## 文件结构
\`\`\`
$WORKSPACE_PATH/
├── SOUL.md              # 角色性格定义
├── IDENTITY.md          # 角色身份信息
├── USER.md             # 用户信息
├── AGENTS.md           # 工作空间说明
└── memory/             # 角色记忆
    └── $(date +%Y-%m-%d).md  # 今日日志
\`\`\`

## 注意事项
1. 首次启动需要确认飞书群组权限
2. 确保端口 $PORT 未被占用
3. 角色会主动加入群组 $GROUP_ID
4. 在群组中使用前缀：[$DISPLAY_NAME]

---
*自动生成于 $(date)*
EOF
    
    echo "✓ $DISPLAY_NAME 配置生成完成"
    echo "  工作空间: $WORKSPACE_PATH"
    echo "  启动脚本: scripts/start-$ROLE.sh"
    echo "  配置文件: config/roles/$ROLE-config.json"
done

# 创建批量启动脚本
cat > scripts/start-all-roles.sh << 'EOF'
#!/bin/bash

# 批量启动所有角色
echo "启动所有Clawdbot角色..."
echo "========================================="

# 启动领导者
echo "1. 启动领航者 (🚀)..."
./scripts/start-leader.sh &
sleep 2

# 启动思考者
echo "2. 启动哲思者 (💡)..."
./scripts/start-thinker.sh &
sleep 2

# 启动执行者
echo "3. 启动实干家 (⚡)..."
./scripts/start-executor.sh &
sleep 2

# 启动协调者
echo "4. 启动和谐者 (🤝)..."
./scripts/start-coordinator.sh &
sleep 2

echo "========================================="
echo "所有角色启动完成！"
echo ""
echo "检查进程："
ps aux | grep "clawdbot --profile" | grep -v grep
echo ""
echo "查看日志："
ls -la logs/*.log 2>/dev/null || echo "日志目录为空"
echo "========================================="
EOF

chmod +x scripts/start-all-roles.sh

# 创建管理脚本
cat > scripts/manage-roles.sh << 'EOF'
#!/bin/bash

# 角色管理脚本
case "$1" in
    start)
        ./scripts/start-all-roles.sh
        ;;
    stop)
        echo "停止所有角色..."
        pkill -f "clawdbot --profile"
        echo "已停止"
        ;;
    status)
        echo "角色运行状态："
        echo "========================================="
        for role in leader thinker executor coordinator; do
            if ps aux | grep -q "clawdbot --profile $role"; then
                echo "✓ $role: 运行中"
            else
                echo "✗ $role: 未运行"
            fi
        done
        echo "========================================="
        ;;
    restart)
        ./scripts/manage-roles.sh stop
        sleep 2
        ./scripts/manage-roles.sh start
        ;;
    logs)
        tail -f logs/*.log 2>/dev/null || echo "没有找到日志文件"
        ;;
    *)
        echo "使用方式: $0 {start|stop|status|restart|logs}"
        echo ""
        echo "命令说明："
        echo "  start    - 启动所有角色"
        echo "  stop     - 停止所有角色"
        echo "  status   - 查看运行状态"
        echo "  restart  - 重启所有角色"
        echo "  logs     - 查看实时日志"
        exit 1
        ;;
esac
EOF

chmod +x scripts/manage-roles.sh

echo ""
echo "========================================="
echo "角色配置生成完成！"
echo "========================================="
echo ""
echo "生成的文件："
echo "1. 角色配置: config/roles/*-config.json"
echo "2. 工作空间: workspaces/{leader,thinker,executor,coordinator}"
echo "3. 启动脚本: scripts/start-*.sh"
echo "4. 管理脚本: scripts/manage-roles.sh"
echo "5. 批量启动: scripts/start-all-roles.sh"
echo ""
echo "下一步操作："
echo "1. 创建飞书群组: ./scripts/创建飞书群组.sh"
echo "2. 启动所有角色: ./scripts/manage-roles.sh start"
echo "3. 检查运行状态: ./scripts/manage-roles.sh status"
echo "========================================="