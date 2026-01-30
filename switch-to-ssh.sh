#!/bin/bash

echo "🔄 GitHub远程仓库切换到SSH协议"
echo "========================================"

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 检查当前目录是否是git仓库
if [ ! -d .git ]; then
    echo -e "${RED}❌ 当前目录不是Git仓库${NC}"
    echo "请进入项目目录：cd /Users/lijian/clawd"
    exit 1
fi

# 显示当前远程配置
echo -e "${BLUE}📊 当前远程配置：${NC}"
git remote -v
echo ""

# 检查是否已有origin远程
if ! git remote | grep -q origin; then
    echo -e "${YELLOW}⚠️  未找到origin远程仓库${NC}"
    echo "请先添加远程仓库："
    echo "  git remote add origin https://github.com/flyskyson/clawd-moss.git"
    echo ""
    echo -e "${YELLOW}是否现在添加？(y/n)${NC}"
    read -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git remote add origin https://github.com/flyskyson/clawd-moss.git
        echo -e "${GREEN}✅ 已添加origin远程仓库${NC}"
    else
        echo "操作取消"
        exit 0
    fi
fi

# 获取当前远程URL
CURRENT_URL=$(git remote get-url origin)
echo -e "${BLUE}📡 当前远程URL：${NC}"
echo "  $CURRENT_URL"
echo ""

# 判断当前协议
if [[ $CURRENT_URL == https://* ]]; then
    echo -e "${YELLOW}⚠️  当前使用HTTPS协议，建议切换到SSH${NC}"
    echo "HTTPS可能需要每次输入凭证，SSH更安全方便"
    echo ""
    
    # 切换到SSH
    NEW_URL="git@github.com:flyskyson/clawd-moss.git"
    echo -e "${YELLOW}GitHub用户: flyskyson${NC}"
    echo -e "${YELLOW}仓库: clawd-moss${NC}"
    echo -e "${BLUE}🔄 切换到SSH协议：${NC}"
    echo "  $NEW_URL"
    echo ""
    
    echo -e "${YELLOW}是否确认切换？(y/n)${NC}"
    read -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git remote set-url origin "$NEW_URL"
        echo -e "${GREEN}✅ 已切换到SSH协议${NC}"
    else
        echo "操作取消"
        exit 0
    fi
elif [[ $CURRENT_URL == git@github.com:* ]]; then
    echo -e "${GREEN}✅ 当前已使用SSH协议${NC}"
    echo "无需切换"
else
    echo -e "${YELLOW}⚠️  未知的远程协议：${NC}"
    echo "  $CURRENT_URL"
    echo "建议使用SSH协议"
fi

# 显示新的远程配置
echo ""
echo -e "${BLUE}📊 新的远程配置：${NC}"
git remote -v
echo ""

# 测试远程连接
echo -e "${BLUE}🔗 测试远程连接...${NC}"
if git ls-remote origin > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 远程仓库可访问${NC}"
    
    # 显示仓库信息
    echo ""
    echo -e "${BLUE}📈 仓库状态：${NC}"
    echo "本地分支: $(git branch --show-current)"
    
    # 获取远程分支信息
    REMOTE_BRANCHES=$(git ls-remote --heads origin | wc -l)
    echo "远程分支数: $REMOTE_BRANCHES"
    
    # 检查是否有未推送的提交
    LOCAL_HASH=$(git rev-parse HEAD)
    REMOTE_HASH=$(git ls-remote origin HEAD | cut -f1)
    
    if [ "$LOCAL_HASH" = "$REMOTE_HASH" ]; then
        echo -e "${GREEN}✅ 本地和远程代码一致${NC}"
    else
        echo -e "${YELLOW}⚠️  本地和远程代码不一致${NC}"
        echo "本地: $LOCAL_HASH"
        echo "远程: $REMOTE_HASH"
    fi
else
    echo -e "${RED}❌ 无法访问远程仓库${NC}"
    echo "请检查："
    echo "1. SSH密钥是否已添加到GitHub"
    echo "2. 网络连接是否正常"
    echo "3. 仓库地址是否正确"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ 远程仓库配置完成！${NC}"
echo -e "${GREEN}下一步：推送代码到远程仓库${NC}"
echo -e "${GREEN}========================================${NC}"