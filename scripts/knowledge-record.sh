#!/bin/bash
# knowledge-record.sh
# 知识记录处理脚本 - 基础版本
# 功能：处理飞书记录请求，保存到知识库

LOG_FILE="$HOME/clawd/logs/knowledge-record.log"
KNOWLEDGE_DIR="$HOME/clawd/knowledge"
TEMP_DIR="$HOME/clawd/temp/knowledge"

mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$TEMP_DIR"

# 日志函数
log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" >> "$LOG_FILE"
}

# 显示帮助
show_help() {
    cat <<EOF
知识记录工具 - 基础版本

用法: $0 [选项] <内容>

选项:
  -t, --type TYPE     记录类型 (inspiration/article/learning/project/work)
  -c, --category CAT  分类目录
  --title TITLE       标题
  --tags TAGS         标签 (逗号分隔)
  --help             显示帮助

示例:
  $0 -t inspiration "AI Agent应该有个性化记忆"
  $0 -t article --title "Clawdbot扩展研究" "文章内容..."
  $0 --type learning --category "AI技术" "机器学习基础学习笔记"

支持的类型:
  inspiration - 灵感记录
  article     - 文章收藏
  learning    - 学习笔记
  project     - 项目想法
  work        - 工作记录
EOF
}

# 根据类型选择模板
get_template_path() {
    local type="$1"
    
    case "$type" in
        inspiration)
            echo "$KNOWLEDGE_DIR/灵感记录/灵感记录模板.md"
            ;;
        article)
            echo "$KNOWLEDGE_DIR/文章收藏/文章收藏模板.md"
            ;;
        learning)
            echo "$KNOWLEDGE_DIR/学习笔记/学习笔记模板.md"
            ;;
        project)
            echo "$KNOWLEDGE_DIR/项目想法/项目想法模板.md"
            ;;
        work)
            echo "$KNOWLEDGE_DIR/工作记录/工作记录模板.md"
            ;;
        *)
            echo "$KNOWLEDGE_DIR/灵感记录/灵感记录模板.md"
            ;;
    esac
}

# 根据类型选择保存目录
get_save_dir() {
    local type="$1"
    local category="$2"
    
    case "$type" in
        inspiration)
            echo "$KNOWLEDGE_DIR/灵感记录"
            ;;
        article)
            echo "$KNOWLEDGE_DIR/文章收藏"
            ;;
        learning)
            if [ -n "$category" ]; then
                echo "$KNOWLEDGE_DIR/学习笔记/$category"
            else
                echo "$KNOWLEDGE_DIR/学习笔记"
            fi
            ;;
        project)
            echo "$KNOWLEDGE_DIR/项目想法"
            ;;
        work)
            echo "$KNOWLEDGE_DIR/工作记录"
            ;;
        *)
            echo "$KNOWLEDGE_DIR/灵感记录"
            ;;
    esac
}

# 生成文件名
generate_filename() {
    local type="$1"
    local title="$2"
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    
    # 如果标题为空，使用类型+时间戳
    if [ -z "$title" ]; then
        echo "${type}_${timestamp}.md"
    else
        # 清理标题中的特殊字符
        local clean_title=$(echo "$title" | tr -cd '[:alnum:][:space:]' | tr ' ' '_' | tr '[:upper:]' '[:lower:]')
        echo "${clean_title}_${timestamp}.md"
    fi
}

