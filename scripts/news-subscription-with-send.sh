#!/bin/bash
# news-subscription-with-send.sh
# 飞天主人新闻订阅服务 - 带自动发送版本
# 创建时间：2026-01-31

CONFIG_FILE="$HOME/clawd/scripts/news-subscription-config.json"
LOG_FILE="$HOME/clawd/logs/news-subscription.log"
RUN_LOG="$HOME/clawd/logs/news-runs.log"
COLLECTOR_SCRIPT="$HOME/clawd/scripts/news-collector-shell.sh"
TEMP_DIR="$HOME/clawd/temp/news"
SENDER_SCRIPT="$HOME/clawd/scripts/news-sender.py"

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
    echo "📰 飞天主人新闻订阅服务 - 自动发送版本"
    echo "========================================"
    echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "会话: $1"
    echo "版本: v2.0 (收集+发送)"
    echo "模式: 真实新闻 + 自动发送"
    echo ""
}

# 检查依赖
check_dependencies() {
    local missing_deps=()
    
    # 检查curl
    if ! command -v curl >/dev/null 2>&1; then
        missing_deps+=("curl")
    fi
    
    # 检查jq（可选，但有更好）
    if ! command -v jq >/dev/null 2>&1; then
        echo "⚠️  jq未安装，JSON解析功能受限"
    fi
    
    # 检查Python3
    if ! command -v python3 >/dev/null 2>&1; then
        missing_deps+=("python3")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo "❌ 缺少依赖: ${missing_deps[*]}"
        echo "请安装: brew install ${missing_deps[*]}"
        return 1
    fi
    
    return 0
}

# 检查配置文件
check_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "⚠️  配置文件不存在，创建默认配置..."
        cat > "$CONFIG_FILE" << 'EOF'
{
  "api_key": "your-openrouter-api-key",
  "model": "perplexity/sonar-pro",
  "sessions": {
    "morning": {
      "query": "科技新闻 早上新闻 AI进展 市场动态",
      "enabled": true
    },
    "afternoon": {
      "query": "科技热点 AI进展 下午新闻 行业趋势",
      "enabled": true
    },
    "evening": {
      "query": "晚间新闻 科技总结 明日展望 市场收盘",
      "enabled": true
    }
  },
  "feishu": {
    "auto_send": true,
    "target": "ou_8924c5894c324474511b00980af769ee"
  }
}
EOF
        echo "✅ 默认配置文件已创建: $CONFIG_FILE"
        echo "⚠️  请编辑配置文件设置您的API密钥"
        return 1
    fi
    
    return 0
}

# 收集新闻
collect_news() {
    local session="$1"
    local mode="$2"
    
    echo "🔍 开始收集 $session 新闻..."
    
    if [ "$mode" = "test" ]; then
        echo "🧪 测试模式: 使用模拟数据"
        
        local test_content
        test_content=$(cat <<EOF
# 🧪 测试新闻
**时间**: $(date '+%Y-%m-%d %H:%M')
**模式**: 测试运行
**会话**: $session

---

1. **测试新闻1** - 系统运行正常
   - 摘要：新闻订阅服务测试运行成功
   - 来源：测试系统 | 时间：现在

2. **测试新闻2** - 自动发送功能
   - 摘要：自动发送到飞书功能测试中
   - 来源：MOSS开发 | 时间：今天

3. **测试新闻3** - 计划执行跟踪
   - 摘要：计划执行和监控系统运行中
   - 来源：项目跟踪 | 时间：持续

---

📊 **状态**: 测试成功
🕐 **下次运行**: 按计划执行
🔧 **功能**: 收集 ✓ | 发送 ✓

*MOSS新闻订阅服务 - 测试版本*
EOF
)
        
        local test_file="$TEMP_DIR/test_${session}_$(date +%Y%m%d_%H%M%S).txt"
        echo "$test_content" > "$test_file"
        echo "📁 测试新闻已保存: $test_file"
        
        log "测试新闻收集完成: $session"
        return 0
    fi
    
    # 生产模式：调用收集器脚本
    if [ -f "$COLLECTOR_SCRIPT" ]; then
        echo "📡 调用新闻收集器..."
        bash "$COLLECTOR_SCRIPT" "$session"
        
        if [ $? -eq 0 ]; then
            echo "✅ 新闻收集成功"
            log "新闻收集成功: $session"
            return 0
        else
            echo "❌ 新闻收集失败"
            log "新闻收集失败: $session"
            return 1
        fi
    else
        echo "❌ 收集器脚本不存在: $COLLECTOR_SCRIPT"
        log "收集器脚本缺失: $COLLECTOR_SCRIPT"
        return 1
    fi
}

