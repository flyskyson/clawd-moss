#!/bin/bash
# communication-control.sh
# 沟通节奏控制工具

# 配置
MAX_POINTS_PER_MESSAGE=3
MAX_LINES_PER_POINT=2
MESSAGE_INTERVAL_SECONDS=30
ENABLE_FEEDBACK_CHECKPOINTS=true

# 颜色和格式
BOLD='\033[1m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
RESET='\033[0m'

# 日志文件
LOG_FILE="$HOME/clawd/logs/communication.log"

# 记录沟通日志
log_communication() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$LOG_FILE"
}

# 格式化消息点
format_point() {
    local point="$1"
    local level="${2:-info}"  # info/important/warning/action
    
    case "$level" in
        "important")
            echo "🎯 $point"
            ;;
        "warning")
            echo "⚠️  $point"
            ;;
        "action")
            echo "🚀 $point"
            ;;
        "info")
            echo "📝 $point"
            ;;
        "success")
            echo "✅ $point"
            ;;
        *)
            echo "• $point"
            ;;
    esac
}

# 发送分段消息
send_segmented_message() {
    local title="$1"
    shift
    local points=("$@")
    
    echo ""
    echo "${BLUE}${BOLD}$title${RESET}"
    echo "---"
    
    local point_count=0
    for point in "${points[@]}"; do
        format_point "$point"
        ((point_count++))
        
        # 每3个点检查是否需要暂停
        if [ $((point_count % MAX_POINTS_PER_MESSAGE)) -eq 0 ] && [ "$ENABLE_FEEDBACK_CHECKPOINTS" = true ]; then
            echo ""
            echo "${YELLOW}⏸️  已显示 $point_count 个要点${RESET}"
            echo "${GREEN}请选择：${RESET}"
            echo "  1. 继续显示更多"
            echo "  2. 暂停，需要消化"
            echo "  3. 只要摘要"
            echo "  4. 换话题"
            echo ""
            read -p "您的选择 (1-4): " choice
            
            case "$choice" in
                1)
                    echo "继续显示..."
                    ;;
                2)
                    echo "暂停，等待您消化..."
                    log_communication "INFO" "用户选择暂停消化"
                    return 1
                    ;;
                3)
                    echo "显示摘要..."
                    log_communication "INFO" "用户选择只要摘要"
                    return 2
                    ;;
                4)
                    echo "换话题..."
                    log_communication "INFO" "用户选择换话题"
                    return 3
                    ;;
                *)
                    echo "默认继续..."
                    ;;
            esac
            echo ""
        fi
    done
    
    echo ""
    return 0
}

# 生成沟通摘要
generate_communication_summary() {
    local content="$1"
    
    # 提取关键句子（以🎯⚠️🚀✅开头的行）
    local summary=$(echo "$content" | grep -E "^(🎯|⚠️|🚀|✅|📝)" | head -5)
    
    if [ -n "$summary" ]; then
        echo "${GREEN}📋 沟通摘要：${RESET}"
        echo "$summary"
    else
        # 提取前3行作为摘要
        echo "${GREEN}📋 内容摘要：${RESET}"
        echo "$content" | head -3
    fi
}

# 等待反馈
wait_for_feedback() {
    local prompt="$1"
    
    echo ""
    echo "${YELLOW}⏳ $prompt${RESET}"
    echo "${GREEN}反馈选项：${RESET}"
    echo "  ✅ 继续 - 继续详细内容"
    echo "  📋 摘要 - 只要核心摘要"
    echo "  ⏸️  暂停 - 需要时间消化"
    echo "  🔄 换题 - 换个话题"
    echo "  🎯 决策 - 需要您决策"
    echo ""
    
    log_communication "INFO" "等待用户反馈: $prompt"
}

# 控制沟通节奏
control_communication_rhythm() {
    local phase="$1"  # start/middle/end
    local topic="$2"
    
    case "$phase" in
        "start")
            echo "${BLUE}${BOLD}🤝 开始沟通：$topic${RESET}"
            echo "我会控制信息节奏，确保沟通舒适。"
            log_communication "START" "开始话题: $topic"
            ;;
        "middle")
            if [ "$ENABLE_FEEDBACK_CHECKPOINTS" = true ]; then
                echo ""
                echo "${YELLOW}⏸️  沟通检查点${RESET}"
                echo "当前节奏如何？"
                echo "  1. 节奏合适，继续"
                echo "  2. 信息太多，简化"
                echo "  3. 需要暂停，消化"
                echo "  4. 换话题"
                echo ""
                read -p "您的反馈 (1-4): " feedback
                
                case "$feedback" in
                    1) echo "好的，继续当前节奏" ;;
                    2) echo "简化信息，只提供核心要点" ;;
                    3) echo "暂停，等待您消化" ;;
                    4) echo "好的，换话题" ;;
                esac
                
                log_communication "FEEDBACK" "用户反馈: $feedback"
            fi
            ;;
        "end")
            echo ""
            echo "${GREEN}${BOLD}🎯 沟通总结${RESET}"
            echo "• 话题: $topic"
            echo "• 状态: 完成"
            echo "• 下一步: 等待您的指示"
            log_communication "END" "结束话题: $topic"
            ;;
    esac
}

