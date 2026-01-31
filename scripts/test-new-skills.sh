#!/bin/bash
# test-new-skills.sh
# 测试新安装的Clawdbot技能

echo "🧪 开始测试新安装技能..."
echo "测试时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 创建测试结果文件
TEST_RESULTS="reports/skills-test-results-$(date +%Y%m%d_%H%M%S).json"
mkdir -p "$(dirname "$TEST_RESULTS")"

# 初始化测试结果
test_results=()

# 函数：记录测试结果
record_test() {
    local skill_name="$1"
    local test_item="$2"
    local status="$3"
    local message="$4"
    
    test_results+=("{\"skill\":\"$skill_name\",\"test\":\"$test_item\",\"status\":\"$status\",\"message\":\"$message\",\"timestamp\":\"$(date -Iseconds)\"}")
    
    if [ "$status" = "PASS" ]; then
        echo "✅ $skill_name - $test_item: $message"
    elif [ "$status" = "WARN" ]; then
        echo "⚠️  $skill_name - $test_item: $message"
    else
        echo "❌ $skill_name - $test_item: $message"
    fi
}

# 函数：测试技能文件
test_skill_file() {
    local skill_name="$1"
    local skill_path="$2"
    
    if [ -f "$skill_path" ]; then
        local line_count=$(wc -l < "$skill_path")
        local has_frontmatter=$(grep -c "^---$" "$skill_path" || echo 0)
        
        if [ $line_count -gt 10 ]; then
            if [ $has_frontmatter -ge 2 ]; then
                record_test "$skill_name" "文件完整性" "PASS" "SKILL.md文件完整，$line_count行，包含Frontmatter"
            else
                record_test "$skill_name" "文件完整性" "WARN" "SKILL.md文件存在但可能格式不标准"
            fi
        else
            record_test "$skill_name" "文件完整性" "FAIL" "SKILL.md文件过小或可能损坏"
        fi
    else
        record_test "$skill_name" "文件存在性" "FAIL" "SKILL.md文件不存在"
    fi
}

# 函数：测试命令可用性
test_command() {
    local skill_name="$1"
    local command_name="$2"
    local test_type="$3"
    
    if command -v "$command_name" >/dev/null 2>&1; then
        local version=$($command_name --version 2>/dev/null | head -1 || echo "未知版本")
        record_test "$skill_name" "$test_type" "PASS" "$command_name已安装: $version"
        return 0
    else
        record_test "$skill_name" "$test_type" "WARN" "$command_name未安装，需要安装后才能使用"
        return 1
    fi
}

echo "📋 测试1: 技能文件完整性测试"
echo "============================="

# 测试GitHub技能
test_skill_file "github" "$HOME/.openclaw/skills/github/SKILL.md"

# 测试搜索技能
test_skill_file "brave-search" "$HOME/.openclaw/skills/brave-search/SKILL.md"
test_skill_file "web-search" "$HOME/.openclaw/skills/web-search/SKILL.md"

# 测试笔记技能
test_skill_file "notes-pkm" "$HOME/.openclaw/skills/notes-pkm/SKILL.md"
test_skill_file "note-taking" "$HOME/.openclaw/skills/note-taking/SKILL.md"

# 测试监控技能
test_skill_file "process-watch" "$HOME/.openclaw/skills/process-watch/SKILL.md"
test_skill_file "system-monitor" "$HOME/.openclaw/skills/system-monitor-community/SKILL.md"

echo ""
echo "🔧 测试2: 依赖工具可用性测试"
echo "============================="

# 测试GitHub CLI
test_command "github" "gh" "GitHub CLI"

# 测试Node.js (搜索技能可能需要)
test_command "brave-search" "node" "Node.js运行时"
test_command "brave-search" "npm" "Node包管理器"

# 测试系统工具
test_command "process-watch" "ps" "进程查看工具"
test_command "system-monitor" "top" "系统监控工具"

echo ""
echo "🔑 测试3: 环境配置测试"
echo "======================"

# 检查Brave Search API配置
if [ -n "${BRAVE_API_KEY}" ]; then
    if [ "${BRAVE_API_KEY}" = "dummy_key_for_test" ]; then
        record_test "brave-search" "API配置" "WARN" "Brave API密钥为测试值，需要替换为真实密钥"
    else
        record_test "brave-search" "API配置" "PASS" "Brave API密钥已配置"
    fi
else
    record_test "brave-search" "API配置" "FAIL" "Brave API密钥未配置"
fi

# 检查GitHub配置
if [ -n "${GITHUB_TOKEN}" ]; then
    record_test "github" "API配置" "PASS" "GitHub令牌已配置"
else
    record_test "github" "API配置" "WARN" "GitHub令牌未配置，部分功能可能受限"
fi

echo ""
echo "🚀 测试4: 功能模拟测试"
echo "======================"

# 模拟GitHub技能使用
echo "模拟GitHub技能命令..."
GITHUB_COMMANDS=(
    "gh repo view --help"
    "gh issue list --help"
    "gh pr create --help"
)

for cmd in "${GITHUB_COMMANDS[@]}"; do
    cmd_name=$(echo "$cmd" | cut -d' ' -f1-2)
    record_test "github" "命令模拟" "INFO" "支持命令: $cmd_name"
done

# 模拟搜索技能使用
record_test "brave-search" "功能模拟" "INFO" "支持命令: brave-search '查询内容'"
record_test "web-search" "功能模拟" "INFO" "支持命令: web-search '查询内容'"

