#!/bin/bash
# news-subscription-manager.sh
# 飞天主人新闻订阅服务管理脚本
# 创建时间：2026-01-31

CONFIG_FILE="$HOME/clawd/scripts/news-subscription-config.json"
LOG_FILE="$HOME/clawd/logs/news-subscription.log"
TEMP_DIR="$HOME/clawd/temp/news"

# 创建必要的目录
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$TEMP_DIR"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo "$1"
}

# 显示帮助
show_help() {
    echo "📰 飞天主人新闻订阅服务管理工具"
    echo "用法: $0 [命令]"
    echo ""
    echo "命令:"
    echo "  status     显示订阅服务状态"
    echo "  test       测试新闻搜索功能"
    echo "  setup      设置cron定时任务"
    echo "  remove     移除cron定时任务"
    echo "  manual     手动运行一次新闻收集"
    echo "  config     显示当前配置"
    echo "  log        查看日志"
    echo "  help       显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 status      # 检查服务状态"
    echo "  $0 setup       # 设置定时任务"
    echo "  $0 test        # 测试功能"
}

# 检查配置
check_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log "❌ 配置文件不存在: $CONFIG_FILE"
        return 1
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        log "⚠️  jq命令未安装，使用python解析JSON"
        return 0
    fi
    
    log "✅ 配置文件检查通过"
    return 0
}

# 显示配置
show_config() {
    echo "=== 新闻订阅配置 ==="
    
    if command -v jq >/dev/null 2>&1; then
        jq '.' "$CONFIG_FILE"
    else
        python3 -c "
import json
with open('$CONFIG_FILE', 'r') as f:
    data = json.load(f)
print(json.dumps(data, indent=2, ensure_ascii=False))
" 2>/dev/null || cat "$CONFIG_FILE"
    fi
    
    echo ""
    echo "=== 当前cron任务 ==="
    crontab -l 2>/dev/null | grep -i "news\|clawdbot" || echo "未找到相关cron任务"
}

