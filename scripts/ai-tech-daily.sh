#!/bin/bash
# ai-tech-daily.sh
# AI技术动态每日收集脚本

# 日志文件
LOG_FILE="$HOME/clawd/logs/ai-tech-daily.log"

# 项目目录
PROJECT_DIR="$HOME/clawd/projects/ai-collector"

# 记录日志
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo "$1"
}

log "========================================"
log "🚀 开始AI技术动态每日收集"
log "========================================"

# 进入项目目录
cd "$PROJECT_DIR" || exit 1

# 运行收集器
log "📡 开始收集数据..."
python3 run_collector.py --run >> "$LOG_FILE" 2>&1

# 检查运行结果
if [ $? -eq 0 ]; then
    log "✅ AI技术动态收集完成"
    
    # 找到最新生成的报告
    LATEST_MD=$(find reports/markdown -name "ai_report_*.md" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
    
    if [ -n "$LATEST_MD" ]; then
        log "📄 最新报告: $LATEST_MD"
        
        # TODO: 发送到飞书
        log "📱 准备发送到飞书..."
        # 这里需要调用飞书API发送消息
        # python3 send_to_feishu.py "$LATEST_MD"
    else
        log "⚠️ 没有找到生成的报告"
    fi
else
    log "❌ AI技术动态收集失败"
fi

log "========================================"
log "✅ 脚本执行完成"
log "========================================"

exit 0