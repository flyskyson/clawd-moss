#!/bin/bash
# feishu-knowledge-processor.sh
# 飞书知识处理器 - 解析自然语言消息并保存到知识库

LOG_FILE="$HOME/clawd/logs/feishu-knowledge.log"
KNOWLEDGE_SCRIPT="$HOME/clawd/scripts/knowledge-record.sh"

mkdir -p "$(dirname "$LOG_FILE")"

# 日志函数
log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" >> "$LOG_FILE"
}

# 解析消息类型
parse_message_type() {
    local message="$1"
    
    # 转换为小写便于匹配
    local lower_msg=$(echo "$message" | tr '[:upper:]' '[:lower:]')
    
    # 检查关键词
    case "$lower_msg" in
        *记录灵感*|*灵感:*|*想法:*|*突然想到*)
            echo "inspiration"
            ;;
        *收藏文章*|*文章收藏*|*保存文章*|*这篇文章*)
            echo "article"
            ;;
        *学习笔记*|*学习总结*|*学习:*|*笔记:*)
            echo "learning"
            ;;
        *项目想法*|*项目:*|*开发*|*构建*)
            echo "project"
            ;;
        *工作记录*|*工作总结*|*工作:*|*完成*)
            echo "work"
            ;;
        *)
            # 默认类型
            echo "inspiration"
            ;;
    esac
}

# 提取标题
extract_title() {
    local message="$1"
    local type="$2"
    
    # 尝试从消息中提取标题
    # 模式1：包含"："的情况
    if [[ "$message" =~ .*[：:]\s*(.+)$ ]]; then
        echo "${BASH_REMATCH[1]}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
    # 模式2：包含引号的情况
    elif [[ "$message" =~ ["'"'"'"](.+?)["'"'"'"]] ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        # 生成默认标题
        local timestamp=$(date '+%m%d%H%M')
        case "$type" in
            inspiration) echo "灵感记录_$timestamp" ;;
            article) echo "文章收藏_$timestamp" ;;
            learning) echo "学习笔记_$timestamp" ;;
            project) echo "项目想法_$timestamp" ;;
            work) echo "工作记录_$timestamp" ;;
            *) echo "记录_$timestamp" ;;
        esac
    fi
}

# 提取内容
extract_content() {
    local message="$1"
    local type="$2"
    
    # 移除可能的标题部分
    local content="$message"
    
    # 如果包含"："，取后面的内容
    if [[ "$message" =~ .*[：:]\s*(.+)$ ]]; then
        content="${BASH_REMATCH[1]}"
    fi
    
    # 移除可能的引导词
    case "$type" in
        inspiration)
            content=$(echo "$content" | sed 's/^记录灵感//;s/^灵感//;s/^想法//')
            ;;
        article)
            content=$(echo "$content" | sed 's/^收藏文章//;s/^文章//;s/^保存//')
            ;;
        learning)
            content=$(echo "$content" | sed 's/^学习笔记//;s/^学习//;s/^笔记//')
            ;;
        project)
            content=$(echo "$content" | sed 's/^项目想法//;s/^项目//;s/^开发//;s/^构建//')
            ;;
        work)
            content=$(echo "$content" | sed 's/^工作记录//;s/^工作//;s/^完成//')
            ;;
    esac
    
    # 清理空格
    content=$(echo "$content" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    # 如果内容为空，使用原始消息
    if [ -z "$content" ]; then
        content="$message"
    fi
    
    echo "$content"
}

# 智能分类
smart_category() {
    local content="$1"
    local type="$2"
    
    local lower_content=$(echo "$content" | tr '[:upper:]' '[:lower:]')
    
    # AI技术相关
    if [[ "$lower_content" =~ (ai|人工智能|机器学习|深度学习|自然语言处理|clawdbot|agent) ]]; then
        echo "AI技术"
    # 学习相关
    elif [[ "$lower_content" =~ (学习|教程|课程|读书|教育) ]]; then
        echo "学习"
    # 工作相关
    elif [[ "$lower_content" =~ (工作|任务|项目|开发|代码) ]]; then
        echo "工作"
    else
        # 根据类型默认分类
        case "$type" in
            inspiration) echo "灵感" ;;
            article) echo "文章" ;;
            learning) echo "学习" ;;
            project) echo "项目" ;;
            work) echo "工作" ;;
            *) echo "其他" ;;
        esac
    fi
}

