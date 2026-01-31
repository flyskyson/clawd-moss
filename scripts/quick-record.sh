#!/bin/bash
# quick-record.sh
# 快速记录 - 最简单可靠的版本

LOG_FILE="$HOME/clawd/logs/quick-record.log"
KNOWLEDGE_DIR="$HOME/clawd/knowledge"

mkdir -p "$(dirname "$LOG_FILE")"

# 主记录函数
record() {
    local message="$1"
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    
    # 简单类型判断
    local record_type="inspiration"
    local category="其他"
    
    if [[ "$message" =~ 灵感|想法 ]]; then
        record_type="inspiration"
    elif [[ "$message" =~ 文章|收藏 ]]; then
        record_type="article"
    elif [[ "$message" =~ 学习|笔记 ]]; then
        record_type="learning"
    elif [[ "$message" =~ 项目 ]]; then
        record_type="project"
    elif [[ "$message" =~ 工作 ]]; then
        record_type="work"
    fi
    
    # 简单分类
    if [[ "$message" =~ AI|技术|代码 ]]; then
        category="AI技术"
    elif [[ "$message" =~ 学习 ]]; then
        category="学习"
    fi
    
    # 提取内容
    local content="$message"
    content=$(echo "$content" | sed 's/^记录灵感[：:]\s*//;s/^灵感[：:]\s*//')
    content=$(echo "$content" | sed 's/^收藏文章[：:]\s*//;s/^文章[：:]\s*//')
    content=$(echo "$content" | sed 's/^学习笔记[：:]\s*//;s/^学习[：:]\s*//')
    
    # 生成文件名（使用时间戳）
    local filename="${record_type}_${timestamp}.md"
    
    # 确定保存目录
    local save_dir="$KNOWLEDGE_DIR"
    case "$record_type" in
        inspiration) save_dir="$KNOWLEDGE_DIR/灵感记录" ;;
        article) save_dir="$KNOWLEDGE_DIR/文章收藏" ;;
        learning) save_dir="$KNOWLEDGE_DIR/学习笔记" ;;
        project) save_dir="$KNOWLEDGE_DIR/项目想法" ;;
        work) save_dir="$KNOWLEDGE_DIR/工作记录" ;;
    esac
    
    mkdir -p "$save_dir"
    local filepath="$save_dir/$filename"
    
    # 写入文件
    cat > "$filepath" << 'MARKDOWN'
---
title: "Quick Note"
date: DATE_PLACEHOLDER
type: TYPE_PLACEHOLDER
category: CATEGORY_PLACEHOLDER
created: CREATED_PLACEHOLDER
---

# Quick Note

## Content
CONTENT_PLACEHOLDER

## Metadata
- Type: TYPE_PLACEHOLDER
- Category: CATEGORY_PLACEHOLDER
- Created: CREATED_PLACEHOLDER
MARKDOWN
    
    # 替换占位符
    local current_date=$(date '+%Y-%m-%d')
    local current_time=$(date '+%Y-%m-%d %H:%M:%S')
    
    # 使用sed替换
    sed -i '' "s/DATE_PLACEHOLDER/$current_date/g" "$filepath"
    sed -i '' "s/CREATED_PLACEHOLDER/$current_time/g" "$filepath"
    sed -i '' "s/TYPE_PLACEHOLDER/$record_type/g" "$filepath"
    sed -i '' "s/CATEGORY_PLACEHOLDER/$category/g" "$filepath"
    sed -i '' "s|CONTENT_PLACEHOLDER|$content|g" "$filepath"
    
    # 获取文件大小
    local size=$(wc -c < "$filepath" 2>/dev/null || echo "0")
    
    echo "✅ 已记录到：$filepath"
    echo "📊 类型：$record_type | 分类：$category | 大小：$size 字节"
}

# 执行
if [ $# -eq 0 ]; then
    echo "用法：$0 \"您的消息内容\""
else
    record "$*"
fi