# 模拟笔记技能使用
record_test "notes-pkm" "功能模拟" "INFO" "支持命令: notes-pkm [categorize|search|list]"
record_test "note-taking" "功能模拟" "INFO" "支持命令: note-taking '内容'"

# 模拟监控技能使用
record_test "process-watch" "功能模拟" "INFO" "支持命令: process-watch [--cpu|--memory|--disk|--network]"
record_test "system-monitor" "功能模拟" "INFO" "支持命令: system-monitor [--all|--quick|--alert]"

echo ""
echo "📊 生成测试报告..."
echo "=================="

# 计算统计
total_tests=${#test_results[@]}
pass_count=0
warn_count=0
fail_count=0
info_count=0

for result in "${test_results[@]}"; do
    status=$(echo "$result" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
    case "$status" in
        "PASS") ((pass_count++)) ;;
        "WARN") ((warn_count++)) ;;
        "FAIL") ((fail_count++)) ;;
        "INFO") ((info_count++)) ;;
    esac
done

# 生成JSON报告
echo "[" > "$TEST_RESULTS"
for i in "${!test_results[@]}"; do
    echo "${test_results[$i]}" >> "$TEST_RESULTS"
    if [ $i -lt $((total_tests - 1)) ]; then
        echo "," >> "$TEST_RESULTS"
    fi
done
echo "]" >> "$TEST_RESULTS"

# 生成摘要报告
SUMMARY_REPORT="reports/skills-test-summary-$(date +%Y%m%d_%H%M%S).md"
cat > "$SUMMARY_REPORT" << EOF
# 新安装技能测试报告
## 测试时间: $(date '+%Y-%m-%d %H:%M:%S')
## 测试环境: $(uname -s) $(uname -r)

## 📊 测试统计
- 总测试项: $total_tests
- ✅ 通过: $pass_count
- ⚠️  警告: $warn_count  
- ❌ 失败: $fail_count
- ℹ️  信息: $info_count

## 🎯 测试结论

EOF

if [ $fail_count -eq 0 ]; then
    if [ $warn_count -eq 0 ]; then
        echo "**✅ 所有测试通过！技能可以批准使用。**" >> "$SUMMARY_REPORT"
        APPROVAL_STATUS="✅ 完全批准"
    else
        echo "**⚠️  测试基本通过，但有$warn_count个警告需要注意。**" >> "$SUMMARY_REPORT"
        APPROVAL_STATUS="⚠️  有条件批准"
    fi
else
    echo "**❌ 测试失败，有$fail_count个问题需要解决。**" >> "$SUMMARY_REPORT"
    APPROVAL_STATUS="❌ 暂不批准"
fi

cat >> "$SUMMARY_REPORT" << EOF

## 🔧 需要解决的问题

EOF

# 添加失败和警告项
for result in "${test_results[@]}"; do
    status=$(echo "$result" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
    if [ "$status" = "FAIL" ] || [ "$status" = "WARN" ]; then
        skill=$(echo "$result" | grep -o '"skill":"[^"]*"' | cut -d'"' -f4)
        test_item=$(echo "$result" | grep -o '"test":"[^"]*"' | cut -d'"' -f4)
        message=$(echo "$result" | grep -o '"message":"[^"]*"' | cut -d'"' -f4)
        
        if [ "$status" = "FAIL" ]; then
            echo "- ❌ **$skill - $test_item**: $message" >> "$SUMMARY_REPORT"
        else
            echo "- ⚠️  **$skill - $test_item**: $message" >> "$SUMMARY_REPORT"
        fi
    fi
done

cat >> "$SUMMARY_REPORT" << EOF

## 🚀 批准使用建议

基于测试结果，建议：

EOF

case "$APPROVAL_STATUS" in
    "✅ 完全批准")
        echo "1. **立即批准使用所有技能**" >> "$SUMMARY_REPORT"
        echo "2. 开始集成到现有系统" >> "$SUMMARY_REPORT"
        echo "3. 监控技能使用效果" >> "$SUMMARY_REPORT"
        ;;
    "⚠️  有条件批准")
        echo "1. **有条件批准使用**" >> "$SUMMARY_REPORT"
        echo "2. 先解决警告问题" >> "$SUMMARY_REPORT"
        echo "3. 然后全面集成使用" >> "$SUMMARY_REPORT"
        ;;
    "❌ 暂不批准")
        echo "1. **暂不批准使用**" >> "$SUMMARY_REPORT"
        echo "2. 必须先解决失败问题" >> "$SUMMARY_REPORT"
        echo "3. 重新测试后再决定" >> "$SUMMARY_REPORT"
        ;;
esac

cat >> "$SUMMARY_REPORT" << EOF

## 📁 测试文件
- 详细测试结果: \`$TEST_RESULTS\`
- 本摘要报告: \`$SUMMARY_REPORT\`

## 🔄 下一步行动
1. 根据批准建议采取行动
2. 配置必要的依赖和环境
3. 开始技能集成开发
4. 定期测试和监控

*测试完成时间: $(date '+%Y-%m-%d %H:%M:%S')*
EOF

echo "📁 测试报告已生成:"
echo "  - 详细结果: $TEST_RESULTS"
echo "  - 摘要报告: $SUMMARY_REPORT"
echo ""
echo "🎯 测试结论: $APPROVAL_STATUS"
echo ""
echo "🧪 技能测试完成！"