# 显示状态
show_status() {
    echo "📊 新闻订阅服务状态检查"
    echo "================================"
    
    # 检查配置文件
    if [ -f "$CONFIG_FILE" ]; then
        echo "✅ 配置文件存在"
    else
        echo "❌ 配置文件不存在"
    fi
    
    # 检查日志文件
    if [ -f "$LOG_FILE" ]; then
        LOG_SIZE=$(ls -lh "$LOG_FILE" | awk '{print $5}')
        echo "✅ 日志文件存在 (大小: $LOG_SIZE)"
    else
        echo "⚠️  日志文件不存在"
    fi
    
    # 检查cron任务
    echo ""
    echo "=== Cron任务检查 ==="
    CRON_JOBS=$(crontab -l 2>/dev/null | grep -c "news-subscription")
    if [ "$CRON_JOBS" -gt 0 ]; then
        echo "✅ 找到 $CRON_JOBS 个cron任务"
        crontab -l 2>/dev/null | grep "news-subscription"
    else
        echo "❌ 未找到cron任务"
    fi
    
    # 检查web_search功能
    echo ""
    echo "=== Web Search功能 ==="
    if clawdbot gateway status >/dev/null 2>&1; then
        echo "✅ Clawdbot服务运行正常"
    else
        echo "❌ Clawdbot服务可能未运行"
    fi
    
    # 显示配置状态
    if [ -f "$CONFIG_FILE" ]; then
        STATUS=$(python3 -c "
import json
try:
    with open('$CONFIG_FILE', 'r') as f:
        data = json.load(f)
    print(data.get('status', 'unknown'))
except:
    print('error')
")
        echo "📋 服务状态: $STATUS"
    fi
    
    echo ""
    echo "💡 建议操作:"
    echo "1. 检查OpenRouter账户余额"
    echo "2. 运行 '$0 test' 测试功能"
    echo "3. 运行 '$0 setup' 设置定时任务"
}

# 测试功能
test_function() {
    echo "🧪 测试新闻订阅功能"
    echo "================================"
    
    # 测试web_search
    echo "测试web_search功能..."
    if clawdbot gateway status >/dev/null 2>&1; then
        echo "✅ Clawdbot网关运行正常"
        
        # 尝试简单的搜索
        echo "尝试搜索测试..."
        TEST_RESULT=$(clawdbot tools web_search --query "测试" --count 1 2>&1 | head -20)
        if echo "$TEST_RESULT" | grep -q "error\|Error\|ERROR"; then
            echo "❌ Web search测试失败:"
            echo "$TEST_RESULT" | head -5
        else
            echo "✅ Web search测试成功"
            echo "$TEST_RESULT" | head -3
        fi
    else
        echo "❌ Clawdbot网关未运行"
    fi
    
    # 测试配置读取
    echo ""
    echo "测试配置读取..."
    if [ -f "$CONFIG_FILE" ]; then
        echo "✅ 配置文件可读取"
        MORNING_TIME=$(python3 -c "
import json
with open('$CONFIG_FILE', 'r') as f:
    data = json.load(f)
print(data['schedule']['morning'])
")
        echo "  早上发送时间: $MORNING_TIME"
    else
        echo "❌ 配置文件不存在"
    fi
    
    # 测试临时目录
    echo ""
    echo "测试文件系统..."
    if [ -d "$TEMP_DIR" ]; then
        echo "✅ 临时目录存在"
    else
        mkdir -p "$TEMP_DIR"
        echo "✅ 临时目录已创建"
    fi
    
    log "功能测试完成"
}

# 设置cron任务
setup_cron() {
    echo "🔄 设置cron定时任务"
    echo "================================"
    
    # 读取配置中的时间
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "❌ 配置文件不存在"
        return 1
    fi
    
    # 使用python解析时间
    SCHEDULE=$(python3 -c "
import json
with open('$CONFIG_FILE', 'r') as f:
    data = json.load(f)
schedule = data['schedule']
print(f\"{schedule['morning']} {schedule['afternoon']} {schedule['evening']}\")
")
    
    MORNING_CRON=$(echo "$SCHEDULE" | awk '{print $1}')
    AFTERNOON_CRON=$(echo "$SCHEDULE" | awk '{print $2}')
    EVENING_CRON=$(echo "$SCHEDULE" | awk '{print $3}')
    
    echo "早上任务: $MORNING_CRON"
    echo "下午任务: $AFTERNOON_CRON"
    echo "晚上任务: $EVENING_CRON"
    
    # 获取当前crontab
    CURRENT_CRON=$(crontab -l 2>/dev/null || echo "")
    
    # 移除旧的新闻任务
    NEW_CRON=$(echo "$CURRENT_CRON" | grep -v "news-subscription")
    
    # 添加新任务
    SCRIPT_PATH="$HOME/clawd/scripts/news-subscription.sh"
    
    # 如果新闻收集脚本不存在，创建占位脚本
    if [ ! -f "$SCRIPT_PATH" ]; then
        echo "创建占位脚本..."
        cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
# 新闻收集脚本（占位版）
# 实际功能需要web_search API修复后实现

echo "📰 新闻订阅服务运行中..."
echo "时间: $(date)"
echo "状态: 等待web_search API修复"
echo "请检查OpenRouter账户并修复配置"

# 记录运行日志
LOG_DIR="$HOME/clawd/logs"
mkdir -p "$LOG_DIR"
echo "[$(date)] 新闻任务触发 - 等待API修复" >> "$LOG_DIR/news-runs.log"
EOF
        chmod +x "$SCRIPT_PATH"
        echo "✅ 占位脚本已创建: $SCRIPT_PATH"
    fi
    
    # 添加cron任务
    CRON_ENTRIES="
# 飞天主人新闻订阅服务
$MORNING_CRON $SCRIPT_PATH morning >> $LOG_FILE 2>&1
$AFTERNOON_CRON $SCRIPT_PATH afternoon >> $LOG_FILE 2>&1
$EVENING_CRON $SCRIPT_PATH evening >> $LOG_FILE 2>&1
"
    
    # 更新crontab
    (echo "$NEW_CRON"; echo "$CRON_ENTRIES") | crontab -
    
    if [ $? -eq 0 ]; then
        echo "✅ Cron任务设置成功"
        echo ""
        echo "设置的任务:"
        crontab -l | grep "news-subscription"
        log "Cron任务设置完成"
    else
        echo "❌ Cron任务设置失败"
        return 1
    fi
}

# 移除cron任务
remove_cron() {
    echo "🗑️  移除cron定时任务"
    echo "================================"
    
    CURRENT_CRON=$(crontab -l 2>/dev/null || echo "")
    NEW_CRON=$(echo "$CURRENT_CRON" | grep -v "news-subscription")
    
    if [ "$CURRENT_CRON" = "$NEW_CRON" ]; then
        echo "ℹ️  未找到新闻订阅的cron任务"
    else
        echo "$NEW_CRON" | crontab -
        echo "✅ 已移除所有新闻订阅cron任务"
        log "Cron任务已移除"
    fi
}

# 查看日志
show_log() {
    echo "📝 新闻订阅服务日志"
    echo "================================"
    
    if [ -f "$LOG_FILE" ]; then
        if [ "$1" = "tail" ]; then
            tail -20 "$LOG_FILE"
        else
            cat "$LOG_FILE"
        fi
    else
        echo "日志文件不存在: $LOG_FILE"
    fi
}

# 主程序
case "$1" in
    status)
        show_status
        ;;
    test)
        test_function
        ;;
    setup)
        setup_cron
        ;;
    remove)
        remove_cron
        ;;
    config)
        show_config
        ;;
    log)
        show_log "$2"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "未知命令: $1"
        echo "使用 '$0 help' 查看帮助"
        exit 1
        ;;
esac

exit 0