# 填充模板
fill_template() {
    local template_path="$1"
    local content="$2"
    local title="$3"
    local tags="$4"
    local category="$5"
    local type="$6"
    
    local current_date=$(date '+%Y-%m-%d')
    local current_time=$(date '+%H:%M:%S')
    
    # 读取模板内容
    local template_content
    template_content=$(cat "$template_path")
    
    # 替换模板变量
    local filled_content="$template_content"
    
    # 替换标题
    if [ -n "$title" ]; then
        filled_content=$(echo "$filled_content" | sed "s/{{灵感标题}}/$title/g")
        filled_content=$(echo "$filled_content" | sed "s/{{文章标题}}/$title/g")
        filled_content=$(echo "$filled_content" | sed "s/{{学习主题}}/$title/g")
        filled_content=$(echo "$filled_content" | sed "s/{{项目名称}}/$title/g")
        filled_content=$(echo "$filled_content" | sed "s/{{工作主题}}/$title/g")
        filled_content=$(echo "$filled_content" | sed "s/{{技术主题}}/$title/g")
    else
        # 使用默认标题
        local default_title
        case "$type" in
            inspiration) default_title="未命名灵感" ;;
            article) default_title="未命名文章" ;;
            learning) default_title="未命名学习笔记" ;;
            project) default_title="未命名项目" ;;
            work) default_title="未命名工作记录" ;;
            *) default_title="未命名记录" ;;
        esac
        filled_content=$(echo "$filled_content" | sed "s/{{[^}]*标题}}/$default_title/g")
        filled_content=$(echo "$filled_content" | sed "s/{{学习主题}}/$default_title/g")
        filled_content=$(echo "$filled_content" | sed "s/{{项目名称}}/$default_title/g")
        filled_content=$(echo "$filled_content" | sed "s/{{工作主题}}/$default_title/g")
        filled_content=$(echo "$filled_content" | sed "s/{{技术主题}}/$default_title/g")
    fi
    
    # 替换日期和时间
    filled_content=$(echo "$filled_content" | sed "s/{{日期}}/$current_date/g")
    filled_content=$(echo "$filled_content" | sed "s/{{记录日期}}/$current_date/g")
    filled_content=$(echo "$filled_content" | sed "s/{{创建日期}}/$current_date/g")
    filled_content=$(echo "$filled_content" | sed "s/{{学习日期}}/$current_date/g")
    filled_content=$(echo "$filled_content" | sed "s/{{阅读日期}}/$current_date/g")
    filled_content=$(echo "$filled_content" | sed "s/{{创建时间}}/$current_time/g")
    filled_content=$(echo "$filled_content" | sed "s/{{开始时间}}/$current_time/g")
    
    # 替换标签
    if [ -n "$tags" ]; then
        # 将逗号分隔的标签转换为YAML数组格式
        local yaml_tags="["
        IFS=',' read -ra TAG_ARRAY <<< "$tags"
        for tag in "${TAG_ARRAY[@]}"; do
            yaml_tags="$yaml_tags\"$tag\", "
        done
        yaml_tags="${yaml_tags%, }]"
        
        filled_content=$(echo "$filled_content" | sed "s/{{标签1}}, {{标签2}}/$yaml_tags/g")
        filled_content=$(echo "$filled_content" | sed "s/{{主题标签}}/$yaml_tags/g")
        filled_content=$(echo "$filled_content" | sed "s/{{技术标签}}/$yaml_tags/g")
        filled_content=$(echo "$filled_content" | sed "s/{{项目标签}}/$yaml_tags/g")
        filled_content=$(echo "$filled_content" | sed "s/{{工作标签}}/$yaml_tags/g")
    fi
    
    # 替换分类
    if [ -n "$category" ]; then
        filled_content=$(echo "$filled_content" | sed "s/{{分类}}/$category/g")
        filled_content=$(echo "$filled_content" | sed "s/{{项目分类}}/$category/g")
        filled_content=$(echo "$filled_content" | sed "s/{{工作分类}}/$category/g")
        filled_content=$(echo "$filled_content" | sed "s/{{具体分类}}/$category/g")
    fi
    
    # 替换内容
    filled_content=$(echo "$filled_content" | sed "s/{{详细描述}}/$content/g")
    filled_content=$(echo "$filled_content" | sed "s/{{文章核心内容摘要}}/$content/g")
    
    echo "$filled_content"
}

# 主函数
main() {
    # 解析参数
    local type="inspiration"
    local category=""
    local title=""
    local tags=""
    local content=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--type)
                type="$2"
                shift 2
                ;;
            -c|--category)
                category="$2"
                shift 2
                ;;
            --title)
                title="$2"
                shift 2
                ;;
            --tags)
                tags="$2"
                shift 2
                ;;
            --help)
                show_help
                return 0
                ;;
            -*)
                echo "错误：未知选项 $1"
                show_help
                return 1
                ;;
            *)
                content="$1"
                shift
                ;;
        esac
    done
    
    if [ -z "$content" ]; then
        echo "错误：需要提供内容"
        show_help
        return 1
    fi
    
    log "开始处理记录请求：type=$type, category=$category, title=$title"
    
    # 获取模板路径
    local template_path
    template_path=$(get_template_path "$type")
    
    if [ ! -f "$template_path" ]; then
        log "错误：模板文件不存在：$template_path"
        echo "错误：模板文件不存在"
        return 1
    fi
    
    # 获取保存目录
    local save_dir
    save_dir=$(get_save_dir "$type" "$category")
    
    # 创建目录（如果不存在）
    mkdir -p "$save_dir"
    
    # 生成文件名
    local filename
    filename=$(generate_filename "$type" "$title")
    local filepath="$save_dir/$filename"
    
    # 填充模板
    local filled_content
    filled_content=$(fill_template "$template_path" "$content" "$title" "$tags" "$category" "$type")
    
    # 保存文件
    echo "$filled_content" > "$filepath"
    
    if [ $? -eq 0 ]; then
        log "成功保存记录到：$filepath"
        echo "✅ 记录已保存到：$filepath"
        echo "📊 文件信息："
        echo "   类型：$type"
        echo "   标题：${title:-自动生成}"
        echo "   分类：${category:-默认分类}"
        echo "   标签：${tags:-无}"
        echo "   大小：$(wc -c < "$filepath") 字节"
        echo "   时间：$(date '+%Y-%m-%d %H:%M:%S')"
        return 0
    else
        log "错误：保存文件失败：$filepath"
        echo "❌ 保存文件失败"
        return 1
    fi
}

# 执行主函数
main "$@"