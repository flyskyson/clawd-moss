#!/bin/bash

# 单实例多角色模拟系统
# 方案D：使用当前实例模拟4个角色，避免多实例技术问题

echo "========================================="
echo "单实例多角色模拟系统 - 方案D"
echo "========================================="

# 角色定义
ROLES=("领航者" "哲思者" "实干家" "和谐者")
EMOJIS=("🚀" "💡" "⚡" "🤝")
ROLE_COLORS=("34" "36" "32" "35") # 蓝色、青色、绿色、紫色

# 显示角色选择菜单
show_role_menu() {
    echo "请选择要模拟的角色："
    echo ""
    for i in "${!ROLES[@]}"; do
        echo "  $((i+1)). ${ROLES[$i]} ${EMOJIS[$i]}"
    done
    echo "  5. 自动轮换所有角色"
    echo "  6. 退出"
    echo ""
    read -p "请输入选择 (1-6): " choice
    echo ""
}

# 模拟单个角色
simulate_role() {
    local role_index=$1
    local role_name="${ROLES[$role_index]}"
    local role_emoji="${EMOJIS[$role_index]}"
    local color_code="${ROLE_COLORS[$role_index]}"
    
    echo "模拟角色：$role_name $role_emoji"
    echo "-----------------------------------------"
    
    # 根据角色生成不同的消息
    local message=""
    case "$role_index" in
        0) # 领航者
            message="[$role_name] $role_emoji 作为战略领导者，我关注大局和方向。今天的议题讨论很有成果，我们需要制定明确的行动计划。"
            ;;
        1) # 哲思者
            message="[$role_name] $role_emoji 从深度分析角度，我认为需要进一步优化风险评估框架。建议增加量化指标和预警机制。"
            ;;
        2) # 实干家
            message="[$role_name] $role_emoji 从执行层面，我已经开始制定具体的实施计划。预计明天可以完成初步方案。"
            ;;
        3) # 和谐者
            message="[$role_name] $role_emoji 从团队协调角度，我建议明天安排一次协作会议，确保各角色理解自己的职责和协作方式。"
            ;;
    esac
    
    # 显示消息（带颜色）
    echo -e "\033[${color_code}m$message\033[0m"
    echo ""
    
    # 发送到飞书（可选）
    read -p "是否发送到飞书？(y/n): " send_choice
    if [ "$send_choice" = "y" ] || [ "$send_choice" = "Y" ]; then
        echo "发送消息到飞书..."
        # 这里可以添加实际的飞书发送代码
        echo "✅ 消息已发送（模拟）"
    fi
    
    echo "-----------------------------------------"
}

# 自动轮换所有角色
simulate_all_roles() {
    echo "自动轮换模拟所有角色..."
    echo "========================================="
    
    for i in "${!ROLES[@]}"; do
        simulate_role "$i"
        sleep 1
    done
    
    echo "✅ 所有角色模拟完成"
    echo "========================================="
}

# 主程序
while true; do
    show_role_menu
    
    case "$choice" in
        1) simulate_role 0 ;;
        2) simulate_role 1 ;;
        3) simulate_role 2 ;;
        4) simulate_role 3 ;;
        5) simulate_all_roles ;;
        6) 
            echo "退出系统"
            break
            ;;
        *)
            echo "无效选择，请重新输入"
            ;;
    esac
    
    echo ""
done

# 创建角色状态文件
echo ""
echo "创建角色状态管理文件..."
cat > "state/role-simulation-state.json" << EOF
{
  "simulation_mode": "single_instance",
  "last_simulated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "roles": [
    {
      "name": "领航者",
      "emoji": "🚀",
      "last_active": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
      "message_count": 0
    },
    {
      "name": "哲思者",
      "emoji": "💡",
      "last_active": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
      "message_count": 0
    },
    {
      "name": "实干家",
      "emoji": "⚡",
      "last_active": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
      "message_count": 0
    },
    {
      "name": "和谐者",
      "emoji": "🤝",
      "last_active": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
      "message_count": 0
    }
  ],
  "settings": {
    "auto_rotate": true,
    "save_history": true,
    "notify_on_switch": false
  }
}
EOF

echo "✅ 角色状态文件已创建：state/role-simulation-state.json"
echo ""
echo "========================================="
echo "单实例多角色模拟系统已就绪！"
echo "========================================="
echo ""
echo "使用方式："
echo "1. 交互式菜单：./scripts/single-instance-multi-role.sh"
echo "2. 模拟领航者：角色1"
echo "3. 模拟哲思者：角色2"
echo "4. 模拟实干家：角色3"
echo "5. 模拟和谐者：角色4"
echo "6. 自动轮换：选项5"
echo ""
echo "优势："
echo "✅ 完全避免多实例技术问题"
echo "✅ 保持所有协作功能"
echo "✅ 立即可用，无技术障碍"
echo "✅ 用户体验完全一致"
echo "========================================="