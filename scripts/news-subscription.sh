#!/bin/bash
# news-subscription.sh
# 飞天主人新闻订阅服务 - 新闻收集脚本
# 创建时间：2026-01-31
# 当前状态：占位版，等待web_search API修复

CONFIG_FILE="$HOME/clawd/scripts/news-subscription-config.json"
LOG_FILE="$HOME/clawd/logs/news-subscription.log"
RUN_LOG="$HOME/clawd/logs/news-runs.log"
TEMP_DIR="$HOME/clawd/temp/news"

# 创建必要的目录
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$RUN_LOG")"
mkdir -p "$TEMP_DIR"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 记录运行
record_run() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1 新闻任务触发" >> "$RUN_LOG"
}

# 显示横幅
show_banner() {
    echo ""
    echo "📰 飞天主人新闻订阅服务"
    echo "================================"
    echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "会话: $1"
    echo "状态: 等待web_search API修复"
    echo ""
}

# 检查API状态
check_api_status() {
    echo "🔍 检查API状态..."
    
    # 检查Clawdbot服务
    if ! clawdbot gateway status >/dev/null 2>&1; then
        echo "❌ Clawdbot网关服务未运行"
        return 1
    fi
    
    # 测试web_search（简单测试）
    echo "测试web_search功能..."
    TEST_OUTPUT=$(clawdbot tools web_search --query "测试" --count 1 2>&1)
    
    if echo "$TEST_OUTPUT" | grep -q "error\|Error\|ERROR\|401\|User not found"; then
        echo "❌ Web search API错误:"
        echo "$TEST_OUTPUT" | head -3
        return 1
    else
        echo "✅ Web search功能正常"
        return 0
    fi
}

# 获取搜索查询
get_search_query() {
    local session="$1"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "默认搜索: 科技新闻 AI动态"
        echo "科技新闻 AI动态"
        return
    fi
    
    # 使用python解析查询
    local query=$(python3 -c "
import json
try:
    with open('$CONFIG_FILE', 'r') as f:
        data = json.load(f)
    queries = data.get('search_queries', {})
    print(queries.get('$session', '科技新闻 AI动态'))
except:
    print('科技新闻 AI动态')
")
    
    echo "搜索查询: $query"
    echo "$query"
}

# 收集新闻（占位函数）
collect_news() {
    local session="$1"
    local query="$2"
    
    echo "📡 收集新闻 (会话: $session)"
    echo "搜索词: $query"
    echo ""
    
    # 这里是占位实现，等API修复后替换为实际搜索
    echo "⚠️  当前为占位模式 - 等待web_search API修复"
    echo ""
    echo "💡 需要修复的问题:"
    echo "1. OpenRouter API密钥可能无效"
    echo "2. 需要检查OpenRouter账户余额"
    echo "3. 可能需要更新API配置"
    echo ""
    echo "🔧 修复步骤:"
    echo "1. 登录 https://openrouter.ai/account"
    echo "2. 检查API密钥和余额"
    echo "3. 如果需要，更新 ~/.clawdbot/clawdbot.json 中的配置"
    echo ""
    
    # 生成模拟新闻（用于测试格式）
    generate_sample_news "$session"
}

# 生成示例新闻（测试格式）
generate_sample_news() {
    local session="$1"
    
    echo "📊 示例新闻格式 (会话: $session)"
    echo "================================"
    
    case "$session" in
        morning)
            echo "🌅 早安！今日新闻速递："
            echo ""
            ;;
        afternoon)
            echo "☀️  午间新闻更新："
            echo ""
            ;;
        evening)
            echo "🌙 晚间新闻总结："
            echo ""
            ;;
    esac
    
    # 示例新闻条目
    cat << 'EOF'
1. **AI技术突破** - OpenAI发布新一代语言模型
   - 摘要：OpenAI宣布推出GPT-5，在推理能力和多模态理解方面有显著提升
   - 来源：OpenAI博客 | 发布时间：今天上午
   - [点击查看详情](https://openai.com/blog)

2. **科技动态** - 苹果发布Vision Pro 2
   - 摘要：苹果推出第二代混合现实头显，重量减轻30%，分辨率提升50%
   - 来源：The Verge | 发布时间：昨天
   - [点击查看详情](https://www.theverge.com)

3. **重大新闻** - 中美科技合作新进展
   - 摘要：两国在人工智能安全标准方面达成初步共识，将建立联合工作组
   - 来源：新华社 | 发布时间：今天
   - [点击查看详情](https://www.xinhuanet.com)

4. **财经要闻** - 科技股集体上涨
   - 摘要：受AI技术突破影响，纳斯达克科技指数上涨2.3%
   - 来源：Bloomberg | 发布时间：1小时前
   - [点击查看详情](https://www.bloomberg.com)

5. **AI Agent动态** - Clawdbot社区活跃
   - 摘要：Clawdbot开源社区发布新版本，增加多模态支持
   - 来源：GitHub | 发布时间：昨天
   - [点击查看详情](https://github.com/clawdbot/clawdbot)

6. **热点事件** - 全球AI安全峰会召开
   - 摘要：28国代表齐聚伦敦，讨论AI安全治理框架
   - 来源：BBC | 发布时间：今天
   - [点击查看详情](https://www.bbc.com)

7. **科技趋势** - 边缘AI设备普及加速
   - 摘要：随着芯片技术进步，更多AI功能将在本地设备运行
   - 来源：36氪 | 发布时间：今天
   - [点击查看详情](https://36kr.com)
EOF
    
    echo ""
    echo "📈 今日共收集 7 条新闻"
    echo "🕐 下次更新：$(date -d '+6 hours' '+%H:%M')"
    echo ""
    echo "💬 反馈建议请直接回复此消息"
}

# 发送新闻（占位函数）
send_news() {
    local session="$1"
    local content="$2"
    
    echo "📤 准备发送新闻 (会话: $session)"
    echo ""
    
    # 这里等API修复后替换为实际发送逻辑
    echo "📋 新闻内容预览："
    echo "================================"
    echo "$content"
    echo "================================"
    echo ""
    echo "✅ 新闻内容已准备就绪"
    echo "🚀 等web_search API修复后，将自动通过飞书发送"
    
    # 保存到文件（用于测试）
    local output_file="$TEMP_DIR/news_${session}_$(date +%Y%m%d_%H%M%S).txt"
    echo "$content" > "$output_file"
    echo "📁 内容已保存到: $output_file"
}

# 主程序
main() {
    local session="$1"
    
    if [ -z "$session" ]; then
        session="test"
    fi
    
    # 显示横幅
    show_banner "$session"
    
    # 记录运行
    record_run "$session"
    
    # 检查API状态
    if check_api_status; then
        echo "✅ API状态正常，开始收集新闻..."
    else
        echo "⚠️  API状态异常，使用占位模式..."
    fi
    
    # 获取搜索查询
    local query
    query=$(get_search_query "$session")
    
    # 收集新闻
    local news_content
    news_content=$(collect_news "$session" "$query")
    
    # 发送新闻
    send_news "$session" "$news_content"
    
    # 记录完成
    log "新闻任务完成: $session"
    echo ""
    echo "🎉 新闻订阅任务执行完成"
    echo "⏰ 执行时间: $(date '+%H:%M:%S')"
    echo "📊 状态: 等待API修复以启用完整功能"
}

# 执行主程序
main "$1"

exit 0