# 智能标签
smart_tags() {
    local content="$1"
    local type="$2"
    
    local tags=""
    local lower_content=$(echo "$content" | tr '[:upper:]' '[:lower:]')
    
    # 添加类型标签
    case "$type" in
        inspiration) tags="灵感,想法" ;;
        article) tags="文章,收藏" ;;
        learning) tags="学习,笔记" ;;
        project) tags="项目,规划" ;;
        work) tags="工作,记录" ;;
    esac
    
    # 内容关键词标签
    if [[ "$lower_content" =~ ai|人工智能 ]]; then
        tags="$tags,AI"
    fi
    if [[ "$lower_content" =~ 机器学习 ]]; then
        tags="$tags,机器学习"
    fi
    if [[ "$lower_content" =~ 深度学习 ]]; then
        tags="$tags,深度学习"
    fi
    if [[ "$lower_content" =~ clawdbot ]]; then
        tags="$tags,Clawdbot"
    fi
    if [[ "$lower_content" =~ agent ]]; then
        tags="$tags,Agent"
    fi
    if [[ "$lower_content" =~ 技术|科技 ]]; then
        tags="$tags,技术"
    fi
    if [[ "$lower_content" =~ 学习|教育 ]]; then
        tags="$tags,学习"
    fi
    
    # 清理标签，移除重复和空标签
    echo "$tags" | tr ',' '\n' | sort -u | grep -v '^$' | tr '\n' ',' | sed 's/,$//'
}

# 处理飞书消息
process_feishu_message() {
    local message="$1"
    
    log "收到飞书消息：$message"
    
    # 解析消息类型
    local type
    type=$(parse_message_type "$message")
    log "解析类型：$type"
    
    # 提取标题
    local title
    title=$(extract_title "$message" "$type")
    log "提取标题：$title"
    
    # 提取内容
    local content
    content=$(extract_content "$message" "$type")
    log "提取内容：$content"
    
    # 智能分类
    local category
    category=$(smart_category "$content" "$type")
    log "智能分类：$category"
    
    # 智能标签
    local tags
    tags=$(smart_tags "$content" "$type")
    log "智能标签：$tags"
    
    # 调用知识记录脚本
    local result
    result=$("$KNOWLEDGE_SCRIPT" \
        --type "$type" \
        --title "$title" \
        --category "$category" \
        --tags "$tags" \
        "$content" 2>&1)
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        log "处理成功：$result"
        echo "✅ 知识记录成功！"
        echo "$result"
        return 0
    else
        log "处理失败：$result"
        echo "❌ 知识记录失败：$result"
        return 1
    fi
}

# 显示使用说明
show_usage() {
    cat <<EOF
飞书知识处理器

用法: $0 "飞书消息内容"

示例:
  $0 "记录灵感：AI Agent应该有个性化记忆"
  $0 "收藏文章：关于Clawdbot扩展的最新研究"
  $0 "学习笔记：机器学习基础概念总结"
  $0 "项目想法：开发智能知识管理工具"
  $0 "工作记录：今天完成了飞书安全配置"

支持的自然语言格式:
  - 记录灵感：XXX
  - 灵感：XXX
  - 收藏文章：XXX
  - 学习笔记：XXX
  - 项目想法：XXX
  - 工作记录：XXX
  - 直接描述内容（自动识别类型）
EOF
}

# 主函数
main() {
    if [ $# -eq 0 ]; then
        show_usage
        return 1
    fi
    
    # 合并所有参数为一条消息
    local message="$*"
    
    # 处理消息
    process_feishu_message "$message"
    
    return $?
}

# 执行主函数
main "$@"