# 发送新闻到飞书
send_to_feishu() {
    local session="$1"
    
    echo "📤 准备发送 $session 新闻到飞书..."
    
    if [ ! -f "$SENDER_SCRIPT" ]; then
        echo "❌ 发送脚本不存在: $SENDER_SCRIPT"
        log "发送脚本缺失: $SENDER_SCRIPT"
        return 1
    fi
    
    # 运行发送脚本
    echo "🚀 调用发送脚本..."
    python3 "$SENDER_SCRIPT" "$session"
    
    local send_result=$?
    
    if [ $send_result -eq 0 ]; then
        echo "✅ 新闻发送成功"
        log "新闻发送成功: $session"
        return 0
    else
        echo "⚠️  新闻发送部分成功或失败"
        log "新闻发送结果: $session (代码: $send_result)"
        return $send_result
    fi
}

# 查找最新新闻文件
find_latest_news() {
    local session="$1"
    local pattern="news_${session}_*.txt"
    
    # 查找文件
    local latest_file
    latest_file=$(find "$TEMP_DIR" -name "$pattern" -type f 2>/dev/null | sort -r | head -1)
    
    if [ -n "$latest_file" ] && [ -f "$latest_file" ]; then
        echo "$latest_file"
        return 0
    else
        echo ""
        return 1
    fi
}

# 主函数
main() {
    local session="${1:-afternoon}"
    local mode="${2:-production}"
    
    # 记录运行
    record_run "$session"
    
    # 显示横幅
    show_banner "$session"
    
    # 检查依赖
    if ! check_dependencies; then
        log "依赖检查失败: $session"
        return 1
    fi
    
    # 检查配置
    if ! check_config; then
        log "配置检查失败: $session"
        return 1
    fi
    
    echo "📊 运行模式: $mode"
    echo "📅 会话类型: $session"
    echo ""
    
    # 步骤1: 收集新闻
    echo "="*50
    echo "步骤1: 收集新闻"
    echo "="*50
    
    collect_news "$session" "$mode"
    local collect_result=$?
    
    # 步骤2: 发送新闻
    echo ""
    echo "="*50
    echo "步骤2: 发送新闻到飞书"
    echo "="*50
    
    if [ $collect_result -eq 0 ]; then
        send_to_feishu "$session"
        local send_result=$?
    else
        echo "⚠️  新闻收集失败，跳过发送步骤"
        local send_result=1
    fi
    
    # 步骤3: 生成报告
    echo ""
    echo "="*50
    echo "步骤3: 生成执行报告"
    echo "="*50
    
    local latest_news_file
    latest_news_file=$(find_latest_news "$session")
    
    local report_content
    report_content=$(cat <<EOF
📤 发送状态
========================================
⏰ 发送时间: $(date '+%H:%M')
🕐 下次发送: 根据定时任务安排

💡 当前模式: $mode
🔧 功能状态: 收集 $( [ $collect_result -eq 0 ] && echo "✓" || echo "✗" ) | 发送 $( [ $send_result -eq 0 ] && echo "✓" || echo "⚠️" )

📋 新闻文件:
----------------------------------------
${latest_news_file:-未找到新闻文件}
----------------------------------------

🎉 新闻订阅任务执行完成
⏰ 执行时间: $(date '+%H:%M:%S')
📊 状态: $mode模式运行中
🔧 功能: 新闻收集 $( [ $collect_result -eq 0 ] && echo "成功" || echo "失败" ) | 飞书发送 $( [ $send_result -eq 0 ] && echo "成功" || echo "失败/跳过" )
EOF
)
    
    echo "$report_content"
    log "任务完成: $session ($mode模式)"
    
    # 总体结果
    if [ $collect_result -eq 0 ] && [ $send_result -eq 0 ]; then
        echo ""
        echo "🎉 任务完全成功!"
        return 0
    elif [ $collect_result -eq 0 ]; then
        echo ""
        echo "⚠️  任务部分成功 (收集成功，发送失败)"
        return 2
    else
        echo ""
        echo "❌ 任务失败"
        return 1
    fi
}

# 执行主程序
main "$@"

exit $?