#!/bin/bash
# test-knowledge-record.sh
# 知识记录测试脚本

KNOWLEDGE_DIR="$HOME/clawd/knowledge"

# 显示测试说明
show_test_instructions() {
    cat <<EOF
📝 知识记录测试说明

支持的消息格式：
1. 灵感记录：记录灵感：您的想法内容
2. 文章收藏：收藏文章：文章标题和内容
3. 学习笔记：学习笔记：学习内容总结
4. 项目想法：项目想法：项目规划和想法
5. 工作记录：工作记录：工作内容和总结

测试步骤：
1. 发送测试消息
2. 系统自动处理
3. 查看生成的文件
4. 验证内容正确性

文件保存位置：$KNOWLEDGE_DIR/
EOF
}

# 处理测试消息
process_test_message() {
    local message="$1"
    
    echo "🧪 处理测试消息：$message"
    echo ""
    
    # 简单类型判断
    if [[ "$message" =~ 记录灵感 ]]; then
        echo "📌 类型：灵感记录"
        local type="inspiration"
        local dir="灵感记录"
    elif [[ "$message" =~ 收藏文章 ]]; then
        echo "📌 类型：文章收藏"
        local type="article"
        local dir="文章收藏"
    elif [[ "$message" =~ 学习笔记 ]]; then
        echo "📌 类型：学习笔记"
        local type="learning"
        local dir="学习笔记"
    elif [[ "$message" =~ 项目想法 ]]; then
        echo "📌 类型：项目想法"
        local type="project"
        local dir="项目想法"
    elif [[ "$message" =~ 工作记录 ]]; then
        echo "📌 类型：工作记录"
        local type="work"
        local dir="工作记录"
    else
        echo "📌 类型：自动识别为灵感记录"
        local type="inspiration"
        local dir="灵感记录"
    fi
    
    # 提取内容
    local content="$message"
    content=$(echo "$content" | sed 's/^记录灵感[：:]\s*//;s/^灵感[：:]\s*//')
    content=$(echo "$content" | sed 's/^收藏文章[：:]\s*//;s/^文章[：:]\s*//')
    content=$(echo "$content" | sed 's/^学习笔记[：:]\s*//;s/^学习[：:]\s*//')
    content=$(echo "$content" | sed 's/^项目想法[：:]\s*//;s/^项目[：:]\s*//')
    content=$(echo "$content" | sed 's/^工作记录[：:]\s*//;s/^工作[：:]\s*//')
    
    # 生成文件名
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local filename="test_${type}_${timestamp}.md"
    local filepath="$KNOWLEDGE_DIR/$dir/$filename"
    
    # 创建测试文件
    mkdir -p "$KNOWLEDGE_DIR/$dir"
    
    cat > "$filepath" <<EOF
# 测试记录 - $type

## 测试时间
$(date '+%Y-%m-%d %H:%M:%S')

## 原始消息
$message

## 处理结果
- 类型：$type
- 目录：$dir
- 文件名：$filename
- 处理时间：$(date '+%H:%M:%S')

## 测试说明
这是知识管理系统的测试记录，用于验证功能正常工作。

---

*知识管理系统测试记录*
EOF
    
    echo "✅ 测试记录已创建！"
    echo ""
    echo "📄 文件信息："
    echo "   路径：$filepath"
    echo "   大小：$(wc -c < "$filepath") 字节"
    echo "   时间：$(date '+%H:%M:%S')"
    echo ""
    echo "📁 查看命令："
    echo "   cat $filepath"
    echo "   ls -la $KNOWLEDGE_DIR/$dir/"
}

# 主函数
main() {
    if [ $# -eq 0 ]; then
        show_test_instructions
        return 0
    fi
    
    local message="$*"
    process_test_message "$message"
}

main "$@"