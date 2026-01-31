#!/bin/bash
# knowledge-processor-v2.sh
# 知识处理器 v2 - 改进的飞书消息处理

LOG_FILE="$HOME/clawd/logs/knowledge-v2.log"
KNOWLEDGE_SCRIPT="$HOME/clawd/scripts/knowledge-record.sh"

mkdir -p "$(dirname "$LOG_FILE")"

# 日志函数
log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" >> "$LOG_FILE"
}

# 改进的标题提取
extract_title_v2() {
    local message="$1"
    
    # 尝试多种模式提取标题
    
    # 模式1：包含中文冒号或英文冒号
    if [[ "$message" =~ ^[^：:]*[：:]\s*(.+)$ ]]; then
        local extracted="${BASH_REMATCH[1]}"
        # 取第一句话作为标题（最多30字符）
        echo "$extracted" | grep -o '^[^。！？.!?]*' | head -c 30
        return 0
    fi
    
    # 模式2：包含引号（简化处理）
    if [[ "$message" =~ \"([^\"]+)\" ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    if [[ "$message" =~ \'([^\']+)\' ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    
    # 模式3：包含《》
    if [[ "$message" =~ 《([^》]+)》 ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    
    # 模式4：提取前几个词作为标题
    local words=$(echo "$message" | awk '{for(i=1;i<=5;i++) printf $i" "}')
    echo "${words}..."
}

# 改进的内容提取
extract_content_v2() {
    local message="$1"
    local type="$2"
    
    # 移除可能的引导词
    local content="$message"
    
    # 定义引导词模式
    local patterns=""
    case "$type" in
        inspiration)
            patterns="记录灵感|灵感|想法|突然想到|想到"
            ;;
        article)
            patterns="收藏文章|文章收藏|保存文章|这篇文章|阅读"
            ;;
        learning)
            patterns="学习笔记|学习总结|学习|笔记|总结"
            ;;
        project)
            patterns="项目想法|项目|开发|构建|创建"
            ;;
        work)
            patterns="工作记录|工作总结|工作|完成|处理"
            ;;
    esac
    
    # 移除引导词
    for pattern in $(echo "$patterns" | tr '|' ' '); do
        content=$(echo "$content" | sed "s/^$pattern[：:]\s*//")
        content=$(echo "$content" | sed "s/^$pattern\s*//")
    done
    
    # 清理空格
    content=$(echo "$content" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    # 如果内容为空或太短，使用原始消息
    if [ -z "$content" ] || [ ${#content} -lt 5 ]; then
        content="$message"
    fi
    
    echo "$content"
}

# 智能类型识别
identify_type() {
    local message="$1"
    
    # 转换为小写便于匹配，但保留中文
    local lower_msg=$(echo "$message" | sed 's/[A-Z]/\L&/g')
    
    # 检查关键词（优先级顺序）
    if [[ "$lower_msg" =~ (记录灵感|灵感[:：]|想法[:：]|突然想到|想到) ]]; then
        echo "inspiration"
    elif [[ "$lower_msg" =~ (收藏文章|文章收藏|保存文章|这篇文章|阅读) ]]; then
        echo "article"
    elif [[ "$lower_msg" =~ (学习笔记|学习总结|学习[:：]|笔记[:：]|总结) ]]; then
        echo "learning"
    elif [[ "$lower_msg" =~ (项目想法|项目[:：]|开发|构建|创建) ]]; then
        echo "project"
    elif [[ "$lower_msg" =~ (工作记录|工作总结|工作[:：]|完成|处理) ]]; then
        echo "work"
    else
        # 默认根据内容判断
        if [[ "$lower_msg" =~ (ai|人工智能|机器学习|深度学习|技术|代码) ]]; then
            echo "inspiration"  # 技术相关默认为灵感
        else
            echo "inspiration"  # 其他默认为灵感
        fi
    fi
}

# 处理消息
process_message() {
    local message="$1"
    
    log "处理消息：$message"
    
    # 识别类型
    local type
    type=$(identify_type "$message")
    log "识别类型：$type"
    
    # 提取标题
    local title
    title=$(extract_title_v2 "$message")
    log "提取标题：$title"
    
    # 提取内容
    local content
    content=$(extract_content_v2 "$message" "$type")
    log "提取内容：$content"
    
    # 智能分类（简化版）
    local category=""
    if [[ "$message" =~ (ai|人工智能|机器学习|深度学习|clawdbot|agent) ]]; then
        category="AI技术"
    elif [[ "$message" =~ (学习|教程|课程|读书) ]]; then
        category="学习"
    elif [[ "$message" =~ (工作|任务|项目) ]]; then
        category="工作"
    fi
    
    # 智能标签
    local tags="$type"
    if [[ "$message" =~ ai|人工智能 ]]; then
        tags="$tags,AI"
    fi
    if [[ "$message" =~ 机器学习 ]]; then
        tags="$tags,机器学习"
    fi
    if [[ "$message" =~ clawdbot ]]; then
        tags="$tags,Clawdbot"
    fi
    
    # 调用知识记录脚本
    echo "📝 正在处理您的记录请求..."
    echo "   类型：$type"
    echo "   标题：$title"
    echo "   分类：${category:-自动分类}"
    echo ""
    
    local result
    result=$("$KNOWLEDGE_SCRIPT" \
        --type "$type" \
        --title "$title" \
        --category "$category" \
        --tags "$tags" \
        "$content" 2>&1)
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        log "处理成功"
        echo "✅ $result"
        return 0
    else
        log "处理失败：$result"
        echo "❌ 处理失败：$result"
        return 1
    fi
}

# 主函数
main() {
    if [ $# -eq 0 ]; then
        echo "📚 知识处理器 v2"
        echo "用法：发送消息内容作为参数"
        echo ""
        echo "示例："
        echo "  $0 \"记录灵感：AI Agent个性化记忆\""
        echo "  $0 \"收藏文章：Clawdbot最新功能\""
        echo "  $0 \"学习笔记：机器学习基础\""
        echo ""
        echo "支持自然语言格式，自动识别类型和提取内容。"
        return 1
    fi
    
    # 合并所有参数
    local message="$*"
    
    # 处理消息
    process_message "$message"
    
    return $?
}

# 执行
main "$@"