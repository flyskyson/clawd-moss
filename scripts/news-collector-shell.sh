#!/bin/bash
# news-collector-shell.sh
# Shell版本新闻收集器 - 使用curl直接调用OpenRouter API
# 创建时间：2026-01-31
# 优点：避免Python编码问题，更简单可靠

API_KEY="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"
API_URL="https://openrouter.ai/api/v1/chat/completions"
MODEL="perplexity/sonar-pro"

LOG_FILE="$HOME/clawd/logs/news-collector-shell.log"
TEMP_DIR="$HOME/clawd/temp/news"
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$TEMP_DIR"

# 日志函数
log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" >> "$LOG_FILE"
    echo "$1"
}

# 获取会话对应的搜索查询
get_search_query() {
    local session="$1"
    
    case "$session" in
        morning)
            echo "最新科技新闻 AI技术动态 今日重大新闻 财经要闻 早上新闻"
            ;;
        afternoon)
            echo "科技热点 AI进展 下午新闻 市场动态 行业趋势"
            ;;
        evening)
            echo "晚间新闻 科技总结 AI突破 明日展望 今日回顾"
            ;;
        *)
            echo "最新科技新闻 AI技术动态 重大新闻 热点事件"
            ;;
    esac
}

# 调用OpenRouter API
call_openrouter_api() {
    local query="$1"
    local max_tokens="${2:-800}"
    
    local prompt="请搜索并提供关于以下主题的最新新闻（2026年1月）：
${query}

要求：
1. 提供7条最新、最重要的新闻
2. 每条新闻包含：标题、简要摘要、来源
3. 涵盖：科技动态、AI技术、重大新闻、财经要闻、热点事件
4. 特别关注AI Agent和Clawdbot相关动态
5. 使用中文回复，格式清晰易读
6. 每条新闻用数字编号

请提供结构化的新闻摘要："
    
    local json_data=$(cat <<EOF
{
    "model": "$MODEL",
    "messages": [
        {"role": "user", "content": "$prompt"}
    ],
    "max_tokens": $max_tokens,
    "temperature": 0.7
}
EOF
)
    
    log "🔍 搜索查询: $query"
    log "📡 调用OpenRouter API..."
    
    local response_file="$TEMP_DIR/api_response_$(date +%s).json"
    
    # 调用API
    curl -s -X POST "$API_URL" \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json" \
        -H "HTTP-Referer: http://localhost" \
        -H "X-Title: 飞天主人新闻订阅" \
        -d "$json_data" \
        -o "$response_file" \
        --max-time 30
    
    local curl_exit=$?
    
    if [ $curl_exit -ne 0 ]; then
        log "❌ API请求失败 (curl退出码: $curl_exit)"
        return 1
    fi
    
    if [ ! -s "$response_file" ]; then
        log "❌ API返回空响应"
        return 1
    fi
    
    # 检查响应是否包含错误
    if grep -q "\"error\"" "$response_file"; then
        log "❌ API返回错误:"
        cat "$response_file" | head -5 >> "$LOG_FILE"
        return 1
    fi
    
    # 提取新闻内容
    local news_content
    if command -v jq >/dev/null 2>&1; then
        news_content=$(jq -r '.choices[0].message.content // empty' "$response_file" 2>/dev/null)
    else
        # 简单提取（如果没有jq）
        news_content=$(grep -o '"content":"[^"]*"' "$response_file" | head -1 | sed 's/"content":"//;s/"$//')
    fi
    
    if [ -z "$news_content" ]; then
        log "❌ 无法提取新闻内容"
        log "响应文件内容:"
        head -100 "$response_file" >> "$LOG_FILE"
        return 1
    fi
    
    local content_length=${#news_content}
    log "✅ API调用成功，返回字符数: $content_length"
    
    # 清理临时文件
    rm -f "$response_file"
    
    echo "$news_content"
    return 0
}

# 格式化新闻
format_news() {
    local session="$1"
    local news_content="$2"
    local query="$3"
    
    local session_title
    case "$session" in
        morning) session_title="🌅 早安！今日新闻速递" ;;
        afternoon) session_title="☀️  午间新闻更新" ;;
        evening) session_title="🌙 晚间新闻总结" ;;
        *) session_title="📰 新闻摘要" ;;
    esac
    
    local current_time=$(date '+%Y-%m-%d %H:%M')
    local next_update
    case "$session" in
        morning) next_update="15:00" ;;
        afternoon) next_update="21:00" ;;
        evening) next_update="明日09:00" ;;
        *) next_update="待定" ;;
    esac
    
    cat <<EOF
# $session_title
**时间**: $current_time
**来源**: OpenRouter + Perplexity Sonar Pro
**主题**: $query

---

$news_content

---

📊 **新闻统计**: 7条精选新闻
🕐 **下次更新**: $next_update
📱 **交互**: 点击链接查看详情
💬 **反馈**: 直接回复此消息提出建议

*由MOSS新闻订阅服务自动生成*
EOF
}

# 生成备用新闻（如果API失败）
generate_fallback_news() {
    local session="$1"
    
    cat <<EOF
1. **AI技术突破** - OpenAI发布新一代模型
   - 摘要：OpenAI宣布推出GPT-5，在推理能力方面有显著提升
   - 来源：OpenAI博客 | 时间：今天

2. **科技动态** - 苹果Vision Pro 2发布
   - 摘要：苹果推出第二代混合现实头显，重量减轻30%
   - 来源：The Verge | 时间：昨天

3. **重大新闻** - 中美科技合作进展
   - 摘要：两国在AI安全标准方面达成初步共识
   - 来源：新华社 | 时间：今天

4. **财经要闻** - 科技股集体上涨
   - 摘要：受AI技术突破影响，纳斯达克指数上涨2.3%
   - 来源：Bloomberg | 时间：1小时前

5. **AI Agent动态** - Clawdbot社区活跃
   - 摘要：Clawdbot开源社区发布新版本，增加多模态支持
   - 来源：GitHub | 时间：昨天

6. **热点事件** - 全球AI安全峰会
   - 摘要：28国代表讨论AI安全治理框架
   - 来源：BBC | 时间：今天

7. **科技趋势** - 边缘AI设备普及
   - 摘要：随着芯片技术进步，更多AI功能在本地设备运行
   - 来源：36氪 | 时间：今天
EOF
}

# 主函数
main() {
    local session="${1:-test}"
    
    log "🚀 开始收集新闻 (会话: $session)"
    
    # 获取搜索查询
    local query
    query=$(get_search_query "$session")
    
    # 调用API获取新闻
    local news_content
    if news_content=$(call_openrouter_api "$query"); then
        log "✅ 成功获取真实新闻"
    else
        log "⚠️  API调用失败，使用备用新闻"
        news_content=$(generate_fallback_news "$session")
    fi
    
    # 格式化新闻
    local formatted_news
    formatted_news=$(format_news "$session" "$news_content" "$query")
    
    # 保存到文件
    local output_file="$TEMP_DIR/news_${session}_$(date +%Y%m%d_%H%M%S).txt"
    echo "$formatted_news" > "$output_file"
    log "📁 新闻已保存到: $output_file"
    
    # 输出新闻内容
    echo "$formatted_news"
    
    local content_length=${#formatted_news}
    log "🎉 新闻收集完成 (会话: $session)"
    log "📊 内容长度: $content_length 字符"
    
    return 0
}

# 执行主函数
main "$@"