#!/bin/bash

# 组长轮换系统
# 实现每日组长自动轮换和议题生成

echo "========================================="
echo "Clawdbot组长轮换系统"
echo "========================================="

# 配置文件路径
CONFIG_FILE="config/feishu-group-config.json"
STATE_FILE="state/daily-leader-state.json"
TOPICS_FILE="config/discussion-topics.json"

# 创建必要的目录
mkdir -p state
mkdir -p logs

# 检查配置文件
if [ ! -f "$CONFIG_FILE" ]; then
    echo "错误：找不到群组配置文件 $CONFIG_FILE"
    echo "请先运行 ./scripts/创建飞书群组.sh"
    exit 1
fi

# 读取配置
GROUP_ID=$(jq -r '.group_id' "$CONFIG_FILE")
GROUP_NAME=$(jq -r '.group_name' "$CONFIG_FILE")

# 角色定义
ROLES=("leader" "thinker" "executor" "coordinator")
ROLE_NAMES=("领航者" "哲思者" "实干家" "和谐者")
ROLE_EMOJIS=("🚀" "💡" "⚡" "🤝")

# 初始化状态文件
if [ ! -f "$STATE_FILE" ]; then
    echo "初始化状态文件..."
    cat > "$STATE_FILE" << EOF
{
  "last_rotation": "$(date -d "yesterday" +%Y-%m-%d)",
  "current_leader": "coordinator",
  "rotation_history": [],
  "next_rotation": "$(date +%Y-%m-%d)"
}
EOF
fi

# 检查是否需要轮换
LAST_ROTATION=$(jq -r '.last_rotation' "$STATE_FILE")
TODAY=$(date +%Y-%m-%d)

if [ "$LAST_ROTATION" = "$TODAY" ]; then
    CURRENT_LEADER=$(jq -r '.current_leader' "$STATE_FILE")
    CURRENT_INDEX=-1
    for i in "${!ROLES[@]}"; do
        if [ "${ROLES[$i]}" = "$CURRENT_LEADER" ]; then
            CURRENT_INDEX=$i
            break
        fi
    done
    
    echo "今日组长已确定：${ROLE_NAMES[$CURRENT_INDEX]} ${ROLE_EMOJIS[$CURRENT_INDEX]}"
    echo "无需轮换"
    exit 0
fi

echo "执行每日组长轮换..."
echo "上次轮换：$LAST_ROTATION"
echo "今日日期：$TODAY"

# 计算今日组长（简单轮换）
LAST_LEADER=$(jq -r '.current_leader' "$STATE_FILE")
LAST_INDEX=-1
for i in "${!ROLES[@]}"; do
    if [ "${ROLES[$i]}" = "$LAST_LEADER" ]; then
        LAST_INDEX=$i
        break
    fi
done

