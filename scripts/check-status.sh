#!/bin/bash
# check-status.sh
# 系统状态检查脚本

echo "🔍 MOSS系统状态检查"
echo "======================"
echo "检查时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 1. 检查核心文件
echo "📁 核心文件状态:"
if [ -f "$HOME/clawd/memory/2026-01-31.md" ]; then
    echo "  ✅ 今日记忆文件: 存在"
else
    echo "  ❌ 今日记忆文件: 缺失"
fi

if [ -f "$HOME/clawd/memory/核心原则和价值观.md" ]; then
    echo "  ✅ 核心原则文档: 存在"
else
    echo "  ❌ 核心原则文档: 缺失"
fi

if [ -f "$HOME/clawd/memory/协作原则和工作流程.md" ]; then
    echo "  ✅ 协作原则文档: 存在"
else
    echo "  ❌ 协作原则文档: 缺失"
fi

echo ""

# 2. 检查项目状态
echo "🚀 项目状态:"

# AI技术动态收集项目
if [ -f "$HOME/clawd/projects/ai-collector/run_collector.py" ]; then
    echo "  ✅ AI技术动态收集: 就绪"
    # 检查最新报告
    latest_report=$(find "$HOME/clawd/projects/reports/markdown" -name "ai_report_*.md" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
    if [ -n "$latest_report" ]; then
        echo "    最新报告: $(basename "$latest_report")"
    else
        echo "    最新报告: 无"
    fi
else
    echo "  ❌ AI技术动态收集: 未就绪"
fi

# 新闻订阅服务
if [ -f "$HOME/clawd/scripts/news-subscription-final.sh" ]; then
    echo "  ✅ 新闻订阅服务: 就绪"
    # 检查cron任务
    cron_count=$(crontab -l 2>/dev/null | grep -c "news-subscription-final.sh")
    if [ "$cron_count" -gt 0 ]; then
        echo "    Cron任务: $cron_count个"
    else
        echo "    Cron任务: 无"
    fi
else
    echo "  ❌ 新闻订阅服务: 未就绪"
fi

echo ""

# 3. 检查定时任务
echo "⏰ 定时任务状态:"
crontab -l 2>/dev/null | grep -v "^#" | while read -r line; do
    if [ -n "$line" ]; then
        echo "  📅 $line"
    fi
done

if ! crontab -l 2>/dev/null | grep -q "."; then
    echo "  ⚠️ 无定时任务"
fi

echo ""

# 4. 检查日志文件
echo "📝 日志文件状态:"
log_dir="$HOME/clawd/logs"
if [ -d "$log_dir" ]; then
    log_count=$(find "$log_dir" -name "*.log" -type f 2>/dev/null | wc -l)
    echo "  日志文件数: $log_count"
    
    # 显示最新日志
    latest_log=$(find "$log_dir" -name "*.log" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
    if [ -n "$latest_log" ]; then
        echo "  最新日志: $(basename "$latest_log")"
        echo "  最后更新: $(stat -f "%Sm" "$latest_log" 2>/dev/null || echo "未知")"
    fi
else
    echo "  ⚠️ 日志目录不存在"
fi

echo ""

# 5. 系统资源
echo "💻 系统资源:"
echo "  内存使用: $(top -l 1 | grep PhysMem | awk '{print $2}')"
echo "  磁盘空间: $(df -h / | tail -1 | awk '{print $4}') 可用"
echo "  运行时间: $(uptime | awk -F'up' '{print $2}' | awk -F',' '{print $1}' | xargs)"

echo ""
echo "======================"
echo "✅ 状态检查完成"
echo ""

# 6. 建议
echo "💡 建议:"
echo "  1. 查看今天工作总结: cat ~/clawd/memory/2026-01-31-工作总结.md"
echo "  2. 查看AI技术动态报告: cat ~/clawd/projects/reports/markdown/ai_report_*.md | head -30"
echo "  3. 查看核心原则: cat ~/clawd/memory/核心原则和价值观.md | head -20"
echo "  4. 等待15:00新闻订阅验证"
echo "  5. 准备明天8:00第一次工作汇报"

echo ""
echo "🎯 明天重要时间:"
echo "  08:00 - 第一次每日工作汇报"
echo "  09:00 - AI技术动态第一次自动运行"
echo "  15:00 - 新闻订阅日常运行"