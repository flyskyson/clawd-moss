#!/bin/bash
# test-web-search.sh
# 测试web_search功能的简单脚本

echo "🧪 测试web_search功能"
echo "================================"

# 方法1：尝试通过agent命令测试
echo "方法1：尝试agent命令..."
export PATH="/Users/lijian/.npm-global/bin:$PATH"

# 检查服务状态
echo "检查Clawdbot服务状态..."
if clawdbot gateway status >/dev/null 2>&1; then
    echo "✅ Clawdbot网关服务运行正常"
else
    echo "❌ Clawdbot网关服务未运行"
    exit 1
fi

# 检查配置
echo ""
echo "检查web_search配置..."
CONFIG_FILE="$HOME/.clawdbot/clawdbot.json"
if [ -f "$CONFIG_FILE" ]; then
    echo "✅ 配置文件存在"
    API_KEY=$(cat "$CONFIG_FILE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
web = data.get('tools', {}).get('web', {})
search = web.get('search', {})
print(search.get('apiKey', '')[:20] + '...')
")
    echo "API Key前20位: $API_KEY"
else
    echo "❌ 配置文件不存在"
fi

# 方法2：尝试直接调用工具
echo ""
echo "方法2：尝试工具调用..."
echo "注意：web_search工具需要通过agent会话调用"
echo "在Clawdbot中，web_search是agent可用的工具之一"

# 方法3：检查日志
echo ""
echo "方法3：检查最近日志..."
LOG_FILE="/tmp/clawdbot/clawdbot-2026-01-31.log"
if [ -f "$LOG_FILE" ]; then
    echo "✅ 日志文件存在"
    echo "最近相关日志:"
    grep -i "web\|search\|perplexity\|openrouter" "$LOG_FILE" | tail -5 || echo "未找到相关日志"
else
    echo "⚠️  日志文件不存在: $LOG_FILE"
fi

# 方法4：测试OpenRouter API直接连接
echo ""
echo "方法4：测试OpenRouter API直接连接..."
echo "这需要有效的API密钥和网络连接"

# 显示当前时间
echo ""
echo "⏰ 当前时间: $(date '+%H:%M:%S')"
echo "📅 下次新闻发送: 09:00 (如果功能正常)"

# 建议
echo ""
echo "💡 建议下一步："
echo "1. 等待9:00自动测试（最直接）"
echo "2. 检查OpenRouter账户的API使用统计"
echo "3. 查看Clawdbot详细日志：clawdbot logs --follow"
echo "4. 测试其他搜索查询"

echo ""
echo "测试完成！"