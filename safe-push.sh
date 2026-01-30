#!/bin/bash

echo "🚀 安全推送脚本 v1.0"
echo "========================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查当前目录
if [ ! -d .git ]; then
    echo -e "${RED}❌ 当前目录不是Git仓库${NC}"
    exit 1
fi

# 检查远程仓库
if ! git remote | grep -q origin; then
    echo -e "${RED}❌ 未配置远程仓库${NC}"
    echo "请先配置远程仓库："
    echo "  git remote add origin git@github.com:flyskyson/clawd-moss.git"
    exit 1
fi

echo -e "${BLUE}📊 检查Git状态...${NC}"

# 显示简洁状态
STATUS_OUTPUT=$(git status --short)
if [[ -n "$STATUS_OUTPUT" ]]; then
    echo -e "${YELLOW}📝 有未提交的更改：${NC}"
    echo "$STATUS_OUTPUT"
    echo ""
    
    echo -e "${YELLOW}是否先提交这些更改？(y/n)${NC}"
    read -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}💾 提交更改...${NC}"
        
        # 自动生成提交信息
        COMMIT_MSG="更新: $(date '+%Y-%m-%d %H:%M:%S')"
        
        # 如果有具体文件，可以更详细
        FILE_COUNT=$(echo "$STATUS_OUTPUT" | wc -l | tr -d ' ')
        if [ "$FILE_COUNT" -eq 1 ]; then
            FILE=$(echo "$STATUS_OUTPUT" | awk '{print $2}')
            COMMIT_MSG="更新 $FILE"
        elif [ "$FILE_COUNT" -lt 5 ]; then
            COMMIT_MSG="更新多个文件 ($FILE_COUNT 个)"
        fi
        
        echo -e "${YELLOW}提交信息: ${COMMIT_MSG}${NC}"
        echo -e "${YELLOW}确认提交？(y/n)${NC}"
        read -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git add .
            git commit -m "$COMMIT_MSG"
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✅ 提交成功！${NC}"
            else
                echo -e "${RED}❌ 提交失败${NC}"
                exit 1
            fi
        else
            echo "提交取消"
            exit 0
        fi
    else
        echo -e "${YELLOW}⚠️  跳过提交，直接推送${NC}"
    fi
else
    echo -e "${GREEN}✅ 工作区干净，没有未提交的更改${NC}"
fi

# 检查远程连接
echo ""
echo -e "${BLUE}🔗 测试远程连接...${NC}"
if git ls-remote origin > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 远程仓库可访问${NC}"
else
    echo -e "${RED}❌ 无法访问远程仓库${NC}"
    echo "请检查："
    echo "1. 网络连接"
    echo "2. SSH密钥配置"
    echo "3. 远程URL是否正确"
    exit 1
fi

# 获取本地和远程差异
echo ""
echo -e "${BLUE}📈 检查代码差异...${NC}"
LOCAL_HASH=$(git rev-parse HEAD)
REMOTE_HASH=$(git ls-remote origin HEAD 2>/dev/null | cut -f1)

if [ -z "$REMOTE_HASH" ]; then
    echo -e "${YELLOW}⚠️  远程仓库为空，首次推送${NC}"
    REMOTE_HASH="空仓库"
else
    if [ "$LOCAL_HASH" = "$REMOTE_HASH" ]; then
        echo -e "${GREEN}✅ 本地和远程代码一致${NC}"
    else
        echo -e "${YELLOW}⚠️  本地和远程代码不一致${NC}"
        echo "本地: $LOCAL_HASH"
        echo "远程: $REMOTE_HASH"
        
        # 检查是否有需要拉取的更改
        echo ""
        echo -e "${YELLOW}是否先拉取远程更改？(y/n)${NC}"
        read -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}⬇️  拉取远程更改...${NC}"
            git pull origin main
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✅ 拉取成功${NC}"
            else
                echo -e "${RED}❌ 拉取失败，可能有冲突${NC}"
                echo "请手动解决冲突后再推送"
                exit 1
            fi
        fi
    fi
fi

# 确认推送
echo ""
echo -e "${YELLOW}🚀 准备推送代码到GitHub${NC}"
echo -e "${BLUE}用户: flyskyson${NC}"
echo -e "${BLUE}仓库: clawd-moss${NC}"
echo -e "${BLUE}分支: main${NC}"
echo ""
echo -e "${YELLOW}是否确认推送？(y/n)${NC}"
read -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "操作取消"
    exit 0
fi

# 执行推送
echo -e "${BLUE}🔄 正在推送...${NC}"
if git push -u origin main; then
    echo -e "${GREEN}✅ 推送成功！${NC}"
    
    # 显示推送结果
    echo ""
    echo -e "${BLUE}📊 推送结果：${NC}"
    echo "最新提交:"
    git log --oneline -1
    
    # 显示分支信息
    echo ""
    echo "远程分支状态:"
    git branch -vv | grep main
    
else
    echo -e "${RED}❌ 推送失败${NC}"
    echo "可能的原因："
    echo "1. 权限不足"
    echo "2. 冲突需要解决"
    echo "3. 网络问题"
    echo "4. 远程仓库设置问题"
    exit 1
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}🎉 GitHub配置完成！${NC}"
echo -e "${GREEN}✅ SSH密钥配置完成${NC}"
echo -e "${GREEN}✅ 远程仓库切换完成${NC}"
echo -e "${GREEN}✅ 代码推送完成${NC}"
echo -e "${GREEN}========================================${NC}"

# 后续建议
echo ""
echo -e "${BLUE}💡 后续建议：${NC}"
echo "1. 设置自动同步：创建定时任务自动推送"
echo "2. 配置GitHub Actions：自动化测试和部署"
echo "3. 设置分支保护：保护main分支"
echo "4. 添加.gitignore：忽略不必要的文件"