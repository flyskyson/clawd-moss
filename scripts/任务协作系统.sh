#!/bin/bash

# 任务协作系统
# 处理主人分配的任务，协调各角色协作完成

echo "========================================="
echo "Clawdbot任务协作系统"
echo "========================================="

# 配置文件路径
CONFIG_FILE="config/feishu-group-config.json"
STATE_FILE="state/task-state.json"
TASKS_DIR="tasks"

# 创建必要的目录
mkdir -p "$TASKS_DIR"
mkdir -p "state"
mkdir -p "logs/tasks"

# 初始化任务状态
if [ ! -f "$STATE_FILE" ]; then
    echo "初始化任务状态文件..."
    cat > "$STATE_FILE" << EOF
{
  "total_tasks": 0,
  "completed_tasks": 0,
  "active_tasks": [],
  "task_history": [],
  "last_updated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
fi

# 任务处理函数
process_task() {
    local task_id="$1"
    local task_file="$2"
    
    echo "处理任务: $task_id"
    
    # 读取任务内容
    TASK_CONTENT=$(cat "$task_file")
    TASK_TITLE=$(echo "$TASK_CONTENT" | grep "^# " | head -1 | sed 's/^# //')
    TASK_PRIORITY=$(echo "$TASK_CONTENT" | grep "优先级:" | head -1 | cut -d: -f2 | tr -d ' ')
    TASK_DEADLINE=$(echo "$TASK_CONTENT" | grep "截止时间:" | head -1 | cut -d: -f2 | tr -d ' ')
    
    echo "任务标题: $TASK_TITLE"
    echo "优先级: ${TASK_PRIORITY:-未指定}"
    echo "截止时间: ${TASK_DEADLINE:-未指定}"
    
    # 分析任务类型，分配角色
    analyze_and_assign() {
        local content="$1"
        local task_id="$2"
        
        # 简单关键词匹配分配
        if echo "$content" | grep -qi "战略\|规划\|决策\|领导"; then
            echo "leader"
        elif echo "$content" | grep -qi "分析\|思考\|研究\|创新"; then
            echo "thinker"
        elif echo "$content" | grep -qi "执行\|实施\|操作\|完成"; then
            echo "executor"
        elif echo "$content" | grep -qi "协调\|沟通\|团队\|合作"; then
            echo "coordinator"
        else
            # 默认分配给今日组长
            TODAY_LEADER=$(jq -r '.current_leader' "state/daily-leader-state.json" 2>/dev/null || echo "leader")
            echo "$TODAY_LEADER"
        fi
    }
    
    MAIN_ASSIGNEE=$(analyze_and_assign "$TASK_CONTENT" "$task_id")
    
    # 确定协作角色（根据任务复杂度）
    TASK_COMPLEXITY=$(echo "$TASK_CONTENT" | grep -c "^##")
    if [ "$TASK_COMPLEXITY" -gt 2 ]; then
        # 复杂任务需要多个角色协作
        COLLABORATORS=("leader" "thinker" "executor" "coordinator")
        # 移除主要负责人
        COLLABORATORS=(${COLLABORATORS[@]/$MAIN_ASSIGNEE})
        # 选择前2个作为协作者
        COLLABORATOR1=${COLLABORATORS[0]}
        COLLABORATOR2=${COLLABORATORS[1]}
        COLLABORATORS_STR="$COLLABORATOR1,$COLLABORATOR2"
    else
        # 简单任务只需要主要负责人
        COLLABORATORS_STR=""
    fi
    
    # 创建任务分配文件
    ASSIGNMENT_FILE="state/task-assignment-$task_id.json"
    cat > "$ASSIGNMENT_FILE" << EOF
{
  "task_id": "$task_id",
  "task_title": "$TASK_TITLE",
  "task_file": "$task_file",
  "main_assignee": "$MAIN_ASSIGNEE",
  "collaborators": "$COLLABORATORS_STR",
  "priority": "${TASK_PRIORITY:-中}",
  "deadline": "${TASK_DEADLINE:-未指定}",
  "status": "assigned",
  "assigned_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "progress": 0,
  "updates": []
}
EOF
    
    echo "任务分配完成："
    echo "  主要负责人: $MAIN_ASSIGNEE"
    if [ -n "$COLLABORATORS_STR" ]; then
        echo "  协作者: $COLLABORATORS_STR"
    fi
    echo "  分配文件: $ASSIGNMENT_FILE"
    
    # 更新状态文件
    jq --arg task_id "$task_id" \
       --arg title "$TASK_TITLE" \
       --arg assignee "$MAIN_ASSIGNEE" \
       '.total_tasks += 1 |
        .active_tasks += [{
          "id": $task_id,
          "title": $title,
          "main_assignee": $assignee,
          "collaborators": "'"$COLLABORATORS_STR"'",
          "status": "assigned",
          "assigned_at": "'"$(date -u +"%Y-%m-%dT%H:%M:%SZ")"'"
        }] |
        .last_updated = "'"$(date -u +"%Y-%m-%dT%H:%M:%SZ")"'"' \
       "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
}

# 检查新任务
check_new_tasks() {
    echo "检查新任务..."
    
    # 查找tasks目录下的新任务文件
    NEW_TASKS=()
    for task_file in "$TASKS_DIR"/*.md "$TASKS_DIR"/*.txt; do
        [ -e "$task_file" ] || continue
        
        TASK_BASENAME=$(basename "$task_file")
        TASK_ID="${TASK_BASENAME%.*}"
        
        # 检查是否已分配
        if [ ! -f "state/task-assignment-$TASK_ID.json" ]; then
            NEW_TASKS+=("$task_file")
        fi
    done
    
    if [ ${#NEW_TASKS[@]} -eq 0 ]; then
        echo "没有发现新任务"
        return 0
    fi
    
    echo "发现 ${#NEW_TASKS[@]} 个新任务："
    for task_file in "${NEW_TASKS[@]}"; do
        TASK_BASENAME=$(basename "$task_file")
        TASK_ID="${TASK_BASENAME%.*}"
        echo "  - $TASK_ID ($task_file)"
        
        # 处理任务
        process_task "$TASK_ID" "$task_file"
    done
    
    return ${#NEW_TASKS[@]}
}

# 更新任务进度
update_task_progress() {
    local task_id="$1"
    local progress="$2"
    local update_message="$3"
    
    ASSIGNMENT_FILE="state/task-assignment-$task_id.json"
    if [ ! -f "$ASSIGNMENT_FILE" ]; then
        echo "错误：找不到任务分配文件 $ASSIGNMENT_FILE"
        return 1
    fi
    
    # 更新进度
    jq --arg progress "$progress" \
       --arg message "$update_message" \
       --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       '.progress = ($progress | tonumber) |
        .updates += [{
          "timestamp": $timestamp,
          "progress": ($progress | tonumber),
          "message": $message
        }] |
        if ($progress | tonumber) >= 100 then .status = "completed" else . end' \
       "$ASSIGNMENT_FILE" > "$ASSIGNMENT_FILE.tmp" && mv "$ASSIGNMENT_FILE.tmp" "$ASSIGNMENT_FILE"
    
    echo "任务 $task_id 进度更新为 $progress%"
    
    # 如果任务完成，更新状态文件
    if [ "$progress" -ge 100 ]; then
        jq --arg task_id "$task_id" \
           '.active_tasks |= map(if .id == $task_id then .status = "completed" else . end) |
            .completed_tasks += 1 |
            .task_history += [{
              "id": $task_id,
              "completed_at": "'"$(date -u +"%Y-%m-%dT%H:%M:%SZ")"'"
            }] |
            .last_updated = "'"$(date -u +"%Y-%m-%dT%H:%M:%SZ")"'"' \
           "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
        
        echo "任务 $task_id 标记为完成"
    fi
}

# 生成任务报告
generate_task_report() {
    echo "生成任务报告..."
    
    REPORT_FILE="reports/task-report-$(date +%Y%m%d-%H%M%S).md"
    mkdir -p "$(dirname "$REPORT_FILE")"
    
    # 读取状态
    TOTAL_TASKS=$(jq -r '.total_tasks' "$STATE_FILE")
    COMPLETED_TASKS=$(jq -r '.completed_tasks' "$STATE_FILE")
    ACTIVE_TASKS=$(jq -r '.active_tasks | length' "$STATE_FILE")
    
    # 计算完成率
    if [ "$TOTAL_TASKS" -gt 0 ]; then
        COMPLETION_RATE=$(( COMPLETED_TASKS * 100 / TOTAL_TASKS ))
    else
        COMPLETION_RATE=0
    fi
    
    cat > "$REPORT_FILE" << EOF
# 任务协作系统报告
## $(date +%Y年%m月%d日 %H:%M)

## 总体统计
- **总任务数**: $TOTAL_TASKS
- **已完成**: $COMPLETED_TASKS
- **进行中**: $ACTIVE_TASKS
- **完成率**: $COMPLETION_RATE%

## 活跃任务详情
EOF
    
    # 添加活跃任务详情
    jq -r '.active_tasks[] | "### \(.title)\n- **ID**: \(.id)\n- **负责人**: \(.main_assignee)\n- **协作者**: \(.collaborators)\n- **状态**: \(.status)\n- **分配时间**: \(.assigned_at)\n"' "$STATE_FILE" >> "$REPORT_FILE"
    
    # 添加今日完成的任务
    TODAY=$(date +%Y-%m-%d)
    TODAY_COMPLETED=$(jq -r --arg today "$TODAY" '.task_history[] | select(.completed_at | startswith($today)) | .id' "$STATE_FILE" | wc -l)
    
    cat >> "$REPORT_FILE" << EOF

## 今日完成
- **今日完成数**: $TODAY_COMPLETED

## 角色任务分布
EOF
    
    # 统计各角色的任务
    for role in leader thinker executor coordinator; do
        ROLE_TASKS=$(jq -r --arg role "$role" '.active_tasks[] | select(.main_assignee == $role) | .id' "$STATE_FILE" | wc -l)
        cat >> "$REPORT_FILE" << EOF
- **$role**: $ROLE_TASKS 个任务
EOF
    done
    
    cat >> "$REPORT_FILE" << EOF

## 建议和改进
1. 任务分配均衡性：$( [ $TOTAL_TASKS -gt 0 ] && echo "良好" || echo "暂无数据" )
2. 协作效率：根据进度更新频率评估
3. 任务复杂度：平均每个任务协作者数量

---
*报告生成时间：$(date)*
*数据来源：$STATE_FILE*
EOF
    
    echo "任务报告已生成: $REPORT_FILE"
}

# 发送任务通知到群组
send_task_notification() {
    local task_id="$1"
    local task_title="$2"
    local assignee="$3"
    local collaborators="$4"
    
    echo "发送任务通知到飞书群组..."
    
    NOTIFICATION_FILE="logs/task-notification-$(date +%Y%m%d-%H%M%S).txt"
    
    cat > "$NOTIFICATION_FILE" << EOF
【新任务分配】

📋 任务标题：$task_title
🆔 任务ID：$task_id

👤 负责人：$assignee
🤝 协作者：${collaborators:-无}

📅 分配时间：$(date)

💪 请负责人：
1. 确认任务理解
2. 制定执行计划
3. 协调协作者（如有）
4. 定期更新进度

🔄 进度更新：
使用命令：./scripts/任务协作系统.sh update $task_id <进度> "<更新说明>"

🌟 完成任务后：
使用命令：./scripts/任务协作系统.sh complete $task_id

让我们高效协作，完成任务！💪
EOF
    
    echo "通知内容已保存到: $NOTIFICATION_FILE"
    echo "实际发送需要配置飞书API"
}

# 主程序
case "$1" in
    check)
        check_new_tasks
        NEW_COUNT=$?
        if [ "$NEW_COUNT" -gt 0 ]; then
            # 为新任务发送通知
            for task_file in "$TASKS_DIR"/*.md "$TASKS_DIR"/*.txt; do
                [ -e "$task_file" ] || continue
                TASK_BASENAME=$(basename "$task_file")
                TASK_ID="${TASK_BASENAME%.*}"
                ASSIGNMENT_FILE="state/task-assignment-$TASK_ID.json"
                
                if [ -f "$ASSIGNMENT_FILE" ]; then
                    TASK_TITLE=$(jq -r '.task_title' "$ASSIGNMENT_FILE")
                    ASSIGNEE=$(jq -r '.main_assignee' "$ASSIGNMENT_FILE")
                    COLLABORATORS=$(jq -r '.collaborators' "$ASSIGNMENT_FILE")
                    
                    send_task_notification "$TASK_ID" "$TASK_TITLE" "$ASSIGNEE" "$COLLABORATORS"
                fi
            done
        fi
        ;;
    update)
        if [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
            echo "使用方式: $0 update <任务ID> <进度百分比> \"<更新说明>\""
            exit 1
        fi
        update_task_progress "$2" "$3" "$4"
        ;;
    complete)
        if [ -z "$2" ]; then
            echo "使用方式: $0 complete <任务ID>"
            exit 1
        fi
        update_task_progress "$2" "100" "任务完成"
        ;;
    report)
        generate_task_report
        ;;
    status)
        echo "任务协作系统状态："
        echo "========================================="
        jq -r '"总任务数: \(.total_tasks)\n已完成: \(.completed_tasks)\n进行中: \(.active_tasks | length)\n最后更新: \(.last_updated)"' "$STATE_FILE"
        echo ""
        echo "活跃任务："
        jq -r '.active_tasks[] | "  - \(.id): \(.title) (\(.status))"' "$STATE_FILE"
        echo "========================================="
        ;;
    *)
        echo "使用方式: $0 {check|update|complete|report|status}"
        echo ""
        echo "命令说明："
        echo "  check    - 检查并处理新任务"
        echo "  update   - 更新任务进度"
        echo "  complete - 标记任务完成"
        echo "  report   - 生成任务报告"
        echo "  status   - 查看系统状态"
        echo ""
        echo "示例："
        echo "  $0 check                     # 检查新任务"
        echo "  $0 update task-001 50 \"已完成调研\"  # 更新进度"
        echo "  $0 complete task-001        # 标记任务完成"
        echo "  $0 report                   # 生成报告"
        echo "  $0 status                   # 查看状态"
        exit 1
        ;;
esac

echo ""
echo "========================================="
echo "任务协作系统执行完成"
echo "========================================="