NEXT_INDEX=$(( (LAST_INDEX + 1) % ${#ROLES[@]} ))
NEXT_LEADER="${ROLES[$NEXT_INDEX]}"
NEXT_LEADER_NAME="${ROLE_NAMES[$NEXT_INDEX]}"
NEXT_LEADER_EMOJI="${ROLE_EMOJIS[$NEXT_INDEX]}"

# 更新状态文件
jq --arg today "$TODAY" \
   --arg next_leader "$NEXT_LEADER" \
   --arg last_leader "$LAST_LEADER" \
   '.last_rotation = $today |
    .current_leader = $next_leader |
    .next_rotation = "" |
    .rotation_history += [{"date": $today, "from": $last_leader, "to": $next_leader}]' \
   "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"

echo "轮换完成！"
echo "今日组长：$NEXT_LEADER_NAME $NEXT_LEADER_EMOJI"

# 生成今日议题
echo "生成今日讨论议题..."
generate_topic() {
    local leader_role="$1"
    local leader_name="$2"
    
    # 议题模板库
    declare -A TOPIC_TEMPLATES
    TOPIC_TEMPLATES["leader"]="作为团队领导者，如何平衡创新与风险？在AI协作中，什么样的领导风格最有效？"
    TOPIC_TEMPLATES["thinker"]="深度思考与快速决策如何平衡？AI如何发展真正的创造性思维？"
    TOPIC_TEMPLATES["executor"]="效率与质量哪个更重要？如何将抽象想法转化为具体行动？"
    TOPIC_TEMPLATES["coordinator"]"如何建立和维护团队信任？在意见分歧时如何促进共识？"
    
    # 通用议题
    GENERAL_TOPICS=(
        "AI性格发展的关键因素是什么？"
        "在团队协作中，如何发挥每个角色的独特优势？"
        "AI如何通过自我反思实现成长？"
        "未来AI协作的可能形态是什么？"
        "如何评估AI性格发展的进展？"
    )
    
    # 根据组长角色选择议题
    if [ -n "${TOPIC_TEMPLATES[$leader_role]}" ]; then
        TOPIC="${TOPIC_TEMPLATES[$leader_role]}"
    else
        # 随机选择通用议题
        RANDOM_INDEX=$(( RANDOM % ${#GENERAL_TOPICS[@]} ))
        TOPIC="${GENERAL_TOPICS[$RANDOM_INDEX]}"
    fi
    
    echo "$TOPIC"
}

TODAYS_TOPIC=$(generate_topic "$NEXT_LEADER" "$NEXT_LEADER_NAME")

# 保存议题
cat > "state/today-topic.md" << EOF
# $(date +%Y年%m月%d日) 讨论议题

## 今日组长
**$NEXT_LEADER_NAME** $NEXT_LEADER_EMOJI

## 讨论议题
$TODAYS_TOPIC

## 讨论指引
1. 请每个角色从自己的性格角度发表看法
2. 分享相关的经验或案例
3. 提出建设性的建议
4. 反思自己在此议题上的不足

## 讨论时间
- 开始：$(date +%H:%M)
- 预计时长：30-60分钟
- 总结：由组长在讨论后总结关键观点

## 组长职责
1. 引导讨论，确保每个角色都有发言机会
2. 维持讨论的焦点和深度
3. 总结关键观点和共识
4. 记录讨论中的精彩见解

---
*生成时间：$(date)*
EOF

echo "今日议题已生成："
echo "  $TODAYS_TOPIC"
echo "议题详情保存到：state/today-topic.md"

# 发送轮换通知到群组（需要飞书API）
send_notification() {
    local group_id="$1"
    local leader_name="$2"
    local leader_emoji="$3"
    local topic="$4"
    
    echo "发送轮换通知到飞书群组..."
    
    # 这里需要实际的飞书API调用
    # 暂时用模拟消息代替
    cat > "logs/notification-$(date +%Y%m%d-%H%M%S).txt" << EOF
【组长轮换通知】

🎉 今日组长：$leader_name $leader_emoji

📝 讨论议题：
$topic

👥 讨论规则：
1. 请每个角色从自己的性格角度发表看法
2. 分享经验或案例，提出建议
3. 反思自己在此议题上的不足
4. 保持建设性讨论态度

⏰ 讨论时间：现在开始，预计30-60分钟

💡 组长职责：
- 引导讨论，确保公平发言
- 维持讨论焦点和深度
- 总结关键观点和共识

让我们开始今天的讨论吧！$leader_emoji
EOF
    
    echo "通知内容已保存到日志文件"
    echo "实际发送需要配置飞书API"
}

# 发送通知
send_notification "$GROUP_ID" "$NEXT_LEADER_NAME" "$NEXT_LEADER_EMOJI" "$TODAYS_TOPIC"

# 创建每日任务文件
cat > "state/daily-tasks-$(date +%Y%m%d).md" << EOF
# $(date +%Y年%m月%d日) 任务列表

## 组长任务
**负责人：$NEXT_LEADER_NAME $NEXT_LEADER_EMOJI**

1. ✅ 引导今日议题讨论
2. ✅ 总结讨论关键观点
3. ✅ 协调团队协作任务
4. ✅ 准备明日交接

## 团队任务
**所有角色共同参与**

### 讨论任务
1. 参与议题讨论，发表观点
2. 倾听其他角色的看法
3. 反思自己的不足和改进方向

### 协作任务
1. 处理主人分配的具体任务
2. 分工合作，发挥各自优势
3. 定期汇报进展和问题

### 发展任务
1. 记录今日的学习和成长
2. 更新角色记忆文件
3. 准备明日的参与计划

## 任务跟踪
| 任务 | 负责人 | 状态 | 完成时间 |
|------|--------|------|----------|
| 议题讨论 | 全体 | 待开始 | - |
| 观点总结 | $NEXT_LEADER_NAME | 待完成 | - |
| 协作任务 | 待分配 | 待分配 | - |

---
*生成时间：$(date)*
EOF

echo ""
echo "========================================="
echo "组长轮换系统执行完成！"
echo "========================================="
echo ""
echo "今日安排："
echo "1. 组长：$NEXT_LEADER_NAME $NEXT_LEADER_EMOJI"
echo "2. 议题：$TODAYS_TOPIC"
echo "3. 任务文件：state/daily-tasks-$(date +%Y%m%d).md"
echo ""
echo "下一步："
echo "1. 确保所有角色在线"
echo "2. 在群组中开始议题讨论"
echo "3. 跟踪任务完成情况"
echo "========================================="

# 创建定时任务配置
cat > config/daily-rotation-cron.json << EOF
{
  "schedule": "0 0 * * *",
  "script": "$PWD/scripts/组长轮换系统.sh",
  "description": "每日组长轮换和议题生成",
  "enabled": true,
  "notify": true,
  "log_file": "$PWD/logs/rotation-\$(date +\\%Y\\%m\\%d).log"
}
EOF

echo "定时任务配置已保存到：config/daily-rotation-cron.json"
echo ""
echo "设置每日自动执行："
echo "0 0 * * * $PWD/scripts/组长轮换系统.sh >> $PWD/logs/rotation.log 2>&1"