#!/bin/bash
# news-subscription-v2.sh
# 飞天主人新闻订阅服务 - 版本2（使用直接OpenRouter API）
# 创建时间：2026-01-31

CONFIG_FILE="$HOME/clawd/scripts/news-subscription-config.json"
LOG_FILE="$HOME/clawd/logs/news-subscription.log"
RUN_LOG="$HOME/clawd/logs/news-runs.log"
TEMP_DIR="$HOME/clawd/temp/news"
PYTHON_SCRIPT="$HOME/clawd/scripts/news-collector-openrouter.py"

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
    echo "📰 飞天主人新闻订阅服务 v2"
    echo "================================"
    echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "会话: $1"
    echo "模式: 直接OpenRouter API"
    echo "状态: 生产模式"
    echo ""
}

# 检查Python脚本
check_python_script() {
    if [ ! -f "$PYTHON_SCRIPT" ]; then
        echo "❌ Python脚本不存在: $PYTHON_SCRIPT"
        return 1
    fi
    
    if ! command -v python3 >/dev/null 2>&1; then
        echo "❌ Python3未安装"
        return 1
    fi
    
    # 检查Python依赖
    if ! python3 -c "import requests" 2>/dev/null; then
        echo "⚠️  requests模块未安装，尝试安装..."
        pip3 install requests 2>/dev/null || {
            echo "❌ 无法安装requests模块"
            return 1
        }
    fi
    
    echo "✅ Python环境检查通过"
    return 0
}

# 收集新闻（使用Python脚本）
collect_news() {
    local session="$1"
    
    echo "📡 使用OpenRouter API收集新闻..."
    echo ""
    
    # 运行Python收集器
    local output
    output=$(python3 "$PYTHON_SCRIPT" "$session" 2>&1)
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo "✅ 新闻收集成功"
        echo "$output"
        return 0
    else
        echo "❌ 新闻收集失败 (退出码: $exit_code)"
        echo "错误信息:"
        echo "$output" | tail -10
        return 1
    fi
}

# 发送新闻到飞书（占位函数，等后续实现）
send_to_feishu() {
    local session="$1"
    local content="$2"
    
    echo "📤 准备发送新闻到飞书 (会话: $session)"
    echo ""
    
    # 这里等后续实现实际的飞书发送功能
    # 目前先保存到文件并显示
    
    local output_file="$TEMP_DIR/feishu_ready_${session}_$(date +%Y%m%d_%H%M%S).md"
    echo "$content" > "$output_file"
    
    echo "📋 新闻内容已准备就绪:"
    echo "================================"
    echo "$content" | head -30
    echo "..."
    echo "================================"
    echo ""
    echo "📁 内容已保存到: $output_file"
    echo ""
    echo "💡 下一步："
    echo "1. 实现飞书自动发送功能"
    echo "2. 或手动复制内容到飞书发送"
    echo "3. 当前可通过cron任务自动收集和保存"
    
    # 记录发送状态
    echo "🔄 飞书发送功能待实现"
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
    
    # 检查Python环境
    if ! check_python_script; then
        echo "❌ Python环境检查失败，使用备用模式"
        # 这里可以添加备用模式
        return 1
    fi
    
    # 收集新闻
    local news_content
    if news_content=$(collect_news "$session"); then
        log "新闻收集成功: $session"
        
        # 发送到飞书（占位）
        send_to_feishu "$session" "$news_content"
        
        # 记录成功
        echo ""
        echo "🎉 新闻订阅任务执行完成"
        echo "⏰ 执行时间: $(date '+%H:%M:%S')"
        echo "📊 状态: 生产模式（直接API）"
        echo "🔧 功能: 新闻收集 ✓ | 飞书发送 ⏳"
        
        log "任务完成: $session (生产模式)"
    else
        log "新闻收集失败: $session"
        echo ""
        echo "❌ 新闻收集失败"
        echo "💡 请检查："
        echo "   1. OpenRouter API密钥有效性"
        echo "   2. 网络连接"
        echo "   3. Python环境"
        
        log "任务失败: $session"
        return 1
    fi
    
    return 0
}

# 执行主程序
main "$1"

exit 0