# 自适应调整配置
adaptive_adjustment() {
    local feedback="$1"
    
    case "$feedback" in
        "信息太多")
            MAX_POINTS_PER_MESSAGE=$((MAX_POINTS_PER_MESSAGE - 1))
            [ $MAX_POINTS_PER_MESSAGE -lt 1 ] && MAX_POINTS_PER_MESSAGE=1
            echo "调整：每段消息最多 $MAX_POINTS_PER_MESSAGE 个要点"
            ;;
        "节奏太快")
            MESSAGE_INTERVAL_SECONDS=$((MESSAGE_INTERVAL_SECONDS + 10))
            echo "调整：消息间隔增加到 $MESSAGE_INTERVAL_SECONDS 秒"
            ;;
        "需要更多细节")
            MAX_POINTS_PER_MESSAGE=$((MAX_POINTS_PER_MESSAGE + 1))
            echo "调整：每段消息最多 $MAX_POINTS_PER_MESSAGE 个要点"
            ;;
        "节奏合适")
            echo "保持当前节奏配置"
            ;;
    esac
    
    log_communication "ADJUST" "自适应调整: $feedback"
}

# 示例使用
example_communication() {
    echo "${BLUE}${BOLD}🧪 沟通节奏控制示例${RESET}"
    echo ""
    
    # 开始沟通
    control_communication_rhythm "start" "工作汇报优化"
    
    sleep 2
    
    # 第一段消息
    send_segmented_message "📋 今日工作摘要" \
        "完成AI技术动态收集项目开发" \
        "创建消息格式优化工具" \
        "系统状态检查完成"
    
    sleep 2
    
    # 等待反馈
    wait_for_feedback "以上摘要是否清晰？"
    
    sleep 2
    
    # 第二段消息（如果需要）
    send_segmented_message "🎯 明日计划" \
        "08:00 第一次优化格式工作汇报" \
        "09:00 AI技术动态第一次自动运行" \
        "15:00 新闻订阅日常运行验证"
    
    sleep 2
    
    # 沟通检查点
    control_communication_rhythm "middle" "工作汇报优化"
    
    sleep 2
    
    # 结束沟通
    control_communication_rhythm "end" "工作汇报优化"
    
    echo ""
    echo "${GREEN}✅ 沟通示例完成${RESET}"
}

# 主函数
main() {
    local action="$1"
    
    case "$action" in
        "example")
            example_communication
            ;;
        "config")
            echo "${BLUE}沟通节奏配置：${RESET}"
            echo "• 每段消息最多要点: $MAX_POINTS_PER_MESSAGE"
            echo "• 每个要点最多行数: $MAX_LINES_PER_POINT"
            echo "• 消息间隔秒数: $MESSAGE_INTERVAL_SECONDS"
            echo "• 反馈检查点: $ENABLE_FEEDBACK_CHECKPOINTS"
            ;;
        "log")
            echo "${BLUE}沟通日志：${RESET}"
            if [ -f "$LOG_FILE" ]; then
                tail -20 "$LOG_FILE"
            else
                echo "暂无沟通日志"
            fi
            ;;
        "adjust")
            echo "${YELLOW}自适应调整${RESET}"
            echo "请选择反馈类型："
            echo "1. 信息太多"
            echo "2. 节奏太快"
            echo "3. 需要更多细节"
            echo "4. 节奏合适"
            read -p "选择 (1-4): " choice
            
            case "$choice" in
                1) adaptive_adjustment "信息太多" ;;
                2) adaptive_adjustment "节奏太快" ;;
                3) adaptive_adjustment "需要更多细节" ;;
                4) adaptive_adjustment "节奏合适" ;;
                *) echo "无效选择" ;;
            esac
            ;;
        *)
            echo "${BLUE}${BOLD}沟通节奏控制工具${RESET}"
            echo ""
            echo "用法:"
            echo "  $0 example      # 运行沟通示例"
            echo "  $0 config       # 查看当前配置"
            echo "  $0 log          # 查看沟通日志"
            echo "  $0 adjust       # 自适应调整配置"
            echo ""
            echo "核心功能："
            echo "  • 控制信息密度和节奏"
            echo "  • 分段发送消息"
            echo "  • 等待反馈检查点"
            echo "  • 自适应调整配置"
            echo "  • 记录沟通日志"
            ;;
    esac
}

# 执行主函数
main "$@"