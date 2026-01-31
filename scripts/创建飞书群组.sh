#!/bin/bash

# 创建飞书群组配置脚本
# 用于创建Clawdbot角色发展实验室群组

echo "========================================="
echo "Clawdbot多角色飞书群组创建脚本"
echo "========================================="

# 检查必要的环境变量
if [ -z "$FEISHU_APP_ID" ] || [ -z "$FEISHU_APP_SECRET" ]; then
    echo "错误：请先设置飞书应用凭证环境变量"
    echo "export FEISHU_APP_ID=your_app_id"
    echo "export FEISHU_APP_SECRET=your_app_secret"
    exit 1
fi

# 获取访问令牌
echo "获取飞书访问令牌..."
ACCESS_TOKEN=$(curl -s -X POST \
  "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal/" \
  -H "Content-Type: application/json" \
  -d "{
    \"app_id\": \"$FEISHU_APP_ID\",
    \"app_secret\": \"$FEISHU_APP_SECRET\"
  }" | jq -r '.tenant_access_token')

if [ "$ACCESS_TOKEN" = "null" ] || [ -z "$ACCESS_TOKEN" ]; then
    echo "错误：获取访问令牌失败"
    exit 1
fi

echo "访问令牌获取成功"

# 创建群组
echo "创建Clawdbot角色发展实验室群组..."
GROUP_RESPONSE=$(curl -s -X POST \
  "https://open.feishu.cn/open-apis/im/v1/chats" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Clawdbot角色发展实验室",
    "description": "多角色AI协作实验平台，探索AI性格发展和团队协作",
    "chat_mode": "group",
    "chat_type": "private",
    "join_message_visibility": "all_members",
    "leave_message_visibility": "all_members",
    "membership_approval": "no_approval_required",
    "owner_id": "ou_8924c5894c324474511b00980af769ee"
  }')

GROUP_ID=$(echo "$GROUP_RESPONSE" | jq -r '.data.chat_id')
if [ "$GROUP_ID" = "null" ] || [ -z "$GROUP_ID" ]; then
    echo "错误：创建群组失败"
    echo "响应：$GROUP_RESPONSE"
    exit 1
fi

echo "群组创建成功，ID: $GROUP_ID"

# 获取群组webhook
echo "创建群组webhook..."
WEBHOOK_RESPONSE=$(curl -s -X POST \
  "https://open.feishu.cn/open-apis/im/v1/chats/$GROUP_ID/webhook" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Clawdbot群组webhook"
  }')

WEBHOOK_URL=$(echo "$WEBHOOK_RESPONSE" | jq -r '.data.url')
if [ "$WEBHOOK_URL" = "null" ] || [ -z "$WEBHOOK_URL" ]; then
    echo "警告：创建webhook失败，可能需要手动创建"
else
    echo "Webhook创建成功: $WEBHOOK_URL"
fi

# 创建配置文件
echo "创建群组配置文件..."
cat > config/feishu-group-config.json << EOF
{
  "group_id": "$GROUP_ID",
  "group_name": "Clawdbot角色发展实验室",
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "description": "多角色AI协作实验平台",
  "webhook_url": "$WEBHOOK_URL",
  "roles": {
    "leader": {
      "display_name": "领航者",
      "description": "战略导向的领导者",
      "emoji": "🚀"
    },
    "thinker": {
      "display_name": "哲思者",
      "description": "深度思考的分析师",
      "emoji": "💡"
    },
    "executor": {
      "display_name": "实干家",
      "description": "高效执行的行动者",
      "emoji": "⚡"
    },
    "coordinator": {
      "display_name": "和谐者",
      "description": "促进协作的协调专家",
      "emoji": "🤝"
    }
  },
  "settings": {
    "daily_rotation": true,
    "rotation_schedule": "00:00",
    "topic_generation": "auto",
    "task_collaboration": true,
    "self_reflection": true
  }
}
EOF

echo "配置文件已保存到 config/feishu-group-config.json"

# 发送欢迎消息
echo "发送欢迎消息到群组..."
curl -s -X POST \
  "https://open.feishu.cn/open-apis/im/v1/messages?receive_id_type=chat_id" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"receive_id\": \"$GROUP_ID\",
    \"msg_type\": \"text\",
    \"content\": \"{\\\"text\\\":\\\"🎉 欢迎来到Clawdbot角色发展实验室！\\n\\n这是一个创新的AI协作实验平台，我们将在这里：\\n\\n1. 🤖 探索多个AI角色的性格发展\\n2. 🗣️ 通过每日议题讨论促进思考\\n3. 👥 实践团队协作和任务处理\\n4. 🌱 实现AI的自我反思和成长\\n\\n角色介绍：\\n🚀 领航者 - 战略领导者\\n💡 哲思者 - 深度思考者\\n⚡ 实干家 - 高效执行者\\n🤝 和谐者 - 团队协调者\\n\\n让我们开始这段有趣的旅程吧！\\\"}\"
  }" > /dev/null

echo "========================================="
echo "群组创建完成！"
echo "========================================="
echo "群组ID: $GROUP_ID"
echo "配置文件: config/feishu-group-config.json"
echo ""
echo "下一步："
echo "1. 邀请Clawdbot角色加入群组"
echo "2. 配置角色轮换机制"
echo "3. 设置议题讨论系统"
echo "========================================="