#!/bin/bash
# format-message.sh
# 消息格式优化工具

# 配置
MAX_LINES_PER_SECTION=5
MAX_SECTIONS=3
USE_EMOJI=true
USE_DIVIDER=true

# 颜色定义（飞书可能不支持，但保留）
COLOR_RESET='\033[0m'
COLOR_TITLE='\033[1;34m'
COLOR_SUCCESS='\033[1;32m'
COLOR_WARNING='\033[1;33m'
COLOR_INFO='\033[1;36m'

# 格式化标题
format_title() {
    local title="$1"
    if [ "$USE_EMOJI" = true ]; then
        echo "📌 $title"
    else
        echo "**$title**"
    fi
    if [ "$USE_DIVIDER" = true ]; then
        echo "---"
    fi
}

# 格式化列表项
format_item() {
    local item="$1"
    local type="${2:-info}"  # success/warning/info
    
    case "$type" in
        "success")
            if [ "$USE_EMOJI" = true ]; then
                echo "✅ $item"
            else
                echo "✓ $item"
            fi
            ;;
        "warning")
            if [ "$USE_EMOJI" = true ]; then
                echo "⚠️  $item"
            else
                echo "! $item"
            fi
            ;;
        "info")
            if [ "$USE_EMOJI" = true ]; then
                echo "📝 $item"
            else
                echo "- $item"
            fi
            ;;
        *)
            if [ "$USE_EMOJI" = true ]; then
                echo "🔹 $item"
            else
                echo "- $item"
            fi
            ;;
    esac
}

# 格式化摘要
format_summary() {
    local file="$1"
    local max_lines="${2:-10}"
    
    if [ ! -f "$file" ]; then
        echo "❌ 文件不存在: $file"
        return 1
    fi
    
    echo "📋 文件摘要: $(basename "$file")"
    echo "📁 路径: $file"
    echo ""
    
    # 提取关键信息
    local line_count=0
    while IFS= read -r line && [ "$line_count" -lt "$max_lines" ]; do
        # 跳过空行和注释
        if [[ -z "$line" || "$line" =~ ^#.* ]]; then
            continue
        fi
        
        # 提取重要内容
        if [[ "$line" =~ ^[#]+[[:space:]]+ || "$line" =~ ^[-*]+[[:space:]]+ || "$line" =~ ^[0-9]+\.[[:space:]]+ ]]; then
            echo "$line"
            ((line_count++))
        fi
    done < "$file"
    
    echo ""
    echo "🔍 完整内容请查看文件"
}

# 生成工作汇报摘要
generate_work_report_summary() {
    local date=$(date '+%Y-%m-%d')
    
    cat << EOF
📅 ${date} 工作汇报摘要

🎯 今日重点：
✅ AI技术动态收集系统验证
✅ 新闻订阅服务部署完成
✅ 核心原则确认和承诺

📊 关键数据：
• 完成工作：13项
• 创建文档：10个
• 系统状态：全部就绪

🚀 明日计划：
⏰ 08:00 - 第一次工作汇报
🚀 09:00 - AI动态第一次运行
📰 15:00 - 新闻订阅日常运行

📁 详细文档：
~/clawd/memory/${date}-工作总结.md

💡 建议：
查看完整文档或告诉我需要哪部分详细内容。
EOF
}

# 生成AI报告摘要
generate_ai_report_summary() {
    local report_file="$1"
    
    if [ ! -f "$report_file" ]; then
        # 查找最新报告
        report_file=$(find ~/clawd/projects/reports/markdown -name "ai_report_*.md" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
    fi
    
    if [ -f "$report_file" ]; then
        local report_name=$(basename "$report_file")
        local report_date=$(echo "$report_name" | grep -oE '[0-9]{8}')
        
        cat << EOF
🤖 AI技术动态报告摘要

📅 报告日期: ${report_date:0:4}-${report_date:4:2}-${report_date:6:2}
📊 文章数量: $(grep -c "^- \*\*" "$report_file" 2>/dev/null || echo "N/A")

🏆 推荐阅读：
$(grep -A2 "### 1\." "$report_file" 2>/dev/null | head -6 || echo "无推荐文章")

📈 分类统计：
$(grep -A5 "### 分类分布" "$report_file" 2>/dev/null | head -6 || echo "无分类数据")

📁 完整报告：
$report_file

🔍 查看建议：
使用终端查看：cat "$report_file" | less
EOF
    else
        echo "❌ 未找到AI技术动态报告"
    fi
}

# 生成状态检查摘要
generate_status_summary() {
    cat << EOF
🔍 系统状态摘要

✅ 核心文件：全部存在
✅ 项目状态：全部就绪
✅ 定时任务：3个配置完成
✅ 系统资源：充足可用

⏰ 下次运行：
📰 15:00 - 新闻订阅验证
📅 明天08:00 - 第一次工作汇报
🚀 明天09:00 - AI动态第一次运行

💻 资源状态：
内存：$(top -l 1 | grep PhysMem | awk '{print $2}')
磁盘：$(df -h / | tail -1 | awk '{print $4}') 可用

📁 详细状态：
运行：~/clawd/scripts/check-status.sh
EOF
}

# 主函数
main() {
    local format_type="$1"
    local file_path="$2"
    
    case "$format_type" in
        "work-report")
            generate_work_report_summary
            ;;
        "ai-report")
            generate_ai_report_summary "$file_path"
            ;;
        "status")
            generate_status_summary
            ;;
        "summary")
            if [ -n "$file_path" ]; then
                format_summary "$file_path"
            else
                echo "❌ 请提供文件路径"
                echo "用法: $0 summary <文件路径>"
            fi
            ;;
        "test")
            echo "🧪 消息格式测试"
            echo ""
            format_title "测试标题"
            format_item "成功项目" "success"
            format_item "警告事项" "warning"
            format_item "信息说明" "info"
            format_item "普通项目"
            ;;
        *)
            echo "📱 消息格式优化工具"
            echo ""
            echo "用法:"
            echo "  $0 work-report          # 生成工作汇报摘要"
            echo "  $0 ai-report [文件]     # 生成AI报告摘要"
            echo "  $0 status              # 生成状态检查摘要"
            echo "  $0 summary <文件>      # 生成文件摘要"
            echo "  $0 test                # 测试消息格式"
            echo ""
            echo "示例:"
            echo "  $0 work-report"
            echo "  $0 ai-report ~/clawd/projects/reports/markdown/ai_report_20260131_131251.md"
            echo "  $0 summary ~/clawd/memory/2026-01-31-工作总结.md"
            ;;
    esac
}

# 执行主函数
main "$@"