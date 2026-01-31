#!/bin/bash
# knowledge-record-simple.sh
# 简化版知识记录 - 专注于可靠性

LOG_FILE="$HOME/clawd/logs/knowledge-simple.log"
KNOWLEDGE_DIR="$HOME/clawd/knowledge"

mkdir -p "$(dirname "$LOG_FILE")"

# 日志函数
log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" >> "$LOG_FILE"
}

# 简单类型识别
simple_type() {
    local msg="$1"
    
    if [[ "$msg" =~ 灵感|想法|想到 ]]; then
        echo "inspiration"
    elif [[ "$msg" =~ 文章|收藏|阅读 ]]; then
        echo "article"
    elif [[ "$msg" =~ 学习|笔记|总结 ]]; then
        echo "learning"
    elif [[ "$msg" =~ 项目|开发|构建 ]]; then
        echo "project"
    elif [[ "$msg" =~ 工作|完成|处理 ]]; then
        echo "work"
    else
        echo "inspiration"
    fi
}

# 简单内容提取
simple_content() {
    local msg="$1"
    
    # 移除"记录灵感："等前缀
    local content="$msg"
    content=$(echo "$content" | sed 's/^记录灵感[：:]\s*//')
    content=$(echo "$content" | sed 's/^灵感[：:]\s*//')
    content=$(echo "$content" | sed 's/^想法[：:]\s*//')
    content=$(echo "$content" | sed 's/^收藏文章[：:]\s*//')
    content=$(echo "$content" | sed 's/^文章[：:]\s*//')
    content=$(echo "$content" | sed 's/^学习笔记[：:]\s*//')
    content=$(echo "$content" | sed 's/^学习[：:]\s*//')
    
    echo "$content" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# 简单标题生成
simple_title() {
    local content="$1"
    local type="$2"
    
    # 取内容前15个字符作为标题
    local title=$(echo "$content" | cut -c1-15)
    
    # 如果太短，使用类型+时间戳
    if [ ${#title} -lt 5 ]; then
        local timestamp=$(date '+%m%d%H%M')
        case "$type" in
            inspiration) echo "灵感记录$timestamp" ;;
            article) echo "文章收藏$timestamp" ;;
            learning) echo "学习笔记$timestamp" ;;
            project) echo "项目想法$timestamp" ;;
            work) echo "工作记录$timestamp" ;;
        esac
    else
        echo "${title}..."
    fi
}

# 创建简单的Markdown文件
create_simple_note() {
    local type="$1"
    local title="$2"
    local content="$3"
    local category="$4"
    
    local current_date=$(date '+%Y-%m-%d %H:%M:%S')
    
    # 确定保存目录
    local save_dir
    case "$type" in
        inspiration) save_dir="$KNOWLEDGE_DIR/灵感记录" ;;
        article) save_dir="$KNOWLEDGE_DIR/文章收藏" ;;
        learning) save_dir="$KNOWLEDGE_DIR/学习笔记" ;;
        project) save_dir="$KNOWLEDGE_DIR/项目想法" ;;
        work) save_dir="$KNOWLEDGE_DIR/工作记录" ;;
        *) save_dir="$KNOWLEDGE_DIR/灵感记录" ;;
    esac
    
    mkdir -p "$save_dir"
    
    # 生成文件名（避免中文字符）
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    # 使用英文字母或简单时间戳作为文件名
    local safe_title=$(echo "$title" | tr -cd '[:alnum:]' | head -c 10)
    if [ -z "$safe_title" ]; then
        safe_title="note"
    fi
    local filename="${type}_${safe_title}_${timestamp}.md"
    local filepath="$save_dir/$filename"
    
    # 创建文件内容
    cat > "$filepath" <<EOF
---
title: "$title"
date: $(date '+%Y-%m-%d')
type: $type
category: ${category:-其他}
tags: [$type]
created: $(date '+%Y-%m-%d %H:%M:%S')
---

# $title

## 💡 内容
$content

## 📅 记录时间
$current_date

---

*由知识管理系统自动生成*
EOF
    
    echo "$filepath"
}

# 主函数
main() {
    local message="$1"
    
    if [ -z "$message" ]; then
        echo "用法：$0 \"消息内容\""
        return 1
    fi
    
    log "收到消息：$message"
    
    # 识别类型
    local type
    type=$(simple_type "$message")
    log "类型：$type"
    
    # 提取内容
    local content
    content=$(simple_content "$message")
    log "内容：$content"
    
    # 生成标题
    local title
    title=$(simple_title "$content" "$type")
    log "标题：$title"
    
    # 简单分类
    local category
    if [[ "$message" =~ AI|机器学习|深度学习|Clawdbot ]]; then
        category="AI技术"
    elif [[ "$message" =~ 学习|教育 ]]; then
        category="学习"
    else
        category="其他"
    fi
    
    # 创建文件
    local filepath
    filepath=$(create_simple_note "$type" "$title" "$content" "$category")
    
    if [ -f "$filepath" ]; then
        log "成功保存：$filepath"
        local size=$(wc -c < "$filepath")
        echo "✅ 知识已记录！"
        echo "📄 文件：$filepath"
        echo "📊 信息："
        echo "   类型：$type"
        echo "   标题：$title"
        echo "   分类：$category"
        echo "   大小：$size 字节"
        echo "   时间：$(date '+%H:%M:%S')"
        return 0
    else
        log "保存失败"
        echo "❌ 保存失败"
        return 1
    fi
}

main "$@"